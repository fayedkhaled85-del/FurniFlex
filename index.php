<?php
declare(strict_types=1);
require __DIR__ . '/includes/bootstrap.php';
require_once __DIR__.'/includes/production.php';
header('X-Content-Type-Options: nosniff');
header('X-Frame-Options: DENY');
header('Referrer-Policy: no-referrer');
$route = $_GET['page'] ?? 'home';
$route = ['my-requests'=>'requests','assigned-requests'=>'requests','my-quotations'=>'quotations','order-details'=>'order','request-details'=>'requests','quotation-details'=>'quotations'][$route] ?? $route;
$method = $_SERVER['REQUEST_METHOD'];
if ($route === 'request-image' && in_array($method, ['GET', 'HEAD'], true)) {
    $user = require_login();
    $q = db()->prepare('SELECT i.image_path FROM request_images i JOIN custom_requests r USING(request_id)
        WHERE i.request_image_id=? AND (?="admin" OR (?="customer" AND r.user_id=?) OR (?="manufacturer" AND (r.assigned_manufacturer_id=? OR EXISTS (SELECT 1 FROM production_orders p WHERE p.request_id=r.request_id AND p.manufacturer_id=?))))');
    $q->execute([(int)($_GET['id'] ?? 0), $user['role'], $user['role'], $user['user_id'], $user['role'], $user['user_id'], $user['user_id']]);
    $folder = realpath(__DIR__.'/uploads/custom-requests');
    $stored = $q->fetchColumn();
    $path = $stored ? realpath(__DIR__.'/'.$stored) : false;
    if (!$folder || !$path || dirname($path) !== $folder || !is_file($path)) { http_response_code(404); exit; }
    $mime = (new finfo(FILEINFO_MIME_TYPE))->file($path);
    if (!in_array($mime, ['image/jpeg','image/png','image/webp'], true)) { http_response_code(404); exit; }
    header('Content-Type: '.$mime);
    header('Cache-Control: private, no-store');
    if ($method === 'GET') readfile($path);
    exit;
}

if ($method === 'POST') {
    try {
    csrf_check();
    $action = $_POST['action'] ?? '';
        if ($action==='production_update') production_update();
        if ($action==='quotation_reply' && ($_POST['status']??'')==='Accepted') accept_quoted_order();
        if (advanced_action((string)$action)) return;
        switch ($action) {
            case 'register':
                $name=trim($_POST['full_name']??''); $email=filter_var($_POST['email']??'',FILTER_VALIDATE_EMAIL); $pw=(string)($_POST['password']??'');
                if (!$name || !$email || strlen($pw)<8) throw new RuntimeException('Enter a name, valid email, and password of at least 8 characters.');
                $q=db()->prepare('SELECT 1 FROM users WHERE email=? LIMIT 1');$q->execute([$email]);
                if($q->fetchColumn()){$_SESSION['register_email']=$email;$_SESSION['register_email_error']='This email address is already registered. Please use another email.';redirect('?page=register');}
                try{$q=db()->prepare("INSERT INTO users(full_name,email,password_hash,phone,role) VALUES(?,?,?,?,'customer')");$q->execute([$name,$email,password_hash($pw,PASSWORD_DEFAULT),trim($_POST['phone']??'')]);}
                catch(PDOException $e){if((string)$e->getCode()==='23000'){$_SESSION['register_email']=$email;$_SESSION['register_email_error']='This email address is already registered. Please use another email.';redirect('?page=register');}throw $e;}
                flash('Your account has been created successfully! Please log in to continue.'); redirect('?page=login');
            case 'login':
                $email=trim((string)($_POST['email']??''));$q=db()->prepare('SELECT * FROM users WHERE email=? AND account_status="active"'); $q->execute([$email]); $u=$q->fetch();
                if (!$u || !password_verify((string)($_POST['password']??''),$u['password_hash'])) { $_SESSION['login_email']=$email;flash('Invalid email or password. Please try again.','danger');redirect('?page=login'); }
                unset($_SESSION['login_email']);session_regenerate_id(true); $_SESSION['user_id']=(int)$u['user_id']; $_SESSION['auth_version']=(int)$u['auth_version']; redirect('?page=dashboard');
            case 'logout': unset($_SESSION['user_id'],$_SESSION['auth_version']); session_regenerate_id(true); redirect('?');
            case 'add_cart':
                require_role('customer'); $pid=(int)$_POST['product_id']; $qty=max(1,min(99,(int)($_POST['quantity']??1))); $p=product($pid);
                if (!$p || $p['availability']!=='In Stock') throw new RuntimeException('This product is unavailable.');
                $cart=active_cart(current_user()['user_id']); $ci=db()->prepare('INSERT INTO cart_items(cart_id,product_id,quantity,unit_price) VALUES(?,?,?,?)'); $ci->execute([$cart,$pid,$qty,$p['base_price']]); flash('Product added to your cart.'); redirect('?page=cart');
            case 'update_cart':
                require_role('customer'); foreach(($_POST['qty']??[]) as $id=>$qty){$q=db()->prepare('UPDATE cart_items ci JOIN carts c ON ci.cart_id=c.cart_id SET ci.quantity=? WHERE ci.cart_item_id=? AND c.user_id=? AND c.cart_status="active"');$q->execute([max(1,min(99,(int)$qty)),(int)$id,current_user()['user_id']]);} flash('Cart updated.'); redirect('?page=cart');
            case 'remove_cart':
                require_role('customer'); $q=db()->prepare('DELETE ci FROM cart_items ci JOIN carts c ON ci.cart_id=c.cart_id WHERE ci.cart_item_id=? AND c.user_id=? AND c.cart_status="active"');$q->execute([(int)$_POST['item_id'],current_user()['user_id']]); redirect('?page=cart');
            case 'checkout':
                require_role('customer'); $u=current_user(); if(trim($_POST['address']??'')==='') throw new RuntimeException('Delivery address is required.');
                $pdo=db();$pdo->beginTransaction();
                $active=$pdo->prepare("SELECT cart_id FROM carts WHERE user_id=? AND cart_status='active' ORDER BY cart_id DESC LIMIT 1 FOR UPDATE");
                $active->execute([$u['user_id']]);$cart=$active->fetchColumn();
                if(!$cart)throw new RuntimeException('Your cart is empty or has already been checked out.');
                $items=$pdo->prepare('SELECT ci.*,p.name,p.availability FROM cart_items ci JOIN products p ON p.product_id=ci.product_id WHERE ci.cart_id=? FOR UPDATE');$items->execute([$cart]);$rows=$items->fetchAll();if(!$rows)throw new RuntimeException('Your cart is empty.');$total=0;foreach($rows as $r){if($r['availability']!=='In Stock')throw new RuntimeException($r['name'].' is no longer available.');$total+=(float)$r['unit_price']*(int)$r['quantity'];}
                $q=$pdo->prepare('INSERT INTO orders(user_id,total_amount,status,delivery_address,payment_method) VALUES(?,?,"Pending",?,?)');$q->execute([$u['user_id'],$total,trim($_POST['address']),$_POST['payment_method']==='Online'?'Simulated Online Payment':'Cash on Delivery']);$oid=(int)$pdo->lastInsertId();
                foreach($rows as $r){$q=$pdo->prepare('INSERT INTO order_items(order_id,product_id,quantity,unit_price,subtotal,product_name_snapshot) VALUES(?,?,?,?,?,?)');$q->execute([$oid,$r['product_id'],$r['quantity'],$r['unit_price'],$r['unit_price']*$r['quantity'],$r['name']]);$orderItemId=(int)$pdo->lastInsertId();$cq=$pdo->prepare('SELECT option_id,selected_value,additional_cost FROM cart_item_customizations WHERE cart_item_id=?');$cq->execute([$r['cart_item_id']]);$copy=$pdo->prepare('INSERT INTO order_item_customizations(order_item_id,option_id,selected_value,additional_cost) VALUES(?,?,?,?)');foreach($cq as $custom)$copy->execute([$orderItemId,$custom['option_id'],$custom['selected_value'],$custom['additional_cost']]);$cc=$pdo->prepare('SELECT component_key,component_label,spec_json,additional_cost FROM cart_item_component_snapshots WHERE cart_item_id=?');$cc->execute([$r['cart_item_id']]);$componentCopy=$pdo->prepare('INSERT INTO order_item_component_snapshots(order_item_id,component_key,component_label,spec_json,additional_cost) VALUES(?,?,?,?,?)');foreach($cc as $component)$componentCopy->execute([$orderItemId,$component['component_key'],$component['component_label'],$component['spec_json'],$component['additional_cost']]);}
                $pdo->prepare('INSERT INTO order_status_history(order_id,status,notes,updated_by) VALUES(?,"Pending","Order placed",?)')->execute([$oid,$u['user_id']]);$pdo->prepare('INSERT INTO payments(order_id,amount,payment_method,payment_status) VALUES(?,?,?,?)')->execute([$oid,$total,$_POST['payment_method']==='Online'?'Simulated Online Payment':'Cash on Delivery','Pending']);$pdo->prepare('UPDATE carts SET cart_status="ordered" WHERE cart_id=?')->execute([$cart]); notify($u['user_id'],'Your order #'.$oid.' has been placed.','order',$oid);$pdo->commit();redirect('?page=order&id='.$oid);
            case 'custom_request':
                require_role('customer'); $required=['furniture_type','description','required_width','required_height','required_depth'];foreach($required as $f)if(trim((string)($_POST[$f]??''))==='')throw new RuntimeException('Please complete all required request fields.');
                foreach(["required_width","required_height","required_depth"] as $dimension){$value=$_POST[$dimension]??null;if(!is_numeric($value)||(float)$value<=0)throw new RuntimeException("Dimensions must be positive numbers.");}
                $validFiles=[];$files=$_FILES['references']??null;if($files&&is_array($files['name'])){if(count($files['name'])>5)throw new RuntimeException('Upload up to five reference images.');$finfo=new finfo(FILEINFO_MIME_TYPE);foreach($files['name'] as $i=>$original){if(($files['error'][$i]??UPLOAD_ERR_NO_FILE)===UPLOAD_ERR_NO_FILE)continue;if($files['error'][$i]!==UPLOAD_ERR_OK||$files['size'][$i]>5*1024*1024)throw new RuntimeException('Each image must be under 5 MB.');$mime=$finfo->file($files['tmp_name'][$i]);$ext=['image/jpeg'=>'jpg','image/png'=>'png','image/webp'=>'webp'][$mime]??null;$info=getimagesize($files['tmp_name'][$i]);if(!$ext||!$info||$info[0]>6000||$info[1]>6000||$info[0]*$info[1]>30000000)throw new RuntimeException('Reference images must be valid JPEG, PNG or WebP files under 30 megapixels.');$validFiles[]=[$files['tmp_name'][$i],bin2hex(random_bytes(16)).'.'.$ext];}}
                $uploadedFiles=[];db()->beginTransaction();
                try {
                $q=db()->prepare('INSERT INTO custom_requests(user_id,furniture_type,title,description,required_width,required_height,required_depth,preferred_material,preferred_color,special_requirements) VALUES(?,?,?,?,?,?,?,?,?,?)');$q->execute([current_user()['user_id'],trim($_POST['furniture_type']),trim($_POST['title']??''),trim($_POST['description']),(float)$_POST['required_width'],(float)$_POST['required_height'],(float)$_POST['required_depth'],trim($_POST['preferred_material']??''),trim($_POST['preferred_color']??''),trim($_POST['special_requirements']??'')]);$rid=(int)db()->lastInsertId();$dir=__DIR__.'/uploads/custom-requests';if(!is_dir($dir)&&!mkdir($dir,0750,true))throw new RuntimeException('Could not prepare the upload folder.');foreach($validFiles as [$tmp,$filename]){if(!move_uploaded_file($tmp,$dir.'/'.$filename))throw new RuntimeException('Could not save a reference image.');$uploadedFiles[]=$dir.'/'.$filename;$q=db()->prepare('INSERT INTO request_images(request_id,image_path) VALUES(?,?)');$q->execute([$rid,'uploads/custom-requests/'.$filename]);}$admins=db()->query("SELECT user_id FROM users WHERE role='admin'")->fetchAll(PDO::FETCH_COLUMN);foreach($admins as $aid)notify((int)$aid,'A new custom furniture request needs review.','request',$rid);db()->commit();
                } catch(Throwable $error) {
                    if(db()->inTransaction())db()->rollBack();
                    foreach($uploadedFiles as $file)if(is_file($file))unlink($file);
                    throw $error;
                }
                flash('Your custom request has been submitted.');redirect('?page=my-requests');
            case 'assign':
                require_role('admin');
                $rid=(int)($_POST['request_id']??0);$mid=(int)($_POST['manufacturer_id']??0);
                $pdo=db();$pdo->beginTransaction();
                $request=$pdo->prepare('SELECT request_id FROM custom_requests WHERE request_id=? AND request_status NOT IN ("Accepted","Rejected","Cancelled") FOR UPDATE');$request->execute([$rid]);
                $manufacturer=$pdo->prepare('SELECT user_id FROM users WHERE user_id=? AND role="manufacturer" AND account_status="active"');$manufacturer->execute([$mid]);
                if(!$request->fetchColumn()||!$manufacturer->fetchColumn())throw new RuntimeException('Choose an existing request and an active manufacturer.');
                $pdo->prepare('UPDATE custom_requests SET assigned_manufacturer_id=?,request_status="Under Technical Review" WHERE request_id=?')->execute([$mid,$rid]);
                notify($mid,'A custom furniture request has been assigned to you.','request',$rid);$pdo->commit();redirect('?page=requests');
            case 'review':
                require_role('manufacturer');$rid=(int)($_POST['request_id']??0);$feasibility=(string)($_POST['feasibility']??'');$notes=trim((string)($_POST['technical_notes']??''));$materials=trim((string)($_POST['material_availability']??''));$time=trim((string)($_POST['estimated_time']??''));$mods=trim((string)($_POST['recommended_modifications']??''));
                if(!in_array($feasibility,['Feasible','Not Feasible','Feasible with Modifications'],true)||$notes===''||mb_strlen($notes)>10000||mb_strlen($materials)>180||mb_strlen($time)>100||mb_strlen($mods)>5000)throw new RuntimeException('Enter a valid feasibility result and technical notes.');
                $pdo=db();$pdo->beginTransaction();$q=$pdo->prepare('SELECT request_id FROM custom_requests WHERE request_id=? AND request_status NOT IN ("Accepted","Rejected","Cancelled") AND assigned_manufacturer_id=? FOR UPDATE');$q->execute([$rid,current_user()['user_id']]);if(!$q->fetch())throw new RuntimeException('This request is not assigned to you.');
                $q=$pdo->prepare('INSERT INTO manufacturer_reviews(request_id,manufacturer_id,technical_notes,feasibility,material_availability,estimated_time,recommended_modifications) VALUES(?,?,?,?,?,?,?)');$q->execute([$rid,current_user()['user_id'],$notes,$feasibility,$materials,$time,$mods]);$pdo->prepare('UPDATE custom_requests SET request_status="Technical Review Completed" WHERE request_id=?')->execute([$rid]);foreach($pdo->query("SELECT user_id FROM users WHERE role='admin'")->fetchAll(PDO::FETCH_COLUMN) as $aid)notify((int)$aid,'Manufacturer technical review submitted.','request',$rid);$pdo->commit();redirect('?page=requests');
            case 'quotation':
                require_role('admin');$rid=(int)($_POST['request_id']??0);$price=filter_var($_POST['price']??null,FILTER_VALIDATE_FLOAT);$time=trim((string)($_POST['estimated_time']??''));$validUntil=trim((string)($_POST['valid_until']??''));$notes=trim((string)($_POST['notes']??''));$status=isset($_POST['send'])?'Sent':'Draft';
                if($price===false||!is_finite((float)$price)||(float)$price<=0||$time===''||mb_strlen($time)>100||mb_strlen($notes)>5000||($validUntil!==''&&(!preg_match('/^\d{4}-\d{2}-\d{2}$/',$validUntil)||!checkdate((int)substr($validUntil,5,2),(int)substr($validUntil,8,2),(int)substr($validUntil,0,4)))))throw new RuntimeException('Enter a positive quotation price, estimated time, and valid expiry date.');
                $pdo=db();$pdo->beginTransaction();$request=$pdo->prepare('SELECT user_id FROM custom_requests WHERE request_id=? AND request_status NOT IN ("Accepted","Rejected","Cancelled") FOR UPDATE');$request->execute([$rid]);$customerId=$request->fetchColumn();if(!$customerId)throw new RuntimeException('Request not found.');$q=$pdo->prepare('INSERT INTO quotations(request_id,admin_id,price,estimated_time,valid_until,notes,status) VALUES(?,?,?,?,?,?,?)');$q->execute([$rid,current_user()['user_id'],(float)$price,$time,$validUntil!==''?$validUntil:null,$notes,$status]);$qid=(int)$pdo->lastInsertId();if($status==='Sent'){notify((int)$customerId,'A quotation is ready for your custom furniture request.','quotation',$qid);$pdo->prepare('UPDATE custom_requests SET request_status="Quotation Sent" WHERE request_id=?')->execute([$rid]);}$pdo->commit();redirect('?page=requests');
            case 'quotation_reply':
                require_role('customer');$status=(string)($_POST['status']??'');if(!in_array($status,['Accepted','Rejected'],true))throw new RuntimeException('Choose Accepted or Rejected.');$qid=(int)($_POST['quotation_id']??0);$pdo=db();$pdo->beginTransaction();$q=$pdo->prepare('UPDATE quotations q JOIN custom_requests r ON r.request_id=q.request_id SET q.status=?,q.accepted_at=IF(?="Accepted",NOW(),NULL),r.request_status=? WHERE q.quotation_id=? AND r.user_id=? AND q.status="Sent"');$q->execute([$status,$status,$status,$qid,current_user()['user_id']]);if(!$q->rowCount())throw new RuntimeException('Quotation could not be updated.');foreach($pdo->query("SELECT user_id FROM users WHERE role='admin'")->fetchAll(PDO::FETCH_COLUMN) as $aid)notify((int)$aid,'A customer '.$status.' a quotation.','quotation',$qid);$pdo->commit();redirect('?page=quotations');
            case 'status':
                require_role('admin');$allowed=['Confirmed','Processing','Manufacturing','Shipped','Delivered','Cancelled'];$s=(string)($_POST['status']??'');if(!in_array($s,$allowed,true))throw new RuntimeException('Invalid order status.');$oid=(int)($_POST['order_id']??0);$pdo=db();$pdo->beginTransaction();$q=$pdo->prepare('SELECT user_id,status FROM orders WHERE order_id=? FOR UPDATE');
                $q->execute([$oid]);
                $order=$q->fetch();
                if(!$order)throw new RuntimeException('Order not found.');
                if(workflow_query('SELECT order_id FROM production_orders WHERE order_id=?',[$oid])->fetchColumn())throw new RuntimeException('Use Custom order production to advance this order.');
                if($order['status']===$s || in_array($order['status'],['Delivered','Cancelled'],true))
                    throw new RuntimeException('This order already has that status or has reached its final status.');
                $customerId=$order['user_id'];$pdo->prepare('UPDATE orders SET status=? WHERE order_id=?')->execute([$s,$oid]);$pdo->prepare('INSERT INTO order_status_history(order_id,status,notes,updated_by) VALUES(?,?,?,?)')->execute([$oid,$s,trim($_POST['notes']??''),current_user()['user_id']]);notify((int)$customerId,'Order #'.$oid.' status updated to '.$s.'.','order',$oid);$pdo->commit();redirect('?page=orders');
            case 'read_notification':
                require_login();db()->prepare('UPDATE notifications SET is_read=1 WHERE notification_id=? AND user_id=?')->execute([(int)$_POST['notification_id'],current_user()['user_id']]);redirect('?page=notifications');
            default: throw new RuntimeException('Unknown action.');
        }
    } catch(Throwable $e) { if(db()->inTransaction())db()->rollBack(); flash($e instanceof PDOException ? 'That action could not be completed. Please check your information and try again.' : $e->getMessage(),'danger'); $back=($_POST['action']??'')==='custom_request'?'?page=custom-request':('?'.http_build_query($_GET)); if($back==='?page=custom-request')$_SESSION['custom_request_old']=array_intersect_key($_POST,array_flip(['furniture_type','title','description','required_width','required_height','required_depth','preferred_material','preferred_color','special_requirements'])); redirect($back); }
}

$title=ucwords(str_replace('-',' ',$route));
?><!doctype html><html lang="en" data-product-fallback="<?=e(furniflex_fallback_image())?>"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title><?=e($title)?> | FurniFlex</title><link href="assets/vendor/bootstrap.min.css" rel="stylesheet"><link href="assets/vendor/bootstrap-icons.min.css" rel="stylesheet"><link href="assets/css/style.css?v=viewer-controls-2" rel="stylesheet"></head><body>
<nav class="navbar navbar-expand-lg navbar-light bg-white sticky-top border-bottom"><div class="container"><a class="navbar-brand fw-bold" href="?">Furni<span>Flex</span></a><button class="navbar-toggler" data-bs-toggle="collapse" data-bs-target="#nav"><span class="navbar-toggler-icon"></span></button><div class="collapse navbar-collapse" id="nav"><div class="navbar-nav ms-auto align-items-lg-center"><a class="nav-link" href="?">Home</a><a class="nav-link" href="?page=shop">Shop</a><?php if(current_user()&&current_user()['role']==='customer'):?><a class="nav-link" href="?page=custom-request">Custom Furniture</a><?php endif;?><?php if(current_user()):?><a class="nav-link" href="?page=dashboard">Dashboard</a><a class="nav-link" href="?page=cart"><i class="bi bi-bag"></i> Cart</a><form method="post" class="ms-lg-2"><?=csrf_field()?><input type="hidden" name="action" value="logout"><button class="btn btn-sm btn-outline-dark">Sign out</button></form><?php else:?><a class="nav-link" href="?page=login">Login</a><a class="btn btn-sm btn-primary ms-lg-2" href="?page=register">Get started</a><?php endif;?></div></div></div></nav>
<main class="container py-4"><?php foreach(flashes() as $f):?><div class="alert alert-<?=e($f['type'])?> alert-dismissible fade show"><?=e($f['message'])?><button class="btn-close" data-bs-dismiss="alert"></button></div><?php endforeach; ?>
<?php if(current_user() && in_array($route,['dashboard','orders','order','order-admin-detail','quotations'],true)):?><p><a href="?page=production">Custom order production</a></p><?php endif;?><?php if($route==='production')production_page();else render_page($route); ?></main><footer class="mt-5 py-5"><div class="container d-flex flex-column flex-md-row justify-content-between"><div><a class="navbar-brand fw-bold" href="?">Furni<span>Flex</span></a><p class="text-secondary mt-2">Furniture made to feel like home.</p></div><div class="small text-secondary">Demo project · Contact details <b> support@furniflex.com </b> <br>© <?=date('Y')?> FurniFlex</div></div></footer><script src="assets/vendor/bootstrap.bundle.min.js"></script><script src="assets/js/app.js?v=overall-dimensions-2"></script><script type="module" src="assets/js/model-preview.js?v=model-root-path-20261113-1"></script></body></html>
