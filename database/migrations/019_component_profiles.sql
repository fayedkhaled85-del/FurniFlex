-- Profile widths describe the shaft. Fixed end sections retain their hardware fit.
UPDATE product_components
SET min_width_cm=default_width_cm*0.9,max_width_cm=default_width_cm*1.1,
    min_depth_cm=default_depth_cm*0.9,max_depth_cm=default_depth_cm*1.1
WHERE component_key IN ('table_leg','bed_legs','dining_legs')
AND min_width_cm=max_width_cm AND min_depth_cm=max_depth_cm;

UPDATE product_components SET max_z_cm=default_z_cm+10
WHERE component_key='desk_drawer' AND min_z_cm=max_z_cm;
