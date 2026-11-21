-- Guard each update against unexpected configuration drift.
START TRANSACTION;
UPDATE product_components SET min_height_cm=7, max_height_cm=30 WHERE component_key='sofa_leg' AND default_height_cm=16.0 AND min_height_cm=8.0 AND max_height_cm=28.0 AND is_active=1;
UPDATE product_components SET min_height_cm=2.5, max_height_cm=5 WHERE component_key='table_top' AND default_height_cm=3.0 AND min_height_cm=3.0 AND max_height_cm=3.8 AND is_active=1;
UPDATE product_components SET min_height_cm=27, max_height_cm=38 WHERE component_key='table_leg' AND default_height_cm=32.0 AND min_height_cm=30.4 AND max_height_cm=33.6 AND is_active=1;
UPDATE product_components SET min_height_cm=12, max_height_cm=28 WHERE component_key='bed_mattress' AND default_height_cm=18.0 AND min_height_cm=17.1 AND max_height_cm=18.9 AND is_active=1;
UPDATE product_components SET min_z_cm=0, max_z_cm=19 WHERE component_key='desk_drawer' AND default_z_cm=0.0 AND min_z_cm=0.0 AND max_z_cm=10.0 AND is_active=1;
UPDATE product_components SET min_height_cm=3, max_height_cm=28 WHERE component_key='wardrobe_foot' AND default_height_cm=12.0 AND min_height_cm=4.0 AND max_height_cm=25.0 AND is_active=1;
COMMIT;
