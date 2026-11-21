-- FurniFlex local component-material and broad color catalogs.
-- Original local PBR maps are authored by scripts/generate_pilot_models.py.
CREATE TABLE IF NOT EXISTS material_catalog (
  material_key VARCHAR(32) PRIMARY KEY,
  material_name VARCHAR(100) NOT NULL,
  category VARCHAR(24) NOT NULL,
  color_hex CHAR(7) NOT NULL,
  roughness DECIMAL(4,3) NOT NULL DEFAULT 0.600,
  metallic DECIMAL(4,3) NOT NULL DEFAULT 0.000,
  normal_scale DECIMAL(4,2) NOT NULL DEFAULT 0.45,
  base_color_map VARCHAR(255) NULL,
  normal_map VARCHAR(255) NULL,
  roughness_map VARCHAR(255) NULL,
  metallic_map VARCHAR(255) NULL,
  ao_map VARCHAR(255) NULL,
  preview_image VARCHAR(255) NULL,
  additional_cost DECIMAL(10,2) NOT NULL DEFAULT 0,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CHECK (color_hex REGEXP '^#[0-9a-fA-F]{6}$'),
  CHECK (roughness BETWEEN 0 AND 1),
  CHECK (metallic BETWEEN 0 AND 1),
  CHECK (normal_scale BETWEEN 0 AND 2),
  CHECK (additional_cost >= 0)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS color_palette_options (
  color_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  color_name VARCHAR(80) NOT NULL,
  category VARCHAR(32) NOT NULL,
  color_hex CHAR(7) NOT NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_palette_color(color_name,color_hex),
  CHECK (color_hex REGEXP '^#[0-9a-fA-F]{6}$')
) ENGINE=InnoDB;

INSERT INTO material_catalog(material_key,material_name,category,color_hex,roughness,metallic,normal_scale,base_color_map,normal_map,roughness_map,metallic_map,ao_map,preview_image,additional_cost) VALUES
('linen','Linen','upholstery','#CABAA3',.920,0,.78,'assets/textures/linen_basecolor.png','assets/textures/linen_normal.png','assets/textures/linen_roughness.png','assets/textures/linen_metalrough.png','assets/textures/linen_ao.png','assets/textures/linen_preview.jpg',18),
('cotton','Cotton','upholstery','#DACFBE',.880,0,.34,'assets/textures/cotton_basecolor.png','assets/textures/cotton_normal.png','assets/textures/cotton_roughness.png','assets/textures/cotton_metalrough.png','assets/textures/cotton_ao.png','assets/textures/cotton_preview.jpg',12),
('velvet','Velvet','upholstery','#5B4C5B',.560,0,.92,'assets/textures/velvet_basecolor.png','assets/textures/velvet_normal.png','assets/textures/velvet_roughness.png','assets/textures/velvet_metalrough.png','assets/textures/velvet_ao.png','assets/textures/velvet_preview.jpg',42),
('boucle','Bouclé','upholstery','#D0C5B4',.940,0,.72,'assets/textures/boucle_basecolor.png','assets/textures/boucle_normal.png','assets/textures/boucle_roughness.png','assets/textures/boucle_metalrough.png','assets/textures/boucle_ao.png','assets/textures/boucle_preview.jpg',36),
('chenille','Chenille','upholstery','#977F6C',.840,0,.58,'assets/textures/chenille_basecolor.png','assets/textures/chenille_normal.png','assets/textures/chenille_roughness.png','assets/textures/chenille_metalrough.png','assets/textures/chenille_ao.png','assets/textures/chenille_preview.jpg',32),
('performance','Performance Fabric','upholstery','#A29D91',.820,0,.38,'assets/textures/performance_basecolor.png','assets/textures/performance_normal.png','assets/textures/performance_roughness.png','assets/textures/performance_metalrough.png','assets/textures/performance_ao.png','assets/textures/performance_preview.jpg',28),
('leather','Leather','upholstery','#694632',.460,0,.40,'assets/textures/leather_basecolor.png','assets/textures/leather_normal.png','assets/textures/leather_roughness.png','assets/textures/leather_metalrough.png','assets/textures/leather_ao.png','assets/textures/leather_preview.jpg',75),
('faux_leather','Faux Leather','upholstery','#553C30',.390,0,.24,'assets/textures/faux_leather_basecolor.png','assets/textures/faux_leather_normal.png','assets/textures/faux_leather_roughness.png','assets/textures/faux_leather_metalrough.png','assets/textures/faux_leather_ao.png','assets/textures/faux_leather_preview.jpg',30),
('suede','Suede','upholstery','#99775C',.810,0,.46,'assets/textures/suede_basecolor.png','assets/textures/suede_normal.png','assets/textures/suede_roughness.png','assets/textures/suede_metalrough.png','assets/textures/suede_ao.png','assets/textures/suede_preview.jpg',38),
('oak','Natural Oak','wood','#A67042',.580,0,.18,'assets/textures/oak_basecolor.png','assets/textures/oak_normal.png','assets/textures/oak_roughness.png','assets/textures/oak_metalrough.png','assets/textures/oak_ao.png','assets/textures/oak_preview.jpg',25),
('walnut','Walnut','wood','#5B3C2B',.520,0,.20,'assets/textures/walnut_basecolor.png','assets/textures/walnut_normal.png','assets/textures/walnut_roughness.png','assets/textures/walnut_metalrough.png','assets/textures/walnut_ao.png','assets/textures/walnut_preview.jpg',35),
('mahogany','Mahogany','wood','#743727',.500,0,.19,'assets/textures/mahogany_basecolor.png','assets/textures/mahogany_normal.png','assets/textures/mahogany_roughness.png','assets/textures/mahogany_metalrough.png','assets/textures/mahogany_ao.png','assets/textures/mahogany_preview.jpg',38),
('beech','Beech','wood','#C29768',.620,0,.16,'assets/textures/beech_basecolor.png','assets/textures/beech_normal.png','assets/textures/beech_roughness.png','assets/textures/beech_metalrough.png','assets/textures/beech_ao.png','assets/textures/beech_preview.jpg',22),
('ash','Ash','wood','#C2B59B',.610,0,.17,'assets/textures/ash_basecolor.png','assets/textures/ash_normal.png','assets/textures/ash_roughness.png','assets/textures/ash_metalrough.png','assets/textures/ash_ao.png','assets/textures/ash_preview.jpg',22),
('pine','Pine','wood','#CBA05F',.650,0,.16,'assets/textures/pine_basecolor.png','assets/textures/pine_normal.png','assets/textures/pine_roughness.png','assets/textures/pine_metalrough.png','assets/textures/pine_ao.png','assets/textures/pine_preview.jpg',16),
('dark_wood','Dark Wood','wood','#4B3327',.500,0,.19,'assets/textures/dark_wood_basecolor.png','assets/textures/dark_wood_normal.png','assets/textures/dark_wood_roughness.png','assets/textures/dark_wood_metalrough.png','assets/textures/dark_wood_ao.png','assets/textures/dark_wood_preview.jpg',28),
('light_wood','Light Wood','wood','#DCC095',.630,0,.16,'assets/textures/light_wood_basecolor.png','assets/textures/light_wood_normal.png','assets/textures/light_wood_roughness.png','assets/textures/light_wood_metalrough.png','assets/textures/light_wood_ao.png','assets/textures/light_wood_preview.jpg',20),
('painted_wood','Painted Wood','wood','#DAD8D0',.690,0,.12,'assets/textures/painted_wood_basecolor.png','assets/textures/painted_wood_normal.png','assets/textures/painted_wood_roughness.png','assets/textures/painted_wood_metalrough.png','assets/textures/painted_wood_ao.png','assets/textures/painted_wood_preview.jpg',14),
('marble','Marble','surface','#DCDACF',.240,0,.18,'assets/textures/marble_basecolor.png','assets/textures/marble_normal.png','assets/textures/marble_roughness.png','assets/textures/marble_metalrough.png','assets/textures/marble_ao.png','assets/textures/marble_preview.jpg',95),
('glass','Glass','surface','#C0D6E0',.090,0,0,'assets/textures/glass_basecolor.png','assets/textures/glass_normal.png','assets/textures/glass_roughness.png','assets/textures/glass_metalrough.png','assets/textures/glass_ao.png','assets/textures/glass_preview.jpg',78),
('ceramic','Ceramic','surface','#DDD5C6',.250,0,.20,'assets/textures/ceramic_basecolor.png','assets/textures/ceramic_normal.png','assets/textures/ceramic_roughness.png','assets/textures/ceramic_metalrough.png','assets/textures/ceramic_ao.png','assets/textures/ceramic_preview.jpg',68),
('stone','Engineered Stone','surface','#9A978F',.310,0,.14,'assets/textures/stone_basecolor.png','assets/textures/stone_normal.png','assets/textures/stone_roughness.png','assets/textures/stone_metalrough.png','assets/textures/stone_ao.png','assets/textures/stone_preview.jpg',82),
('metal_black','Matte Black Metal','metal','#212325',.310,.940,.20,'assets/textures/metal_black_basecolor.png','assets/textures/metal_black_normal.png','assets/textures/metal_black_roughness.png','assets/textures/metal_black_metalrough.png','assets/textures/metal_black_ao.png','assets/textures/metal_black_preview.jpg',18),
('steel','Brushed Steel','metal','#A0A4A5',.300,.920,.14,'assets/textures/steel_basecolor.png','assets/textures/steel_normal.png','assets/textures/steel_roughness.png','assets/textures/steel_metalrough.png','assets/textures/steel_ao.png','assets/textures/steel_preview.jpg',22),
('chrome','Chrome','metal','#CDD0D3',.160,1,.10,'assets/textures/chrome_basecolor.png','assets/textures/chrome_normal.png','assets/textures/chrome_roughness.png','assets/textures/chrome_metalrough.png','assets/textures/chrome_ao.png','assets/textures/chrome_preview.jpg',28),
('brass','Brass','metal','#B48942',.280,.920,.14,'assets/textures/brass_basecolor.png','assets/textures/brass_normal.png','assets/textures/brass_roughness.png','assets/textures/brass_metalrough.png','assets/textures/brass_ao.png','assets/textures/brass_preview.jpg',26),
('gold','Gold','metal','#C99D4D',.210,.960,.12,'assets/textures/gold_basecolor.png','assets/textures/gold_normal.png','assets/textures/gold_roughness.png','assets/textures/gold_metalrough.png','assets/textures/gold_ao.png','assets/textures/gold_preview.jpg',40),
('bronze','Bronze','metal','#7A4F31',.340,.900,.15,'assets/textures/bronze_basecolor.png','assets/textures/bronze_normal.png','assets/textures/bronze_roughness.png','assets/textures/bronze_metalrough.png','assets/textures/bronze_ao.png','assets/textures/bronze_preview.jpg',32)
ON DUPLICATE KEY UPDATE material_name=VALUES(material_name),category=VALUES(category),color_hex=VALUES(color_hex),roughness=VALUES(roughness),metallic=VALUES(metallic),normal_scale=VALUES(normal_scale),base_color_map=VALUES(base_color_map),normal_map=VALUES(normal_map),roughness_map=VALUES(roughness_map),metallic_map=VALUES(metallic_map),ao_map=VALUES(ao_map),preview_image=VALUES(preview_image),additional_cost=VALUES(additional_cost);

INSERT IGNORE INTO color_palette_options(color_name,category,color_hex) VALUES
('Porcelain','White & off-white','#F5F1E8'),('Warm White','White & off-white','#E8E1D5'),('Ivory','White & off-white','#F3E8D2'),('Black','Black & charcoal','#171717'),('Charcoal','Black & charcoal','#34383B'),('Graphite','Black & charcoal','#53585C'),('Silver Gray','Gray & silver','#AEB4B8'),('Slate','Gray & silver','#68727B'),('Mushroom','Beige & cream','#B5A897'),('Oat','Beige & cream','#D7C7AA'),('Sand','Beige & cream','#C8AF8E'),('Cognac','Brown & natural wood','#A7613B'),('Walnut','Brown & natural wood','#68432E'),('Terracotta','Red & burgundy','#B85F46'),('Wine','Red & burgundy','#722F3B'),('Dusty Rose','Pink & pastel','#C58F94'),('Blush','Pink & pastel','#E6B8B3'),('Navy','Blue & navy','#26384D'),('Denim','Blue & navy','#456B8A'),('Sage','Green & olive','#8A9B83'),('Olive','Green & olive','#68704A'),('Forest','Green & olive','#315443'),('Mustard','Yellow & mustard','#C49B38'),('Ochre','Yellow & mustard','#B77C32'),('Burnt Orange','Orange & terracotta','#C26A3D'),('Lavender','Pink & pastel','#A694B5'),('Powder Blue','Blue & navy','#A9C3D4'),('Custom Color','Custom colors','#FFFFFF');

-- Material assignments are explicit per component so customers only see supported surfaces.
INSERT IGNORE INTO product_component_options(component_id,option_type,option_name,color_hex,texture_key,additional_cost)
SELECT c.component_id,'material',m.material_name,m.color_hex,m.material_key,m.additional_cost
FROM product_components c JOIN material_catalog m ON m.is_active=1
WHERE (c.product_id=1 AND ((c.component_key IN ('frame','left_arm','right_arm','backrest','seat_cushion') AND m.category IN ('upholstery','wood')) OR (c.component_key='sofa_leg' AND m.category IN ('wood','metal'))))
   OR (c.product_id=2 AND ((c.component_key='table_top' AND m.category IN ('wood','surface')) OR (c.component_key IN ('table_leg','table_brace') AND m.category IN ('wood','metal'))))
   OR (c.product_id=8 AND ((c.component_key IN ('wardrobe_frame','wardrobe_door','wardrobe_drawer','wardrobe_shelf','wardrobe_divider') AND m.category='wood') OR (c.component_key='wardrobe_handle' AND m.category='metal') OR (c.component_key='wardrobe_foot' AND m.category IN ('wood','metal'))));

-- Align the shipped default shape keys with the detailed local GLB templates.
UPDATE product_components SET default_shape='rounded' WHERE product_id=1 AND component_key IN ('frame','left_arm','right_arm','backrest');
UPDATE product_components SET default_shape='rounded' WHERE product_id=2 AND component_key='table_top';
UPDATE product_components SET default_shape='tapered' WHERE product_id=2 AND component_key='table_leg';
UPDATE product_components SET default_shape='cylinder' WHERE product_id=8 AND component_key='wardrobe_handle';
