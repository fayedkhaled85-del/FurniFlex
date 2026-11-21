-- Link repeated component layouts to their parent parametric component so
-- supports and attached parts follow host dimensions instead of bunching at center.
ALTER TABLE product_components
  ADD COLUMN anchor_component_key VARCHAR(60) NULL AFTER layout_axis;

UPDATE product_components child
JOIN product_components parent ON parent.product_id = child.product_id
SET child.anchor_component_key = parent.component_key
WHERE (child.product_id = 1 AND child.component_key IN ('sofa_leg', 'seat_cushion') AND parent.component_key = 'frame')
   OR (child.product_id = 2 AND child.component_key IN ('table_leg', 'table_brace') AND parent.component_key = 'table_top')
   OR (child.product_id = 8 AND child.component_key IN ('wardrobe_door', 'wardrobe_drawer', 'wardrobe_shelf', 'wardrobe_divider', 'wardrobe_foot') AND parent.component_key = 'wardrobe_frame')
   OR (child.product_id = 8 AND child.component_key = 'wardrobe_handle' AND parent.component_key = 'wardrobe_door');
