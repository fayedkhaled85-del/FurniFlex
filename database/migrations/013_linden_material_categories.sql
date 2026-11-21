-- Correct catalog options for the real oak trestle and stretcher meshes in
-- the Linden Morrow GLB. Migration 011 initially assigned metal options to
-- those groups; they are oak in the source model and must expose wood only.
UPDATE product_components
SET display_name='Solid oak trestle legs and feet', default_material='Natural Oak'
WHERE product_id=4 AND component_key='dining_legs';

UPDATE product_components
SET display_name='Oak tie rail and lower stretcher', default_material='Natural Oak'
WHERE product_id=4 AND component_key='dining_brace';

UPDATE product_components
SET display_name='Solid oval oak tabletop', default_material='Natural Oak'
WHERE product_id=4 AND component_key='dining_top';

INSERT INTO product_component_options(component_id,option_type,option_name,color_hex,texture_key,additional_cost,is_active)
SELECT c.component_id,'material',m.material_name,m.color_hex,m.material_key,m.additional_cost,1
FROM product_components c
JOIN material_catalog m ON m.is_active=1 AND m.category='wood'
WHERE c.product_id=4 AND c.component_key IN ('dining_legs','dining_brace')
AND NOT EXISTS(
  SELECT 1 FROM product_component_options o
  WHERE o.component_id=c.component_id AND o.option_type='material' AND o.option_name=m.material_name
);
