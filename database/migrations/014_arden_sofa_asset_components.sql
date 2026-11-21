-- Align the existing sofa component labels and catalog categories with the
-- separate mesh groups in Innerscene's Boxwell Tuxedo CC0 model.
UPDATE product_components
SET display_name='Boxed deck and rear frame', default_material='Textile'
WHERE product_id=1 AND component_key='frame';

UPDATE product_components
SET display_name='Steel sled feet', default_material='Satin metal'
WHERE product_id=1 AND component_key='sofa_leg';

INSERT INTO product_component_options(component_id,option_type,option_name,color_hex,texture_key,additional_cost,is_active)
SELECT c.component_id,'material',m.material_name,m.color_hex,m.material_key,m.additional_cost,1
FROM product_components c
JOIN material_catalog m ON m.is_active=1 AND m.category='metal'
WHERE c.product_id=1 AND c.component_key='sofa_leg'
AND NOT EXISTS(
  SELECT 1 FROM product_component_options o
  WHERE o.component_id=c.component_id AND o.option_type='material' AND o.option_name=m.material_name
);
