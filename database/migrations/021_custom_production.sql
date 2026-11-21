-- Custom furniture has a quoted line price and no catalog product.
ALTER TABLE order_items MODIFY product_id INT UNSIGNED NULL;
CREATE TABLE IF NOT EXISTS production_orders (
 order_id INT UNSIGNED PRIMARY KEY,
 quotation_id INT UNSIGNED NOT NULL UNIQUE,
 request_id INT UNSIGNED NOT NULL UNIQUE,
 manufacturer_id INT UNSIGNED NULL,
 stage VARCHAR(32) NOT NULL,
 specification LONGTEXT NOT NULL,
 carrier VARCHAR(100), tracking_reference VARCHAR(120),
 FOREIGN KEY(order_id) REFERENCES orders(order_id),
 FOREIGN KEY(quotation_id) REFERENCES quotations(quotation_id),
 FOREIGN KEY(request_id) REFERENCES custom_requests(request_id),
 FOREIGN KEY(manufacturer_id) REFERENCES users(user_id)
) ENGINE=InnoDB;
