<?php
declare(strict_types=1);

/** An explicit catalog taxonomy for retrieval. Classifier decision scores are never displayed as probabilities. */
function advisor_types(): array {
    return ['sofa'=>'sofa_leg','coffee_table'=>'table_top','bed'=>'bed_frame','dining_table'=>'dining_top','desk'=>'desk_top','wardrobe'=>'wardrobe_frame'];
}

// A part is the purchase target when the request names a spare, or asks for a
// part for an existing piece. A construction detail ("desk with brass handles")
// and a whole replacement desk should continue through normal product retrieval.
function advisor_parts_only(string $text): bool {
    $part = '(?:legs?|feet|foot|handles?|knobs?|hinges?|hardware|slats?|rails?|brackets?|bolts?|screws?|fasteners?|castors?|casters?|drawer pulls?|parts?)';
    $piece = '(?:(?:coffee|dining) table|table|bed|drawer|wardrobe|desk|sofa|cabinet)';
    $partName = '(?:(?:wooden|metal|brass|steel|oak)\s+)?(?:'.$piece.'[ -])?'.$part;
    $text = preg_replace('/\bwith\s+(?:(?:a|an|some|four|two|additional)\s+)*(?:spare|replacement)\s+'.$partName.'\b/i', '', $text);
    // A demonstrative can refer back to a broken fitting in an earlier sentence.
    // Require an exclusive purchase cue; a description of a damaged hinge alone
    // does not establish that the shopper wants hardware instead of new furniture.
    if (preg_match('/\b(?:just|only)\s+(?:(?:need|want|order|buy)\s+)?(?:the|that|those|these)\s+'.$partName.'\b(?=\s*[,.;!?]|\s+(?:for|to repair|to fix)\b|\s*$)/i',$text)) return true;
    if (preg_match('/\b'.$partName.'\s*(?:,\s*please\s*,?\s*)?\s*for\s+(?:repairing|fixing)\s+(?:my |our |the |an? )?'.$piece.'\b/i',$text)) return true;
    return (bool) preg_match('/\b(?:spare|replacement)\s+'.$partName.'\b|\b'.$part.'\s+(?:only|separately|by (?:itself|themselves))\b/i', $text)
        || (bool) preg_match('/\b'.$partName.'\s+(?:for|to (?:repair|fix))\s+(?:the |my |our |an? |existing |old )*'.$piece.'\b/i', $text)
        || (bool) preg_match('/(?:^|\b(?:need|buy|replace|order|just|only|looking for)\s+)(?:(?:a|an|the|some|new|four|two|my|broken|spare)\s+)*'.$partName.'\s*[.!?]*$/i', $text);
}

function advisor_first_choice(string $text, array $types, array $terms): ?string {
    if (count($types) < 2) return null;
    // Only infer ordering across a fallback boundary when the primary clause
    // names one type and describes it positively.
    $clauses = preg_split('/\b(?:failing that|otherwise|if that (?:is not|isn.t) possible)\b/i',$text,2);
    if (count($clauses) === 2 && preg_match('/\b(?:would be ideal|would be perfect|ideally)\b/i',$clauses[0])) {
        $primary = array_filter($types,fn($type)=>preg_match('/\b(?:'.$terms[$type].')\b/i',$clauses[0]));
        if (count($primary) === 1) return reset($primary);
    }
    foreach ($types as $type) {
        $item = '(?:'.$terms[$type].')';
        $others = array_intersect_key($terms,array_flip(array_diff($types,[$type])));
        $alternative = '(?:'.implode('|',$others).')';
        $lead = '(?:first choice|first preference|priority|primary choice)(?: is| would be)?|prefer(?:red)?|preferably|rather have';
        if (preg_match('/\b(?:'.$lead.')\s*[:,]?\s*(?:(?:an?|the|new)\s+)*'.$item.'\b/i', $text)
            || preg_match('/\b'.$item.'\s+(?:over|rather than|ahead of)\s+(?:an? |the )?'.$alternative.'\b/i', $text)
            || preg_match('/\b'.$item.'\s+(?:(?:is|would be)\s+)?(?:my |our |the )?(?:first choice|first preference|priority)\b/i', $text)) return $type;
    }
    if (count($types) === 2) {
        foreach ($types as $index=>$type) {
            $item = '(?:'.$terms[$type].')';
            if (preg_match('/\b'.$item.'\s+(?:is |would be )?(?:my |our |an? )?(?:backup|fallback|second choice)\b/i', $text)
                || preg_match('/\b(?:fallback|backup|second choice)\s*(?:is|would be|:)\s*(?:an? |the )?'.$item.'\b/i', $text)) return $types[1-$index];
        }
    }
    return null;
}

function advisor_candidates(string $description,array $prediction): array {
    $text = strtolower(trim($description));
    $types = array_keys(advisor_types());
    $plan = ['types'=>[], 'wood'=>false, 'room'=>'', 'compact'=>false, 'reason'=>'', 'choices'=>[], 'preferred'=>null, 'parts_only'=>false];
    if (advisor_parts_only($text)) {
        $plan['parts_only']=true;
        $plan['reason']='The catalog sells complete furniture. The requested part is not offered separately.';
        return $plan;
    }
    // Ignore a bounded ownership statement, not the shopper's following request.
    $ownedItem = '(?:(?:dining|office|arm|folding)\s+chairs?|chairs?|stools?|wardrobes?|sofas?|couches|desks?|beds?|(?:coffee|dining) tables?)';
    $ownedMentions=[];
    $text = preg_replace_callback('/\b(?:i|we)\s+(?:(?:already|currently)\s+)?(?:own|have)\s+(?:(?:an?|the|some|enough|my|our|two|three|four|six|\d+)\s+)*'.$ownedItem.'(?=\s*(?:[.,;!?]|$)|\s+(?:but|and (?:now |would |want|need|am |are ))\b)/i',function($match) use (&$ownedMentions) {
        $ownedMentions[]=$match[0];
        return ' ';
    },$text);
    // Strip measurement and placement references before matching requested types.
    $text = preg_replace('/\b(?:chair|stool)[ -]height\b|\b(?:beside|next to|in front of|alongside|to go with|to match)\s+(?:my |our |the |an? )?(?:existing |old )?(?:chairs?|stools?|sofas?|couch(?:es)?|beds?|desks?|wardrobes?)\b/i', ' ', $text);
    if (preg_match('/\b(?:chair|stool|nightstand|bookcase|side table|end table|pool table|table tennis|dressing table|console table)s?\b/i',$text,$unsupported)
        || preg_match('/\b(?:slipcovers?|tablecloths?|bedding|sofa covers?|desk mats?|chair covers?)\b/i',$text,$unsupported)) {
        $plan['reason']='The catalog does not offer a matching '.strtolower($unsupported[0]).'.';
        return $plan;
    }
    $terms = [
        'coffee_table'=>'coffee tables?|cocktail tables?|(?:put|set|rest) (?:my |a |the )?(?:coffee|drink)(?: cup)? on',
        'dining_table'=>'dining(?: room)? tables?|(?:dinner|supper) tables?|(?:gather around|table) for (?:dinner|supper)|(?:family|shared) (?:dinners|meals)',
        'wardrobe'=>'wardrobes?|armoires?|(?:store|storing|organize|hang) (?:my |our )?clothes',
        'sofa'=>'sofas?|couches|couch|settees?', 'bed'=>'beds?|bedframes?', 'desk'=>'desks?|workstations?'
    ];
    foreach ($terms as $type=>$pattern) {
        if (preg_match('/\b(?:'.$pattern.')\b/i',$text)) $plan['types'][]=$type;
    }
    if (!$plan['types'] && preg_match('/\btables?\b/i',$text)) $plan['types']=['coffee_table','dining_table'];
    $plan['preferred']=advisor_first_choice($text,$plan['types'],$terms);
    foreach (['bedroom'=>'Bedroom','living room'=>'Living Room','dining room'=>'Dining Room','home office'=>'Office'] as $phrase=>$room) {
        if(str_contains($text,$phrase)) {$plan['room']=$room;break;}
    }
    $plan['compact']=(bool)preg_match('/\b(?:small|compact|limited|tight)\s+(?:room|space|apartment)\b/',$text);
    $plan['wood']=(bool)preg_match('/\b(?:wood|wooden)\b/',$text);
    if (!$plan['types'] && ($plan['room']||$plan['compact']||$plan['wood']) && preg_match('/\bfurniture\b/',$text)) {
        $plan['types']=$types;
    }
    if (!$plan['types'] && ($prediction['status']??'')==='ok' && in_array($prediction['intent'],$types,true)) {
        $intent=$prediction['intent'];
        if (!$ownedMentions || (preg_match('/[a-z]/i',$text) && !preg_match('/\b(?:'.$terms[$intent].')\b/i',implode(' ',$ownedMentions)))) {
            $plan['types']=[$intent];
        }
    }
    if (!$plan['types']) {
        $plan['reason']='Which type of furniture are you looking for?';
        $plan['choices']=$types;
    }
    return $plan;
}
