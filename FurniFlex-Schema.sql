SET NAMES utf8mb4; SET FOREIGN_KEY_CHECKS=0;



CREATE TABLE `cart_item_component_snapshots` (
  `snapshot_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `cart_item_id` int(10) unsigned NOT NULL,
  `component_key` varchar(60) NOT NULL,
  `component_label` varchar(100) NOT NULL,
  `spec_json` longtext NOT NULL,
  `additional_cost` decimal(10,2) NOT NULL DEFAULT 0.00,
  PRIMARY KEY (`snapshot_id`),
  KEY `fk_cart_component_item` (`cart_item_id`),
  CONSTRAINT `fk_cart_component_item` FOREIGN KEY (`cart_item_id`) REFERENCES `cart_items` (`cart_item_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `cart_item_customizations` (
  `cart_item_customization_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `cart_item_id` int(10) unsigned NOT NULL,
  `option_id` int(10) unsigned DEFAULT NULL,
  `selected_value` varchar(180) NOT NULL,
  `additional_cost` decimal(10,2) NOT NULL DEFAULT 0.00,
  PRIMARY KEY (`cart_item_customization_id`),
  KEY `cart_item_id` (`cart_item_id`),
  KEY `option_id` (`option_id`),
  CONSTRAINT `cart_item_customizations_ibfk_1` FOREIGN KEY (`cart_item_id`) REFERENCES `cart_items` (`cart_item_id`) ON DELETE CASCADE,
  CONSTRAINT `cart_item_customizations_ibfk_2` FOREIGN KEY (`option_id`) REFERENCES `customization_options` (`option_id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `cart_items` (
  `cart_item_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `cart_id` int(10) unsigned NOT NULL,
  `product_id` int(10) unsigned NOT NULL,
  `quantity` smallint(5) unsigned NOT NULL,
  `unit_price` decimal(10,2) NOT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`cart_item_id`),
  KEY `cart_id` (`cart_id`),
  KEY `product_id` (`product_id`),
  CONSTRAINT `cart_items_ibfk_1` FOREIGN KEY (`cart_id`) REFERENCES `carts` (`cart_id`) ON DELETE CASCADE,
  CONSTRAINT `cart_items_ibfk_2` FOREIGN KEY (`product_id`) REFERENCES `products` (`product_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `carts` (
  `cart_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` int(10) unsigned NOT NULL,
  `cart_status` enum('active','ordered','abandoned') NOT NULL DEFAULT 'active',
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`cart_id`),
  KEY `user_id` (`user_id`,`cart_status`),
  CONSTRAINT `carts_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `categories` (
  `category_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `category_name` varchar(100) NOT NULL,
  `description` text DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`category_id`),
  UNIQUE KEY `category_name` (`category_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `color_palette_options` (
  `color_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `color_name` varchar(80) NOT NULL,
  `category` varchar(32) NOT NULL,
  `color_hex` char(7) NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`color_id`),
  UNIQUE KEY `uq_palette_color` (`color_name`,`color_hex`),
  CONSTRAINT `CONSTRAINT_1` CHECK (`color_hex` regexp '^#[0-9a-fA-F]{6}$')
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `custom_requests` (
  `request_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` int(10) unsigned NOT NULL,
  `assigned_manufacturer_id` int(10) unsigned DEFAULT NULL,
  `furniture_type` varchar(100) NOT NULL,
  `title` varchar(180) DEFAULT NULL,
  `description` text NOT NULL,
  `required_width` decimal(8,2) NOT NULL,
  `required_height` decimal(8,2) NOT NULL,
  `required_depth` decimal(8,2) NOT NULL,
  `preferred_material` varchar(100) DEFAULT NULL,
  `preferred_color` varchar(80) DEFAULT NULL,
  `special_requirements` text DEFAULT NULL,
  `request_status` enum('Pending Review','Under Technical Review','Technical Review Completed','Quotation Pending','Quotation Sent','Accepted','Rejected','Cancelled') NOT NULL DEFAULT 'Pending Review',
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`request_id`),
  KEY `request_status` (`request_status`),
  KEY `user_id` (`user_id`),
  KEY `assigned_manufacturer_id` (`assigned_manufacturer_id`),
  CONSTRAINT `custom_requests_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`),
  CONSTRAINT `custom_requests_ibfk_2` FOREIGN KEY (`assigned_manufacturer_id`) REFERENCES `users` (`user_id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `customization_options` (
  `option_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `type_id` int(10) unsigned NOT NULL,
  `option_name` varchar(100) NOT NULL,
  `additional_cost` decimal(10,2) NOT NULL DEFAULT 0.00,
  `description` text DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `preview_color` char(7) DEFAULT NULL,
  `preview_image_path` varchar(255) DEFAULT NULL,
  `preview_layer_key` enum('main','overlay','material','component') NOT NULL DEFAULT 'main',
  PRIMARY KEY (`option_id`),
  KEY `type_id` (`type_id`),
  CONSTRAINT `customization_options_ibfk_1` FOREIGN KEY (`type_id`) REFERENCES `customization_types` (`type_id`) ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `customization_types` (
  `type_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `type_name` varchar(80) NOT NULL,
  `description` text DEFAULT NULL,
  PRIMARY KEY (`type_id`),
  UNIQUE KEY `type_name` (`type_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `manufacturer_reviews` (
  `review_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `request_id` int(10) unsigned NOT NULL,
  `manufacturer_id` int(10) unsigned NOT NULL,
  `technical_notes` text NOT NULL,
  `feasibility` enum('Feasible','Not Feasible','Feasible with Modifications') NOT NULL,
  `material_availability` varchar(180) DEFAULT NULL,
  `estimated_time` varchar(100) DEFAULT NULL,
  `recommended_modifications` text DEFAULT NULL,
  `review_date` timestamp NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`review_id`),
  KEY `request_id` (`request_id`),
  KEY `manufacturer_id` (`manufacturer_id`),
  CONSTRAINT `manufacturer_reviews_ibfk_1` FOREIGN KEY (`request_id`) REFERENCES `custom_requests` (`request_id`),
  CONSTRAINT `manufacturer_reviews_ibfk_2` FOREIGN KEY (`manufacturer_id`) REFERENCES `users` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `material_catalog` (
  `material_key` varchar(32) NOT NULL,
  `material_name` varchar(100) NOT NULL,
  `category` varchar(24) NOT NULL,
  `color_hex` char(7) NOT NULL,
  `roughness` decimal(4,3) NOT NULL DEFAULT 0.600,
  `metallic` decimal(4,3) NOT NULL DEFAULT 0.000,
  `normal_scale` decimal(4,2) NOT NULL DEFAULT 0.45,
  `base_color_map` varchar(255) DEFAULT NULL,
  `normal_map` varchar(255) DEFAULT NULL,
  `roughness_map` varchar(255) DEFAULT NULL,
  `metallic_map` varchar(255) DEFAULT NULL,
  `ao_map` varchar(255) DEFAULT NULL,
  `preview_image` varchar(255) DEFAULT NULL,
  `additional_cost` decimal(10,2) NOT NULL DEFAULT 0.00,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`material_key`),
  CONSTRAINT `CONSTRAINT_1` CHECK (`color_hex` regexp '^#[0-9a-fA-F]{6}$'),
  CONSTRAINT `CONSTRAINT_2` CHECK (`roughness` between 0 and 1),
  CONSTRAINT `CONSTRAINT_3` CHECK (`metallic` between 0 and 1),
  CONSTRAINT `CONSTRAINT_4` CHECK (`normal_scale` between 0 and 2),
  CONSTRAINT `CONSTRAINT_5` CHECK (`additional_cost` >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `notifications` (
  `notification_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` int(10) unsigned NOT NULL,
  `message` varchar(255) NOT NULL,
  `related_type` varchar(40) DEFAULT NULL,
  `related_id` int(10) unsigned DEFAULT NULL,
  `is_read` tinyint(1) NOT NULL DEFAULT 0,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`notification_id`),
  KEY `user_id` (`user_id`,`is_read`,`created_at`),
  CONSTRAINT `notifications_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `order_item_component_snapshots` (
  `snapshot_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `order_item_id` int(10) unsigned NOT NULL,
  `component_key` varchar(60) NOT NULL,
  `component_label` varchar(100) NOT NULL,
  `spec_json` longtext NOT NULL,
  `additional_cost` decimal(10,2) NOT NULL DEFAULT 0.00,
  PRIMARY KEY (`snapshot_id`),
  KEY `fk_order_component_item` (`order_item_id`),
  CONSTRAINT `fk_order_component_item` FOREIGN KEY (`order_item_id`) REFERENCES `order_items` (`order_item_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `order_item_customizations` (
  `order_item_customization_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `order_item_id` int(10) unsigned NOT NULL,
  `option_id` int(10) unsigned DEFAULT NULL,
  `selected_value` varchar(180) NOT NULL,
  `additional_cost` decimal(10,2) NOT NULL DEFAULT 0.00,
  PRIMARY KEY (`order_item_customization_id`),
  KEY `order_item_id` (`order_item_id`),
  KEY `option_id` (`option_id`),
  CONSTRAINT `order_item_customizations_ibfk_1` FOREIGN KEY (`order_item_id`) REFERENCES `order_items` (`order_item_id`),
  CONSTRAINT `order_item_customizations_ibfk_2` FOREIGN KEY (`option_id`) REFERENCES `customization_options` (`option_id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `order_items` (
  `order_item_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `order_id` int(10) unsigned NOT NULL,
  `product_id` int(10) unsigned DEFAULT NULL,
  `quantity` smallint(5) unsigned NOT NULL,
  `unit_price` decimal(10,2) NOT NULL,
  `subtotal` decimal(12,2) NOT NULL,
  `product_name_snapshot` varchar(180) NOT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`order_item_id`),
  KEY `order_id` (`order_id`),
  KEY `product_id` (`product_id`),
  CONSTRAINT `order_items_ibfk_1` FOREIGN KEY (`order_id`) REFERENCES `orders` (`order_id`),
  CONSTRAINT `order_items_ibfk_2` FOREIGN KEY (`product_id`) REFERENCES `products` (`product_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `order_status_history` (
  `history_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `order_id` int(10) unsigned NOT NULL,
  `status` varchar(30) NOT NULL,
  `notes` text DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_by` int(10) unsigned DEFAULT NULL,
  PRIMARY KEY (`history_id`),
  KEY `order_id` (`order_id`),
  KEY `updated_by` (`updated_by`),
  CONSTRAINT `order_status_history_ibfk_1` FOREIGN KEY (`order_id`) REFERENCES `orders` (`order_id`),
  CONSTRAINT `order_status_history_ibfk_2` FOREIGN KEY (`updated_by`) REFERENCES `users` (`user_id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `orders` (
  `order_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` int(10) unsigned NOT NULL,
  `order_date` timestamp NULL DEFAULT current_timestamp(),
  `total_amount` decimal(12,2) NOT NULL,
  `status` enum('Pending','Confirmed','Processing','Manufacturing','Shipped','Delivered','Cancelled') NOT NULL DEFAULT 'Pending',
  `delivery_address` text NOT NULL,
  `payment_method` varchar(50) NOT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`order_id`),
  KEY `user_id` (`user_id`,`order_date`),
  CONSTRAINT `orders_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `password_reset_tokens` (
  `reset_id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` int(10) unsigned NOT NULL,
  `token_hash` char(64) NOT NULL,
  `expires_at` datetime NOT NULL,
  `used_at` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`reset_id`),
  UNIQUE KEY `token_hash` (`token_hash`),
  KEY `user_id` (`user_id`,`expires_at`),
  CONSTRAINT `fk_reset_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `payments` (
  `payment_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `order_id` int(10) unsigned NOT NULL,
  `amount` decimal(12,2) NOT NULL,
  `payment_method` varchar(50) NOT NULL,
  `payment_status` enum('Pending','Paid','Failed','Refunded') NOT NULL DEFAULT 'Pending',
  `payment_date` timestamp NULL DEFAULT NULL,
  `transaction_reference` varchar(120) DEFAULT NULL,
  PRIMARY KEY (`payment_id`),
  KEY `order_id` (`order_id`),
  CONSTRAINT `payments_ibfk_1` FOREIGN KEY (`order_id`) REFERENCES `orders` (`order_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `product_component_options` (
  `component_option_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `component_id` int(10) unsigned NOT NULL,
  `option_type` enum('material','color','finish') NOT NULL,
  `option_name` varchar(100) NOT NULL,
  `color_hex` char(7) NOT NULL DEFAULT '#A98568',
  `texture_key` varchar(24) NOT NULL DEFAULT 'solid',
  `additional_cost` decimal(10,2) NOT NULL DEFAULT 0.00,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (`component_option_id`),
  UNIQUE KEY `uq_component_option` (`component_id`,`option_type`,`option_name`),
  CONSTRAINT `fk_component_option_component` FOREIGN KEY (`component_id`) REFERENCES `product_components` (`component_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `product_components` (
  `component_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `product_id` int(10) unsigned NOT NULL,
  `component_key` varchar(60) NOT NULL,
  `display_name` varchar(100) NOT NULL,
  `geometry_type` varchar(32) NOT NULL,
  `layout_axis` varchar(16) NOT NULL DEFAULT 'none',
  `anchor_component_key` varchar(60) DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `default_shape` varchar(32) NOT NULL,
  `allowed_shapes_json` longtext NOT NULL,
  `shape_prices_json` longtext NOT NULL,
  `default_material` varchar(100) NOT NULL DEFAULT 'Oak',
  `default_color_hex` char(7) NOT NULL DEFAULT '#B88752',
  `default_texture_key` varchar(24) NOT NULL DEFAULT 'oak',
  `default_finish` varchar(100) NOT NULL DEFAULT 'Matte',
  `default_width_cm` decimal(8,2) NOT NULL,
  `min_width_cm` decimal(8,2) NOT NULL,
  `max_width_cm` decimal(8,2) NOT NULL,
  `default_depth_cm` decimal(8,2) NOT NULL,
  `min_depth_cm` decimal(8,2) NOT NULL,
  `max_depth_cm` decimal(8,2) NOT NULL,
  `default_height_cm` decimal(8,2) NOT NULL,
  `min_height_cm` decimal(8,2) NOT NULL,
  `max_height_cm` decimal(8,2) NOT NULL,
  `default_quantity` smallint(5) unsigned NOT NULL DEFAULT 1,
  `min_quantity` smallint(5) unsigned NOT NULL DEFAULT 0,
  `max_quantity` smallint(5) unsigned NOT NULL DEFAULT 20,
  `default_x_cm` decimal(8,2) NOT NULL DEFAULT 0.00,
  `min_x_cm` decimal(8,2) NOT NULL DEFAULT -200.00,
  `max_x_cm` decimal(8,2) NOT NULL DEFAULT 200.00,
  `default_y_cm` decimal(8,2) NOT NULL DEFAULT 0.00,
  `min_y_cm` decimal(8,2) NOT NULL DEFAULT -200.00,
  `max_y_cm` decimal(8,2) NOT NULL DEFAULT 250.00,
  `default_z_cm` decimal(8,2) NOT NULL DEFAULT 0.00,
  `min_z_cm` decimal(8,2) NOT NULL DEFAULT -200.00,
  `max_z_cm` decimal(8,2) NOT NULL DEFAULT 200.00,
  `unit_price` decimal(10,2) NOT NULL DEFAULT 0.00,
  `width_rate` decimal(10,2) NOT NULL DEFAULT 0.00,
  `depth_rate` decimal(10,2) NOT NULL DEFAULT 0.00,
  `height_rate` decimal(10,2) NOT NULL DEFAULT 0.00,
  PRIMARY KEY (`component_id`),
  UNIQUE KEY `uq_product_component` (`product_id`,`component_key`),
  KEY `idx_component_product` (`product_id`,`is_active`),
  CONSTRAINT `fk_component_product` FOREIGN KEY (`product_id`) REFERENCES `products` (`product_id`) ON DELETE CASCADE,
  CONSTRAINT `CONSTRAINT_1` CHECK (`max_width_cm` >= `min_width_cm` and `default_width_cm` between `min_width_cm` and `max_width_cm`),
  CONSTRAINT `CONSTRAINT_2` CHECK (`max_depth_cm` >= `min_depth_cm` and `default_depth_cm` between `min_depth_cm` and `max_depth_cm`),
  CONSTRAINT `CONSTRAINT_3` CHECK (`max_height_cm` >= `min_height_cm` and `default_height_cm` between `min_height_cm` and `max_height_cm`),
  CONSTRAINT `CONSTRAINT_4` CHECK (`max_quantity` >= `min_quantity` and `default_quantity` between `min_quantity` and `max_quantity`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `product_customization_options` (
  `product_id` int(10) unsigned NOT NULL,
  `option_id` int(10) unsigned NOT NULL,
  PRIMARY KEY (`product_id`,`option_id`),
  KEY `option_id` (`option_id`),
  CONSTRAINT `product_customization_options_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `products` (`product_id`) ON DELETE CASCADE,
  CONSTRAINT `product_customization_options_ibfk_2` FOREIGN KEY (`option_id`) REFERENCES `customization_options` (`option_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `product_dimension_price_ranges` (
  `range_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `product_id` int(10) unsigned NOT NULL,
  `dimension_name` enum('width','height','depth') NOT NULL,
  `min_cm` decimal(8,2) NOT NULL,
  `max_cm` decimal(8,2) NOT NULL,
  `additional_cost` decimal(10,2) NOT NULL DEFAULT 0.00,
  PRIMARY KEY (`range_id`),
  KEY `product_id` (`product_id`,`dimension_name`,`min_cm`,`max_cm`),
  CONSTRAINT `fk_dimension_range_product` FOREIGN KEY (`product_id`) REFERENCES `products` (`product_id`) ON DELETE CASCADE,
  CONSTRAINT `CONSTRAINT_1` CHECK (`max_cm` > `min_cm` and `additional_cost` >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `product_dimension_rules` (
  `product_id` int(10) unsigned NOT NULL,
  `dimension_name` enum('width','height','depth') NOT NULL,
  `min_cm` decimal(8,2) NOT NULL,
  `max_cm` decimal(8,2) NOT NULL,
  `default_cm` decimal(8,2) NOT NULL,
  `step_cm` decimal(6,2) NOT NULL DEFAULT 1.00,
  `pricing_mode` enum('none','per_cm','fixed','percentage','ranges','material_usage') NOT NULL DEFAULT 'none',
  `price_amount` decimal(10,2) NOT NULL DEFAULT 0.00,
  PRIMARY KEY (`product_id`,`dimension_name`),
  CONSTRAINT `fk_dimension_product` FOREIGN KEY (`product_id`) REFERENCES `products` (`product_id`) ON DELETE CASCADE,
  CONSTRAINT `CONSTRAINT_1` CHECK (`min_cm` > 0 and `max_cm` > `min_cm` and `default_cm` >= `min_cm` and `default_cm` <= `max_cm` and `step_cm` > 0 and `price_amount` >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `product_images` (
  `image_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `product_id` int(10) unsigned NOT NULL,
  `image_path` varchar(255) NOT NULL,
  `alt_text` varchar(200) DEFAULT NULL,
  `is_primary` tinyint(1) DEFAULT 0,
  `uploaded_at` timestamp NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`image_id`),
  KEY `product_id` (`product_id`),
  CONSTRAINT `product_images_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `products` (`product_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `production_orders` (
  `order_id` int(10) unsigned NOT NULL,
  `quotation_id` int(10) unsigned NOT NULL,
  `request_id` int(10) unsigned NOT NULL,
  `manufacturer_id` int(10) unsigned DEFAULT NULL,
  `stage` varchar(32) NOT NULL,
  `specification` longtext NOT NULL,
  `carrier` varchar(100) DEFAULT NULL,
  `tracking_reference` varchar(120) DEFAULT NULL,
  PRIMARY KEY (`order_id`),
  UNIQUE KEY `quotation_id` (`quotation_id`),
  UNIQUE KEY `request_id` (`request_id`),
  KEY `manufacturer_id` (`manufacturer_id`),
  CONSTRAINT `production_orders_ibfk_1` FOREIGN KEY (`order_id`) REFERENCES `orders` (`order_id`),
  CONSTRAINT `production_orders_ibfk_2` FOREIGN KEY (`quotation_id`) REFERENCES `quotations` (`quotation_id`),
  CONSTRAINT `production_orders_ibfk_3` FOREIGN KEY (`request_id`) REFERENCES `custom_requests` (`request_id`),
  CONSTRAINT `production_orders_ibfk_4` FOREIGN KEY (`manufacturer_id`) REFERENCES `users` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `products` (
  `product_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `category_id` int(10) unsigned DEFAULT NULL,
  `name` varchar(180) NOT NULL,
  `description` text DEFAULT NULL,
  `base_price` decimal(10,2) NOT NULL,
  `availability` enum('In Stock','Out of Stock','Archived') NOT NULL DEFAULT 'In Stock',
  `is_customizable` tinyint(1) NOT NULL DEFAULT 0,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `default_width_cm` decimal(8,2) NOT NULL DEFAULT 100.00,
  `default_height_cm` decimal(8,2) NOT NULL DEFAULT 100.00,
  `default_depth_cm` decimal(8,2) NOT NULL DEFAULT 100.00,
  `width_rate_per_cm` decimal(10,2) NOT NULL DEFAULT 0.00,
  `height_rate_per_cm` decimal(10,2) NOT NULL DEFAULT 0.00,
  `depth_rate_per_cm` decimal(10,2) NOT NULL DEFAULT 0.00,
  `customization_preview_kind` enum('generic','sofa','coffee_table','bed','dining_table','wardrobe') NOT NULL DEFAULT 'generic',
  PRIMARY KEY (`product_id`),
  KEY `category_id` (`category_id`),
  CONSTRAINT `fk_product_category` FOREIGN KEY (`category_id`) REFERENCES `categories` (`category_id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `quotations` (
  `quotation_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `request_id` int(10) unsigned NOT NULL,
  `admin_id` int(10) unsigned NOT NULL,
  `price` decimal(12,2) NOT NULL,
  `estimated_time` varchar(100) NOT NULL,
  `valid_until` date DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `status` enum('Draft','Sent','Accepted','Rejected','Expired','Cancelled') NOT NULL DEFAULT 'Draft',
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `accepted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`quotation_id`),
  KEY `request_id` (`request_id`,`status`),
  KEY `admin_id` (`admin_id`),
  CONSTRAINT `quotations_ibfk_1` FOREIGN KEY (`request_id`) REFERENCES `custom_requests` (`request_id`),
  CONSTRAINT `quotations_ibfk_2` FOREIGN KEY (`admin_id`) REFERENCES `users` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `request_images` (
  `request_image_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `request_id` int(10) unsigned NOT NULL,
  `image_path` varchar(255) NOT NULL,
  `uploaded_at` timestamp NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`request_image_id`),
  KEY `request_id` (`request_id`),
  CONSTRAINT `request_images_ibfk_1` FOREIGN KEY (`request_id`) REFERENCES `custom_requests` (`request_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `users` (
  `user_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `full_name` varchar(140) NOT NULL,
  `email` varchar(190) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `phone` varchar(40) DEFAULT NULL,
  `role` enum('customer','admin','manufacturer') NOT NULL DEFAULT 'customer',
  `account_status` enum('active','inactive') NOT NULL DEFAULT 'active',
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `auth_version` int(10) unsigned NOT NULL DEFAULT 1,
  PRIMARY KEY (`user_id`),
  UNIQUE KEY `email` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


SET FOREIGN_KEY_CHECKS=1;
