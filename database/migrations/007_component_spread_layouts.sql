-- Spread internal dividers and support braces through their host furniture.
UPDATE product_components
SET layout_axis = 'columns'
WHERE product_id = 8 AND component_key = 'wardrobe_divider';

UPDATE product_components
SET layout_axis = 'spread_z'
WHERE product_id = 2 AND component_key = 'table_brace';
