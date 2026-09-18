ALTER TABLE `player_vehicles` ADD COLUMN IF NOT EXISTS `financed` tinyint(1) NOT NULL DEFAULT 0;
ALTER TABLE `player_vehicles` ADD COLUMN IF NOT EXISTS `finance_data` longtext DEFAULT NULL;

CREATE TABLE IF NOT EXISTS `dealership_vehicles` (
  `spawn_code` varchar(100) NOT NULL,
  `brand` varchar(255) DEFAULT NULL,
  `model` varchar(255) DEFAULT NULL,
  `hashkey` varchar(100) DEFAULT NULL,
  `category` varchar(100) NOT NULL,
  `price` float NOT NULL,
  `price_limits_enabled` tinyint(1) NOT NULL DEFAULT 0,
  `min_price` float DEFAULT NULL,
  `max_price` float DEFAULT NULL,
  `unlimited_stock` tinyint(1) NOT NULL DEFAULT 1,
  `global_stock_limit` int(11) DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`spawn_code`)
);

CREATE TABLE IF NOT EXISTS `dealership_dispveh` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `dealership` varchar(100) NOT NULL,
  `vehicle` varchar(100) NOT NULL,
  `color` varchar(100) NOT NULL,
  `coords` varchar(255) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_dispveh_dealership` (`dealership`),
  KEY `fk_dispveh_vehicle` (`vehicle`)
);

CREATE TABLE IF NOT EXISTS `dealership_orders` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `vehicle` varchar(100) NOT NULL,
  `dealership` varchar(100) NOT NULL,
  `quantity` int(11) NOT NULL DEFAULT 0,
  `delivered` int(11) NOT NULL DEFAULT 0,
  `cost` float NOT NULL DEFAULT 0,
  `delivery_time` int(11) NOT NULL,
  `order_created` datetime NOT NULL DEFAULT current_timestamp(),
  `fulfilled` tinyint(1) NOT NULL DEFAULT 0,
  `ordered_by` varchar(255) DEFAULT NULL,
  `delivered_by` varchar(255) DEFAULT NULL,
  `delivered_at` datetime DEFAULT NULL,
  `delivery_pickup_location` varchar(255) DEFAULT NULL,
  `size_category` ENUM('small', 'medium', 'large') DEFAULT 'medium',
  PRIMARY KEY (`id`),
  KEY `orders_vehicle_fk` (`vehicle`),
  KEY `orders_dealership_fk` (`dealership`)
);

CREATE TABLE IF NOT EXISTS `dealership_sales` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `dealership` varchar(255) NOT NULL,
  `vehicle` varchar(100) NOT NULL,
  `plate` varchar(255) NOT NULL,
  `player` varchar(255) NOT NULL,
  `seller` varchar(255),
  `purchase_type` varchar(50) NOT NULL,
  `paid` float NOT NULL DEFAULT 0,
  `owed` float NOT NULL DEFAULT 0,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `fk_sales_vehicle` (`vehicle`),
  KEY `fk_sales_dealership` (`dealership`),
  KEY `fk_sales_player` (`player`),
  KEY `fk_sales_plate` (`plate`)
);

CREATE TABLE IF NOT EXISTS `dealership_stock` (
  `dealership` varchar(100) NOT NULL,
  `vehicle` varchar(100) NOT NULL,
  `stock` int(11) NOT NULL,
  `price` float NOT NULL DEFAULT 0,
  PRIMARY KEY (`dealership`, `vehicle`),
  KEY `vehicle_fk` (`vehicle`)
);

CREATE TABLE IF NOT EXISTS `dealership_employees` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `identifier` varchar(255) NOT NULL,
  `dealership` varchar(255) NOT NULL,
  `role` varchar(100) NOT NULL,
  `joined` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `fk_employees_dealership` (`dealership`)
);

CREATE TABLE IF NOT EXISTS `dealership_locations` (
  `id` VARCHAR(255) NOT NULL,
  `name` VARCHAR(255) NOT NULL,
  `type` VARCHAR(100) NOT NULL,
  `disabled` BOOLEAN DEFAULT 0 NOT NULL,
  `job_name` VARCHAR(100),
  `job_rank_permissions` TEXT NULL,
  `job_rank_mapping` TEXT NULL,
  `balance` FLOAT DEFAULT 0 NOT NULL,
  `owner_id` VARCHAR(255) DEFAULT NULL,
  `owner_name` VARCHAR(255) DEFAULT NULL,
  `employee_commission` INT(11) DEFAULT '10',
  `dealership_zone` TEXT NULL,
  `showroom_coords` TEXT NOT NULL,
  `management_coords` TEXT NULL,
  `purchase_vehicle_coords` TEXT NULL,
  `trucking_vehicle_coords` TEXT NULL,
  `enable_finance` BOOLEAN DEFAULT 0 NOT NULL,
  `enable_sell_vehicle` BOOLEAN DEFAULT 0 NOT NULL,
  `sell_vehicle_coords` TEXT NULL,
  `sell_vehicle_percent` INT(11) NULL,
  `enable_test_drive` BOOLEAN DEFAULT 0 NOT NULL,
  `test_drive_coords` TEXT NULL,
  `categories` TEXT NOT NULL,
  `camera_data` TEXT NOT NULL,
  `colour_selection_type` VARCHAR(10),
  `colour_options` TEXT NULL,
  `enable_purchase` BOOLEAN DEFAULT 1 NOT NULL,
  `showroom_job_whitelist` TEXT NULL,
  `showroom_gang_whitelist` TEXT NULL,
  `society_purchase_job_whitelist` TEXT NULL,
  `society_purchase_gang_whitelist` TEXT NULL,
  `payment_methods` TEXT NULL DEFAULT '["bank", "cash"]',
  `currency_balances` TEXT NULL,
  `additional_data` TEXT NULL,
  PRIMARY KEY (`id`)
);

CREATE TABLE IF NOT EXISTS `dealership_coupons` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `code` VARCHAR(50) NOT NULL,
  `dealership_id` VARCHAR(255) NOT NULL,
  `discount_type` ENUM('amount', 'percent') NOT NULL,
  `discount_value` FLOAT NOT NULL,
  `max_uses` INT(11) NULL COMMENT 'NULL = unlimited',
  `current_uses` INT(11) DEFAULT 0 NOT NULL,
  `per_player_limit` INT(11) NULL COMMENT 'NULL = unlimited per player',
  `expiry_date` BIGINT NULL COMMENT 'Unix timestamp in milliseconds, NULL = never expires',
  `vehicle_restrictions` TEXT NULL COMMENT 'JSON array of spawn codes, NULL = all vehicles',
  `category_restrictions` TEXT NULL COMMENT 'JSON array of categories, NULL = all categories',
  `allow_finance` BOOLEAN DEFAULT 1 NOT NULL COMMENT 'Whether coupon can be used with financed purchases',
  `active` BOOLEAN DEFAULT 1 NOT NULL,
  `created_at` BIGINT NOT NULL,
  `created_by` VARCHAR(255) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `code_dealership` (`code`, `dealership_id`),
  KEY `dealership_id` (`dealership_id`)
);

CREATE TABLE IF NOT EXISTS `dealership_coupon_usage` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `coupon_id` INT(11) NOT NULL,
  `player_identifier` VARCHAR(255) NOT NULL,
  `vehicle_spawn_code` VARCHAR(100) NOT NULL,
  `purchase_type` VARCHAR(50) NOT NULL COMMENT 'personal or society',
  `was_financed` BOOLEAN NOT NULL,
  `discount_applied` FLOAT NOT NULL,
  `used_at` BIGINT NOT NULL,
  PRIMARY KEY (`id`),
  KEY `coupon_id` (`coupon_id`),
  KEY `player_identifier` (`player_identifier`)
);
