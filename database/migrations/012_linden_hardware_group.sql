INSERT INTO product_components(product_id,component_key,display_name,geometry_type,layout_axis,default_shape,allowed_shapes_json,shape_prices_json,
 default_width_cm,min_width_cm,max_width_cm,default_depth_cm,min_depth_cm,max_depth_cm,default_height_cm,min_height_cm,max_height_cm,
 default_quantity,min_quantity,max_quantity,default_x_cm,min_x_cm,max_x_cm,default_y_cm,min_y_cm,max_y_cm,default_z_cm,min_z_cm,max_z_cm,
 default_material,default_color_hex,default_texture_key,default_finish,unit_price,width_rate,depth_rate,height_rate)
VALUES(4,'dining_hardware','Bronze and steel fittings','handle','none','bar','["bar"]','{"bar":0}',201,201,201,93,93,93,4,4,4,1,1,1,0,0,0,0,0,0,0,0,0,'Bronze','#A67C52','bronze','Satin',0,0,0,0)
ON DUPLICATE KEY UPDATE component_key=VALUES(component_key);

INSERT INTO product_component_options(component_id,option_type,option_name,color_hex,texture_key,additional_cost,is_active)
SELECT c.component_id,'material',m.material_name,m.color_hex,m.material_key,m.additional_cost,1
FROM product_components c JOIN material_catalog m ON m.is_active=1 AND m.category='metal'
WHERE c.product_id=4 AND c.component_key='dining_hardware'
AND NOT EXISTS(SELECT 1 FROM product_component_options o WHERE o.component_id=c.component_id AND o.option_type='material' AND o.option_name=m.material_name);
