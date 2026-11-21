-- Keep pilot component quantities within the supported parametric layouts.
UPDATE product_components
SET max_quantity = 4
WHERE product_id = 1 AND component_key = 'seat_cushion';

UPDATE product_components
SET max_quantity = 4
WHERE product_id = 8 AND component_key = 'wardrobe_door';

UPDATE product_components
SET max_quantity = 6
WHERE product_id = 8 AND component_key IN ('wardrobe_drawer', 'wardrobe_shelf');
