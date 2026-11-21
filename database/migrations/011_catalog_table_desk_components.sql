-- Enable genuine component-level finish customization for the ready GLBs.
-- Product 5 was previously not customizable; this flag is required to expose its configurator.
UPDATE products SET is_customizable=1 WHERE product_id=5;

INSERT INTO product_components(product_id,component_key,display_name,geometry_type,layout_axis,default_shape,allowed_shapes_json,shape_prices_json,
 default_width_cm,min_width_cm,max_width_cm,default_depth_cm,min_depth_cm,max_depth_cm,default_height_cm,min_height_cm,max_height_cm,
 default_quantity,min_quantity,max_quantity,default_x_cm,min_x_cm,max_x_cm,default_y_cm,min_y_cm,max_y_cm,default_z_cm,min_z_cm,max_z_cm,
 default_material,default_color_hex,default_texture_key,default_finish,unit_price,width_rate,depth_rate,height_rate)
VALUES
 (4,'dining_top','Walnut tabletop','top','none','rectangular','["rectangular"]','{"rectangular":0}',201,201,201,93,93,93,4,4,4,1,1,1,0,0,0,0,0,0,0,0,0,'Walnut','#65432F','walnut','Satin',0,0,0,0),
 (4,'dining_legs','Crossed steel legs and feet','leg','none','square','["square"]','{"square":0}',201,201,201,93,93,93,76,76,76,1,1,1,0,0,0,0,0,0,0,0,0,'Powdercoat Steel','#353535','metal_black','Matte',0,0,0,0),
 (4,'dining_brace','Table braces and fittings','box','none','rectangular','["rectangular"]','{"rectangular":0}',201,201,201,93,93,93,76,76,76,1,1,1,0,0,0,0,0,0,0,0,0,'Powdercoat Steel','#353535','metal_black','Matte',0,0,0,0),
 (5,'desk_top','Walnut desktop','top','none','rectangular','["rectangular"]','{"rectangular":0}',140,140,140,65,65,65,2.8,2.8,2.8,1,1,1,0,0,0,0,0,0,0,0,0,'Walnut','#65432F','walnut','Satin',0,0,0,0),
 (5,'desk_frame','Steel legs and apron','leg','none','square','["square"]','{"square":0}',140,140,140,65,65,65,76,76,76,1,1,1,0,0,0,0,0,0,0,0,0,'Powdercoat Steel','#353535','metal_black','Matte',0,0,0,0),
 (5,'desk_drawer','Drawer and front','drawer','none','rectangular','["rectangular"]','{"rectangular":0}',140,140,140,65,65,65,10,10,10,1,1,1,0,0,0,0,0,0,0,0,0,'Walnut','#65432F','walnut','Satin',0,0,0,0),
 (5,'desk_hardware','Drawer pull and fittings','handle','none','bar','["bar"]','{"bar":0}',140,140,140,65,65,65,10,10,10,1,1,1,0,0,0,0,0,0,0,0,0,'Bronze','#A67C52','bronze','Satin',0,0,0,0)
ON DUPLICATE KEY UPDATE component_key=VALUES(component_key);

INSERT INTO product_component_options(component_id,option_type,option_name,color_hex,texture_key,additional_cost,is_active)
SELECT c.component_id,'material',m.material_name,m.color_hex,m.material_key,m.additional_cost,1
FROM product_components c JOIN material_catalog m ON m.is_active=1 AND m.category=CASE
 WHEN c.component_key IN ('dining_top','desk_top','desk_drawer') THEN 'wood'
 WHEN c.component_key IN ('dining_legs','dining_brace','desk_frame','desk_hardware') THEN 'metal' END
WHERE ((c.product_id=4 AND c.component_key IN ('dining_top','dining_legs','dining_brace')) OR (c.product_id=5 AND c.component_key IN ('desk_top','desk_frame','desk_drawer','desk_hardware')))
AND NOT EXISTS(SELECT 1 FROM product_component_options o WHERE o.component_id=c.component_id AND o.option_type='material' AND o.option_name=m.material_name);
