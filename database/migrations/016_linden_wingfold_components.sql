-- Integrate Innerscene Wingfold CC0 butterfly-leaf table as Linden's current
-- model. Add one real, separately selectable leaf group; preserve catalog rows,
-- prices, stock, carts, orders and existing snapshots.

UPDATE product_components
SET display_name='Wingfold oak sliding tabletop', default_material='Natural Oak',
    default_color_hex='#A67042', default_texture_key='oak', default_finish='Satin',
    default_width_cm=200, min_width_cm=200, max_width_cm=200,
    default_depth_cm=90, min_depth_cm=90, max_depth_cm=90,
    default_height_cm=3.1, min_height_cm=3.1, max_height_cm=3.1
WHERE product_id=4 AND component_key='dining_top';

UPDATE product_components
SET display_name='Oak portal legs', default_material='Natural Oak', default_texture_key='oak',
    default_width_cm=9, min_width_cm=9, max_width_cm=9,
    default_depth_cm=7.5, min_depth_cm=7.5, max_depth_cm=7.5,
    default_height_cm=72, min_height_cm=72, max_height_cm=72
WHERE product_id=4 AND component_key='dining_legs';

UPDATE product_components
SET display_name='Portal ties and top bearings', default_material='Natural Oak', default_texture_key='oak'
WHERE product_id=4 AND component_key='dining_brace';

UPDATE product_components
SET display_name='Butterfly extension hardware', default_material='Satin Steel', default_texture_key='metal'
WHERE product_id=4 AND component_key='dining_hardware';

INSERT INTO product_components(
 product_id,component_key,display_name,geometry_type,layout_axis,default_shape,allowed_shapes_json,shape_prices_json,
 default_width_cm,min_width_cm,max_width_cm,default_depth_cm,min_depth_cm,max_depth_cm,default_height_cm,min_height_cm,max_height_cm,
 default_quantity,min_quantity,max_quantity,default_x_cm,min_x_cm,max_x_cm,default_y_cm,min_y_cm,max_y_cm,default_z_cm,min_z_cm,max_z_cm,
 default_material,default_color_hex,default_texture_key,default_finish,unit_price,width_rate,depth_rate,height_rate
) VALUES (
 4,'dining_extension_leaf','Folding oak butterfly leaves','panel','none','rectangular','["rectangular"]','{"rectangular":0}',
 51,51,51,45,45,45,3.1,3.1,3.1,2,2,2,0,0,0,0,0,0,0,0,0,
 'Natural Oak','#A67042','oak','Satin',0,0,0,0
) ON DUPLICATE KEY UPDATE display_name=VALUES(display_name),default_material=VALUES(default_material),
 default_color_hex=VALUES(default_color_hex),default_texture_key=VALUES(default_texture_key),default_finish=VALUES(default_finish);

INSERT INTO product_components(
 product_id,component_key,display_name,geometry_type,layout_axis,default_shape,allowed_shapes_json,shape_prices_json,
 default_width_cm,min_width_cm,max_width_cm,default_depth_cm,min_depth_cm,max_depth_cm,default_height_cm,min_height_cm,max_height_cm,
 default_quantity,min_quantity,max_quantity,default_x_cm,min_x_cm,max_x_cm,default_y_cm,min_y_cm,max_y_cm,default_z_cm,min_z_cm,max_z_cm,
 default_material,default_color_hex,default_texture_key,default_finish,unit_price,width_rate,depth_rate,height_rate
) VALUES (
 4,'dining_foot_glides','Felt floor glides','panel','none','rectangular','["rectangular"]','{"rectangular":0}',
 1.5,1.5,1.5,1.5,1.5,1.5,0.5,0.5,0.5,4,4,4,0,0,0,0,0,0,0,0,0,
 'Black Felt','#292929','felt','Matte',0,0,0,0
) ON DUPLICATE KEY UPDATE display_name=VALUES(display_name),default_material=VALUES(default_material),
 default_color_hex=VALUES(default_color_hex),default_texture_key=VALUES(default_texture_key),default_finish=VALUES(default_finish);

-- Add surface choices only for components that are actually wood in Wingfold.
INSERT INTO product_component_options(component_id,option_type,option_name,color_hex,texture_key,additional_cost,is_active)
SELECT c.component_id,'material',m.material_name,m.color_hex,m.material_key,m.additional_cost,1
FROM product_components c JOIN material_catalog m ON m.is_active=1 AND m.category='wood'
WHERE c.product_id=4 AND c.component_key='dining_extension_leaf'
AND NOT EXISTS (SELECT 1 FROM product_component_options o WHERE o.component_id=c.component_id AND o.option_type='material' AND o.option_name=m.material_name);

INSERT INTO product_component_options(component_id,option_type,option_name,color_hex,texture_key,additional_cost,is_active)
SELECT c.component_id,'finish',f.option_name,'#A98568',f.texture_key,0,1
FROM product_components c
CROSS JOIN (SELECT 'Matte' option_name,'matte' texture_key UNION ALL SELECT 'Satin','satin' UNION ALL SELECT 'Gloss','gloss') f
WHERE c.product_id=4 AND c.component_key='dining_extension_leaf'
AND NOT EXISTS (SELECT 1 FROM product_component_options o WHERE o.component_id=c.component_id AND o.option_type='finish' AND o.option_name=f.option_name);
