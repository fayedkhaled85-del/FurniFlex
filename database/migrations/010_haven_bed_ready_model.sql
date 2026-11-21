-- Add an editable surface map for the ready-made Haven bed GLB.
-- The model is a finished CC0 asset. Geometry, count, dimensions and placement
-- remain locked; only separately modeled visual groups receive material/color controls.
INSERT INTO product_components(
  product_id,component_key,display_name,geometry_type,layout_axis,default_shape,allowed_shapes_json,shape_prices_json,
  default_width_cm,min_width_cm,max_width_cm,default_depth_cm,min_depth_cm,max_depth_cm,default_height_cm,min_height_cm,max_height_cm,
  default_quantity,min_quantity,max_quantity,default_x_cm,min_x_cm,max_x_cm,default_y_cm,min_y_cm,max_y_cm,default_z_cm,min_z_cm,max_z_cm,
  default_material,default_color_hex,default_texture_key,default_finish,unit_price,width_rate,depth_rate,height_rate
) VALUES
  (3,'bed_frame','Frame, rails and sprung slats','box','none','rectangular','["rectangular"]','{"rectangular":0}',159,159,159,205,205,205,38,38,38,1,1,1,0,0,0,0,0,0,0,0,0,'Oak','#9A6335','oak','Satin',0,0,0,0),
  (3,'bed_ends','Headboard and footboard','panel','none','rectangular','["rectangular"]','{"rectangular":0}',160,160,160,8,8,8,105,105,105,1,1,1,0,0,0,0,0,0,0,0,0,'Oak','#9A6335','oak','Satin',0,0,0,0),
  (3,'bed_legs','Tapered bed posts','leg','none','tapered','["tapered"]','{"tapered":0}',6,6,6,6,6,6,64,64,64,1,1,1,0,0,0,0,0,0,0,0,0,'Oak','#9A6335','oak','Satin',0,0,0,0),
  (3,'bed_hardware','Bronze post caps','panel','none','cylinder','["cylinder"]','{"cylinder":0}',5.2,5.2,5.2,5.2,5.2,5.2,4.3,4.3,4.3,1,1,1,0,0,0,0,0,0,0,0,0,'Bronze','#7A5535','bronze','Satin',0,0,0,0),
  (3,'bed_mattress','Mattress','cushion','none','rectangular','["rectangular"]','{"rectangular":0}',154,154,154,198,198,198,18,18,18,1,1,1,0,0,0,0,0,0,0,0,0,'Ivory woven bedding','#EEE8DD','upholstery','Matte',0,0,0,0),
  (3,'bed_pillows','Pillows','cushion','none','rectangular','["rectangular"]','{"rectangular":0}',50,50,50,36,36,36,16,16,16,1,1,1,0,0,0,0,0,0,0,0,0,'Ivory woven bedding','#EEE8DD','upholstery','Matte',0,0,0,0),
  (3,'bed_quilt','Sage quilt','cushion','none','rectangular','["rectangular"]','{"rectangular":0}',154,154,154,198,198,198,42,42,42,1,1,1,0,0,0,0,0,0,0,0,0,'Sage linen','#8B9B82','upholstery','Matte',0,0,0,0),
  (3,'bed_folded_return','Folded bedding return','cushion','none','rectangular','["rectangular"]','{"rectangular":0}',80,80,80,50,50,50,6,6,6,1,1,1,0,0,0,0,0,0,0,0,0,'Ivory woven bedding','#EEE8DD','upholstery','Matte',0,0,0,0)
ON DUPLICATE KEY UPDATE component_key=VALUES(component_key);

INSERT INTO product_component_options(component_id,option_type,option_name,color_hex,texture_key,additional_cost,is_active)
SELECT c.component_id,'material',m.material_name,m.color_hex,m.material_key,m.additional_cost,1
FROM product_components c
JOIN material_catalog m ON m.is_active=1 AND m.category=CASE
  WHEN c.component_key IN ('bed_frame','bed_ends','bed_legs') THEN 'wood'
  WHEN c.component_key='bed_hardware' THEN 'metal'
  ELSE 'upholstery' END
WHERE c.product_id=3 AND c.component_key IN ('bed_frame','bed_ends','bed_legs','bed_hardware','bed_mattress','bed_pillows','bed_quilt','bed_folded_return')
  AND NOT EXISTS(SELECT 1 FROM product_component_options o WHERE o.component_id=c.component_id AND o.option_type='material' AND o.option_name=m.material_name);
