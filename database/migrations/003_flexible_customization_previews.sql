-- FurniFlex flexible customization: additive, safe to apply once after migrations 001 and 002.
ALTER TABLE products
  ADD COLUMN customization_preview_kind ENUM('generic','sofa','coffee_table','bed','dining_table') NOT NULL DEFAULT 'generic';
ALTER TABLE customization_options
  ADD COLUMN preview_color CHAR(7) NULL,
  ADD COLUMN preview_image_path VARCHAR(255) NULL,
  ADD COLUMN preview_layer_key ENUM('main','overlay','material','component') NOT NULL DEFAULT 'main';

CREATE TABLE product_dimension_rules (
  product_id INT UNSIGNED NOT NULL,
  dimension_name ENUM('width','height','depth') NOT NULL,
  min_cm DECIMAL(8,2) NOT NULL,
  max_cm DECIMAL(8,2) NOT NULL,
  default_cm DECIMAL(8,2) NOT NULL,
  step_cm DECIMAL(6,2) NOT NULL DEFAULT 1,
  pricing_mode ENUM('none','per_cm','fixed','percentage','ranges','material_usage') NOT NULL DEFAULT 'none',
  price_amount DECIMAL(10,2) NOT NULL DEFAULT 0,
  PRIMARY KEY(product_id,dimension_name),
  CONSTRAINT fk_dimension_product FOREIGN KEY(product_id) REFERENCES products(product_id) ON DELETE CASCADE,
  CHECK(min_cm>0 AND max_cm>min_cm AND default_cm>=min_cm AND default_cm<=max_cm AND step_cm>0 AND price_amount>=0)
) ENGINE=InnoDB;

CREATE TABLE product_dimension_price_ranges (
  range_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  product_id INT UNSIGNED NOT NULL,
  dimension_name ENUM('width','height','depth') NOT NULL,
  min_cm DECIMAL(8,2) NOT NULL,
  max_cm DECIMAL(8,2) NOT NULL,
  additional_cost DECIMAL(10,2) NOT NULL DEFAULT 0,
  INDEX(product_id,dimension_name,min_cm,max_cm),
  CONSTRAINT fk_dimension_range_product FOREIGN KEY(product_id) REFERENCES products(product_id) ON DELETE CASCADE,
  CHECK(max_cm>min_cm AND additional_cost>=0)
) ENGINE=InnoDB;

UPDATE products SET customization_preview_kind=CASE product_id WHEN 1 THEN 'sofa' WHEN 2 THEN 'coffee_table' WHEN 3 THEN 'bed' WHEN 4 THEN 'dining_table' ELSE 'generic' END WHERE product_id IN (1,2,3,4);

-- Product-specific size controls. Product 2 deliberately uses ranges and fixed dimension pricing;
-- other products have different dimension sets and formulas.
INSERT INTO product_dimension_rules(product_id,dimension_name,min_cm,max_cm,default_cm,step_cm,pricing_mode,price_amount) VALUES
(1,'width',140,260,200,1,'per_cm',1.50),(1,'height',70,130,90,1,'per_cm',0.75),(1,'depth',70,135,95,1,'per_cm',1.10),
(2,'width',60,180,110,1,'ranges',0),(2,'depth',40,120,65,1,'fixed',25),
(3,'width',140,240,180,1,'per_cm',1.25),(3,'depth',180,260,210,1,'material_usage',30),
(4,'width',100,260,160,1,'material_usage',40),(4,'height',70,95,75,1,'fixed',20),(4,'depth',70,130,90,1,'per_cm',0.80);
INSERT INTO product_dimension_price_ranges(product_id,dimension_name,min_cm,max_cm,additional_cost) VALUES
(2,'width',60,100,0),(2,'width',100,140,45),(2,'width',140,180,95);

INSERT INTO customization_types(type_name,description)
SELECT 'Upholstery','Fabric and leather cover options for seating' WHERE NOT EXISTS (SELECT 1 FROM customization_types WHERE type_name='Upholstery');
INSERT INTO customization_types(type_name,description)
SELECT 'Leg style','Alternative furniture leg designs' WHERE NOT EXISTS (SELECT 1 FROM customization_types WHERE type_name='Leg style');
INSERT INTO customization_types(type_name,description)
SELECT 'Handle style','Decorative handle options where a product supports handles' WHERE NOT EXISTS (SELECT 1 FROM customization_types WHERE type_name='Handle style');

INSERT INTO customization_options(type_id,option_name,additional_cost,description,preview_color,preview_layer_key)
SELECT t.type_id,'Performance Weave',90,'Durable upholstery fabric','#A98568','main' FROM customization_types t WHERE t.type_name='Upholstery' AND NOT EXISTS (SELECT 1 FROM customization_options o WHERE o.type_id=t.type_id AND o.option_name='Performance Weave');
INSERT INTO customization_options(type_id,option_name,additional_cost,description,preview_color,preview_layer_key)
SELECT t.type_id,'Velvet',145,'Soft velvet upholstery','#737A8C','main' FROM customization_types t WHERE t.type_name='Upholstery' AND NOT EXISTS (SELECT 1 FROM customization_options o WHERE o.type_id=t.type_id AND o.option_name='Velvet');
INSERT INTO customization_options(type_id,option_name,additional_cost,description,preview_color,preview_layer_key)
SELECT t.type_id,'Tapered legs',35,'Slim tapered wood legs',NULL,'component' FROM customization_types t WHERE t.type_name='Leg style' AND NOT EXISTS (SELECT 1 FROM customization_options o WHERE o.type_id=t.type_id AND o.option_name='Tapered legs');
INSERT INTO customization_options(type_id,option_name,additional_cost,description,preview_color,preview_layer_key)
SELECT t.type_id,'Turned legs',55,'Classic turned wood legs',NULL,'component' FROM customization_types t WHERE t.type_name='Leg style' AND NOT EXISTS (SELECT 1 FROM customization_options o WHERE o.type_id=t.type_id AND o.option_name='Turned legs');
INSERT INTO customization_options(type_id,option_name,additional_cost,description,preview_color,preview_layer_key)
SELECT t.type_id,'Brushed brass',18,'Warm metal hardware',NULL,'component' FROM customization_types t WHERE t.type_name='Handle style' AND NOT EXISTS (SELECT 1 FROM customization_options o WHERE o.type_id=t.type_id AND o.option_name='Brushed brass');

-- Color choices update the solid-color illustration; product-specific image layers are optional.
UPDATE customization_options o JOIN customization_types t USING(type_id)
SET o.preview_color=CASE o.option_name WHEN 'Warm Beige' THEN '#C9AA85' WHEN 'Charcoal' THEN '#46484B' WHEN 'Olive' THEN '#68755A' ELSE o.preview_color END,
    o.preview_layer_key='main'
WHERE t.type_name='Color' AND o.option_name IN ('Warm Beige','Charcoal','Olive');

-- Restrict fabric and leather choices to the sofa; wood products get wood materials, colors and finishes.
DELETE po FROM product_customization_options po JOIN customization_options o USING(option_id) JOIN customization_types t USING(type_id)
WHERE po.product_id IN (1,2,3,4) AND t.type_name='Material' AND o.option_name IN ('Performance Fabric','Leather');
DELETE po FROM product_customization_options po JOIN customization_options o USING(option_id) JOIN customization_types t USING(type_id)
WHERE po.product_id=1 AND t.type_name='Material';
INSERT IGNORE INTO product_customization_options(product_id,option_id)
SELECT 1,o.option_id FROM customization_options o JOIN customization_types t USING(type_id) WHERE t.type_name='Upholstery';
INSERT IGNORE INTO product_customization_options(product_id,option_id)
SELECT p.product_id,o.option_id FROM products p JOIN customization_options o JOIN customization_types t USING(type_id)
WHERE p.product_id IN (1,2,3,4) AND t.type_name='Leg style';
