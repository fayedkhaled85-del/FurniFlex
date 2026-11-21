<?php
declare(strict_types=1);

function workflow_query(string $sql, array $params=[]): PDOStatement {
    $statement=db()->prepare($sql);
    $statement->execute($params);
    return $statement;
}

function workflow_admin_notice(string $message, int $order): void {
    foreach(workflow_query("SELECT user_id FROM users WHERE role='admin' AND account_status='active'")->fetchAll(PDO::FETCH_COLUMN) as $id)
        notify((int)$id,$message,'order',$order);
}

function accept_quoted_order(): never {
    $customer=require_role('customer');
    $id=(int)($_POST['quotation_id']??0);
    db()->beginTransaction();
    $quote=workflow_query("SELECT q.*,r.user_id FROM quotations q JOIN custom_requests r USING(request_id)
        WHERE q.quotation_id=? AND r.user_id=? FOR UPDATE",[$id,$customer['user_id']])->fetch();
    if(!$quote)throw new RuntimeException('Quotation unavailable.');
    $linked=workflow_query('SELECT order_id FROM production_orders WHERE quotation_id=?',[$id])->fetchColumn();
    if($linked){db()->commit();redirect('?page=order&id='.$linked);}
    if($quote['status']!=='Sent' || ($quote['valid_until'] && $quote['valid_until']<workflow_query('SELECT CURRENT_DATE')->fetchColumn()))
        throw new RuntimeException('Only a current sent quotation can be accepted.');
    $rid=$quote['request_id'];
    $request=workflow_query('SELECT * FROM custom_requests WHERE request_id=? FOR UPDATE',[$rid])->fetch();
    if($request['request_status']!=='Quotation Sent' || workflow_query("SELECT quotation_id FROM quotations WHERE request_id=? AND status='Accepted'",[$rid])->fetchColumn())
        throw new RuntimeException('This request is no longer awaiting acceptance.');
    $address=trim((string)($_POST['address']??''));
    if($address==='' || mb_strlen($address)>1000)throw new RuntimeException('Enter a delivery address of up to 1000 characters.');
    $snapshot=['request'=>$request,'quotation'=>$quote,'images'=>workflow_query('SELECT image_path FROM request_images WHERE request_id=?',[$rid])->fetchAll(PDO::FETCH_COLUMN),
        'reviews'=>workflow_query('SELECT * FROM manufacturer_reviews WHERE request_id=? ORDER BY review_date',[$rid])->fetchAll()];
    workflow_query("INSERT INTO orders(user_id,total_amount,status,delivery_address,payment_method) VALUES(?,?,'Confirmed',?,'Cash on Delivery')",[$customer['user_id'],$quote['price'],$address]);
    $order=(int)db()->lastInsertId();
    workflow_query('INSERT INTO order_items(order_id,product_id,quantity,unit_price,subtotal,product_name_snapshot) VALUES(?,NULL,1,?,?,?)',[$order,$quote['price'],$quote['price'],$request['title']?:$request['furniture_type']]);
    workflow_query("INSERT INTO production_orders(order_id,quotation_id,request_id,stage,specification) VALUES(?,?,?,'Awaiting assignment',?)",[$order,$id,$rid,json_encode($snapshot,JSON_THROW_ON_ERROR)]);
    workflow_query("INSERT INTO payments(order_id,amount,payment_method,payment_status) VALUES(?,?,'Cash on Delivery','Pending')",[$order,$quote['price']]);
    workflow_query("UPDATE quotations SET status='Accepted',accepted_at=NOW() WHERE quotation_id=?",[$id]);
    workflow_query("UPDATE quotations SET status='Cancelled' WHERE request_id=? AND quotation_id<>? AND status IN ('Draft','Sent')",[$rid,$id]);
    workflow_query("UPDATE custom_requests SET request_status='Accepted' WHERE request_id=?",[$rid]);
    workflow_query("INSERT INTO order_status_history(order_id,status,notes,updated_by) VALUES(?,'Confirmed','Customer accepted quotation',?)",[$order,$customer['user_id']]);
    workflow_admin_notice("Custom order #$order needs production assignment.",$order);
    notify((int)$customer['user_id'],"Quotation accepted. Order #$order created.",'order',$order);
    db()->commit();
    redirect('?page=order&id='.$order);
}

// action => permitted role, required stage, next stage, customer order status
function production_steps(): array {
    return [
        'Assign'=>['admin','Awaiting assignment','Assigned','Confirmed'],
        'Accept'=>['manufacturer','Assigned','In production','Manufacturing'],
        'Reject'=>['manufacturer','Assigned','Awaiting assignment','Confirmed'],
        'Progress'=>['manufacturer','In production','In production','Manufacturing'],
        'Complete'=>['manufacturer','In production','Awaiting QC','Manufacturing'],
        'Rework'=>['admin','Awaiting QC','In production','Manufacturing'],
        'Approve QC'=>['admin','Awaiting QC','Ready for shipment','Manufacturing'],
        'Ship'=>['admin','Ready for shipment','Shipped','Shipped'],
        'Deliver'=>['admin','Shipped','Delivered','Delivered'],
        'Confirm receipt'=>['customer','Delivered','Receipt confirmed','Delivered']
    ];
}

function production_update(): never {
    $action=(string)($_POST['step']??'');
    $rule=production_steps()[$action]??null;
    if(!$rule)throw new RuntimeException('Unknown production step.');
    [$role,$from,$to,$status]=$rule;
    $user=require_role($role);
    $order=(int)($_POST['order_id']??0);
    db()->beginTransaction();
    $row=workflow_query('SELECT p.*,o.user_id FROM production_orders p JOIN orders o USING(order_id) WHERE order_id=? FOR UPDATE',[$order])->fetch();
    if(!$row || ($role==='manufacturer' && $row['manufacturer_id']!=$user['user_id']) || ($role==='customer' && $row['user_id']!=$user['user_id']))
        throw new RuntimeException('Order unavailable.');
    if($row['stage']!==$from)throw new RuntimeException('This step is unavailable at the current stage.');
    $notes=trim((string)($_POST['notes']??''));
    if(mb_strlen($notes)>1000 || ($notes==='' && in_array($action,['Progress','Complete','Rework','Reject','Approve QC'],true)))throw new RuntimeException('Enter a production note (up to 1000 characters).');
    $manufacturer=$row['manufacturer_id'];
    if($action==='Assign'){
        $manufacturer=(int)($_POST['manufacturer_id']??0);
        if(!workflow_query("SELECT user_id FROM users WHERE user_id=? AND role='manufacturer' AND account_status='active' FOR UPDATE",[$manufacturer])->fetchColumn())throw new RuntimeException('Choose an active manufacturer.');
    }
    if($action==='Reject')$manufacturer=null;
    $carrier=$row['carrier'];$tracking=$row['tracking_reference'];
    if($action==='Ship'){
        $carrier=trim((string)($_POST['carrier']??''));$tracking=trim((string)($_POST['tracking']??''));
        if(!$carrier||!$tracking||mb_strlen($carrier)>100||mb_strlen($tracking)>120)throw new RuntimeException('Enter a carrier and tracking reference.');
    }
    workflow_query('UPDATE production_orders SET stage=?,manufacturer_id=?,carrier=?,tracking_reference=? WHERE order_id=?',[$to,$manufacturer,$carrier,$tracking,$order]);
    workflow_query('UPDATE orders SET status=? WHERE order_id=?',[$status,$order]);
    workflow_query('INSERT INTO order_status_history(order_id,status,notes,updated_by) VALUES(?,?,?,?)',[$order,$status,trim("$action — $to. $notes"),$user['user_id']]);
    $message="Custom order #$order: $to.";
    notify((int)$row['user_id'],$message,'order',$order);
    if($manufacturer && $role!=='manufacturer')notify((int)$manufacturer,$message,'order',$order);
    if($role!=='admin')workflow_admin_notice($message,$order);
    db()->commit();redirect('?page=production');
}

function production_page(): void {
    $user=require_login();$role=$user['role'];
    $where=['admin'=>'','customer'=>' WHERE o.user_id=?','manufacturer'=>' WHERE p.manufacturer_id=?'][$role];
    $rows=workflow_query('SELECT p.*,o.total_amount,o.delivery_address FROM production_orders p JOIN orders o USING(order_id)'.$where.' ORDER BY order_id DESC',$role==='admin'?[]:[$user['user_id']])->fetchAll();
    ?><h1>Custom order production</h1><p>Shipping and delivery are recorded locally for demonstration.</p><?php
    if(!$rows)echo '<p>No custom orders available.</p>';
    foreach($rows as $row){
        $s=json_decode($row['specification'],true);$r=$s['request'];$id=$row['order_id'];?>
        <article class="card p-3 mb-3" data-production-order="<?=$id?>"><h2 class="h5">Order #<?=$id?> · <?=e($r['title']?:$r['furniture_type'])?></h2>
        <p><?=e($row['stage'])?> · <?=money($row['total_amount'])?> · Quotation #<?=$row['quotation_id']?></p>
        <p><?=e($r['description'])?> · <?=e(implode(' × ',[$r['required_width'],$r['required_depth'],$r['required_height']]))?> cm · <?=e($r['preferred_material'])?> <?=e($r['preferred_color'])?></p>
        <?php if ($s['images']) {
            $imageIds = workflow_query('SELECT image_path,request_image_id FROM request_images WHERE request_id=?', [$row['request_id']])->fetchAll(PDO::FETCH_KEY_PAIR);
            foreach ($s['images'] as $path) {
                if (isset($imageIds[$path])) { ?><a href="?page=request-image&amp;id=<?=(int)$imageIds[$path]?>">Reference image</a><?php }
            }
        } ?>
        <?php foreach($s['reviews'] as $review):?><p><?=e($review['technical_notes'])?> · <?=e($review['material_availability'])?></p><?php endforeach;?>
        <?php if($row['carrier']):?><p>Simulated shipment · <?=e($row['carrier'])?> · <?=e($row['tracking_reference'])?></p><?php endif;?>
        <?php foreach(production_steps() as $action=>[$permitted,$stage]){if($role!==$permitted||$row['stage']!==$stage)continue;?>
        <form method="post" class="mt-2"><?=csrf_field()?><input type="hidden" name="action" value="production_update"><input type="hidden" name="order_id" value="<?=$id?>">
        <?php if($action==='Assign'):?><label>Manufacturer <select name="manufacturer_id" required><?php foreach(workflow_query("SELECT user_id,full_name FROM users WHERE role='manufacturer' AND account_status='active'") as $m):?><option value="<?=$m['user_id']?>"><?=e($m['full_name'])?></option><?php endforeach;?></select></label><?php endif;?>
        <?php if(in_array($action,['Complete','Progress','Rework','Reject','Approve QC'],true)):?><label>Notes <input name="notes" required maxlength="1000"></label><?php endif;?>
        <?php if($action==='Ship'):?><label>Carrier <input name="carrier" required maxlength="100"></label> <label>Tracking reference <input name="tracking" required maxlength="120"></label><?php endif;?>
        <input type="hidden" name="step" value="<?=e($action)?>"><button class="btn btn-primary" type="submit"><?=e($action)?></button></form><?php }?></article><?php
    }
}
