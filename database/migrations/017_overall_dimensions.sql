-- Add the missing product-level axes needed by the overall-dimensions controls.
-- INSERT IGNORE is intentional: existing dimensions, prices and defaults remain untouched.
INSERT IGNORE INTO product_dimension_rules
    (product_id, dimension_name, min_cm, max_cm, default_cm, step_cm, pricing_mode, price_amount)
VALUES
    (2, 'height', 30, 55, 42, 1, 'per_cm', 0.50),
    (3, 'height', 85, 125, 105, 1, 'per_cm', 1.00),
    (5, 'width', 110, 180, 140, 1, 'per_cm', 1.20),
    (5, 'height', 70, 82, 75, 1, 'per_cm', 1.50),
    (5, 'depth', 50, 85, 65, 1, 'per_cm', 1.00),
    (8, 'width', 120, 220, 160, 1, 'per_cm', 1.50),
    (8, 'height', 180, 260, 220, 1, 'per_cm', 2.00),
    (8, 'depth', 45, 85, 60, 1, 'per_cm', 1.25);
