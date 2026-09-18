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
  KEY `dealership_id` (`dealership_id`),
  FOREIGN KEY (`dealership_id`) REFERENCES `dealership_locations`(`id`) ON DELETE CASCADE
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
  KEY `player_identifier` (`player_identifier`),
  FOREIGN KEY (`coupon_id`) REFERENCES `dealership_coupons`(`id`) ON DELETE CASCADE
);

-- Vehicle price limits and global stock limits
ALTER TABLE `dealership_vehicles` ADD COLUMN IF NOT EXISTS `price_limits_enabled` TINYINT(1) NOT NULL DEFAULT 0;
ALTER TABLE `dealership_vehicles` ADD COLUMN IF NOT EXISTS `min_price` FLOAT DEFAULT NULL;
ALTER TABLE `dealership_vehicles` ADD COLUMN IF NOT EXISTS `max_price` FLOAT DEFAULT NULL;
ALTER TABLE `dealership_vehicles` ADD COLUMN IF NOT EXISTS `unlimited_stock` TINYINT(1) NOT NULL DEFAULT 1;
ALTER TABLE `dealership_vehicles` ADD COLUMN IF NOT EXISTS `global_stock_limit` INT(11) DEFAULT NULL;

-- Delivery tracking columns
ALTER TABLE `dealership_orders` ADD COLUMN IF NOT EXISTS `ordered_by` VARCHAR(255) DEFAULT NULL;
ALTER TABLE `dealership_orders` ADD COLUMN IF NOT EXISTS `delivered_by` VARCHAR(255) DEFAULT NULL;
ALTER TABLE `dealership_orders` ADD COLUMN IF NOT EXISTS `delivered_at` DATETIME DEFAULT NULL;
ALTER TABLE `dealership_orders` ADD COLUMN IF NOT EXISTS `delivery_pickup_location` VARCHAR(255) DEFAULT NULL;
ALTER TABLE `dealership_orders` ADD COLUMN IF NOT EXISTS `delivered` INT(11) NOT NULL DEFAULT 0;
ALTER TABLE `dealership_orders` ADD COLUMN IF NOT EXISTS `size_category` ENUM('small', 'medium', 'large') DEFAULT 'medium';
