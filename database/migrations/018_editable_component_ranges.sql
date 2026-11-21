-- Extend only the original fixed profiles; preserve administrator overrides.
UPDATE product_components
SET min_width_cm=default_width_cm, max_width_cm=default_width_cm+8,
    min_depth_cm=default_depth_cm, max_depth_cm=default_depth_cm+6,
    min_height_cm=default_height_cm, max_height_cm=default_height_cm+0.8
WHERE component_key IN ('table_top','dining_top')
  AND min_width_cm=max_width_cm AND min_depth_cm=max_depth_cm AND min_height_cm=max_height_cm;

UPDATE product_components
SET min_width_cm=default_width_cm-2,max_width_cm=default_width_cm+2,
    min_depth_cm=default_depth_cm-1,max_depth_cm=default_depth_cm+1,
    min_height_cm=default_height_cm-0.5,max_height_cm=default_height_cm+0.5,
    min_x_cm=default_x_cm-1,max_x_cm=default_x_cm+1,
    min_z_cm=default_z_cm-1,max_z_cm=default_z_cm+1
WHERE component_key='bed_pillows'
  AND min_width_cm=max_width_cm AND min_depth_cm=max_depth_cm AND min_height_cm=max_height_cm
  AND min_x_cm=max_x_cm AND min_z_cm=max_z_cm;
UPDATE product_components
SET min_width_cm=default_width_cm, max_width_cm=default_width_cm+8,
    min_depth_cm=default_depth_cm, max_depth_cm=default_depth_cm+6,
    min_height_cm=default_height_cm, max_height_cm=default_height_cm+0.8
WHERE component_key IN ('table_top','dining_top')
  AND min_width_cm=max_width_cm AND min_depth_cm=max_depth_cm AND min_height_cm=max_height_cm;

UPDATE product_components
SET min_width_cm=default_width_cm-2,max_width_cm=default_width_cm+2,
    min_depth_cm=default_depth_cm-1,max_depth_cm=default_depth_cm+1,
    min_height_cm=default_height_cm-0.5,max_height_cm=default_height_cm+0.5,
    min_x_cm=default_x_cm-1,max_x_cm=default_x_cm+1,
    min_y_cm=default_y_cm-1,max_y_cm=default_y_cm+1
WHERE component_key='desk_drawer_handle'
  AND min_width_cm=max_width_cm AND min_depth_cm=max_depth_cm AND min_height_cm=max_height_cm
  AND min_x_cm=max_x_cm AND min_y_cm=max_y_cm;
