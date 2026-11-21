-- Additive component definitions for the local Innerscene COVE 122 coffee table
-- and finer-grained, genuinely separate LINEA 140 desk mesh groups.
-- Product identities, prices, stock, orders, carts, and snapshots are untouched.

UPDATE product_components SET
  display_name='Walnut tabletop', default_material='Walnut', default_color_hex='#5B3C2B',
  default_texture_key='walnut', default_finish='Satin', default_shape='rounded',
  default_width_cm=122, min_width_cm=122, max_width_cm=122,
  default_depth_cm=66, min_depth_cm=66, max_depth_cm=66,
  default_height_cm=3, min_height_cm=3, max_height_cm=3
WHERE product_id=2 AND component_key='table_top';

UPDATE product_components SET
  display_name='Turned walnut legs', default_material='Walnut', default_color_hex='#5B3C2B',
  default_texture_key='walnut', default_finish='Satin', default_shape='tapered',
  default_width_cm=7, min_width_cm=7, max_width_cm=7,
  default_depth_cm=7, min_depth_cm=7, max_depth_cm=7,
  default_height_cm=32, min_height_cm=32, max_height_cm=32,
  default_quantity=4, min_quantity=4, max_quantity=4
WHERE product_id=2 AND component_key='table_leg';

UPDATE product_components SET
  display_name='Slatted lower shelf', default_material='Walnut', default_color_hex='#5B3C2B',
  default_texture_key='walnut', default_finish='Satin', default_shape='rectangular',
  default_width_cm=84, min_width_cm=84, max_width_cm=84,
  default_depth_cm=46, min_depth_cm=46, max_depth_cm=46,
  default_height_cm=2.5, min_height_cm=2.5, max_height_cm=2.5,
  default_quantity=1, min_quantity=1, max_quantity=1
WHERE product_id=2 AND component_key='table_brace';

INSERT INTO product_components(product_id,component_key,display_name,geometry_type,layout_axis,default_shape,allowed_shapes_json,shape_prices_json,
 default_width_cm,min_width_cm,max_width_cm,default_depth_cm,min_depth_cm,max_depth_cm,default_height_cm,min_height_cm,max_height_cm,
 default_quantity,min_quantity,max_quantity,default_x_cm,min_x_cm,max_x_cm,default_y_cm,min_y_cm,max_y_cm,default_z_cm,min_z_cm,max_z_cm,
 default_material,default_color_hex,default_texture_key,default_finish,unit_price,width_rate,depth_rate,height_rate)
VALUES
 (2,'table_frame','Walnut apron frame','box','none','rectangular','["rectangular"]','{"rectangular":0}',86,86,86,46,46,46,6,6,6,1,1,1,0,0,0,31,31,31,0,0,0,'Walnut','#5B3C2B','walnut','Satin',0,0,0,0),
 (2,'table_hardware','Brass, steel and felt fittings','handle','none','bar','["bar"]','{"bar":0}',8,8,8,8,8,8,3,3,3,1,1,1,0,0,0,2,2,2,0,0,0,'Brass','#B48942','brass','Satin',0,0,0,0),
 (5,'desk_legs','Steel legs and feet','leg','none','square','["square"]','{"square":0}',140,140,140,65,65,65,72,72,72,1,1,1,0,0,0,36,36,36,0,0,0,'Matte Black Metal','#212325','metal_black','Matte',0,0,0,0),
 (5,'desk_drawer_front','Walnut drawer front','panel','none','rectangular','["rectangular"]','{"rectangular":0}',52,52,52,42,42,42,2.8,2.8,2.8,1,1,1,0,0,0,0,0,0,0,0,0,'Walnut','#5B3C2B','walnut','Satin',0,0,0,0),
 (5,'desk_drawer_handle','Bronze drawer pull','handle','none','bar','["bar"]','{"bar":0}',12,12,12,3,3,3,2,2,2,1,1,1,0,0,0,0,0,0,0,0,0,'Bronze','#7A4F31','bronze','Satin',0,0,0,0)
ON DUPLICATE KEY UPDATE component_key=VALUES(component_key);

UPDATE product_components SET display_name='Walnut desktop', default_material='Walnut', default_texture_key='walnut'
WHERE product_id=5 AND component_key='desk_top';
UPDATE product_components SET display_name='Steel apron frame', default_material='Matte Black Metal', default_texture_key='metal_black'
WHERE product_id=5 AND component_key='desk_frame';
UPDATE product_components SET display_name='Drawer carcass and slides', default_material='Walnut', default_texture_key='walnut'
WHERE product_id=5 AND component_key='desk_drawer';
UPDATE product_components SET display_name='Cable and mounting hardware', default_material='Bronze', default_texture_key='bronze'
WHERE product_id=5 AND component_key='desk_hardware';
UPDATE product_components SET default_texture_key='oak', default_color_hex='#A67042'
WHERE product_id=4 AND component_key IN ('dining_top','dining_legs','dining_brace');

-- Material choices are scoped to the actual surface category of each mesh group.
INSERT INTO product_component_options(component_id,option_type,option_name,color_hex,texture_key,additional_cost,is_active)
SELECT c.component_id,'material',m.material_name,m.color_hex,m.material_key,m.additional_cost,1
FROM product_components c JOIN material_catalog m ON m.is_active=1 AND m.category=CASE
 WHEN c.component_key IN ('table_top','table_leg','table_brace','table_frame','desk_top','desk_drawer','desk_drawer_front') THEN 'wood'
 WHEN c.component_key IN ('table_hardware','desk_frame','desk_legs','desk_drawer_handle','desk_hardware') THEN 'metal' END
WHERE ((c.product_id=2 AND c.component_key IN ('table_top','table_leg','table_brace','table_frame','table_hardware'))
 OR (c.product_id=5 AND c.component_key IN ('desk_top','desk_frame','desk_legs','desk_drawer','desk_drawer_front','desk_drawer_handle','desk_hardware')))
AND NOT EXISTS(SELECT 1 FROM product_component_options o WHERE o.component_id=c.component_id AND o.option_type='material' AND o.option_name=m.material_name);

-- Component-specific finish choices change real PBR roughness in the viewer.
INSERT INTO product_component_options(component_id,option_type,option_name,color_hex,texture_key,additional_cost,is_active)
SELECT c.component_id,'finish',f.option_name,'#A98568',f.texture_key,0,1
FROM product_components c
CROSS JOIN (SELECT 'Matte' option_name,'matte' texture_key UNION ALL SELECT 'Satin','satin' UNION ALL SELECT 'Gloss','gloss') f
WHERE c.product_id IN (2,4,5)
AND c.component_key IN ('table_top','table_leg','table_brace','table_frame','table_hardware','dining_top','dining_legs','dining_brace','dining_hardware','desk_top','desk_frame','desk_legs','desk_drawer','desk_drawer_front','desk_drawer_handle','desk_hardware')
AND NOT EXISTS(SELECT 1 FROM product_component_options o WHERE o.component_id=c.component_id AND o.option_type='finish' AND o.option_name=f.option_name);
