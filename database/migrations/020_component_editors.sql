START TRANSACTION;
UPDATE product_components SET min_width_cm=default_width_cm-GREATEST(0.1, ROUND(default_width_cm * 0.05,1)), max_width_cm=default_width_cm+GREATEST(0.1, ROUND(default_width_cm * 0.05,1)) WHERE is_active=1 AND min_width_cm=max_width_cm;
UPDATE product_components SET min_depth_cm=default_depth_cm-GREATEST(0.1, ROUND(default_depth_cm * 0.05,1)), max_depth_cm=default_depth_cm+GREATEST(0.1, ROUND(default_depth_cm * 0.05,1)) WHERE is_active=1 AND min_depth_cm=max_depth_cm;
UPDATE product_components SET min_height_cm=default_height_cm-GREATEST(0.1, ROUND(default_height_cm * 0.05,1)), max_height_cm=default_height_cm+GREATEST(0.1, ROUND(default_height_cm * 0.05,1)) WHERE is_active=1 AND min_height_cm=max_height_cm;
UPDATE product_components SET min_x_cm=default_x_cm-0.5, max_x_cm=default_x_cm+0.5 WHERE is_active=1 AND min_x_cm=max_x_cm;
UPDATE product_components SET min_y_cm=default_y_cm-0.5, max_y_cm=default_y_cm+0.5 WHERE is_active=1 AND min_y_cm=max_y_cm;
UPDATE product_components SET min_z_cm=default_z_cm-0.5, max_z_cm=default_z_cm+0.5 WHERE is_active=1 AND min_z_cm=max_z_cm;

INSERT IGNORE INTO product_component_options(component_id,option_type,option_name,color_hex,texture_key,additional_cost)
SELECT c.component_id,'color',p.color_name,p.color_hex,'solid',0
FROM product_components c CROSS JOIN color_palette_options p
WHERE c.is_active=1 AND p.is_active=1 AND NOT EXISTS
(SELECT 1 FROM product_component_options o WHERE o.component_id=c.component_id AND o.option_type='color' AND o.is_active=1);

INSERT IGNORE INTO product_component_options(component_id,option_type,option_name,texture_key,additional_cost)
SELECT c.component_id,'finish',f.label,f.texture,0 FROM product_components c
CROSS JOIN (SELECT 'Matte' label,'matte' texture UNION ALL SELECT 'Satin','satin' UNION ALL SELECT 'Gloss','gloss') f
WHERE c.is_active=1 AND NOT EXISTS
(SELECT 1 FROM product_component_options o WHERE o.component_id=c.component_id AND o.option_type='finish' AND o.is_active=1);

INSERT IGNORE INTO product_component_options(component_id,option_type,option_name,color_hex,texture_key,additional_cost)
SELECT c.component_id,'material',m.material_name,m.color_hex,m.material_key,m.additional_cost
FROM product_components c CROSS JOIN material_catalog m
WHERE c.component_key='dining_foot_glides' AND m.is_active=1 AND m.category='metal';
COMMIT;
