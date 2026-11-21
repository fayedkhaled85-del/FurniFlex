-- Restore coffee-table proportions and align its editable GLB components.
-- No product price, order, cart, or other product row is changed.
UPDATE product_components
SET default_y_cm = 45
WHERE product_id = 2 AND component_key = 'table_top';

UPDATE product_components
SET default_height_cm = 40,
    min_height_cm = 30,
    default_y_cm = 20
WHERE product_id = 2 AND component_key = 'table_leg';

UPDATE product_components
SET default_depth_cm = 56,
    min_depth_cm = 45,
    max_depth_cm = 65,
    default_y_cm = 24,
    display_name = 'Lower display shelf'
WHERE product_id = 2 AND component_key = 'table_brace';
