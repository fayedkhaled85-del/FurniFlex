<?php
declare(strict_types=1);
require_once __DIR__.'/advisor-candidates.php';
/** Read-only advisor: no cart, product, user or order writes. */
function advisor_styles(string $description): array {
    // Include only style names explicitly used in catalog copy. The vocabulary is editorial.
    $styles = [];
    foreach (['Modern', 'Contemporary', 'Minimalist', 'Scandinavian', 'Classic', 'Industrial'] as $style) {
        if (preg_match('/\b'.preg_quote($style, '/').'\b/i', $description)) $styles[] = $style;
    }
    return $styles;
}

function advisor_catalog_styles(): array {
    $styles = [];
    foreach (db()->query("SELECT description FROM products WHERE availability = 'In Stock'") as $product) {
        $styles = array_merge($styles, advisor_styles((string)$product['description']));
    }
    return array_values(array_unique($styles));
}

function advisor_inputs(array $raw): array {
    $out=[];
    foreach(['description','room','style','material','color','budget_min','budget_max','width','depth','height'] as $key){
        if(isset($raw[$key])&&!is_scalar($raw[$key]))throw new InvalidArgumentException('Invalid preference value.');
        $out[$key]=trim((string)($raw[$key]??''));
    }
    if(preg_match('/^.{3,1500}$/usD',$out['description'])!==1)throw new InvalidArgumentException('Describe your furniture in 3–1500 characters.');
    if(!in_array($out['room'],['','Living Room','Bedroom','Dining Room','Office','Other'],true))throw new InvalidArgumentException('Choose a valid room.');
    if($out['style']!=='' && !in_array($out['style'],advisor_catalog_styles(),true))throw new InvalidArgumentException('Choose a style listed in the current catalog.');
    $materials=array_column(component_material_catalog(),'material_key');
    if($out['material']!==''&&!in_array($out['material'],$materials,true))throw new InvalidArgumentException('Choose an available material.');
    if($out['color']!==''&&!preg_match('/^#[0-9a-fA-F]{6}$/D',$out['color']))throw new InvalidArgumentException('Use a six-digit HEX color such as #805533.');
    $out['color']=strtoupper($out['color']);
    foreach(['budget_min','budget_max','width','depth','height'] as $key){
        if($out[$key]===''){$out[$key]=null;continue;}
        $n=filter_var($out[$key],FILTER_VALIDATE_FLOAT);$limit=str_starts_with($key,'budget')?1000000:1000;
        if($n===false||!is_finite((float)$n)||$n<0||$n>$limit||(!str_starts_with($key,'budget')&&$n==0))throw new InvalidArgumentException('Enter valid non-negative budgets (up to 1,000,000) and positive space dimensions (up to 1000 cm).');
        $out[$key]=(float)$n;
    }
    if($out['budget_min']!==null&&$out['budget_max']!==null&&$out['budget_min']>$out['budget_max'])throw new InvalidArgumentException('Minimum budget cannot exceed maximum budget.');
    return $out;
}
function advisor_rate_limit(int $userId): void {
    // Per-account lock survives cookie renewal; no descriptions/IP addresses stored.
    $path=sys_get_temp_dir().'/furniflex-advisor-'.hash('sha256',__DIR__.':'.$userId).'.json';
    $f=fopen($path,'c+');if(!$f||!flock($f,LOCK_EX))throw new RuntimeException('Advisor temporarily unavailable.');
    try{$times=json_decode(stream_get_contents($f),true);$times=is_array($times)?array_values(array_filter($times,fn($t)=>is_int($t)&&$t>time()-60)):[];
        if(count($times)>=12)throw new OverflowException('Please wait a minute before requesting more recommendations.');
        $times[]=time();rewind($f);ftruncate($f,0);fwrite($f,json_encode($times));
    }finally{flock($f,LOCK_UN);fclose($f);}
}
function advisor_predict(string $text): array {
    // Use PHP's built-in HTTP stream in both Apache and CLI. XAMPP can load different extensions in the two SAPIs.
    $context = stream_context_create(['http' => [
        'method' => 'POST',
        'header' => "Content-Type: application/json\r\nConnection: close\r\n",
        'content' => json_encode(['text' => $text], JSON_THROW_ON_ERROR),
        'timeout' => 3,
        'follow_location' => 0,
        'ignore_errors' => true,
    ]]);
    $stream = @fopen((getenv('ADVISOR_ENDPOINT') ?: 'http://127.0.0.1:8765/predict'), 'rb', false, $context);
    if (!$stream) throw new RuntimeException('The AI service is unavailable. You can still browse the Shop.');
    try {
        $headers = stream_get_meta_data($stream)['wrapper_data'] ?? [];
        $body = stream_get_contents($stream, 20001);
        if (!preg_match('~^HTTP/\S+ 200\b~', $headers[0] ?? '') ||
            $body === false || strlen($body) > 20000 || stream_get_meta_data($stream)['timed_out']) {
            throw new RuntimeException('The AI service is unavailable. You can still browse the Shop.');
        }
    } finally {
        fclose($stream);
    }
    $result=json_decode($body,true);
    if(!is_array($result)||!in_array($result['status']??'', ['ok','unknown'],true)||(($result['status']==='ok')&&!in_array($result['intent']??'',['sofa','coffee_table','bed','dining_table','desk','wardrobe'],true)))throw new RuntimeException('The AI service returned an invalid response. Please try again.');
    return $result;
}
function advisor_matches(array $input,array $prediction): array {
    $plan = advisor_candidates($input['description'], $prediction);
    if (!$plan['types']) return ['items'=>[], 'reasons'=>[$plan['reason']], 'choices'=>$plan['choices'], 'parts_only'=>$plan['parts_only']];
    $keys = advisor_types();
    $markers = implode(',', array_fill(0, count($plan['types']), '?'));
    $query = db()->prepare("SELECT p.*, c.category_name FROM products p
        JOIN categories c USING(category_id)
        WHERE EXISTS (SELECT 1 FROM product_components pc WHERE pc.product_id=p.product_id AND pc.component_key IN ($markers) AND pc.is_active=1)");
    $query->execute(array_map(fn($type)=>$keys[$type],$plan['types']));
    $items=[]; $excluded=[];
    foreach ($query->fetchAll() as $p) {
        $components=component_definitions((int)$p['product_id']);
        $boundKeys=array_column($components,'component_key');
        $type=current(array_filter($plan['types'],fn($t)=>in_array($keys[$t],$boundKeys,true)));
        $p['advisor_priority']=($type===$plan['preferred']) ? 0 : 1;
        $p['advisor_type']=ucwords(str_replace('_',' ',$type));
        $reasons=[];$price=(float)$p['base_price'];
        if($p['availability']!=='In Stock')$reasons[]='The matching product is not in stock.';
        if(($input['budget_min']!==null&&$price<$input['budget_min'])||($input['budget_max']!==null&&$price>$input['budget_max']))$reasons[]=$p['name'].' starts at '.money($price).', outside your starting-price budget.';
        if($input['room']!==''&&$input['room']!=='Other'&&$p['category_name']!==$input['room'])$reasons[]='The product’s catalog room differs from your selected room.';
        if($plan['room'] && $p['category_name']!==$plan['room'])$reasons[]='The item is outside the requested room category.';
        if($input['style']!=='' && !in_array($input['style'],advisor_styles((string)$p['description']),true))$reasons[]='The product description does not list your selected style.';
        $q=db()->prepare('SELECT dimension_name,default_cm,min_cm,max_cm FROM product_dimension_rules WHERE product_id=?');$q->execute([$p['product_id']]);$dims=[];
        foreach($q as $d){$dims[$d['dimension_name']]=$d;}
        foreach(['width','depth','height'] as $axis){if($input[$axis]!==null&&(!isset($dims[$axis])||(float)$dims[$axis]['default_cm']>$input[$axis]))$reasons[]='The default '.$axis.' does not fit your available space; configurable parameters are not a guarantee of physical fit.';}
        $materialParts=[];$colorParts=[];$woodParts=[];
        foreach($components as $part){
            foreach($part['options'] as $option)if($option['option_type']==='material' && $option['material_category']==='wood')$woodParts[]=$part['display_name'];
            foreach($part['options'] as $option)if($option['option_type']==='material'&&$option['texture_key']===$input['material'])$materialParts[]=$part['display_name'];
            if(in_array('custom_color',$part['supported_controls'],true))$colorParts[]=$part['display_name'];
        }
        if($input['material']!==''&&!$materialParts)$reasons[]='The preferred material is not offered by this product’s components.';
        if($input['color']!==''&&!$colorParts)$reasons[]='Custom HEX color is not supported for this product.';
        if($plan['wood']&&!$woodParts)$reasons[]='No wood option is offered on this item.';
        if($reasons){$excluded=array_merge($excluded,$reasons);continue;}
        $p['advisor_dimensions']=$dims;
        $budget = match (true) {
            $input['budget_min']!==null && $input['budget_max']!==null => ' within your '.money($input['budget_min']).'–'.money($input['budget_max']).' budget',
            $input['budget_max']!==null => ' within your '.money($input['budget_max']).' limit',
            $input['budget_min']!==null => ' above or at your '.money($input['budget_min']).' minimum',
            default => ''
        };
        $p['advisor_reasons'] = [$p['name'].' is an in-stock '.strtolower($p['advisor_type']).' starting at '.money($price).$budget.'.'];
        if($plan['wood'])$p['advisor_reasons'][]='Wood finishes are available for '.reset($woodParts).'.';
        if($input['width']||$input['height']||$input['depth'])$p['advisor_reasons'][]='The default dimensions fit your specified space limits.';
        if($plan['compact'])$p['advisor_reasons'][]='Shown in order of default floor area. Enter space limits in Advanced Preferences to check fit.';
        $p['advisor_area']=(float)($dims['width']['default_cm']??INF)*(float)($dims['depth']['default_cm']??INF);
        if($input['style']!=='')$p['advisor_reasons'][]='The product description explicitly lists the '.$input['style'].' style.';
        if($input['material']!=='')$p['advisor_reasons'][]='Preferred material is available on: '.implode(', ',array_unique($materialParts)).'. Select it in the configurator; upgrades may increase the price.';
        if($input['color']!=='')$p['advisor_reasons'][]='HEX '.$input['color'].' can be selected on supported components in the configurator.';

        $items[]=$p;
    }
    // Compare eligible products only. Compact requests prioritize default floor area.
    usort($items,fn($a,$b)=>($a['advisor_priority']<=>$b['advisor_priority'])?:($plan['compact']?($a['advisor_area']<=>$b['advisor_area']):0)?:((float)$a['base_price']<=>(float)$b['base_price'])?:((int)$a['product_id']<=>(int)$b['product_id']));
    return ['items'=>array_slice($items,0,3),'reasons'=>array_values(array_unique($excluded?:['No live catalog product maps to this predicted furniture type.']))];
}
function advisor_prepare(): array {
    $u=require_role('customer');$state=['input'=>[],'result'=>null,'error'=>null];
    if($_SERVER['REQUEST_METHOD']!=='POST')return $state;
    try{
        if((int)($_SERVER['CONTENT_LENGTH']??0)>10000)throw new LengthException('Request too large.');
        try{csrf_check();}catch(RuntimeException $e){http_response_code(403);$state['error']=$e->getMessage();return $state;}$state['input']=advisor_inputs($_POST);advisor_rate_limit((int)$u['user_id']);$state['result']=advisor_matches($state['input'],advisor_predict($state['input']['description']));
    }catch(OverflowException $e){http_response_code(429);$state['error']=$e->getMessage();}
    catch(InvalidArgumentException|LengthException $e){http_response_code(422);$state['error']=$e->getMessage();}
    catch(PDOException $e){error_log('FurniFlex advisor database query failed');http_response_code(503);$state['error']='Recommendations are temporarily unavailable.';}
    catch(RuntimeException $e){http_response_code(503);$state['error']=$e->getMessage();}
    catch(Throwable $e){error_log('FurniFlex advisor failed: '.get_class($e));http_response_code(503);$state['error']='Recommendations are temporarily unavailable. The Shop remains available.';}
    return $state;
}
/** Suggested examples only. Missing catalog data leaves the corresponding suggestion blank. */
function advisor_numeric_suggestions(): array {
    $prices=db()->query("SELECT MIN(base_price),MAX(base_price) FROM products WHERE availability='In Stock'")->fetch(PDO::FETCH_NUM);
    $defaults=['budget_min'=>$prices[0]===null?'':floor($prices[0]/100)*100,
        'budget_max'=>$prices[1]===null?'':ceil($prices[1]/100)*100];
    $axes=[];
    $presets=[];
    $rows=db()->query("SELECT dimension_name,default_cm FROM product_dimension_rules JOIN products USING(product_id)
        WHERE availability='In Stock' AND default_cm>0 ORDER BY default_cm");
    foreach($rows as $row) $axes[$row['dimension_name']][]=(float)$row['default_cm'];
    foreach(['width','depth','height'] as $axis) {
        $values=$axes[$axis]??[];$defaults[$axis]='';
        if(!$values)continue;
        $last=count($values)-1;
        foreach(['Small'=>0.25,'Medium'=>0.5,'Large'=>1] as $size=>$fraction) {
            $pos=$last*$fraction;
            $cm=$values[(int)floor($pos)]+($pos-floor($pos))*($values[(int)ceil($pos)]-$values[(int)floor($pos)]);
            $presets[$size][$axis]=min(1000,ceil($cm/10)*10);
        }
        $defaults[$axis]=$presets['Medium'][$axis];
    }
    return [$defaults,$presets];
}

function advisor_number_control(string $key,string $label,$suggestion,string $value): void {
    $budget=str_starts_with($key,'budget');
    $increment=$budget?100:10;
    ?>
    <div class="mb-2" data-number-control>
      <label class="form-label mb-1" for="advisor-<?=$key?>"><?=e($label)?></label>
      <small class="text-secondary ms-1" data-number-state></small>
      <div class="input-group">
        <?php foreach([-1,1] as $direction):?>
          <?php if($direction===1):?>
          <input class="form-control" type="number" inputmode="decimal" step="any" min="0" max="<?=$budget?1000000:1000?>" id="advisor-<?=$key?>" name="<?=$key?>" data-number="<?=$key?>" data-suggestion="<?=e((string)$suggestion)?>" data-step="<?=$increment?>" placeholder="<?=e((string)$suggestion)?>" value="<?=$value?>" aria-describedby="advisor-error-<?=$key?>">
          <?php endif;?>
          <button hidden type="button" class="btn btn-outline-secondary" style="min-width:44px;min-height:44px" data-adjust="<?=$direction?>" aria-label="<?=e(($direction<0?'Decrease ':'Increase ').$label.' by '.$increment)?>"><?=$direction<0?'−':'+'?></button>
        <?php endforeach;?>
      </div>
      <small class="text-danger" id="advisor-error-<?=$key?>" data-number-error aria-live="polite"></small>
    </div>
    <?php
}
function advisor_page(array $state): void {
    [$suggestions,$presets]=advisor_numeric_suggestions();
    $values=$state['input'];$v=fn($key)=>e($values[$key]??(is_scalar($_POST[$key]??null)?$_POST[$key]:''));
    ?>
    <link rel="stylesheet" href="assets/css/advisor.css?v=<?=filemtime(__DIR__.'/../assets/css/advisor.css')?>">
    <div class="ff-advisor">
      <header class="advisor-intro">
        <span class="advisor-mark" aria-hidden="true"><i class="bi bi-stars"></i></span>
        <div><h1>FurniFlex AI Advisor</h1><p>Find furniture that fits your space, style, and budget.</p></div>
      </header>
      <div class="advisor-columns">
      <form method="post" action="?page=ai-advisor" id="advisor-form" class="advisor-panel">
      <h2>Your preferences</h2><?=csrf_field()?>
    <label class="form-label" for="advisor-description">Describe your furniture</label><textarea class="form-control mb-3" id="advisor-description" name="description" autocomplete="off" minlength="3" maxlength="1500" rows="4" required placeholder="I need a wooden dining table for my apartment."><?=$v('description')?></textarea>
    <div class="d-flex flex-wrap gap-2 mb-3" aria-label="Example requests"><?php foreach(['Living Room Sofa','Coffee Table','Dining Table','Bedroom Furniture','Study Desk','Storage Wardrobe'] as $chip):?><button type="button" class="advisor-chip" aria-pressed="false" data-advisor-example="<?=e($chip)?>"><?=e($chip)?></button><?php endforeach;?></div>
    <input type="hidden" disabled id="advisor-disclosure-state" name="advisor_expanded" value="">
    <?php $validationError = http_response_code()===422;
    $showAdvanced = isset($_POST['advisor_expanded'])
        ? $_POST['advisor_expanded']==='1'
        : (bool)array_filter(array_intersect_key($values,$suggestions+array_flip(['room','style','material','color'])),fn($v)=>$v!==null&&$v!==''); ?>
    <details class="mb-3" id="advisor-advanced" <?=($validationError || $showAdvanced)?'open':''?>><summary><span><i class="bi bi-sliders" aria-hidden="true"></i> Advanced Preferences</span><i class="bi bi-chevron-down" aria-hidden="true"></i></summary><div class="mt-3">
    <fieldset class="mb-3"><legend class="h6">Starting-price budget</legend>
    <p class="small text-secondary mb-2">Edit either amount to set a limit. Suggested amounts are optional.</p>
    <?php foreach(['budget_min'=>'Minimum budget ($)','budget_max'=>'Maximum budget ($)'] as $key=>$label) advisor_number_control($key,$label,$suggestions[$key],$v($key));?>
    </fieldset>
    <fieldset class="mb-3"><legend class="h6">Available space</legend>
    <div hidden data-enhanced><label class="form-check mb-2"><input class="form-check-input" type="checkbox" id="advisor-apply-space"> Apply space limits</label>
    <p class="small text-secondary mb-2">Choose a suggested space, apply the displayed limits, or edit a single measurement.</p>
    <div class="d-flex gap-2 flex-wrap mb-2"><?php foreach($presets as $size=>$axes): if(count($axes)!==3)continue;?><button type="button" class="btn btn-outline-dark btn-sm" style="min-height:44px" data-space-preset="<?=e(json_encode($axes))?>" aria-pressed="false"><?=e($size)?> Space</button><?php endforeach;?></div></div>
    <?php foreach(['width'=>'Maximum width (cm)','depth'=>'Maximum depth (cm)','height'=>'Maximum height (cm)'] as $key=>$label) advisor_number_control($key,$label,$suggestions[$key],$v($key));?>
    </fieldset><fieldset><legend class="h6">Design preferences</legend>
    <label class="form-label" for="advisor-room">Room</label><select class="form-select mb-3" name="room" id="advisor-room"><?php foreach([''=>'Any room','Living Room'=>'Living Room','Bedroom'=>'Bedroom','Dining Room'=>'Dining Room','Office'=>'Home Office','Other'=>'Other'] as $key=>$name):?><option value="<?=e($key)?>" <?=($values['room']??($_POST['room']??''))===$key?'selected':''?>><?=e($name)?></option><?php endforeach;?></select>
    <label class="form-label" for="advisor-style">Style</label><select class="form-select" id="advisor-style" name="style"><option value="">Any style</option><?php foreach(advisor_catalog_styles() as $style):?><option value="<?=e($style)?>" <?=($values['style']??($_POST['style']??''))===$style?'selected':''?>><?=e($style)?></option><?php endforeach;?></select><small class="text-secondary mb-3">Style filters use the terms found in current product descriptions.</small>
    <label class="form-label" for="advisor-material">Preferred material</label><select class="form-select mb-3" name="material" id="advisor-material"><option value="">Any material</option><?php foreach(component_material_catalog() as $m):?><option value="<?=e($m['material_key'])?>" <?=($values['material']??($_POST['material']??''))===$m['material_key']?'selected':''?>><?=e($m['material_name'])?></option><?php endforeach;?></select>
    <label class="form-label" for="advisor-color">Preferred color / custom HEX</label><input class="form-control" id="advisor-color" name="color" list="advisor-colors" maxlength="7" pattern="#[0-9a-fA-F]{6}" placeholder="#805533" value="<?=$v('color')?>"><datalist id="advisor-colors"><?php foreach(component_color_palette() as $c):?><option value="<?=e($c['color_hex'])?>"><?=e($c['color_name'])?></option><?php endforeach;?></datalist>
    </fieldset></div></details>
    <small id="advisor-filter-summary" aria-live="polite"></small>
    <p class="advisor-note">Apply your preferences to see matches. Customization can change the final price.</p>
    <div class="advisor-actions"><button class="btn btn-primary" id="advisor-submit"><i class="bi bi-stars" aria-hidden="true"></i> Find My Furniture</button>
    <a href="?page=ai-advisor" id="advisor-reset">Reset Preferences</a></div></form>
    <section class="advisor-panel" aria-label="Recommendations" id="advisor-results" tabindex="-1">
      <h2>Your recommendations</h2>
      <div id="advisor-loading" hidden><span class="spinner-border spinner-border-sm" aria-hidden="true"></span> Finding furniture for you…</div>
      <div id="advisor-outcome">
      <?php if($state['error']):?>
        <div class="advisor-message" role="alert"><i class="bi bi-info-circle" aria-hidden="true"></i><h3>We couldn’t complete your search</h3><p><?=e($state['error'])?></p><a href="?page=shop">Browse the Shop</a></div>
      <?php elseif($state['result']!==null && !$state['result']['items']):?>
        <div class="advisor-message"><i class="bi bi-search" aria-hidden="true"></i>
        <h3><?=empty($state['result']['choices'])?'No matching products':'Narrow your search'?></h3>
        <ul><?php foreach($state['result']['reasons'] as $reason):?><li><?=e($reason)?></li><?php endforeach;?></ul>
        <?php if(!empty($state['result']['choices'])):?><div class="advisor-actions mb-2"><?php foreach($state['result']['choices'] as $choice):?><button type="button" class="advisor-chip" aria-pressed="false" data-advisor-example="<?=e(str_replace('_',' ',$choice))?>"><?=e(ucwords(str_replace('_',' ',$choice)))?></button><?php endforeach;?></div><?php endif;?>
        <?php if(empty($state['result']['parts_only'])):?><a href="?page=custom-request">Request custom furniture</a><?php endif;?></div>
      <?php elseif($state['result']!==null):?><div class="advisor-products">
        <?php foreach($state['result']['items'] as $p):?><article class="advisor-result"><div class="advisor-product-visual"><?php if($model=furniflex_model_url((int)$p['product_id'])):?>
        <div class="model-preview model-preview-card furniflex-3d-preview rounded" data-product-id="<?=(int)$p['product_id']?>" data-product-name="<?=e($p['name'])?>" data-model-url="<?=e($model)?>">
          <canvas aria-label="3D preview of <?=e($p['name'])?>"></canvas><?php render_model_fallback($p);?>
          <span class="model-loading">Loading 3D preview…</span>
        </div>
        <?php else:render_product_visual($p,'w-100 rounded');endif;?></div><div class="advisor-product-copy"><small class="eyebrow"><?=e($p['advisor_type'])?> · <?=e($p['category_name'])?></small><h3 class="h4"><?=e($p['name'])?></h3><p><strong>From <?=money($p['base_price'])?></strong> · <?=e($p['availability'])?></p><p class="small">Default dimensions: <?=e(implode(' · ',array_map(fn($axis,$d)=>ucfirst($axis).' '.(float)$d['default_cm'].' cm',array_keys($p['advisor_dimensions']),$p['advisor_dimensions'])))?></p><ul class="small"><?php foreach($p['advisor_reasons'] as $reason):?><li><?=e($reason)?></li><?php endforeach;?></ul><div class="d-flex flex-wrap gap-2"><a class="btn btn-outline-dark" href="?page=product&amp;id=<?=(int)$p['product_id']?>">Product Details</a><a class="btn btn-primary" href="?page=customize&amp;id=<?=(int)$p['product_id']?>">Customize Product</a></div></div></article><?php endforeach;?></div><?php endif;?></div>
      <div id="advisor-empty" <?=$state['result']!==null||$state['error']?'hidden':''?>>
        <img src="assets/images/hero.svg" alt="" class="advisor-room">
        <div><h3>Your recommendations will appear here.</h3><p>Describe the piece you want. We’ll compare it with the catalog and explain which options fit.</p></div>
      </div>
    </section></div><span class="visually-hidden" role="status" id="advisor-status"></span></div><script src="assets/js/advisor.js?v=<?=filemtime(__DIR__.'/../assets/js/advisor.js')?>"></script><?php
}
