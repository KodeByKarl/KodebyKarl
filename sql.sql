-- --------------------------------------------------------
-- Host:                         127.0.0.1
-- Server version:               12.0.2-MariaDB - mariadb.org binary distribution
-- Server OS:                    Win64
-- HeidiSQL Version:             12.6.0.6765
-- --------------------------------------------------------

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET NAMES utf8 */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;


-- Dumping database structure for cfx_cs_v3
CREATE DATABASE IF NOT EXISTS `cfx_cs_v3` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci */;
USE `cfx_cs_v3`;

-- Dumping structure for table cfx_cs_v3.banking_pins
CREATE TABLE IF NOT EXISTS `banking_pins` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `identifier` varchar(50) NOT NULL COMMENT 'Player identifier (ESX) or citizenid (QB)',
  `pin` varchar(4) NOT NULL COMMENT '4-digit PIN for ATM access',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp() COMMENT 'PIN creation date',
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp() COMMENT 'Last PIN update',
  PRIMARY KEY (`id`),
  UNIQUE KEY `identifier` (`identifier`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table cfx_cs_v3.banking_pins: ~1 rows (approximately)
INSERT INTO `banking_pins` (`id`, `identifier`, `pin`, `created_at`, `updated_at`) VALUES
	(1, '8d580e801963852f52c994e1670bf72282712462', '0000', '2025-12-18 14:09:31', '2025-12-18 14:09:31');

-- Dumping structure for table cfx_cs_v3.banking_savings
CREATE TABLE IF NOT EXISTS `banking_savings` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `identifier` varchar(50) NOT NULL COMMENT 'Player identifier (ESX) or citizenid (QB)',
  `balance` int(11) NOT NULL DEFAULT 0 COMMENT 'Savings account balance',
  `status` varchar(20) NOT NULL DEFAULT 'active' COMMENT 'Account status: active, inactive',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp() COMMENT 'Account creation date',
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp() COMMENT 'Last update date',
  PRIMARY KEY (`id`),
  UNIQUE KEY `identifier` (`identifier`),
  KEY `status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table cfx_cs_v3.banking_savings: ~0 rows (approximately)

-- Dumping structure for table cfx_cs_v3.banking_transactions
CREATE TABLE IF NOT EXISTS `banking_transactions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `identifier` varchar(50) NOT NULL COMMENT 'Player identifier (ESX) or citizenid (QB)',
  `type` varchar(50) NOT NULL COMMENT 'Transaction type: deposit, withdrawal, transfer_in, transfer_out, fee, savings_deposit, savings_withdrawal, account_transfer, savings_opened, savings_closed',
  `amount` int(11) NOT NULL COMMENT 'Transaction amount',
  `description` text DEFAULT NULL COMMENT 'Transaction description',
  `date` timestamp NOT NULL DEFAULT current_timestamp() COMMENT 'Transaction timestamp',
  PRIMARY KEY (`id`),
  KEY `identifier` (`identifier`),
  KEY `type` (`type`),
  KEY `date` (`date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table cfx_cs_v3.banking_transactions: ~0 rows (approximately)

-- Dumping structure for table cfx_cs_v3.beekeeper_hives
CREATE TABLE IF NOT EXISTS `beekeeper_hives` (
  `id` varchar(32) NOT NULL,
  `owner` varchar(64) DEFAULT NULL,
  `coords` text DEFAULT NULL,
  `bees` int(11) DEFAULT 0,
  `queen` tinyint(1) DEFAULT 0,
  `honeycomb` float DEFAULT 0,
  `fed_until` bigint(20) DEFAULT NULL,
  `shared_with` longtext DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table cfx_cs_v3.beekeeper_hives: ~0 rows (approximately)

-- Dumping structure for table cfx_cs_v3.cd_dispatch
CREATE TABLE IF NOT EXISTS `cd_dispatch` (
  `identifier` varchar(50) DEFAULT NULL,
  `callsign` varchar(100) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table cfx_cs_v3.cd_dispatch: ~0 rows (approximately)

-- Dumping structure for table cfx_cs_v3.cfx-cs-bed
CREATE TABLE IF NOT EXISTS `cfx-cs-bed` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` longtext NOT NULL DEFAULT 'Uncle Bob',
  `identifier` varchar(50) NOT NULL,
  `time` int(11) NOT NULL DEFAULT 0,
  `reason` longtext NOT NULL DEFAULT 'No reason was provided',
  `bedIndex` int(11) NOT NULL,
  `hospital` longtext NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table cfx_cs_v3.cfx-cs-bed: ~0 rows (approximately)

-- Dumping structure for table cfx_cs_v3.cfx-cs-business
CREATE TABLE IF NOT EXISTS `cfx-cs-business` (
  `business` longtext DEFAULT NULL,
  `dateCreated` datetime NOT NULL DEFAULT current_timestamp(),
  UNIQUE KEY `business` (`business`) USING HASH
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table cfx_cs_v3.cfx-cs-business: ~0 rows (approximately)

-- Dumping structure for table cfx_cs_v3.cfx-cs-community
CREATE TABLE IF NOT EXISTS `cfx-cs-community` (
  `identifier` varchar(50) NOT NULL,
  `name` longtext NOT NULL,
  `amount` int(11) DEFAULT NULL,
  `reason` longtext DEFAULT 'No reaason was provided.',
  `items` longtext NOT NULL DEFAULT '[]',
  `create_at` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table cfx_cs_v3.cfx-cs-community: ~0 rows (approximately)

-- Dumping structure for table cfx_cs_v3.cfx-cs-freecars
CREATE TABLE IF NOT EXISTS `cfx-cs-freecars` (
  `identifier` varchar(50) NOT NULL,
  `date` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table cfx_cs_v3.cfx-cs-freecars: ~1 rows (approximately)
INSERT INTO `cfx-cs-freecars` (`identifier`, `date`) VALUES
	('8d580e801963852f52c994e1670bf72282712462', '2025-12-20 21:42:30');

-- Dumping structure for table cfx_cs_v3.cfx-cs-multijob
CREATE TABLE IF NOT EXISTS `cfx-cs-multijob` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `identifier` varchar(50) DEFAULT NULL,
  `job` varchar(60) DEFAULT NULL,
  `grade` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table cfx_cs_v3.cfx-cs-multijob: ~0 rows (approximately)

-- Dumping structure for table cfx_cs_v3.cfx-cs-society
CREATE TABLE IF NOT EXISTS `cfx-cs-society` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `job_name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `amount` int(100) NOT NULL,
  `type` enum('boss','gang') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'boss',
  PRIMARY KEY (`id`),
  UNIQUE KEY `job_name` (`job_name`),
  KEY `type` (`type`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table cfx_cs_v3.cfx-cs-society: ~2 rows (approximately)
INSERT INTO `cfx-cs-society` (`id`, `job_name`, `amount`, `type`) VALUES
	(1, 'government', 2100, 'boss'),
	(2, 'ambulance', 5000, 'boss');

-- Dumping structure for table cfx_cs_v3.dealership_data
CREATE TABLE IF NOT EXISTS `dealership_data` (
  `name` varchar(100) NOT NULL,
  `label` varchar(255) NOT NULL,
  `balance` float NOT NULL DEFAULT 0,
  `owner_id` varchar(255) DEFAULT NULL,
  `owner_name` varchar(255) DEFAULT NULL,
  `employee_commission` int(11) DEFAULT 10,
  PRIMARY KEY (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table cfx_cs_v3.dealership_data: ~2 rows (approximately)
INSERT INTO `dealership_data` (`name`, `label`, `balance`, `owner_id`, `owner_name`, `employee_commission`) VALUES
	('boats', '', 0, NULL, NULL, 10),
	('pdm', '', 0, NULL, NULL, 10);

-- Dumping structure for table cfx_cs_v3.dealership_dispveh
CREATE TABLE IF NOT EXISTS `dealership_dispveh` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `dealership` varchar(100) NOT NULL,
  `vehicle` varchar(100) NOT NULL,
  `color` varchar(100) NOT NULL,
  `coords` varchar(255) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_dispveh_dealership` (`dealership`),
  KEY `fk_dispveh_vehicle` (`vehicle`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table cfx_cs_v3.dealership_dispveh: ~0 rows (approximately)

-- Dumping structure for table cfx_cs_v3.dealership_employees
CREATE TABLE IF NOT EXISTS `dealership_employees` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `identifier` varchar(255) NOT NULL,
  `dealership` varchar(255) NOT NULL,
  `role` varchar(100) NOT NULL,
  `joined` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `fk_employees_dealership` (`dealership`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table cfx_cs_v3.dealership_employees: ~0 rows (approximately)

-- Dumping structure for table cfx_cs_v3.dealership_orders
CREATE TABLE IF NOT EXISTS `dealership_orders` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `vehicle` varchar(100) NOT NULL,
  `dealership` varchar(100) NOT NULL,
  `quantity` int(11) NOT NULL DEFAULT 0,
  `cost` float NOT NULL DEFAULT 0,
  `delivery_time` int(11) NOT NULL,
  `order_created` datetime NOT NULL DEFAULT current_timestamp(),
  `fulfilled` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `orders_vehicle_fk` (`vehicle`),
  KEY `orders_dealership_fk` (`dealership`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table cfx_cs_v3.dealership_orders: ~0 rows (approximately)

-- Dumping structure for table cfx_cs_v3.dealership_sales
CREATE TABLE IF NOT EXISTS `dealership_sales` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `dealership` varchar(255) NOT NULL,
  `vehicle` varchar(100) NOT NULL,
  `plate` varchar(255) NOT NULL,
  `player` varchar(255) NOT NULL,
  `seller` varchar(255) DEFAULT NULL,
  `purchase_type` varchar(50) NOT NULL,
  `paid` float NOT NULL DEFAULT 0,
  `owed` float NOT NULL DEFAULT 0,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `fk_sales_vehicle` (`vehicle`),
  KEY `fk_sales_dealership` (`dealership`),
  KEY `fk_sales_player` (`player`),
  KEY `fk_sales_plate` (`plate`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table cfx_cs_v3.dealership_sales: ~0 rows (approximately)

-- Dumping structure for table cfx_cs_v3.dealership_stock
CREATE TABLE IF NOT EXISTS `dealership_stock` (
  `dealership` varchar(100) NOT NULL,
  `vehicle` varchar(100) NOT NULL,
  `stock` int(11) NOT NULL,
  `price` float NOT NULL DEFAULT 0,
  PRIMARY KEY (`dealership`,`vehicle`),
  KEY `vehicle_fk` (`vehicle`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table cfx_cs_v3.dealership_stock: ~0 rows (approximately)

-- Dumping structure for table cfx_cs_v3.dealership_vehicles
CREATE TABLE IF NOT EXISTS `dealership_vehicles` (
  `spawn_code` varchar(100) NOT NULL,
  `brand` varchar(255) DEFAULT NULL,
  `model` varchar(255) DEFAULT NULL,
  `hashkey` varchar(100) DEFAULT NULL,
  `category` varchar(100) NOT NULL,
  `price` float NOT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`spawn_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table cfx_cs_v3.dealership_vehicles: ~0 rows (approximately)

-- Dumping structure for table cfx_cs_v3.gg_studio_electricianjob
CREATE TABLE IF NOT EXISTS `gg_studio_electricianjob` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `identifier` varchar(100) NOT NULL,
  `player_experience` int(11) DEFAULT 0,
  `completed_challenges` int(11) DEFAULT 0,
  `challenges` text DEFAULT NULL,
  `daily_progress` text DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `unique_identifier` (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;

-- Dumping data for table cfx_cs_v3.gg_studio_electricianjob: ~0 rows (approximately)

-- Dumping structure for table cfx_cs_v3.gg_studio_global
CREATE TABLE IF NOT EXISTS `gg_studio_global` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `script_id` varchar(100) NOT NULL,
  `daily_time` int(11) DEFAULT 0,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;

-- Dumping data for table cfx_cs_v3.gg_studio_global: ~1 rows (approximately)
INSERT INTO `gg_studio_global` (`id`, `script_id`, `daily_time`) VALUES
	(1, 'gg_electricianjob', 1768994790);

-- Dumping structure for table cfx_cs_v3.gksphone_advertising
CREATE TABLE IF NOT EXISTS `gksphone_advertising` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `phone_number` varchar(50) NOT NULL,
  `phone_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `firstname` varchar(256) NOT NULL,
  `title` varchar(250) DEFAULT NULL,
  `message` longtext NOT NULL,
  `image` longtext DEFAULT NULL,
  `price` int(11) DEFAULT NULL,
  `time` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`) USING BTREE,
  KEY `phone_id` (`phone_id`),
  CONSTRAINT `FK_gksphone_advertising_gksphone_esim` FOREIGN KEY (`phone_id`) REFERENCES `gksphone_esim` (`phone_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table cfx_cs_v3.gksphone_advertising: ~0 rows (approximately)

-- Dumping structure for table cfx_cs_v3.gksphone_bank_history
CREATE TABLE IF NOT EXISTS `gksphone_bank_history` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `phone_number` varchar(50) NOT NULL DEFAULT '',
  `type` int(11) NOT NULL,
  `amount` int(11) NOT NULL DEFAULT 0,
  `description` longtext NOT NULL,
  `time` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `phone_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `phone_id` (`phone_id`),
  CONSTRAINT `FK_gksphone_bank_histroy_gksphone_esim` FOREIGN KEY (`phone_id`) REFERENCES `gksphone_esim` (`phone_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table cfx_cs_v3.gksphone_bank_history: ~0 rows (approximately)

-- Dumping structure for table cfx_cs_v3.gksphone_billing
CREATE TABLE IF NOT EXISTS `gksphone_billing` (
  `id` int(10) NOT NULL AUTO_INCREMENT,
  `citizenid` varchar(50) NOT NULL,
  `amount` int(11) NOT NULL DEFAULT 0,
  `society` varchar(50) NOT NULL DEFAULT '',
  `societylabel` varchar(50) NOT NULL DEFAULT '',
  `sender` varchar(50) NOT NULL,
  `sendercitizenid` varchar(50) NOT NULL,
  `description` varchar(250) NOT NULL,
  `status` varchar(50) NOT NULL DEFAULT '',
  `bill_holder` varchar(50) NOT NULL,
  `time` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table cfx_cs_v3.gksphone_billing: ~0 rows (approximately)

-- Dumping structure for table cfx_cs_v3.gksphone_calls
CREATE TABLE IF NOT EXISTS `gksphone_calls` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `phone_id` varchar(50) NOT NULL DEFAULT '',
  `caller` varchar(50) NOT NULL,
  `receiver` varchar(50) NOT NULL DEFAULT '',
  `type` varchar(50) NOT NULL DEFAULT '',
  `status` int(11) NOT NULL,
  `hidden` int(11) NOT NULL DEFAULT 0,
  `time` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `phone_id` (`phone_id`),
  CONSTRAINT `FK_gksphone_calls_gksphone_esim` FOREIGN KEY (`phone_id`) REFERENCES `gksphone_esim` (`phone_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table cfx_cs_v3.gksphone_calls: ~0 rows (approximately)

-- Dumping structure for table cfx_cs_v3.gksphone_contacts
CREATE TABLE IF NOT EXISTS `gksphone_contacts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `phone_number` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `number` varchar(30) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `display` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `options` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `block` tinyint(1) NOT NULL DEFAULT 0,
  `phone_id` varchar(50) NOT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `phone_id` (`phone_id`),
  CONSTRAINT `gksphone_contacts_ibfk_1` FOREIGN KEY (`phone_id`) REFERENCES `gksphone_esim` (`phone_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table cfx_cs_v3.gksphone_contacts: ~0 rows (approximately)

-- Dumping structure for table cfx_cs_v3.gksphone_darkchat_messages
CREATE TABLE IF NOT EXISTS `gksphone_darkchat_messages` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `room_id` int(11) NOT NULL,
  `sender_id` int(11) NOT NULL,
  `message` text NOT NULL,
  `message_type` enum('text','image','video','location') DEFAULT 'text',
  `attachment_data` longtext DEFAULT NULL,
  `sent_at` timestamp NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_room_messages` (`room_id`,`sent_at`) USING BTREE,
  KEY `idx_sender` (`sender_id`) USING BTREE,
  KEY `idx_messages_recent` (`room_id`,`sent_at`) USING BTREE,
  CONSTRAINT `gksphone_darkchat_messages_ibfk_1` FOREIGN KEY (`room_id`) REFERENCES `gksphone_darkchat_rooms` (`id`) ON DELETE CASCADE,
  CONSTRAINT `gksphone_darkchat_messages_ibfk_2` FOREIGN KEY (`sender_id`) REFERENCES `gksphone_darkchat_users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table cfx_cs_v3.gksphone_darkchat_messages: ~0 rows (approximately)

-- Dumping structure for table cfx_cs_v3.gksphone_darkchat_rooms
CREATE TABLE IF NOT EXISTS `gksphone_darkchat_rooms` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `owner_id` int(11) NOT NULL,
  `room_name` varchar(100) NOT NULL,
  `room_image` text DEFAULT NULL,
  `is_password_protected` tinyint(1) DEFAULT 0,
  `password` varchar(255) DEFAULT NULL,
  `is_private` tinyint(1) DEFAULT 0,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `is_active` tinyint(1) DEFAULT 1,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `room_name` (`room_name`) USING BTREE,
  KEY `idx_owner` (`owner_id`) USING BTREE,
  KEY `idx_private` (`is_private`) USING BTREE,
  KEY `idx_rooms_search` (`room_name`,`is_private`,`is_active`) USING BTREE,
  CONSTRAINT `gksphone_darkchat_rooms_ibfk_1` FOREIGN KEY (`owner_id`) REFERENCES `gksphone_darkchat_users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table cfx_cs_v3.gksphone_darkchat_rooms: ~0 rows (approximately)

-- Dumping structure for table cfx_cs_v3.gksphone_darkchat_room_members
CREATE TABLE IF NOT EXISTS `gksphone_darkchat_room_members` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `room_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `joined_at` timestamp NULL DEFAULT current_timestamp(),
  `role` enum('owner','member') DEFAULT 'member',
  `is_muted` tinyint(1) DEFAULT 0,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `unique_member` (`room_id`,`user_id`) USING BTREE,
  KEY `idx_room_members` (`room_id`) USING BTREE,
  KEY `idx_user_rooms` (`user_id`) USING BTREE,
  CONSTRAINT `gksphone_darkchat_room_members_ibfk_1` FOREIGN KEY (`room_id`) REFERENCES `gksphone_darkchat_rooms` (`id`) ON DELETE CASCADE,
  CONSTRAINT `gksphone_darkchat_room_members_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `gksphone_darkchat_users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table cfx_cs_v3.gksphone_darkchat_room_members: ~0 rows (approximately)

-- Dumping structure for table cfx_cs_v3.gksphone_darkchat_users
CREATE TABLE IF NOT EXISTS `gksphone_darkchat_users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `identifier` varchar(255) NOT NULL,
  `username` varchar(50) NOT NULL,
  `password` varchar(255) NOT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `is_active` tinyint(1) DEFAULT 1,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `username` (`username`) USING BTREE,
  KEY `idx_users_search` (`username`,`is_active`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table cfx_cs_v3.gksphone_darkchat_users: ~0 rows (approximately)

-- Dumping structure for table cfx_cs_v3.gksphone_esim
CREATE TABLE IF NOT EXISTS `gksphone_esim` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `pin` int(11) NOT NULL DEFAULT 0,
  `operator` varchar(50) NOT NULL DEFAULT '0',
  `package_id` int(11) NOT NULL DEFAULT 0,
  `phone_number` varchar(50) NOT NULL DEFAULT '0',
  `phone_id` varchar(50) NOT NULL DEFAULT '',
  `is_active` tinyint(4) NOT NULL DEFAULT 0,
  `package_sms` int(11) NOT NULL DEFAULT 0,
  `package_call` int(11) NOT NULL DEFAULT 0,
  `package_internet` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `phone_number` (`phone_number`),
  KEY `idx_phone_id` (`phone_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table cfx_cs_v3.gksphone_esim: ~0 rows (approximately)

-- Dumping structure for table cfx_cs_v3.gksphone_flare_matches
CREATE TABLE IF NOT EXISTS `gksphone_flare_matches` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user1_id` int(11) DEFAULT NULL,
  `user2_id` int(11) DEFAULT NULL,
  `matched_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `user1_id` (`user1_id`,`user2_id`) USING BTREE,
  KEY `user2_id` (`user2_id`) USING BTREE,
  CONSTRAINT `gksphone_flare_matches_ibfk_1` FOREIGN KEY (`user1_id`) REFERENCES `gksphone_flare_users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `gksphone_flare_matches_ibfk_2` FOREIGN KEY (`user2_id`) REFERENCES `gksphone_flare_users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table cfx_cs_v3.gksphone_flare_matches: ~0 rows (approximately)

-- Dumping structure for table cfx_cs_v3.gksphone_flare_messages
CREATE TABLE IF NOT EXISTS `gksphone_flare_messages` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `match_id` int(11) DEFAULT NULL,
  `sender_id` int(11) DEFAULT NULL,
  `message` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `read_at` tinyint(4) NOT NULL DEFAULT 0,
  `sent_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`) USING BTREE,
  KEY `match_id` (`match_id`) USING BTREE,
  KEY `sender_id` (`sender_id`) USING BTREE,
  CONSTRAINT `gksphone_flare_messages_ibfk_1` FOREIGN KEY (`match_id`) REFERENCES `gksphone_flare_matches` (`id`) ON DELETE CASCADE,
  CONSTRAINT `gksphone_flare_messages_ibfk_2` FOREIGN KEY (`sender_id`) REFERENCES `gksphone_flare_users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table cfx_cs_v3.gksphone_flare_messages: ~0 rows (approximately)

-- Dumping structure for table cfx_cs_v3.gksphone_flare_swipes
CREATE TABLE IF NOT EXISTS `gksphone_flare_swipes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `swiper_id` int(11) DEFAULT NULL,
  `target_id` int(11) DEFAULT NULL,
  `swipe_type` enum('like','pass','undo') DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`) USING BTREE,
  KEY `FK_gksphone_flare_swipes_gksphone_flare_users` (`swiper_id`) USING BTREE,
  KEY `FK_gksphone_flare_swipes_gksphone_flare_users_2` (`target_id`) USING BTREE,
  CONSTRAINT `FK_gksphone_flare_swipes_gksphone_flare_users` FOREIGN KEY (`swiper_id`) REFERENCES `gksphone_flare_users` (`id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  CONSTRAINT `FK_gksphone_flare_swipes_gksphone_flare_users_2` FOREIGN KEY (`target_id`) REFERENCES `gksphone_flare_users` (`id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table cfx_cs_v3.gksphone_flare_swipes: ~0 rows (approximately)

-- Dumping structure for table cfx_cs_v3.gksphone_flare_users
CREATE TABLE IF NOT EXISTS `gksphone_flare_users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `phone_id` varchar(100) DEFAULT NULL,
  `name` varchar(100) DEFAULT NULL,
  `about` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `birthday` varchar(50) DEFAULT NULL,
  `gender` enum('woman','man') DEFAULT NULL,
  `interested` enum('women','men','everyone') DEFAULT NULL,
  `images` longtext DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table cfx_cs_v3.gksphone_flare_users: ~0 rows (approximately)

-- Dumping structure for table cfx_cs_v3.gksphone_gallery
CREATE TABLE IF NOT EXISTS `gksphone_gallery` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `phone_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '',
  `image` longtext NOT NULL,
  `favorite` tinyint(4) NOT NULL DEFAULT 0,
  `time` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`) USING BTREE,
  KEY `phone_id` (`phone_id`),
  CONSTRAINT `FK_gksphone_gallery_gksphone_esim` FOREIGN KEY (`phone_id`) REFERENCES `gksphone_esim` (`phone_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table cfx_cs_v3.gksphone_gallery: ~0 rows (approximately)

-- Dumping structure for table cfx_cs_v3.gksphone_gameleaderboard
CREATE TABLE IF NOT EXISTS `gksphone_gameleaderboard` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `tetris` int(11) NOT NULL DEFAULT 0,
  `snake` int(11) NOT NULL DEFAULT 0,
  `twenty` int(11) NOT NULL DEFAULT 0,
  `phone_id` varchar(500) NOT NULL,
  `name` varchar(500) NOT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `phone_id` (`phone_id`),
  CONSTRAINT `FK_gksphone_gameleaderboard_gksphone_esim` FOREIGN KEY (`phone_id`) REFERENCES `gksphone_esim` (`phone_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table cfx_cs_v3.gksphone_gameleaderboard: ~0 rows (approximately)

-- Dumping structure for table cfx_cs_v3.gksphone_gps
CREATE TABLE IF NOT EXISTS `gksphone_gps` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `citizenid` longtext NOT NULL,
  `gps_name` longtext NOT NULL,
  `gps_coord` longtext NOT NULL,
  `time` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `phone_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `phone_id` (`phone_id`),
  CONSTRAINT `FK_gksphone_gps_gksphone_esim` FOREIGN KEY (`phone_id`) REFERENCES `gksphone_esim` (`phone_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table cfx_cs_v3.gksphone_gps: ~0 rows (approximately)

-- Dumping structure for view cfx_cs_v3.gksphone_instagram_active_stories_v2
-- Creating temporary table to overcome VIEW dependency errors
CREATE TABLE `gksphone_instagram_active_stories_v2` (
	`story_id` BIGINT(20) NOT NULL,
	`user_id` BIGINT(20) NOT NULL,
	`media_url` VARCHAR(500) NOT NULL COLLATE 'utf8mb4_unicode_ci',
	`media_type` ENUM('image','video') NOT NULL COLLATE 'utf8mb4_unicode_ci',
	`created_at` TIMESTAMP NOT NULL,
	`expires_at` DATETIME NOT NULL,
	`username` VARCHAR(30) NOT NULL COLLATE 'utf8mb4_unicode_ci',
	`profile_picture_url` VARCHAR(500) NULL COLLATE 'utf8mb4_unicode_ci',
	`is_verified` TINYINT(1) NULL,
	`hours_ago` BIGINT(21) NULL,
	`minutes_ago` BIGINT(21) NULL
) ENGINE=MyISAM;

-- Dumping structure for table cfx_cs_v3.gksphone_instagram_comments
CREATE TABLE IF NOT EXISTS `gksphone_instagram_comments` (
  `comment_id` bigint(20) NOT NULL AUTO_INCREMENT,
  `post_id` bigint(20) NOT NULL,
  `user_id` bigint(20) NOT NULL,
  `parent_comment_id` bigint(20) DEFAULT NULL,
  `comment_text` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `likes_count` int(11) DEFAULT 0,
  `replies_count` int(11) DEFAULT 0,
  `is_pinned` tinyint(1) DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`comment_id`) USING BTREE,
  KEY `idx_post_id` (`post_id`) USING BTREE,
  KEY `idx_user_id` (`user_id`) USING BTREE,
  KEY `idx_parent_comment` (`parent_comment_id`) USING BTREE,
  KEY `idx_post_created` (`post_id`,`created_at`) USING BTREE,
  KEY `idx_is_pinned` (`is_pinned`) USING BTREE,
  KEY `idx_comments_parent_created` (`parent_comment_id`,`created_at`) USING BTREE,
  KEY `idx_comments_post_parent` (`post_id`,`parent_comment_id`) USING BTREE,
  KEY `idx_comments_parent_id` (`parent_comment_id`) USING BTREE,
  KEY `idx_comments_replies_count` (`replies_count`) USING BTREE,
  CONSTRAINT `gksphone_instagram_comments_ibfk_1` FOREIGN KEY (`post_id`) REFERENCES `gksphone_instagram_posts` (`post_id`) ON DELETE CASCADE,
  CONSTRAINT `gksphone_instagram_comments_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `gksphone_instagram_users` (`user_id`) ON DELETE CASCADE,
  CONSTRAINT `gksphone_instagram_comments_ibfk_3` FOREIGN KEY (`parent_comment_id`) REFERENCES `gksphone_instagram_comments` (`comment_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table cfx_cs_v3.gksphone_instagram_comments: ~0 rows (approximately)

-- Dumping structure for table cfx_cs_v3.gksphone_instagram_comment_likes
CREATE TABLE IF NOT EXISTS `gksphone_instagram_comment_likes` (
  `like_id` bigint(20) NOT NULL AUTO_INCREMENT,
  `comment_id` bigint(20) NOT NULL,
  `user_id` bigint(20) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`like_id`) USING BTREE,
  UNIQUE KEY `unique_comment_like` (`comment_id`,`user_id`) USING BTREE,
  KEY `idx_comment_id` (`comment_id`) USING BTREE,
  KEY `idx_user_id` (`user_id`) USING BTREE,
  CONSTRAINT `gksphone_instagram_comment_likes_ibfk_1` FOREIGN KEY (`comment_id`) REFERENCES `gksphone_instagram_comments` (`comment_id`) ON DELETE CASCADE,
  CONSTRAINT `gksphone_instagram_comment_likes_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `gksphone_instagram_users` (`user_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table cfx_cs_v3.gksphone_instagram_comment_likes: ~0 rows (approximately)

-- Dumping structure for table cfx_cs_v3.gksphone_instagram_conversations
CREATE TABLE IF NOT EXISTS `gksphone_instagram_conversations` (
  `conversation_id` bigint(20) NOT NULL AUTO_INCREMENT,
  `conversation_type` enum('direct') DEFAULT 'direct',
  `created_by` bigint(20) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`conversation_id`) USING BTREE,
  KEY `idx_created_by` (`created_by`) USING BTREE,
  KEY `idx_updated_at` (`updated_at`) USING BTREE,
  CONSTRAINT `gksphone_instagram_conversations_ibfk_1` FOREIGN KEY (`created_by`) REFERENCES `gksphone_instagram_users` (`user_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table cfx_cs_v3.gksphone_instagram_conversations: ~0 rows (approximately)

-- Dumping structure for view cfx_cs_v3.gksphone_instagram_conversations_v1
-- Creating temporary table to overcome VIEW dependency errors
CREATE TABLE `gksphone_instagram_conversations_v1` (
	`conversation_id` BIGINT(20) NOT NULL,
	`created_by` BIGINT(20) NULL,
	`updated_at` TIMESTAMP NOT NULL,
	`participant_id` BIGINT(20) NOT NULL,
	`other_user_id` BIGINT(20) NULL,
	`other_username` VARCHAR(30) NULL COLLATE 'utf8mb4_unicode_ci',
	`other_profile_picture` VARCHAR(500) NULL COLLATE 'utf8mb4_unicode_ci',
	`other_is_verified` TINYINT(1) NULL,
	`last_message` TEXT NULL COLLATE 'utf8mb4_unicode_ci',
	`last_message_type` ENUM('text','image','video','audio','post_share','profile_share') NULL COLLATE 'utf8mb4_unicode_ci',
	`last_message_time` TIMESTAMP NULL,
	`last_message_sender_id` BIGINT(20) NULL,
	`last_message_sender_username` VARCHAR(30) NULL COLLATE 'utf8mb4_unicode_ci',
	`unread_count` BIGINT(21) NOT NULL
) ENGINE=MyISAM;

-- Dumping structure for table cfx_cs_v3.gksphone_instagram_conversation_participants
CREATE TABLE IF NOT EXISTS `gksphone_instagram_conversation_participants` (
  `participant_id` bigint(20) NOT NULL AUTO_INCREMENT,
  `conversation_id` bigint(20) NOT NULL,
  `user_id` bigint(20) NOT NULL,
  `joined_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `messages_deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`participant_id`) USING BTREE,
  UNIQUE KEY `unique_participant` (`conversation_id`,`user_id`) USING BTREE,
  KEY `idx_conversation_id` (`conversation_id`) USING BTREE,
  KEY `idx_user_id` (`user_id`) USING BTREE,
  CONSTRAINT `gksphone_instagram_conversation_participants_ibfk_1` FOREIGN KEY (`conversation_id`) REFERENCES `gksphone_instagram_conversations` (`conversation_id`) ON DELETE CASCADE,
  CONSTRAINT `gksphone_instagram_conversation_participants_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `gksphone_instagram_users` (`user_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table cfx_cs_v3.gksphone_instagram_conversation_participants: ~0 rows (approximately)

-- Dumping structure for table cfx_cs_v3.gksphone_instagram_follows
CREATE TABLE IF NOT EXISTS `gksphone_instagram_follows` (
  `follow_id` bigint(20) NOT NULL AUTO_INCREMENT,
  `follower_id` bigint(20) NOT NULL,
  `following_id` bigint(20) NOT NULL,
  `is_accepted` tinyint(1) DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `requested_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `accepted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`follow_id`) USING BTREE,
  UNIQUE KEY `unique_follow` (`follower_id`,`following_id`) USING BTREE,
  KEY `idx_follower_id` (`follower_id`) USING BTREE,
  KEY `idx_following_id` (`following_id`) USING BTREE,
  KEY `idx_is_accepted` (`is_accepted`) USING BTREE,
  KEY `idx_created_at` (`created_at`) USING BTREE,
  KEY `idx_follows_status` (`is_accepted`,`created_at`) USING BTREE,
  CONSTRAINT `gksphone_instagram_follows_ibfk_1` FOREIGN KEY (`follower_id`) REFERENCES `gksphone_instagram_users` (`user_id`) ON DELETE CASCADE,
  CONSTRAINT `gksphone_instagram_follows_ibfk_2` FOREIGN KEY (`following_id`) REFERENCES `gksphone_instagram_users` (`user_id`) ON DELETE CASCADE,
  CONSTRAINT `CONSTRAINT_1` CHECK (`follower_id` <> `following_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table cfx_cs_v3.gksphone_instagram_follows: ~0 rows (approximately)

-- Dumping structure for table cfx_cs_v3.gksphone_instagram_messages
CREATE TABLE IF NOT EXISTS `gksphone_instagram_messages` (
  `message_id` bigint(20) NOT NULL AUTO_INCREMENT,
  `conversation_id` bigint(20) NOT NULL,
  `sender_id` bigint(20) NOT NULL,
  `message_text` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `message_type` enum('text','image','video','audio','post_share','profile_share') DEFAULT 'text',
  `is_read` tinyint(1) DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`message_id`) USING BTREE,
  KEY `idx_conversation_id` (`conversation_id`) USING BTREE,
  KEY `idx_sender_id` (`sender_id`) USING BTREE,
  KEY `idx_created_at` (`created_at`) USING BTREE,
  KEY `idx_conversation_created` (`conversation_id`,`created_at`) USING BTREE,
  CONSTRAINT `gksphone_instagram_messages_ibfk_1` FOREIGN KEY (`conversation_id`) REFERENCES `gksphone_instagram_conversations` (`conversation_id`) ON DELETE CASCADE,
  CONSTRAINT `gksphone_instagram_messages_ibfk_2` FOREIGN KEY (`sender_id`) REFERENCES `gksphone_instagram_users` (`user_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table cfx_cs_v3.gksphone_instagram_messages: ~0 rows (approximately)

-- Dumping structure for table cfx_cs_v3.gksphone_instagram_notifications
CREATE TABLE IF NOT EXISTS `gksphone_instagram_notifications` (
  `notification_id` bigint(20) NOT NULL AUTO_INCREMENT,
  `user_id` bigint(20) NOT NULL,
  `actor_id` bigint(20) NOT NULL,
  `notification_type` enum('like','comment','follow','mention','post_tag') NOT NULL,
  `post_id` bigint(20) DEFAULT NULL,
  `comment_id` bigint(20) DEFAULT NULL,
  `is_read` tinyint(1) DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`notification_id`) USING BTREE,
  KEY `post_id` (`post_id`) USING BTREE,
  KEY `comment_id` (`comment_id`) USING BTREE,
  KEY `idx_user_id` (`user_id`) USING BTREE,
  KEY `idx_actor_id` (`actor_id`) USING BTREE,
  KEY `idx_created_at` (`created_at`) USING BTREE,
  KEY `idx_is_read` (`is_read`) USING BTREE,
  KEY `idx_user_unread` (`user_id`,`is_read`,`created_at`) USING BTREE,
  CONSTRAINT `gksphone_instagram_notifications_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `gksphone_instagram_users` (`user_id`) ON DELETE CASCADE,
  CONSTRAINT `gksphone_instagram_notifications_ibfk_2` FOREIGN KEY (`actor_id`) REFERENCES `gksphone_instagram_users` (`user_id`) ON DELETE CASCADE,
  CONSTRAINT `gksphone_instagram_notifications_ibfk_3` FOREIGN KEY (`post_id`) REFERENCES `gksphone_instagram_posts` (`post_id`) ON DELETE CASCADE,
  CONSTRAINT `gksphone_instagram_notifications_ibfk_4` FOREIGN KEY (`comment_id`) REFERENCES `gksphone_instagram_comments` (`comment_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table cfx_cs_v3.gksphone_instagram_notifications: ~0 rows (approximately)

-- Dumping structure for table cfx_cs_v3.gksphone_instagram_posts
CREATE TABLE IF NOT EXISTS `gksphone_instagram_posts` (
  `post_id` bigint(20) NOT NULL AUTO_INCREMENT,
  `user_id` bigint(20) NOT NULL,
  `caption` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `location` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `media` longtext DEFAULT NULL,
  `likes_count` int(11) DEFAULT 0,
  `comments_count` int(11) DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`post_id`) USING BTREE,
  KEY `idx_user_id` (`user_id`) USING BTREE,
  KEY `idx_created_at` (`created_at`) USING BTREE,
  KEY `idx_user_created` (`user_id`,`created_at`) USING BTREE,
  CONSTRAINT `gksphone_instagram_posts_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `gksphone_instagram_users` (`user_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table cfx_cs_v3.gksphone_instagram_posts: ~0 rows (approximately)

-- Dumping structure for table cfx_cs_v3.gksphone_instagram_post_likes
CREATE TABLE IF NOT EXISTS `gksphone_instagram_post_likes` (
  `like_id` bigint(20) NOT NULL AUTO_INCREMENT,
  `post_id` bigint(20) NOT NULL,
  `user_id` bigint(20) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`like_id`) USING BTREE,
  UNIQUE KEY `unique_post_like` (`post_id`,`user_id`) USING BTREE,
  KEY `idx_post_id` (`post_id`) USING BTREE,
  KEY `idx_user_id` (`user_id`) USING BTREE,
  KEY `idx_created_at` (`created_at`) USING BTREE,
  CONSTRAINT `gksphone_instagram_post_likes_ibfk_1` FOREIGN KEY (`post_id`) REFERENCES `gksphone_instagram_posts` (`post_id`) ON DELETE CASCADE,
  CONSTRAINT `gksphone_instagram_post_likes_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `gksphone_instagram_users` (`user_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table cfx_cs_v3.gksphone_instagram_post_likes: ~0 rows (approximately)

-- Dumping structure for table cfx_cs_v3.gksphone_instagram_stories
CREATE TABLE IF NOT EXISTS `gksphone_instagram_stories` (
  `story_id` bigint(20) NOT NULL AUTO_INCREMENT,
  `user_id` bigint(20) NOT NULL,
  `media_url` varchar(500) NOT NULL,
  `media_type` enum('image','video') NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `expires_at` datetime NOT NULL,
  PRIMARY KEY (`story_id`) USING BTREE,
  KEY `idx_user_id` (`user_id`) USING BTREE,
  KEY `idx_created_at` (`created_at`) USING BTREE,
  KEY `idx_expires_at` (`expires_at`) USING BTREE,
  KEY `idx_user_created` (`user_id`,`created_at`) USING BTREE,
  CONSTRAINT `gksphone_instagram_stories_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `gksphone_instagram_users` (`user_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table cfx_cs_v3.gksphone_instagram_stories: ~0 rows (approximately)

-- Dumping structure for table cfx_cs_v3.gksphone_instagram_users
CREATE TABLE IF NOT EXISTS `gksphone_instagram_users` (
  `user_id` bigint(20) NOT NULL AUTO_INCREMENT,
  `identifier` mediumtext NOT NULL,
  `username` varchar(30) NOT NULL,
  `password` varchar(255) NOT NULL,
  `full_name` varchar(100) DEFAULT NULL,
  `bio` varchar(250) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `profile_picture_url` varchar(500) DEFAULT NULL,
  `is_verified` tinyint(1) DEFAULT 0,
  `is_private` tinyint(1) DEFAULT 0,
  `is_active` tinyint(1) DEFAULT 1,
  `followers_count` int(11) DEFAULT 0,
  `following_count` int(11) DEFAULT 0,
  `posts_count` int(11) DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`user_id`) USING BTREE,
  UNIQUE KEY `username` (`username`) USING BTREE,
  KEY `idx_username` (`username`) USING BTREE,
  KEY `idx_created_at` (`created_at`) USING BTREE,
  KEY `idx_is_active` (`is_active`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table cfx_cs_v3.gksphone_instagram_users: ~0 rows (approximately)

-- Dumping structure for table cfx_cs_v3.gksphone_mails
CREATE TABLE IF NOT EXISTS `gksphone_mails` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `citizenid` varchar(255) NOT NULL DEFAULT '0',
  `sender` varchar(255) NOT NULL DEFAULT '0',
  `subject` varchar(255) NOT NULL DEFAULT '0',
  `image` varchar(250) DEFAULT NULL,
  `message` text NOT NULL,
  `button` longtext DEFAULT NULL,
  `read_at` timestamp NULL DEFAULT NULL,
  `time` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table cfx_cs_v3.gksphone_mails: ~0 rows (approximately)

-- Dumping structure for table cfx_cs_v3.gksphone_messages
CREATE TABLE IF NOT EXISTS `gksphone_messages` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `sender` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `receiver` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `message` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `phone_id` varchar(50) NOT NULL DEFAULT '0',
  `read_at` timestamp NULL DEFAULT NULL,
  `sent_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `is_editable` tinyint(1) NOT NULL DEFAULT 0,
  `is_sender` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `phone_id` (`phone_id`),
  CONSTRAINT `FK_gksphone_messages_gksphone_esim` FOREIGN KEY (`phone_id`) REFERENCES `gksphone_esim` (`phone_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table cfx_cs_v3.gksphone_messages: ~0 rows (approximately)

-- Dumping structure for table cfx_cs_v3.gksphone_messages_groups
CREATE TABLE IF NOT EXISTS `gksphone_messages_groups` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `phone_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '',
  `phone_number` varchar(50) NOT NULL,
  `iscreator` tinyint(4) NOT NULL DEFAULT 0,
  `group_name` longtext NOT NULL,
  `group_about` longtext NOT NULL,
  `group_image` longtext NOT NULL,
  `admin_only_messages` tinyint(1) NOT NULL DEFAULT 0 COMMENT '0=Everyone can send, 1=Only admins can send',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`) USING BTREE,
  KEY `phone_id` (`phone_id`),
  CONSTRAINT `FK_gksphone_messages_group_gksphone_esim` FOREIGN KEY (`phone_id`) REFERENCES `gksphone_esim` (`phone_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table cfx_cs_v3.gksphone_messages_groups: ~0 rows (approximately)

-- Dumping structure for table cfx_cs_v3.gksphone_messages_groups_members
CREATE TABLE IF NOT EXISTS `gksphone_messages_groups_members` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `phone_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '',
  `group_id` int(11) NOT NULL,
  `phone_number` varchar(50) NOT NULL,
  `role` tinyint(4) DEFAULT 0 COMMENT '0=Member, 1=Admin, 2=Owner',
  `joined_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`) USING BTREE,
  KEY `phone_id` (`phone_id`) USING BTREE,
  KEY `group_id` (`group_id`) USING BTREE,
  CONSTRAINT `FK_gksphone_messages_groups_members_gksphone_messages_groups` FOREIGN KEY (`group_id`) REFERENCES `gksphone_messages_groups` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `gksphone_messages_groups_members_ibfk_1` FOREIGN KEY (`phone_id`) REFERENCES `gksphone_esim` (`phone_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;

-- Dumping data for table cfx_cs_v3.gksphone_messages_groups_members: ~0 rows (approximately)

-- Dumping structure for table cfx_cs_v3.gksphone_messages_groups_messages
CREATE TABLE IF NOT EXISTS `gksphone_messages_groups_messages` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `phone_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '',
  `group_id` int(11) NOT NULL,
  `message` text NOT NULL,
  `sender` varchar(50) NOT NULL,
  `sent_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `read_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`) USING BTREE,
  KEY `phone_id` (`phone_id`) USING BTREE,
  KEY `group_id` (`group_id`) USING BTREE,
  CONSTRAINT `gksphone_messages_groups_messages_ibfk_1` FOREIGN KEY (`group_id`) REFERENCES `gksphone_messages_groups` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `gksphone_messages_groups_messages_ibfk_2` FOREIGN KEY (`phone_id`) REFERENCES `gksphone_esim` (`phone_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;

-- Dumping data for table cfx_cs_v3.gksphone_messages_groups_messages: ~0 rows (approximately)

-- Dumping structure for table cfx_cs_v3.gksphone_music
CREATE TABLE IF NOT EXISTS `gksphone_music` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `playlist_name` longtext NOT NULL,
  `playlist_img` longtext NOT NULL,
  `details` longtext NOT NULL,
  `phone_id` varchar(50) NOT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `FK_gksphone_music_gksphone_esim` (`phone_id`) USING BTREE,
  CONSTRAINT `FK_gksphone_music_gksphone_esim` FOREIGN KEY (`phone_id`) REFERENCES `gksphone_esim` (`phone_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table cfx_cs_v3.gksphone_music: ~0 rows (approximately)

-- Dumping structure for table cfx_cs_v3.gksphone_music_like
CREATE TABLE IF NOT EXISTS `gksphone_music_like` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `phone_id` varchar(50) NOT NULL,
  `songid` varchar(50) NOT NULL,
  `title` varchar(250) NOT NULL,
  `artist` varchar(250) NOT NULL,
  `img` longtext NOT NULL,
  `seconds` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `FK__gksphone_esim` (`phone_id`) USING BTREE,
  CONSTRAINT `FK__gksphone_esim` FOREIGN KEY (`phone_id`) REFERENCES `gksphone_esim` (`phone_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table cfx_cs_v3.gksphone_music_like: ~0 rows (approximately)

-- Dumping structure for table cfx_cs_v3.gksphone_news
CREATE TABLE IF NOT EXISTS `gksphone_news` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `news_text` longtext NOT NULL,
  `news_title` longtext NOT NULL,
  `news_image` longtext DEFAULT NULL,
  `news_video` longtext DEFAULT NULL,
  `time` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table cfx_cs_v3.gksphone_news: ~0 rows (approximately)

-- Dumping structure for table cfx_cs_v3.gksphone_notes
CREATE TABLE IF NOT EXISTS `gksphone_notes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `phone_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '',
  `title` longtext NOT NULL,
  `image` longtext DEFAULT NULL,
  `note` longtext NOT NULL,
  `time` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`) USING BTREE,
  KEY `phone_id` (`phone_id`) USING BTREE,
  CONSTRAINT `gksphone_notes_ibfk_1` FOREIGN KEY (`phone_id`) REFERENCES `gksphone_esim` (`phone_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;

-- Dumping data for table cfx_cs_v3.gksphone_notes: ~0 rows (approximately)

-- Dumping structure for table cfx_cs_v3.gksphone_settings
CREATE TABLE IF NOT EXISTS `gksphone_settings` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `unique_id` varchar(50) NOT NULL DEFAULT '',
  `identifier` longtext NOT NULL,
  `setup_owner` longtext NOT NULL,
  `model_type` varchar(50) NOT NULL DEFAULT '0',
  `mail_address` longtext NOT NULL,
  `mail_password` longtext NOT NULL,
  `phone_lang` varchar(50) NOT NULL DEFAULT '0',
  `status` tinyint(4) NOT NULL DEFAULT 0,
  `setup_status` tinyint(4) NOT NULL DEFAULT 0,
  `phone_password` varchar(50) NOT NULL DEFAULT '0',
  `look_id` tinyint(4) NOT NULL DEFAULT 0,
  `security_question` varchar(50) NOT NULL DEFAULT '0',
  `security_answer` longtext NOT NULL,
  `phone_settings` longtext NOT NULL,
  `social_accounts` text NOT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `unique_id` (`unique_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table cfx_cs_v3.gksphone_settings: ~0 rows (approximately)

-- Dumping structure for table cfx_cs_v3.gksphone_stockmarket
CREATE TABLE IF NOT EXISTS `gksphone_stockmarket` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `phone_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `stock_market` longtext NOT NULL,
  `stock_histroy` longtext NOT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `phone_id` (`phone_id`),
  CONSTRAINT `gksphone_stockmarket_ibfk_1` FOREIGN KEY (`phone_id`) REFERENCES `gksphone_esim` (`phone_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;

-- Dumping data for table cfx_cs_v3.gksphone_stockmarket: ~0 rows (approximately)

-- Dumping structure for table cfx_cs_v3.gksphone_twt_followers
CREATE TABLE IF NOT EXISTS `gksphone_twt_followers` (
  `follow_id` int(11) NOT NULL AUTO_INCREMENT,
  `userid` int(11) NOT NULL,
  `followid` int(11) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`follow_id`) USING BTREE,
  KEY `userid` (`userid`) USING BTREE,
  KEY `FK_gksphone_twt_follower_gksphone_twt_users` (`followid`) USING BTREE,
  CONSTRAINT `FK_gksphone_twt_follower_gksphone_twt_users` FOREIGN KEY (`followid`) REFERENCES `gksphone_twt_users` (`user_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  CONSTRAINT `FK_gksphone_twt_followers_gksphone_twt_users` FOREIGN KEY (`userid`) REFERENCES `gksphone_twt_users` (`user_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table cfx_cs_v3.gksphone_twt_followers: ~0 rows (approximately)

-- Dumping structure for table cfx_cs_v3.gksphone_twt_hastags
CREATE TABLE IF NOT EXISTS `gksphone_twt_hastags` (
  `hastag_id` int(11) NOT NULL AUTO_INCREMENT,
  `hastag` varchar(250) NOT NULL DEFAULT '',
  `postid` int(11) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`hastag_id`) USING BTREE,
  KEY `postid` (`postid`) USING BTREE,
  CONSTRAINT `FK_gksphone_twt_hastags_gksphone_twt_posts` FOREIGN KEY (`postid`) REFERENCES `gksphone_twt_posts` (`post_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table cfx_cs_v3.gksphone_twt_hastags: ~0 rows (approximately)

-- Dumping structure for table cfx_cs_v3.gksphone_twt_likepost
CREATE TABLE IF NOT EXISTS `gksphone_twt_likepost` (
  `like_id` int(11) NOT NULL AUTO_INCREMENT,
  `postid` int(11) NOT NULL,
  `userid` int(11) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`like_id`) USING BTREE,
  KEY `userid` (`userid`) USING BTREE,
  KEY `postid` (`postid`) USING BTREE,
  CONSTRAINT `FK_gksphone_twt_likepost_gksphone_twt_posts` FOREIGN KEY (`postid`) REFERENCES `gksphone_twt_posts` (`post_id`) ON DELETE CASCADE,
  CONSTRAINT `FK_gksphone_twt_likepost_gksphone_twt_users` FOREIGN KEY (`userid`) REFERENCES `gksphone_twt_users` (`user_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table cfx_cs_v3.gksphone_twt_likepost: ~0 rows (approximately)

-- Dumping structure for table cfx_cs_v3.gksphone_twt_posts
CREATE TABLE IF NOT EXISTS `gksphone_twt_posts` (
  `post_id` int(11) NOT NULL AUTO_INCREMENT,
  `identifier` longtext NOT NULL,
  `user_id` int(11) DEFAULT NULL,
  `content` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `media` longtext DEFAULT NULL,
  `poll_options` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `end_date` timestamp NULL DEFAULT NULL,
  `comment` int(11) NOT NULL DEFAULT 0,
  `commentid` int(11) NOT NULL DEFAULT 0,
  `pinned` int(11) NOT NULL DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`post_id`) USING BTREE,
  KEY `user_id` (`user_id`) USING BTREE,
  CONSTRAINT `gksphone_twt_posts_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `gksphone_twt_users` (`user_id`) ON DELETE CASCADE,
  CONSTRAINT `poll_options` CHECK (json_valid(`poll_options`))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table cfx_cs_v3.gksphone_twt_posts: ~0 rows (approximately)

-- Dumping structure for table cfx_cs_v3.gksphone_twt_retweet
CREATE TABLE IF NOT EXISTS `gksphone_twt_retweet` (
  `retwettsid` int(11) NOT NULL AUTO_INCREMENT,
  `postid` int(11) NOT NULL,
  `userid` int(11) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`retwettsid`) USING BTREE,
  KEY `userid` (`userid`) USING BTREE,
  KEY `postid` (`postid`) USING BTREE,
  CONSTRAINT `FK_gksphone_twt_retweet_gksphone_twt_posts` FOREIGN KEY (`postid`) REFERENCES `gksphone_twt_posts` (`post_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  CONSTRAINT `FK_gksphone_twt_retweet_gksphone_twt_users` FOREIGN KEY (`userid`) REFERENCES `gksphone_twt_users` (`user_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table cfx_cs_v3.gksphone_twt_retweet: ~0 rows (approximately)

-- Dumping structure for table cfx_cs_v3.gksphone_twt_users
CREATE TABLE IF NOT EXISTS `gksphone_twt_users` (
  `user_id` int(11) NOT NULL AUTO_INCREMENT,
  `identifier` longtext NOT NULL,
  `username` varchar(255) NOT NULL,
  `password` varchar(255) NOT NULL,
  `displayname` varchar(255) NOT NULL,
  `avatar` varchar(255) DEFAULT NULL,
  `banner` varchar(255) DEFAULT NULL,
  `is_verified` int(11) NOT NULL DEFAULT 0,
  `verifedbuytime` timestamp NULL DEFAULT current_timestamp(),
  `banned` int(11) NOT NULL DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`user_id`) USING BTREE,
  UNIQUE KEY `unique_username` (`username`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table cfx_cs_v3.gksphone_twt_users: ~0 rows (approximately)

-- Dumping structure for table cfx_cs_v3.gksphone_vehicle_sales
CREATE TABLE IF NOT EXISTS `gksphone_vehicle_sales` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `identifier` longtext NOT NULL,
  `player_name` varchar(50) NOT NULL,
  `phone_number` varchar(255) NOT NULL,
  `plate` varchar(255) NOT NULL,
  `model` varchar(255) NOT NULL,
  `price` int(11) NOT NULL,
  `image` longtext NOT NULL,
  `time` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table cfx_cs_v3.gksphone_vehicle_sales: ~0 rows (approximately)

-- Dumping structure for table cfx_cs_v3.gksphone_wanted
CREATE TABLE IF NOT EXISTS `gksphone_wanted` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `citizenid` varchar(50) NOT NULL,
  `fullname` varchar(50) NOT NULL,
  `reason` varchar(250) DEFAULT NULL,
  `appearance` varchar(250) DEFAULT NULL,
  `lastseen` varchar(250) DEFAULT NULL,
  `time` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table cfx_cs_v3.gksphone_wanted: ~0 rows (approximately)

-- Dumping structure for table cfx_cs_v3.items
CREATE TABLE IF NOT EXISTS `items` (
  `name` varchar(50) NOT NULL,
  `label` varchar(50) NOT NULL,
  `weight` int(11) NOT NULL DEFAULT 1,
  `rare` tinyint(4) NOT NULL DEFAULT 0,
  `can_remove` tinyint(4) NOT NULL DEFAULT 1,
  PRIMARY KEY (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table cfx_cs_v3.items: ~0 rows (approximately)

-- Dumping structure for table cfx_cs_v3.jobs
CREATE TABLE IF NOT EXISTS `jobs` (
  `name` varchar(50) NOT NULL,
  `label` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table cfx_cs_v3.jobs: ~38 rows (approximately)
INSERT INTO `jobs` (`name`, `label`) VALUES
	('ambulance', 'EMS'),
	('bahamas', 'Bahamas'),
	('beanmachine', 'Bean Machine'),
	('burgershot', 'Burgershot'),
	('government', 'Government'),
	('mechanic', 'Mechanic'),
	('offambulance', 'Off-Duty'),
	('offbahamas', 'Off-Duty'),
	('offbeanmachine', 'Off-Duty'),
	('offburgershot', 'Off-Duty'),
	('offmechanic', 'Off-Duty'),
	('offparesan', 'Off-Duty'),
	('offpharmacy', 'Off-Duty'),
	('offpolice', 'Off-Duty'),
	('offpops', 'Off-Duty'),
	('offravens', 'Off-Duty'),
	('offsalon', 'Off-Duty'),
	('offsambulance', 'Off-Duty'),
	('offsheriff', 'Off-Duty'),
	('offtaco', 'Off-Duty'),
	('offtattoo1', 'Off-Duty'),
	('offuwu', 'Off-Duty'),
	('offvu', 'Off-Duty'),
	('offyoutool', 'Off-Duty'),
	('paresan', 'Paresan'),
	('pharmacy', 'Pharmacy'),
	('police', 'Police'),
	('pops', 'Pop\'s Diner'),
	('ravens', 'Ravens'),
	('salon', 'Burst Fade Salon'),
	('sambulance', 'Sandy EMS'),
	('sheriff', 'Sheriff'),
	('taco', 'Tacoshop'),
	('tattoo1', 'TS Tattooshop'),
	('unemployed', 'Unemployed'),
	('uwu', 'Uwu Cafe'),
	('vu', 'Vanilla Unicorn'),
	('youtool', 'Youtool');

-- Dumping structure for table cfx_cs_v3.job_grades
CREATE TABLE IF NOT EXISTS `job_grades` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `job_name` varchar(50) DEFAULT NULL,
  `grade` int(11) NOT NULL,
  `name` varchar(50) NOT NULL,
  `label` varchar(50) NOT NULL,
  `salary` int(11) NOT NULL,
  `skin_male` longtext NOT NULL,
  `skin_female` longtext NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=987 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table cfx_cs_v3.job_grades: ~188 rows (approximately)
INSERT INTO `job_grades` (`id`, `job_name`, `grade`, `name`, `label`, `salary`, `skin_male`, `skin_female`) VALUES
	(1, 'unemployed', 0, 'unemployed', 'Civilian', 10, '{}', '{}'),
	(248, 'uwu', 0, 'uwu1', 'Employee', 100, '{}', '{}'),
	(249, 'offuwu', 0, 'uwu1', 'Employee', 0, '{}', '{}'),
	(250, 'uwu', 1, 'uwu2', 'Manager', 100, '{}', '{}'),
	(251, 'offuwu', 1, 'uwu2', 'Manager', 0, '{}', '{}'),
	(252, 'uwu', 2, 'boss', 'Owner', 100, '{}', '{}'),
	(253, 'offuwu', 2, 'boss', 'Owner', 0, '{}', '{}'),
	(266, 'offravens', 0, 'ravens1', 'Employee', 0, '{}', '{}'),
	(267, 'ravens', 0, 'ravens1', 'Employee', 0, '{}', '{}'),
	(268, 'offravens', 1, 'ravens2', 'Manager', 0, '{}', '{}'),
	(269, 'ravens', 1, 'ravens2', 'Manager', 0, '{}', '{}'),
	(270, 'offravens', 2, 'boss', 'Owner', 0, '{}', '{}'),
	(271, 'ravens', 2, 'boss', 'Owner', 0, '{}', '{}'),
	(278, 'sheriff', 0, 'sheriff1', 'Sheriff Recruit / Cadet', 200, '{}', '{}'),
	(279, 'sheriff', 1, 'sheriff2', 'Senior Officer', 200, '{}', '{}'),
	(280, 'sheriff', 2, 'sheriff3', 'Patrol Officer', 200, '{}', '{}'),
	(281, 'sheriff', 3, 'sheriff4', 'Sergeant', 200, '{}', '{}'),
	(282, 'sheriff', 4, 'sheriff5', 'Corporal', 200, '{}', '{}'),
	(283, 'sheriff', 5, 'sheriff6', 'Lieutenant', 200, '{}', '{}'),
	(284, 'sheriff', 6, 'sheriff7', 'Captain', 200, '{}', '{}'),
	(285, 'sheriff', 7, 'sheriff8', 'Deputy Chief / Assistant Chief', 200, '{}', '{}'),
	(287, 'offsheriff', 0, 'sheriff1', 'Sheriff Recruit / Cadet', 0, '{}', '{}'),
	(288, 'offsheriff', 1, 'sheriff2', 'Senior Officer', 0, '{}', '{}'),
	(289, 'offsheriff', 2, 'sheriff3', 'Patrol Officer', 0, '{}', '{}'),
	(290, 'offsheriff', 3, 'sheriff4', 'Sergeant', 0, '{}', '{}'),
	(291, 'offsheriff', 4, 'sheriff5', 'Corporal', 0, '{}', '{}'),
	(292, 'offsheriff', 5, 'sheriff6', 'Lieutenant', 0, '{}', '{}'),
	(293, 'offsheriff', 6, 'sheriff7', 'Captain', 0, '{}', '{}'),
	(294, 'offsheriff', 7, 'sheriff8', 'Deputy Chief / Assistant Chief', 0, '{}', '{}'),
	(324, 'sambulance', 0, 'ems1', 'TRAINEE', 200, '{}', '{}'),
	(325, 'sambulance', 1, 'ems2', 'EMT', 200, '{}', '{}'),
	(326, 'sambulance', 2, 'ems3', 'Paramedic', 200, '{}', '{}'),
	(327, 'sambulance', 3, 'ems4', 'Nurse', 200, '{}', '{}'),
	(328, 'sambulance', 4, 'ems5', 'Head Nurse', 200, '{}', '{}'),
	(329, 'sambulance', 5, 'ems6', 'Intern Doctor', 200, '{}', '{}'),
	(330, 'sambulance', 6, 'ems7', 'Senior Residents', 200, '{}', '{}'),
	(331, 'sambulance', 7, 'ems8', 'HR', 200, '{}', '{}'),
	(332, 'sambulance', 8, 'ems9', 'Assistant Director', 200, '{}', '{}'),
	(333, 'sambulance', 9, 'boss', 'Medical Director', 200, '{}', '{}'),
	(334, 'offsambulance', 0, 'ems1', 'TRAINEE', 0, '{}', '{}'),
	(335, 'offsambulance', 1, 'ems2', 'EMT', 0, '{}', '{}'),
	(336, 'offsambulance', 2, 'ems3', 'Paramedic', 0, '{}', '{}'),
	(337, 'offsambulance', 3, 'ems4', 'Nurse', 0, '{}', '{}'),
	(338, 'offsambulance', 4, 'ems5', 'Head Nurse', 0, '{}', '{}'),
	(339, 'offsambulance', 5, 'ems6', 'Intern Doctor', 0, '{}', '{}'),
	(340, 'offsambulance', 6, 'ems7', 'Senior Residents', 0, '{}', '{}'),
	(341, 'offsambulance', 7, 'ems8', 'HR', 0, '{}', '{}'),
	(342, 'offsambulance', 8, 'ems9', 'Assistant Director', 0, '{}', '{}'),
	(343, 'offsambulance', 9, 'boss', 'Medical Director', 0, '{}', '{}'),
	(350, 'pops', 0, 'pops1', 'Employee', 0, '{}', '{}'),
	(351, 'offpops', 0, 'pops1', 'Employee', 0, '{}', '{}'),
	(352, 'offpops', 1, 'pops2', 'Manager', 0, '{}', '{}'),
	(353, 'pops', 1, 'pops2', 'Manager', 0, '{}', '{}'),
	(354, 'pops', 2, 'boss', 'Owner', 0, '{}', '{}'),
	(355, 'offpops', 2, 'boss', 'Owner', 0, '{}', '{}'),
	(356, 'ambulance', 0, 'ambulance1', 'Paramedic', 100, '{}', '{}'),
	(357, 'ambulance', 1, 'ambulance2', 'Nurse', 100, '{}', '{}'),
	(358, 'ambulance', 2, 'ambulance3', 'Head Nurse', 100, '{}', '{}'),
	(359, 'ambulance', 3, 'ambulance4', 'Junior Resident', 100, '{}', '{}'),
	(360, 'ambulance', 4, 'ambulance5', 'Senior Resident', 100, '{}', '{}'),
	(361, 'ambulance', 5, 'ambulance6', 'Chief Resident', 100, '{}', '{}'),
	(362, 'ambulance', 6, 'ambulance7', 'Fellow', 100, '{}', '{}'),
	(363, 'ambulance', 7, 'ambulance8', 'Surgeon', 100, '{}', '{}'),
	(364, 'ambulance', 8, 'ambulance9', 'Attending', 100, '{}', '{}'),
	(365, 'ambulance', 9, 'ambulance10', 'Head Doctor', 100, '{}', '{}'),
	(366, 'ambulance', 10, 'ambulance11', 'Human Resource', 100, '{}', '{}'),
	(367, 'ambulance', 11, 'ambulance12', 'Assistant Director', 100, '{}', '{}'),
	(368, 'ambulance', 12, 'boss', 'Medical Director', 100, '{}', '{}'),
	(369, 'police', 0, 'police1', 'Probationary', 100, '{}', '{}'),
	(370, 'police', 1, 'police2', 'Officer I', 100, '{}', '{}'),
	(371, 'police', 2, 'police3', 'Officer II', 100, '{}', '{}'),
	(372, 'police', 3, 'police4', 'Officer III', 100, '{}', '{}'),
	(373, 'police', 4, 'police5', 'Sergeant', 100, '{}', '{}'),
	(374, 'police', 5, 'police6', 'Lieutenant I', 100, '{}', '{}'),
	(375, 'police', 6, 'police7', 'Lieutenant II', 100, '{}', '{}'),
	(376, 'police', 7, 'police8', 'Captain', 100, '{}', '{}'),
	(377, 'police', 8, 'police9', 'Major', 100, '{}', '{}'),
	(378, 'police', 9, 'police10', 'Colonel', 100, '{}', '{}'),
	(379, 'police', 10, 'police11', 'Chief of Police', 100, '{}', '{}'),
	(380, 'police', 11, 'police12', 'Lieutenant General', 100, '{}', '{}'),
	(381, 'police', 12, 'boss', 'Police General', 100, '{}', '{}'),
	(382, 'offambulance', 0, 'ambulance1', 'Paramedic', 0, '{}', '{}'),
	(383, 'offambulance', 1, 'ambulance2', 'Nurse', 0, '{}', '{}'),
	(384, 'offambulance', 2, 'ambulance3', 'Head Nurse', 0, '{}', '{}'),
	(385, 'offambulance', 3, 'ambulance4', 'Junior Resident', 0, '{}', '{}'),
	(386, 'offambulance', 4, 'ambulance5', 'Senior Resident', 0, '{}', '{}'),
	(387, 'offambulance', 5, 'ambulance6', 'Chief Resident', 0, '{}', '{}'),
	(388, 'offambulance', 6, 'ambulance7', 'Fellow', 0, '{}', '{}'),
	(389, 'offambulance', 7, 'ambulance8', 'Surgeon', 0, '{}', '{}'),
	(390, 'offambulance', 8, 'ambulance9', 'Attending', 0, '{}', '{}'),
	(391, 'offambulance', 9, 'ambulance10', 'Head Doctor', 0, '{}', '{}'),
	(392, 'offambulance', 10, 'ambulance11', 'Human Resource', 0, '{}', '{}'),
	(393, 'offambulance', 11, 'ambulance12', 'Assistant Director', 0, '{}', '{}'),
	(394, 'offambulance', 12, 'boss', 'Medical Director', 0, '{}', '{}'),
	(395, 'offpolice', 0, 'police1', 'Probationary', 0, '{}', '{}'),
	(396, 'offpolice', 1, 'police2', 'Officer I', 0, '{}', '{}'),
	(397, 'offpolice', 2, 'police3', 'Officer II', 0, '{}', '{}'),
	(398, 'offpolice', 3, 'police4', 'Officer III', 0, '{}', '{}'),
	(399, 'offpolice', 4, 'police5', 'Sergeant', 0, '{}', '{}'),
	(400, 'offpolice', 5, 'police6', 'Lieutenant I', 0, '{}', '{}'),
	(401, 'offpolice', 6, 'police7', 'Lieutenant II', 0, '{}', '{}'),
	(402, 'offpolice', 7, 'police8', 'Captain', 0, '{}', '{}'),
	(403, 'offpolice', 8, 'police9', 'Major', 0, '{}', '{}'),
	(404, 'offpolice', 9, 'police10', 'Colonel', 0, '{}', '{}'),
	(405, 'offpolice', 10, 'police11', 'Chief of Police', 0, '{}', '{}'),
	(406, 'offpolice', 11, 'police12', 'Lieutenant General', 0, '{}', '{}'),
	(407, 'offpolice', 12, 'boss', 'Police General', 0, '{}', '{}'),
	(408, 'mechanic', 0, 'mechanic1', 'Entry-Level Technician', 100, '{}', '{}'),
	(409, 'mechanic', 1, 'mechanic2', 'Specialized Technician', 100, '{}', '{}'),
	(410, 'mechanic', 2, 'mechanic3', 'Master Technician', 100, '{}', '{}'),
	(411, 'mechanic', 3, 'mechanic4', 'Service Manager', 100, '{}', '{}'),
	(412, 'mechanic', 4, 'mechanic5', 'Asst. Boss Mech', 100, '{}', '{}'),
	(413, 'mechanic', 5, 'boss', 'Boss Mech', 100, '{}', '{}'),
	(414, 'offmechanic', 0, 'mechanic1', 'Entry-Level Technician', 0, '{}', '{}'),
	(415, 'offmechanic', 1, 'mechanic2', 'Specialized Technician', 0, '{}', '{}'),
	(416, 'offmechanic', 2, 'mechanic3', 'Master Technician', 0, '{}', '{}'),
	(417, 'offmechanic', 3, 'mechanic4', 'Service Manager', 0, '{}', '{}'),
	(418, 'offmechanic', 4, 'mechanic5', 'Asst. Boss Mech', 0, '{}', '{}'),
	(419, 'offmechanic', 5, 'boss', 'Boss Mech', 0, '{}', '{}'),
	(420, 'government', 0, 'boss', 'Tax Collector', 0, '{}', '{}'),
	(421, 'pharmacy', 0, 'pharmacy1', 'Employee', 100, '{}', '{}'),
	(422, 'pharmacy', 1, 'pharmacy2', 'Manager', 100, '{}', '{}'),
	(423, 'pharmacy', 2, 'boss', 'Owner', 100, '{}', '{}'),
	(424, 'offpharmacy', 0, 'pharmacy1', 'Employee', 0, '{}', '{}'),
	(425, 'offpharmacy', 1, 'pharmacy2', 'Manager', 0, '{}', '{}'),
	(426, 'offpharmacy', 2, 'boss', 'Owner', 0, '{}', '{}'),
	(427, 'vu', 0, 'vanilla1', 'Bouncer', 100, '{}', '{}'),
	(428, 'vu', 1, 'vanilla2', 'Bartender', 100, '{}', '{}'),
	(429, 'vu', 2, 'vanilla3', 'Stripper', 100, '{}', '{}'),
	(430, 'vu', 3, 'vanilla4', 'Manager', 100, '{}', '{}'),
	(431, 'vu', 4, 'boss', 'Owner', 100, '{}', '{}'),
	(432, 'offvu', 0, 'vanilla1', 'Bouncer', 0, '{}', '{}'),
	(433, 'offvu', 1, 'vanilla2', 'Bartender', 0, '{}', '{}'),
	(434, 'offvu', 2, 'vanilla2', 'Stripper', 0, '{}', '{}'),
	(435, 'offvu', 3, 'vanilla2', 'Manager', 0, '{}', '{}'),
	(436, 'offvu', 4, 'boss', 'Owner', 0, '{}', '{}'),
	(437, 'bahamas', 0, 'bahamas1', 'Bouncer', 100, '{}', '{}'),
	(438, 'offbahamas', 0, 'bahamas1', 'Bouncer', 0, '{}', '{}'),
	(439, 'bahamas', 1, 'bahamas2', 'Bartender', 100, '{}', '{}'),
	(440, 'offbahamas', 1, 'bahamas2', 'Bartender', 0, '{}', '{}'),
	(441, 'bahamas', 2, 'bahamas3', 'Stripper', 100, '{}', '{}'),
	(442, 'offbahamas', 2, 'bahamas3', 'Stripper', 0, '{}', '{}'),
	(443, 'bahamas', 3, 'bahamas4', 'Manager', 100, '{}', '{}'),
	(444, 'offbahamas', 3, 'bahamas4', 'Manager', 0, '{}', '{}'),
	(445, 'bahamas', 4, 'boss', 'Owner', 100, '{}', '{}'),
	(446, 'offbahamas', 4, 'boss', 'Owner', 0, '{}', '{}'),
	(453, 'paresan', 0, 'paresan1', 'Employee', 100, '{}', '{}'),
	(454, 'offparesan', 0, 'paresan1', 'Employee', 0, '{}', '{}'),
	(455, 'paresan', 1, 'paresan2', 'Manager', 100, '{}', '{}'),
	(456, 'offparesan', 1, 'paresan2', 'Manager', 0, '{}', '{}'),
	(457, 'paresan', 2, 'boss', 'Owner', 100, '{}', '{}'),
	(458, 'offparesan', 2, 'boss', 'Owner', 0, '{}', '{}'),
	(951, 'youtool', 0, 'youtool1', 'Employee', 100, '{}', '{}'),
	(952, 'offyoutool', 0, 'youtool1', 'Employee', 0, '{}', '{}'),
	(953, 'offyoutool', 1, 'youtool2', 'Manager', 0, '{}', '{}'),
	(954, 'youtool', 1, 'youtool2', 'Manager', 100, '{}', '{}'),
	(955, 'beanmachine', 0, 'beanmachine1', 'Employee', 10, '{}', '{}'),
	(956, 'offbeanmachine', 0, 'beanmachine1', 'Employee', 0, '{}', '{}'),
	(957, 'offyoutool', 2, 'boss', 'Owner', 0, '{}', '{}'),
	(958, 'offtattoo1', 0, 'tattoo11', 'Employee', 0, '{}', '{}'),
	(959, 'tattoo1', 0, 'tattoo11', 'Employee', 10, '{}', '{}'),
	(960, 'youtool', 2, 'boss', 'Owner', 100, '{}', '{}'),
	(961, 'beanmachine', 1, 'boss', 'Manager', 15, '{}', '{}'),
	(962, 'salon', 0, 'salon1', 'Employee', 10, '{}', '{}'),
	(963, 'offbeanmachine', 1, 'boss', 'Manager', 0, '{}', '{}'),
	(964, 'offtattoo1', 1, 'tattoo12', 'Manager', 0, '{}', '{}'),
	(965, 'offsalon', 0, 'salon1', 'Employee', 0, '{}', '{}'),
	(966, 'tattoo1', 1, 'tattoo12', 'Manager', 15, '{}', '{}'),
	(967, 'salon', 1, 'salon2', 'Manager', 15, '{}', '{}'),
	(968, 'beanmachine', 2, 'boss', 'Owner', 20, '{}', '{}'),
	(969, 'offbeanmachine', 2, 'boss', 'Owner', 0, '{}', '{}'),
	(970, 'taco', 0, 'taco1', 'Employee', 10, '{}', '{}'),
	(971, 'offsalon', 1, 'salon2', 'Manager', 0, '{}', '{}'),
	(972, 'offtattoo1', 2, 'boss', 'Owner', 0, '{}', '{}'),
	(973, 'offtaco', 0, 'taco1', 'Employee', 0, '{}', '{}'),
	(974, 'tattoo1', 2, 'boss', 'Owner', 20, '{}', '{}'),
	(975, 'salon', 2, 'boss', 'Owner', 20, '{}', '{}'),
	(976, 'taco', 1, 'boss', 'Manager', 15, '{}', '{}'),
	(977, 'offsalon', 2, 'boss', 'Owner', 0, '{}', '{}'),
	(978, 'offtaco', 1, 'boss', 'Manager', 0, '{}', '{}'),
	(979, 'taco', 2, 'boss', 'Owner', 20, '{}', '{}'),
	(980, 'offtaco', 2, 'boss', 'Owner', 0, '{}', '{}'),
	(981, 'burgershot', 0, 'burgershot1', 'Employee', 10, '{}', '{}'),
	(982, 'offburgershot', 0, 'burgershot1', 'Employee', 0, '{}', '{}'),
	(983, 'burgershot', 1, 'boss', 'Manager', 15, '{}', '{}'),
	(984, 'offburgershot', 1, 'boss', 'Manager', 0, '{}', '{}'),
	(985, 'burgershot', 2, 'boss', 'Owner', 20, '{}', '{}'),
	(986, 'offburgershot', 2, 'boss', 'Owner', 0, '{}', '{}');

-- Dumping structure for table cfx_cs_v3.mechanic_data
CREATE TABLE IF NOT EXISTS `mechanic_data` (
  `name` varchar(100) NOT NULL,
  `label` varchar(255) NOT NULL,
  `balance` float NOT NULL DEFAULT 0,
  `owner_id` varchar(255) DEFAULT NULL,
  `owner_name` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table cfx_cs_v3.mechanic_data: ~2 rows (approximately)
INSERT INTO `mechanic_data` (`name`, `label`, `balance`, `owner_id`, `owner_name`) VALUES
	('bennys', '', 0, NULL, NULL),
	('lscustoms', '', 0, NULL, NULL);

-- Dumping structure for table cfx_cs_v3.mechanic_employees
CREATE TABLE IF NOT EXISTS `mechanic_employees` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `identifier` varchar(255) NOT NULL,
  `mechanic` varchar(255) NOT NULL,
  `role` varchar(100) NOT NULL,
  `joined` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table cfx_cs_v3.mechanic_employees: ~0 rows (approximately)

-- Dumping structure for table cfx_cs_v3.mechanic_invoices
CREATE TABLE IF NOT EXISTS `mechanic_invoices` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `identifier` varchar(255) DEFAULT NULL,
  `mechanic` varchar(255) NOT NULL,
  `total` float NOT NULL,
  `data` text NOT NULL,
  `paid` tinyint(1) DEFAULT 0,
  `date` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table cfx_cs_v3.mechanic_invoices: ~0 rows (approximately)

-- Dumping structure for table cfx_cs_v3.mechanic_orders
CREATE TABLE IF NOT EXISTS `mechanic_orders` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `identifier` varchar(255) NOT NULL,
  `mechanic` varchar(255) NOT NULL,
  `plate` varchar(10) NOT NULL,
  `amount_paid` float NOT NULL DEFAULT 0,
  `cart` text NOT NULL,
  `props_to_apply` text NOT NULL,
  `installation_progress` text DEFAULT NULL,
  `fulfilled` tinyint(1) DEFAULT 0,
  `date` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table cfx_cs_v3.mechanic_orders: ~0 rows (approximately)

-- Dumping structure for table cfx_cs_v3.mechanic_servicing_history
CREATE TABLE IF NOT EXISTS `mechanic_servicing_history` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `identifier` varchar(255) NOT NULL,
  `mechanic` varchar(255) NOT NULL,
  `plate` varchar(10) NOT NULL,
  `serviced_part` varchar(10) NOT NULL,
  `mileage_km` float NOT NULL DEFAULT 0,
  `date` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table cfx_cs_v3.mechanic_servicing_history: ~0 rows (approximately)

-- Dumping structure for table cfx_cs_v3.mechanic_settings
CREATE TABLE IF NOT EXISTS `mechanic_settings` (
  `identifier` varchar(255) NOT NULL,
  `preferences` text DEFAULT NULL,
  PRIMARY KEY (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table cfx_cs_v3.mechanic_settings: ~0 rows (approximately)

-- Dumping structure for table cfx_cs_v3.mechanic_vehicledata
CREATE TABLE IF NOT EXISTS `mechanic_vehicledata` (
  `plate` varchar(10) NOT NULL,
  `data` text NOT NULL,
  PRIMARY KEY (`plate`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table cfx_cs_v3.mechanic_vehicledata: ~0 rows (approximately)

-- Dumping structure for table cfx_cs_v3.owned_vehicles
CREATE TABLE IF NOT EXISTS `owned_vehicles` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `owner` varchar(46) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `plate` varchar(12) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `vehicle` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `type` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'automobile',
  `job` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `stored` tinyint(4) NOT NULL DEFAULT 0,
  `parking` varchar(60) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `pound` varchar(60) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `mileage` int(11) DEFAULT 0,
  `metadata` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT '{"keys":{}}',
  `glovebox` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `trunk` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `carseller` int(11) DEFAULT 0,
  `private` tinyint(1) DEFAULT 0,
  `name` varchar(40) DEFAULT 'Unknown',
  `financed` tinyint(1) NOT NULL DEFAULT 0,
  `finance_data` longtext DEFAULT NULL,
  `in_garage` tinyint(1) DEFAULT 0,
  `garage_id` varchar(50) DEFAULT 'Legion Square',
  `garage_type` varchar(50) DEFAULT 'car',
  `job_personalowned` varchar(50) DEFAULT '',
  `property` int(10) DEFAULT 0,
  `impound` int(10) DEFAULT 0,
  `impound_data` longtext DEFAULT '',
  `adv_stats` longtext DEFAULT '{"plate":"nil","mileage":0.0,"maxhealth":1000.0}',
  `fuel` int(10) DEFAULT 100,
  `engine` int(10) DEFAULT 1000,
  `body` int(10) DEFAULT 1000,
  `damage` longtext DEFAULT '',
  `job_vehicle` tinyint(1) DEFAULT 0,
  `job_vehicle_rank` int(10) DEFAULT 0,
  `gang_vehicle` tinyint(1) DEFAULT 0,
  `gang_vehicle_rank` int(10) DEFAULT 0,
  `impound_retrievable` int(10) DEFAULT 0,
  `nickname` varchar(255) DEFAULT '',
  `gang` varchar(100) DEFAULT NULL,
  `configName` varchar(100) DEFAULT NULL,
  `vehicleid` int(11) DEFAULT NULL,
  `vehicletv` tinyint(1) DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_plate` (`plate`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table cfx_cs_v3.owned_vehicles: ~0 rows (approximately)

-- Dumping structure for table cfx_cs_v3.ox_doorlock
CREATE TABLE IF NOT EXISTS `ox_doorlock` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(50) NOT NULL,
  `data` longtext NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table cfx_cs_v3.ox_doorlock: ~0 rows (approximately)

-- Dumping structure for table cfx_cs_v3.ox_inventory
CREATE TABLE IF NOT EXISTS `ox_inventory` (
  `owner` varchar(60) DEFAULT NULL,
  `name` varchar(100) NOT NULL,
  `data` longtext DEFAULT NULL,
  `lastupdated` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  UNIQUE KEY `owner` (`owner`,`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table cfx_cs_v3.ox_inventory: ~1 rows (approximately)
INSERT INTO `ox_inventory` (`owner`, `name`, `data`, `lastupdated`) VALUES
	('', 'g1_boss_stash', '[{"slot":1,"count":50,"name":"ammo-box3"},{"slot":2,"count":100,"name":"at_clip_extended_rifle"},{"slot":3,"count":100,"name":"pendrive"},{"slot":4,"count":1,"name":"WEAPON_PISTOL","metadata":{"components":[],"ammo":0,"serial":"744205EYJ836345","durability":100}},{"slot":5,"count":1,"name":"WEAPON_PISTOL","metadata":{"components":[],"ammo":0,"serial":"481853QGH581150","durability":100}},{"slot":6,"count":1,"name":"WEAPON_PISTOL","metadata":{"components":[],"ammo":0,"serial":"506307TVR307986","durability":100}},{"slot":7,"count":1,"name":"WEAPON_PISTOL","metadata":{"components":[],"ammo":0,"serial":"894120OIV108123","durability":100}},{"slot":8,"count":1,"name":"WEAPON_PISTOL","metadata":{"components":[],"ammo":0,"serial":"494674RLT394334","durability":100}},{"slot":9,"count":1,"name":"WEAPON_PISTOL","metadata":{"components":[],"ammo":0,"serial":"301796JZB896096","durability":100}},{"slot":10,"count":1,"name":"WEAPON_PISTOL","metadata":{"components":[],"ammo":0,"serial":"215277VCW208772","durability":100}},{"slot":11,"count":1,"name":"WEAPON_PISTOL","metadata":{"components":[],"ammo":0,"serial":"862956PQG623602","durability":100}},{"slot":12,"count":1,"name":"WEAPON_PISTOL","metadata":{"components":[],"ammo":0,"serial":"822032VRS373770","durability":100}},{"slot":13,"count":1,"name":"WEAPON_PISTOL","metadata":{"components":[],"ammo":0,"serial":"110738BAJ316619","durability":100}},{"slot":14,"count":1,"name":"WEAPON_PISTOL","metadata":{"components":[],"ammo":0,"serial":"194834ZQI906964","durability":100}},{"slot":15,"count":1,"name":"WEAPON_PISTOL","metadata":{"components":[],"ammo":0,"serial":"333342WHA314076","durability":100}},{"slot":16,"count":1,"name":"WEAPON_PISTOL","metadata":{"components":[],"ammo":0,"serial":"392920MJF614920","durability":100}},{"slot":17,"count":1,"name":"WEAPON_PISTOL","metadata":{"components":[],"ammo":0,"serial":"313141EOF707657","durability":100}},{"slot":18,"count":1,"name":"WEAPON_PISTOL","metadata":{"components":[],"ammo":0,"serial":"932667TWT472348","durability":100}},{"slot":19,"count":1,"name":"WEAPON_PISTOL","metadata":{"components":[],"ammo":0,"serial":"855239WCN981625","durability":100}},{"slot":20,"count":1,"name":"WEAPON_PISTOL","metadata":{"components":[],"ammo":0,"serial":"328585HSF862966","durability":100}},{"slot":21,"count":1,"name":"WEAPON_PISTOL","metadata":{"components":[],"ammo":0,"serial":"494348IQB909319","durability":100}},{"slot":22,"count":1,"name":"WEAPON_PISTOL","metadata":{"components":[],"ammo":0,"serial":"573778UGM474602","durability":100}},{"slot":23,"count":1,"name":"WEAPON_PISTOL","metadata":{"components":[],"ammo":0,"serial":"729417HXM519451","durability":100}},{"slot":24,"count":1,"name":"WEAPON_PISTOL","metadata":{"components":[],"ammo":0,"serial":"570468VRL537567","durability":100}},{"slot":25,"count":1,"name":"WEAPON_PISTOL","metadata":{"components":[],"ammo":0,"serial":"958029RKQ335711","durability":100}},{"slot":26,"count":1,"name":"WEAPON_PISTOL","metadata":{"components":[],"ammo":0,"serial":"279987LLM528070","durability":100}},{"slot":27,"count":1,"name":"WEAPON_PISTOL","metadata":{"components":[],"ammo":0,"serial":"466287BLP749461","durability":100}},{"slot":28,"count":1,"name":"WEAPON_PISTOL","metadata":{"components":[],"ammo":0,"serial":"637303GTS620066","durability":100}},{"slot":29,"count":1,"name":"WEAPON_PISTOL","metadata":{"components":[],"ammo":0,"serial":"521162CTQ293145","durability":100}},{"slot":30,"count":1,"name":"WEAPON_PISTOL","metadata":{"components":[],"ammo":0,"serial":"408097JMN156372","durability":100}},{"slot":31,"count":1,"name":"WEAPON_PISTOL","metadata":{"components":[],"ammo":0,"serial":"772798KTA769744","durability":100}},{"slot":32,"count":1,"name":"WEAPON_PISTOL","metadata":{"components":[],"ammo":0,"serial":"911506TCQ621726","durability":100}},{"slot":33,"count":1,"name":"WEAPON_PISTOL","metadata":{"components":[],"ammo":0,"serial":"195481KSN725744","durability":100}},{"slot":34,"count":1,"name":"WEAPON_PISTOL","metadata":{"components":[],"ammo":0,"serial":"824493YMJ506372","durability":100}},{"slot":35,"count":1,"name":"WEAPON_PISTOL","metadata":{"components":[],"ammo":0,"serial":"620994UHO782953","durability":100}},{"slot":36,"count":1,"name":"WEAPON_PISTOL","metadata":{"components":[],"ammo":0,"serial":"795351ING789678","durability":100}},{"slot":37,"count":1,"name":"WEAPON_PISTOL","metadata":{"components":[],"ammo":0,"serial":"498939ZKS313839","durability":100}},{"slot":38,"count":1,"name":"WEAPON_PISTOL","metadata":{"components":[],"ammo":0,"serial":"886822KBA256263","durability":100}},{"slot":39,"count":1,"name":"WEAPON_PISTOL","metadata":{"components":[],"ammo":0,"serial":"116709STH938216","durability":100}},{"slot":40,"count":1,"name":"WEAPON_PISTOL","metadata":{"components":[],"ammo":0,"serial":"309447LIT296206","durability":100}},{"slot":41,"count":1,"name":"WEAPON_PISTOL","metadata":{"components":[],"ammo":0,"serial":"128338KFT534198","durability":100}},{"slot":42,"count":1,"name":"WEAPON_PISTOL","metadata":{"components":[],"ammo":0,"serial":"433364FJC852141","durability":100}},{"slot":43,"count":1,"name":"WEAPON_PISTOL","metadata":{"components":[],"ammo":0,"serial":"191247DDX600422","durability":100}},{"slot":44,"count":1,"name":"WEAPON_PISTOL","metadata":{"components":[],"ammo":0,"serial":"728491HID686271","durability":100}},{"slot":45,"count":1,"name":"WEAPON_PISTOL","metadata":{"components":[],"ammo":0,"serial":"657129SSH802863","durability":100}},{"slot":46,"count":1,"name":"WEAPON_PISTOL","metadata":{"components":[],"ammo":0,"serial":"718102HCR312130","durability":100}},{"slot":47,"count":1,"name":"WEAPON_PISTOL","metadata":{"components":[],"ammo":0,"serial":"937118GDU283021","durability":100}},{"slot":48,"count":1,"name":"WEAPON_PISTOL","metadata":{"components":[],"ammo":0,"serial":"507233HVS932119","durability":100}},{"slot":49,"count":1,"name":"WEAPON_PISTOL","metadata":{"components":[],"ammo":0,"serial":"175094CDV145245","durability":100}},{"slot":50,"count":1,"name":"WEAPON_PISTOL","metadata":{"components":[],"ammo":0,"serial":"532851QQT367972","durability":100}},{"slot":51,"count":1,"name":"WEAPON_PISTOL","metadata":{"components":[],"ammo":0,"serial":"497910GPF344530","durability":100}},{"slot":52,"count":1,"name":"WEAPON_PISTOL","metadata":{"components":[],"ammo":0,"serial":"777167HJO596496","durability":100}},{"slot":53,"count":1,"name":"WEAPON_PISTOL","metadata":{"components":[],"ammo":0,"serial":"769146LBT649176","durability":100}},{"slot":54,"count":1,"name":"WEAPON_ASSAULTRIFLE","metadata":{"components":[],"ammo":0,"serial":"583403IHY879156","durability":100}},{"slot":55,"count":1,"name":"WEAPON_ASSAULTRIFLE","metadata":{"components":[],"ammo":0,"serial":"746751XVY208128","durability":100}},{"slot":56,"count":1,"name":"WEAPON_ASSAULTRIFLE","metadata":{"components":[],"ammo":0,"serial":"151386KRW736106","durability":100}},{"slot":57,"count":1,"name":"WEAPON_ASSAULTRIFLE","metadata":{"components":[],"ammo":0,"serial":"195855ATJ539810","durability":100}},{"slot":58,"count":1,"name":"WEAPON_ASSAULTRIFLE","metadata":{"components":[],"ammo":0,"serial":"861647JNA330072","durability":100}},{"slot":59,"count":1,"name":"WEAPON_ASSAULTRIFLE","metadata":{"components":[],"ammo":0,"serial":"844555OXK732830","durability":100}},{"slot":60,"count":1,"name":"WEAPON_ASSAULTRIFLE","metadata":{"components":[],"ammo":0,"serial":"889802RDM257572","durability":100}},{"slot":61,"count":1,"name":"WEAPON_ASSAULTRIFLE","metadata":{"components":[],"ammo":0,"serial":"701792VBO568796","durability":100}},{"slot":62,"count":1,"name":"WEAPON_ASSAULTRIFLE","metadata":{"components":[],"ammo":0,"serial":"768332GIE230213","durability":100}},{"slot":63,"count":1,"name":"WEAPON_ASSAULTRIFLE","metadata":{"components":[],"ammo":0,"serial":"626452NVR560567","durability":100}},{"slot":64,"count":1,"name":"WEAPON_ASSAULTRIFLE","metadata":{"components":[],"ammo":0,"serial":"963816TQY757577","durability":100}},{"slot":65,"count":1,"name":"WEAPON_ASSAULTRIFLE","metadata":{"components":[],"ammo":0,"serial":"169536YHY996447","durability":100}},{"slot":66,"count":1,"name":"WEAPON_ASSAULTRIFLE","metadata":{"components":[],"ammo":0,"serial":"348984HSB723622","durability":100}},{"slot":67,"count":1,"name":"WEAPON_ASSAULTRIFLE","metadata":{"components":[],"ammo":0,"serial":"167241YAL968321","durability":100}},{"slot":68,"count":1,"name":"WEAPON_ASSAULTRIFLE","metadata":{"components":[],"ammo":0,"serial":"760995WFR873582","durability":100}},{"slot":69,"count":1,"name":"WEAPON_ASSAULTRIFLE","metadata":{"components":[],"ammo":0,"serial":"780543GZG568629","durability":100}},{"slot":70,"count":1,"name":"WEAPON_ASSAULTRIFLE","metadata":{"components":[],"ammo":0,"serial":"779775GUT779915","durability":100}},{"slot":71,"count":1,"name":"WEAPON_ASSAULTRIFLE","metadata":{"components":[],"ammo":0,"serial":"217298KVH402484","durability":100}},{"slot":72,"count":1,"name":"WEAPON_ASSAULTRIFLE","metadata":{"components":[],"ammo":0,"serial":"486367PNS273206","durability":100}},{"slot":73,"count":1,"name":"WEAPON_ASSAULTRIFLE","metadata":{"components":[],"ammo":0,"serial":"494388JKR400398","durability":100}},{"slot":74,"count":1,"name":"WEAPON_ASSAULTRIFLE","metadata":{"components":[],"ammo":0,"serial":"543384IUI692218","durability":100}},{"slot":75,"count":1,"name":"WEAPON_ASSAULTRIFLE","metadata":{"components":[],"ammo":0,"serial":"802923ZCI836669","durability":100}},{"slot":76,"count":1,"name":"WEAPON_ASSAULTRIFLE","metadata":{"components":[],"ammo":0,"serial":"906158AOM511146","durability":100}},{"slot":77,"count":1,"name":"WEAPON_ASSAULTRIFLE","metadata":{"components":[],"ammo":0,"serial":"352520DXA541579","durability":100}},{"slot":78,"count":1,"name":"WEAPON_ASSAULTRIFLE","metadata":{"components":[],"ammo":0,"serial":"738208HEN148182","durability":100}},{"slot":79,"count":1,"name":"WEAPON_ASSAULTRIFLE","metadata":{"components":[],"ammo":0,"serial":"808380AUG152918","durability":100}},{"slot":80,"count":1,"name":"WEAPON_ASSAULTRIFLE","metadata":{"components":[],"ammo":0,"serial":"624768YVD180027","durability":100}},{"slot":81,"count":1,"name":"WEAPON_ASSAULTRIFLE","metadata":{"components":[],"ammo":0,"serial":"977740PVY563956","durability":100}},{"slot":82,"count":1,"name":"WEAPON_ASSAULTRIFLE","metadata":{"components":[],"ammo":0,"serial":"352912ZEV122483","durability":100}},{"slot":83,"count":1,"name":"WEAPON_ASSAULTRIFLE","metadata":{"components":[],"ammo":0,"serial":"378528JBV151614","durability":100}},{"slot":84,"count":1000000,"name":"black_money"},{"slot":85,"count":100,"name":"laptop_h"},{"slot":86,"count":200,"name":"gauze"},{"slot":87,"count":100,"name":"lockpick","metadata":{"degrade":2160,"durability":1766562663}},{"slot":88,"count":100,"name":"at_flashlight"},{"slot":89,"count":50,"name":"ammo-box1"},{"slot":90,"count":2000000,"name":"money"},{"slot":91,"count":100,"name":"at_clip_extended_pistol"},{"slot":92,"count":200,"name":"oxy"},{"slot":93,"count":200,"name":"bandage"},{"slot":94,"count":1,"name":"WEAPON_PISTOL50","metadata":{"components":[],"ammo":0,"serial":"491236BUP707909","durability":100}},{"slot":95,"count":1,"name":"WEAPON_PISTOL50","metadata":{"components":[],"ammo":0,"serial":"485704EEG535664","durability":100}},{"slot":96,"count":1,"name":"WEAPON_PISTOL50","metadata":{"components":[],"ammo":0,"serial":"606933SSL197783","durability":100}},{"slot":97,"count":1,"name":"WEAPON_PISTOL50","metadata":{"components":[],"ammo":0,"serial":"591268IFI757699","durability":100}},{"slot":98,"count":1,"name":"WEAPON_PISTOL50","metadata":{"components":[],"ammo":0,"serial":"853793EJS574298","durability":100}},{"slot":99,"count":1,"name":"WEAPON_PISTOL50","metadata":{"components":[],"ammo":0,"serial":"319200XEH813369","durability":100}},{"slot":100,"count":1,"name":"WEAPON_PISTOL50","metadata":{"components":[],"ammo":0,"serial":"335033CMW372066","durability":100}},{"slot":101,"count":1,"name":"WEAPON_PISTOL50","metadata":{"components":[],"ammo":0,"serial":"766426BSF130996","durability":100}},{"slot":102,"count":1,"name":"WEAPON_PISTOL50","metadata":{"components":[],"ammo":0,"serial":"681840DMK472505","durability":100}},{"slot":103,"count":1,"name":"WEAPON_PISTOL50","metadata":{"components":[],"ammo":0,"serial":"733374DTN252972","durability":100}},{"slot":104,"count":1,"name":"WEAPON_PISTOL50","metadata":{"components":[],"ammo":0,"serial":"826116MRD285213","durability":100}},{"slot":105,"count":1,"name":"WEAPON_PISTOL50","metadata":{"components":[],"ammo":0,"serial":"484370QUQ398214","durability":100}},{"slot":106,"count":1,"name":"WEAPON_PISTOL50","metadata":{"components":[],"ammo":0,"serial":"990228THF221187","durability":100}},{"slot":107,"count":1,"name":"WEAPON_PISTOL50","metadata":{"components":[],"ammo":0,"serial":"563958BKQ199017","durability":100}},{"slot":108,"count":1,"name":"WEAPON_PISTOL50","metadata":{"components":[],"ammo":0,"serial":"670453QPU750306","durability":100}},{"slot":109,"count":1,"name":"WEAPON_PISTOL50","metadata":{"components":[],"ammo":0,"serial":"848808BXH623378","durability":100}},{"slot":110,"count":1,"name":"WEAPON_PISTOL50","metadata":{"components":[],"ammo":0,"serial":"541518GXE997392","durability":100}},{"slot":111,"count":1,"name":"WEAPON_PISTOL50","metadata":{"components":[],"ammo":0,"serial":"940276TMA404249","durability":100}},{"slot":112,"count":1,"name":"WEAPON_PISTOL50","metadata":{"components":[],"ammo":0,"serial":"735640RSE169742","durability":100}},{"slot":113,"count":1,"name":"WEAPON_PISTOL50","metadata":{"components":[],"ammo":0,"serial":"498079JJO996828","durability":100}},{"slot":114,"count":1,"name":"WEAPON_PISTOL50","metadata":{"components":[],"ammo":0,"serial":"545181GIU867202","durability":100}},{"slot":115,"count":1,"name":"WEAPON_PISTOL50","metadata":{"components":[],"ammo":0,"serial":"894974JSV612997","durability":100}},{"slot":116,"count":1,"name":"WEAPON_PISTOL50","metadata":{"components":[],"ammo":0,"serial":"144323AAM913252","durability":100}},{"slot":117,"count":1,"name":"WEAPON_PISTOL50","metadata":{"components":[],"ammo":0,"serial":"339561QPV899792","durability":100}},{"slot":118,"count":1,"name":"WEAPON_PISTOL50","metadata":{"components":[],"ammo":0,"serial":"761867ERZ192933","durability":100}},{"slot":119,"count":1,"name":"WEAPON_PISTOL50","metadata":{"components":[],"ammo":0,"serial":"962330MKJ887050","durability":100}},{"slot":120,"count":1,"name":"WEAPON_PISTOL50","metadata":{"components":[],"ammo":0,"serial":"487059HEA449426","durability":100}},{"slot":121,"count":1,"name":"WEAPON_PISTOL50","metadata":{"components":[],"ammo":0,"serial":"546278OUY366892","durability":100}},{"slot":122,"count":1,"name":"WEAPON_PISTOL50","metadata":{"components":[],"ammo":0,"serial":"393420YGP924099","durability":100}},{"slot":123,"count":1,"name":"WEAPON_PISTOL50","metadata":{"components":[],"ammo":0,"serial":"808415ZNV258592","durability":100}},{"slot":124,"count":1,"name":"WEAPON_PISTOL50","metadata":{"components":[],"ammo":0,"serial":"826296ASJ625860","durability":100}},{"slot":125,"count":1,"name":"WEAPON_PISTOL50","metadata":{"components":[],"ammo":0,"serial":"231741NDZ809878","durability":100}},{"slot":126,"count":1,"name":"WEAPON_PISTOL50","metadata":{"components":[],"ammo":0,"serial":"912108AHA571084","durability":100}},{"slot":127,"count":1,"name":"WEAPON_PISTOL50","metadata":{"components":[],"ammo":0,"serial":"406001VTL232340","durability":100}},{"slot":128,"count":1,"name":"WEAPON_PISTOL50","metadata":{"components":[],"ammo":0,"serial":"557707OSZ418201","durability":100}},{"slot":129,"count":1,"name":"WEAPON_PISTOL50","metadata":{"components":[],"ammo":0,"serial":"130843WSN350621","durability":100}},{"slot":130,"count":1,"name":"WEAPON_PISTOL50","metadata":{"components":[],"ammo":0,"serial":"310234HTL656037","durability":100}},{"slot":131,"count":1,"name":"WEAPON_PISTOL50","metadata":{"components":[],"ammo":0,"serial":"597499POG647584","durability":100}},{"slot":132,"count":1,"name":"WEAPON_PISTOL50","metadata":{"components":[],"ammo":0,"serial":"987611XBW857229","durability":100}},{"slot":133,"count":1,"name":"WEAPON_PISTOL50","metadata":{"components":[],"ammo":0,"serial":"485442USJ878859","durability":100}},{"slot":134,"count":1,"name":"WEAPON_PISTOL50","metadata":{"components":[],"ammo":0,"serial":"384817HII541130","durability":100}},{"slot":135,"count":1,"name":"WEAPON_PISTOL50","metadata":{"components":[],"ammo":0,"serial":"904364MHX179200","durability":100}},{"slot":136,"count":1,"name":"WEAPON_PISTOL50","metadata":{"components":[],"ammo":0,"serial":"563317YWC801423","durability":100}},{"slot":137,"count":1,"name":"WEAPON_PISTOL50","metadata":{"components":[],"ammo":0,"serial":"675944PEV627033","durability":100}},{"slot":138,"count":1,"name":"WEAPON_PISTOL50","metadata":{"components":[],"ammo":0,"serial":"315258BDU424379","durability":100}},{"slot":139,"count":1,"name":"WEAPON_PISTOL50","metadata":{"components":[],"ammo":0,"serial":"307425UZH396185","durability":100}},{"slot":140,"count":1,"name":"WEAPON_PISTOL50","metadata":{"components":[],"ammo":0,"serial":"953175EMT962135","durability":100}},{"slot":141,"count":1,"name":"WEAPON_PISTOL50","metadata":{"components":[],"ammo":0,"serial":"897923DRO404274","durability":100}},{"slot":142,"count":1,"name":"WEAPON_PISTOL50","metadata":{"components":[],"ammo":0,"serial":"411189XAL795666","durability":100}},{"slot":143,"count":1,"name":"WEAPON_PISTOL50","metadata":{"components":[],"ammo":0,"serial":"870523AZT986842","durability":100}},{"slot":144,"count":100,"name":"at_clip_extended_smg"},{"slot":145,"count":100,"name":"at_grip"},{"slot":146,"count":100,"name":"at_suppressor_heavy"},{"slot":147,"count":100,"name":"at_suppressor_light"},{"slot":148,"count":9,"name":"gang_perks_sunrise"}]', '2025-12-22 20:00:00');

-- Dumping structure for table cfx_cs_v3.player_outfits
CREATE TABLE IF NOT EXISTS `player_outfits` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `citizenid` varchar(50) DEFAULT NULL,
  `outfitname` varchar(50) NOT NULL DEFAULT '0',
  `model` varchar(50) DEFAULT NULL,
  `props` varchar(1000) DEFAULT NULL,
  `components` varchar(1500) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `citizenid_outfitname_model` (`citizenid`,`outfitname`,`model`),
  KEY `citizenid` (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table cfx_cs_v3.player_outfits: ~0 rows (approximately)

-- Dumping structure for table cfx_cs_v3.player_outfit_codes
CREATE TABLE IF NOT EXISTS `player_outfit_codes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `outfitid` int(11) NOT NULL,
  `code` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '',
  PRIMARY KEY (`id`),
  KEY `FK_player_outfit_codes_player_outfits` (`outfitid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table cfx_cs_v3.player_outfit_codes: ~0 rows (approximately)

-- Dumping structure for table cfx_cs_v3.player_priv_garages
CREATE TABLE IF NOT EXISTS `player_priv_garages` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `owners` longtext DEFAULT NULL,
  `name` varchar(255) DEFAULT NULL,
  `type` varchar(50) DEFAULT NULL,
  `x` float DEFAULT NULL,
  `y` float DEFAULT NULL,
  `z` float DEFAULT NULL,
  `h` float DEFAULT NULL,
  `distance` int(11) DEFAULT 10,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table cfx_cs_v3.player_priv_garages: ~0 rows (approximately)

-- Dumping structure for table cfx_cs_v3.police_fines
CREATE TABLE IF NOT EXISTS `police_fines` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `label` varchar(255) DEFAULT NULL,
  `amount` int(11) DEFAULT NULL,
  `category` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=56 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table cfx_cs_v3.police_fines: ~55 rows (approximately)
INSERT INTO `police_fines` (`id`, `label`, `amount`, `category`) VALUES
	(1, 'Misuse of a horn', 2000, 0),
	(2, 'Illegally Crossing a continuous Line', 2000, 0),
	(3, 'Driving on the wrong side of the road', 3000, 0),
	(4, 'Illegal U-Turn', 3000, 0),
	(5, 'Illegally Driving Off-road', 3000, 0),
	(6, 'Refusing a Lawful Command', 3000, 0),
	(7, 'Illegally Stopping a Vehicle', 3000, 0),
	(8, 'Illegal Parking', 3000, 0),
	(9, 'Failing to Yield to the right', 3000, 0),
	(10, 'Failure to comply with Vehicle Information', 3000, 0),
	(11, 'Failing to stop at a Stop Sign ', 3000, 0),
	(12, 'Failing to stop at a Red Light', 3000, 0),
	(13, 'Illegal Passing', 3000, 0),
	(14, 'Driving an illegal Vehicle', 3000, 0),
	(15, 'Driving without a License', 3000, 0),
	(16, 'Hit and Run', 15000, 2),
	(17, 'Exceeding Speeds Over < 5 mph', 3000, 0),
	(18, 'Exceeding Speeds Over 5-15 mph', 3000, 0),
	(19, 'Exceeding Speeds Over 15-30 mph', 3000, 0),
	(20, 'Exceeding Speeds Over > 30 mph', 3000, 0),
	(21, 'Impeding traffic flow', 10000, 1),
	(22, 'Public Intoxication', 15000, 1),
	(23, 'Disorderly conduct', 15000, 1),
	(24, 'Obstruction of Justice', 15000, 1),
	(25, 'Insults towards Civilians', 15000, 1),
	(26, 'Disrespecting of an LEO', 15000, 2),
	(27, 'Verbal Threat towards a Civilian', 15000, 1),
	(28, 'Verbal Threat towards an LEO', 15000, 2),
	(29, 'Providing False Information', 15000, 1),
	(30, 'Attempt of Corruption', 15000, 1),
	(31, 'Brandishing a weapon in city Limits', 5000, 2),
	(32, 'Brandishing a Lethal Weapon in city Limits', 15000, 2),
	(33, 'No Firearms License', 15000, 2),
	(34, 'Possession of an Illegal Weapon', 15000, 2),
	(35, 'Possession of Burglary Tools', 5000, 2),
	(36, 'Grand Theft Auto', 5000, 2),
	(37, 'Intent to Sell/Distribute of an illegal Substance', 30000, 2),
	(38, 'Fabrication of an Illegal Substance', 20000, 2),
	(39, 'Possession of an Illegal Substance ', 50000, 2),
	(40, 'Kidnapping of a Civilian', 100000, 3),
	(41, 'Kidnapping of an LEO', 20000, 3),
	(42, 'Robbery', 15000, 2),
	(43, 'Armed Robbery of a Store', 20000, 2),
	(44, 'Armed Robbery of a Bank', 30000, 2),
	(45, 'Assault on a Civilian', 10000, 3),
	(46, 'Assault of an LEO', 20000, 3),
	(47, 'Attempt of Murder of a Civilian', 20000, 3),
	(48, 'Attempt of Murder of an LEO', 40000, 3),
	(49, 'Murder of a Civilian', 30000, 3),
	(50, 'Murder of an LEO', 50000, 3),
	(51, 'Involuntary manslaughter', 30000, 3),
	(52, 'Fraud', 25000, 2),
	(53, 'Possession of Contraband', 10000, 2),
	(54, 'Resisting Arrest', 50000, 2),
	(55, 'Possession of LEO Weapon', 20000, 2);

-- Dumping structure for table cfx_cs_v3.police_mdt_reports
CREATE TABLE IF NOT EXISTS `police_mdt_reports` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `char_id` int(11) DEFAULT NULL,
  `title` varchar(255) DEFAULT NULL,
  `incident` longtext DEFAULT NULL,
  `charges` longtext DEFAULT NULL,
  `author` varchar(255) DEFAULT NULL,
  `name` varchar(255) DEFAULT NULL,
  `date` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table cfx_cs_v3.police_mdt_reports: ~1 rows (approximately)
INSERT INTO `police_mdt_reports` (`id`, `char_id`, `title`, `incident`, `charges`, `author`, `name`, `date`) VALUES
	(1, 1, 'eqeqeqeqeq', 'qweqweqeq', '{"Driving on the wrong side of the road":1,"Illegally Crossing a continuous Line":1,"Misuse of a horn":1}', 'Ziee Oliveroz', 'Ziee Oliveroz', '12-20-2025 14:04:17');

-- Dumping structure for table cfx_cs_v3.police_mdt_warrants
CREATE TABLE IF NOT EXISTS `police_mdt_warrants` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  `char_id` int(11) DEFAULT NULL,
  `report_id` int(11) DEFAULT NULL,
  `report_title` varchar(255) DEFAULT NULL,
  `charges` longtext DEFAULT NULL,
  `date` varchar(255) DEFAULT NULL,
  `expire` varchar(255) DEFAULT NULL,
  `notes` varchar(255) DEFAULT NULL,
  `author` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table cfx_cs_v3.police_mdt_warrants: ~1 rows (approximately)
INSERT INTO `police_mdt_warrants` (`id`, `name`, `char_id`, `report_id`, `report_title`, `charges`, `date`, `expire`, `notes`, `author`) VALUES
	(1, 'eqeqeq', NULL, NULL, 'qweqw', '[]', '12-20-2025 14:09:38', '2025-12-27T06:09:38.838Z', 'qeqeq', 'Ziee Oliveroz');

-- Dumping structure for table cfx_cs_v3.police_user_convictions
CREATE TABLE IF NOT EXISTS `police_user_convictions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `char_id` int(11) DEFAULT NULL,
  `offense` varchar(255) DEFAULT NULL,
  `count` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table cfx_cs_v3.police_user_convictions: ~3 rows (approximately)
INSERT INTO `police_user_convictions` (`id`, `char_id`, `offense`, `count`) VALUES
	(1, 1, 'Driving on the wrong side of the road', 1),
	(2, 1, 'Illegally Crossing a continuous Line', 1),
	(3, 1, 'Misuse of a horn', 1);

-- Dumping structure for table cfx_cs_v3.police_user_mdt
CREATE TABLE IF NOT EXISTS `police_user_mdt` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `char_id` int(11) DEFAULT NULL,
  `notes` varchar(255) DEFAULT NULL,
  `mugshot_url` varchar(255) DEFAULT NULL,
  `bail` bit(1) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table cfx_cs_v3.police_user_mdt: ~0 rows (approximately)

-- Dumping structure for table cfx_cs_v3.police_vehicle_mdt
CREATE TABLE IF NOT EXISTS `police_vehicle_mdt` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `plate` varchar(255) DEFAULT NULL,
  `stolen` bit(1) DEFAULT b'0',
  `notes` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table cfx_cs_v3.police_vehicle_mdt: ~0 rows (approximately)

-- Dumping structure for table cfx_cs_v3.users
CREATE TABLE IF NOT EXISTS `users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `identifier` varchar(60) NOT NULL,
  `ssn` varchar(11) NOT NULL,
  `discord` varchar(60) DEFAULT NULL,
  `identifiers` longtext DEFAULT '[]',
  `hwdid` longtext DEFAULT '[]',
  `DateCreated` datetime NOT NULL DEFAULT current_timestamp(),
  `LastConnected` datetime NOT NULL DEFAULT current_timestamp(),
  `avatar` longtext NOT NULL DEFAULT 'https://r2.fivemanage.com/jnFlnukrREoazOSLNY1VW/male.png',
  `accounts` longtext DEFAULT NULL,
  `group` varchar(50) DEFAULT 'user',
  `inventory` longtext DEFAULT NULL,
  `job` varchar(20) DEFAULT 'unemployed',
  `job_grade` int(11) DEFAULT 0,
  `loadout` longtext DEFAULT NULL,
  `metadata` longtext DEFAULT NULL,
  `position` longtext DEFAULT NULL,
  `firstname` varchar(16) DEFAULT NULL,
  `lastname` varchar(16) DEFAULT NULL,
  `dateofbirth` varchar(10) DEFAULT NULL,
  `sex` varchar(1) DEFAULT NULL,
  `height` int(11) DEFAULT NULL,
  `gang` text DEFAULT NULL,
  `skin` longtext DEFAULT NULL,
  `garage_limit` int(10) DEFAULT 7,
  `dead` int(11) DEFAULT 0,
  `phone_number` varchar(20) DEFAULT NULL,
  `playtime` int(10) DEFAULT 0,
  `expdrugs` int(250) NOT NULL DEFAULT 0,
  `weapon_skins` longtext DEFAULT '[]',
  `cryptocurrency` longtext NOT NULL DEFAULT '',
  `crypto_wallet` int(11) DEFAULT 0,
  `iban` varchar(32) DEFAULT NULL,
  `okok_pincode` longtext DEFAULT NULL,
  `okok_credit_score` int(11) DEFAULT NULL,
  `okok_bank_contacts` text DEFAULT NULL,
  `opening_date` longtext DEFAULT NULL,
  `last_property` longtext DEFAULT NULL,
  PRIMARY KEY (`identifier`),
  UNIQUE KEY `id` (`id`),
  UNIQUE KEY `unique_ssn` (`ssn`),
  KEY `idx_users_iban` (`iban`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table cfx_cs_v3.users: ~6 rows (approximately)
INSERT INTO `users` (`id`, `identifier`, `ssn`, `discord`, `identifiers`, `hwdid`, `DateCreated`, `LastConnected`, `avatar`, `accounts`, `group`, `inventory`, `job`, `job_grade`, `loadout`, `metadata`, `position`, `firstname`, `lastname`, `dateofbirth`, `sex`, `height`, `gang`, `skin`, `garage_limit`, `dead`, `phone_number`, `playtime`, `expdrugs`, `weapon_skins`, `cryptocurrency`, `crypto_wallet`, `iban`, `okok_pincode`, `okok_credit_score`, `okok_bank_contacts`, `opening_date`, `last_property`) VALUES
	(1, '8d580e801963852f52c994e1670bf72282712462', '616-43-1223', '769922509071188029', '["license:8d580e801963852f52c994e1670bf72282712462","discord:769922509071188029","fivem:1960258","license2:8d580e801963852f52c994e1670bf72282712462","ip:172.29.192.1"]', '["3:2831f01c827b1e34d7f5797c9c859e4f8db45ca554a3f12e2dc55958f244dbf5","4:5981cc7f9ba02c58dab41d33b44b6be236c70fbb8107d5e3027f48bd9e3b039a","4:cd433230f982fb256fa706ea5280cdb70a0baf4769e67b89ce39f0a433443540","4:887f5c7b8303bcd04b366ac306e69fac28bf8378edddb30c78babee4346f8448","2:ddee567d069e28b0a4caf786b7cf06852186cd336b3da5dac20855816d1dbfb1","5:2910de86d36552a74ca0240576c47bc3b4ebf29c514f7bf142d2dc467b44e502"]', '2025-12-18 21:42:15', '2026-01-21 19:27:06', 'https://r2.fivemanage.com/jnFlnukrREoazOSLNY1VW/male.png', '{"black_money":0,"money":758,"bank":13680,"th_coin":0}', 'developer', '[{"slot":1,"count":10,"name":"arabica"},{"slot":2,"metadata":{"headerFirstName":"Ziee","elements":[{"elementid":"_m0","type":"input","label":"INSURED FIRSTNAME","value":"qweqwe"},{"elementid":"_m1","type":"input","label":"INSURED LASTNAME","value":"qweqe"},{"elementid":"_m2","type":"input","label":"VALID UNTIL","can_be_empty":false,"value":"qeqeq"},{"elementid":"_m3","type":"textarea","label":"MEDICAL NOTES","value":"THE AFOREMENTIONED INSURED CITIZEN WAS TESTED BY A HEALTHCARE OFFICIAL AND DETERMINED HEALTHY WITH NO DETECTED LONGTERM CONDITIONS. THIS REPORT IS VALID UNTIL THE AFOREMENTIONED EXPIRATION DATE."}],"headerSubtitle":"Official medical report provided by a pathologist.","submittable":true,"headerTitle":"MEDICAL REPORT - PATHOLOGY","signed":true,"headerJobLabel":"EMS","headerJobGrade":"Head Nurse","job":"ambulance","headerDateCreated":"20/12/2025 17:47:50","headerLastName":"Oliveroz","headerDateOfBirth":"02/02/2002"},"count":1,"name":"documents"},{"slot":3,"count":100,"name":"bandage"},{"slot":4,"count":758,"name":"money"},{"slot":5,"metadata":{"ammo":0,"registered":"Ziee Oliveroz","serial":"354673BQS232043","durability":100,"components":[]},"count":1,"name":"WEAPON_MINISMG"},{"slot":6,"count":978,"name":"ammo-9"},{"slot":7,"metadata":{"ammo":11,"registered":"Ziee Oliveroz","serial":"355197MIG191905","durability":98.8,"components":[]},"count":1,"name":"WEAPON_PISTOL"},{"slot":9,"count":1,"name":"emsbadge"},{"slot":10,"metadata":{"ammo":0,"registered":"Ziee Oliveroz","serial":"614860GUR945579","durability":100,"components":[]},"count":1,"name":"WEAPON_PISTOL_MK2"},{"slot":11,"count":1,"name":"policebadge"},{"slot":12,"count":11,"name":"onion"},{"slot":14,"metadata":{"headerFirstName":"Ziee","elements":[{"elementid":"_m4","type":"input","label":"INSURED FIRSTNAME","value":"qweq"},{"elementid":"_m5","type":"input","label":"INSURED LASTNAME","value":"eqeq"},{"elementid":"_m6","type":"input","label":"VALID UNTIL","can_be_empty":false,"value":"eqeqeq"},{"elementid":"_m7","type":"textarea","label":"MEDICAL NOTES","value":"THE AFOREMENTIONED INSURED CITIZEN WAS TESTED BY A HEALTHCARE OFFICIAL AND DETERMINED MENTALLY HEALTHY BY THE LOWEST APPROVED PSYCHOLOGY STANDARDS. THIS REPORT IS VALID UNTIL THE AFOREMENTIONED EXPIRATION DATE."}],"headerSubtitle":"Official medical report provided by a psychologist.","submittable":true,"headerTitle":"MEDICAL REPORT - PSYCHOLOGY","headerDateOfBirth":"02/02/2002","headerJobGrade":"Head Nurse","job":"ambulance","headerDateCreated":"20/12/2025 17:51:47","headerLastName":"Oliveroz","headerJobLabel":"EMS"},"count":1,"name":"documents"},{"slot":15,"count":3,"name":"medicine_powder"},{"slot":16,"count":2,"name":"steel"},{"slot":17,"count":5,"name":"glass"},{"slot":18,"count":2,"name":"rubber"},{"slot":19,"metadata":{"description":"Trowel Durability: 97","health":97,"durability":1769426858,"degrade":7200},"count":1,"name":"trowel"}]', 'ambulance', 3, '[]', '{"disease":"none","callsign":"NO CALLSIGN","armor":0,"licenses":{"motorcycle":{"label":"Motorcycle License","has":false,"name":"motorcycle"},"car":{"label":"Car License","has":false,"name":"car"},"therotical":{"label":"Student Permit","has":false,"name":"therotical"},"weapon":{"label":"Weapon License","has":false,"name":"weapon"},"boat":{"label":"Boat License","has":false,"name":"boat"}},"jobDuty":true,"health":200,"status":{"stress":0,"hunger":52,"thirst":52},"injuries":{"limbs":{"NECK":{"isDamaged":true,"causeLimp":false,"label":"Neck","severity":2},"LARM":{"isDamaged":false,"causeLimp":false,"label":"Left Arm","severity":0},"UPPER_BODY":{"isDamaged":false,"causeLimp":false,"label":"Upper Body","severity":0},"RHAND":{"isDamaged":false,"causeLimp":false,"label":"Right Hand","severity":0},"RFINGER":{"isDamaged":false,"causeLimp":false,"label":"Right Hand Fingers","severity":0},"RLEG":{"isDamaged":true,"causeLimp":true,"label":"Right Leg","severity":1},"LOWER_BODY":{"isDamaged":false,"causeLimp":true,"label":"Lower Body","severity":0},"LLEG":{"isDamaged":false,"causeLimp":true,"label":"Left Leg","severity":0},"HEAD":{"isDamaged":true,"causeLimp":false,"label":"Head","severity":1},"SPINE":{"isDamaged":true,"causeLimp":true,"label":"Spine","severity":1},"LFINGER":{"isDamaged":false,"causeLimp":false,"label":"Left Hand Fingers","severity":0},"LFOOT":{"isDamaged":false,"causeLimp":true,"label":"Left Foot","severity":0},"RARM":{"isDamaged":false,"causeLimp":false,"label":"Right Arm","severity":0},"RFOOT":{"isDamaged":false,"causeLimp":true,"label":"Right Foot","severity":0},"LHAND":{"isDamaged":false,"causeLimp":false,"label":"Left Hand","severity":0}},"isBleeding":4}}', '{"z":41.07470703125,"heading":147.40158081054688,"x":2065.028564453125,"y":4927.8857421875}', 'Ziee', 'Oliveroz', '02/02/2002', 'm', 200, '{"grade":{"level":2,"name":"Patron"},"isboss":true,"label":"Gang 1","name":"g1"}', '{"headBlend":{"skinFirst":0,"thirdMix":0,"skinSecond":0,"shapeMix":0,"shapeSecond":0,"skinThird":0,"skinMix":0,"shapeFirst":0,"shapeThird":0},"model":"mp_m_freemode_01","eyeColor":-1,"tattoos":[],"components":[{"component_id":0,"texture":0,"drawable":0},{"component_id":1,"texture":0,"drawable":0},{"component_id":2,"texture":0,"drawable":0},{"component_id":3,"texture":0,"drawable":0},{"component_id":4,"texture":0,"drawable":0},{"component_id":5,"texture":0,"drawable":0},{"component_id":6,"texture":0,"drawable":0},{"component_id":7,"texture":0,"drawable":0},{"component_id":8,"texture":0,"drawable":0},{"component_id":9,"texture":0,"drawable":0},{"component_id":10,"texture":0,"drawable":0},{"component_id":11,"texture":0,"drawable":0}],"props":[{"prop_id":0,"texture":-1,"drawable":-1},{"prop_id":1,"texture":-1,"drawable":-1},{"prop_id":2,"texture":-1,"drawable":-1},{"prop_id":6,"texture":-1,"drawable":-1},{"prop_id":7,"texture":-1,"drawable":-1}],"headOverlays":{"blush":{"secondColor":0,"opacity":0,"color":0,"style":0},"sunDamage":{"secondColor":0,"opacity":0,"color":0,"style":0},"complexion":{"secondColor":0,"opacity":0,"color":0,"style":0},"blemishes":{"secondColor":0,"opacity":0,"color":0,"style":0},"beard":{"secondColor":0,"opacity":0,"color":0,"style":0},"chestHair":{"secondColor":0,"opacity":0,"color":0,"style":0},"ageing":{"secondColor":0,"opacity":0,"color":0,"style":0},"makeUp":{"secondColor":0,"opacity":0,"color":0,"style":0},"eyebrows":{"secondColor":0,"opacity":0,"color":0,"style":0},"moleAndFreckles":{"secondColor":0,"opacity":0,"color":0,"style":0},"bodyBlemishes":{"secondColor":0,"opacity":0,"color":0,"style":0},"lipstick":{"secondColor":0,"opacity":0,"color":0,"style":0}},"hair":{"style":0,"highlight":0,"texture":0,"color":0},"faceFeatures":{"lipsThickness":0,"neckThickness":0,"nosePeakHigh":0,"cheeksBoneHigh":0,"noseWidth":0,"chinBoneLowering":0,"eyeBrownForward":0,"chinHole":0,"cheeksWidth":0,"nosePeakLowering":0,"jawBoneBackSize":0,"noseBoneTwist":0,"jawBoneWidth":0,"eyeBrownHigh":0,"nosePeakSize":0,"noseBoneHigh":0,"eyesOpening":0,"chinBoneSize":0,"chinBoneLenght":0,"cheeksBoneWidth":0}}', 7, 0, NULL, 53024, 0, '[]', '', 0, NULL, NULL, NULL, NULL, NULL, NULL),
	(5, '8d580e801963852f52c994e1670bf722827124621', '369-96-7222', '769922509071188029', '["license:8d580e801963852f52c994e1670bf72282712462","discord:769922509071188029","fivem:1960258","license2:8d580e801963852f52c994e1670bf72282712462","ip:192.168.56.1"]', '["3:b9dd434ecf8175821be56bcc1b6f9642dcd15cf384ffb1c1167ab787064bac0f","4:d467174102692f3cc70d70fbd3a2cc5ade1d8f3acae381c2a29e4e0ee331fc26","4:cd433230f982fb256fa706ea5280cdb70a0baf4769e67b89ce39f0a433443540","4:887f5c7b8303bcd04b366ac306e69fac28bf8378edddb30c78babee4346f8448","2:ddee567d069e28b0a4caf786b7cf06852186cd336b3da5dac20855816d1dbfb1","5:2910de86d36552a74ca0240576c47bc3b4ebf29c514f7bf142d2dc467b44e502"]', '2026-01-03 00:39:50', '2026-01-03 00:39:50', 'https://r2.fivemanage.com/jnFlnukrREoazOSLNY1VW/male.png', '{"money":0,"bank":50010,"black_money":0,"th_coin":0}', 'user', '[{"count":1,"name":"welcome_kit","slot":1},{"metadata":{"lastname":"Qwewqe","identifier":"8d580e801963852f52c994e1670bf722827124621","mugShot":"none","cardtype":"id_card","durability":1767804268,"sex":"m","degrade":7200,"badge":"none","isSv":true,"nationality":"Los Santos","firstname":"Qweqwe","birthdate":"02/02/2002"},"count":1,"name":"id_card","slot":2}]', 'unemployed', 0, '[]', '{"armor":0,"health":197,"callsign":"NO CALLSIGN","status":{"thirst":46,"hunger":46,"stress":0},"jobDuty":false,"licenses":{"car":{"has":false,"label":"Car License","name":"car"},"boat":{"has":false,"label":"Boat License","name":"boat"},"therotical":{"has":false,"label":"Student Permit","name":"therotical"},"motorcycle":{"has":false,"label":"Motorcycle License","name":"motorcycle"},"weapon":{"has":false,"label":"Weapon License","name":"weapon"}},"disease":"none"}', '{"heading":93.54330444335938,"x":-1030.10107421875,"y":-2729.69677734375,"z":20.1640625}', 'Qweqwe', 'Qwewqe', '02/02/2002', 'm', 200, '{"grade":{"name":"none","level":0},"label":"No Gang Affiliaton","name":"none","isboss":false}', '{"eyeColor":-1,"components":[{"texture":0,"component_id":0,"drawable":0},{"texture":0,"component_id":1,"drawable":0},{"texture":0,"component_id":2,"drawable":0},{"texture":0,"component_id":3,"drawable":0},{"texture":0,"component_id":4,"drawable":0},{"texture":0,"component_id":5,"drawable":0},{"texture":0,"component_id":6,"drawable":0},{"texture":0,"component_id":7,"drawable":0},{"texture":0,"component_id":8,"drawable":0},{"texture":0,"component_id":9,"drawable":0},{"texture":0,"component_id":10,"drawable":0},{"texture":0,"component_id":11,"drawable":0}],"faceFeatures":{"jawBoneBackSize":0,"cheeksWidth":0,"noseBoneHigh":0,"lipsThickness":0,"nosePeakHigh":0,"cheeksBoneWidth":0,"noseBoneTwist":0,"chinBoneLenght":0,"noseWidth":0,"nosePeakSize":0,"eyesOpening":0,"nosePeakLowering":0,"neckThickness":0,"eyeBrownForward":0,"chinHole":0,"eyeBrownHigh":0,"jawBoneWidth":0,"cheeksBoneHigh":0,"chinBoneSize":0,"chinBoneLowering":0},"tattoos":[],"headBlend":{"shapeSecond":0,"skinThird":0,"skinMix":0,"shapeMix":0,"skinSecond":0,"thirdMix":0,"skinFirst":0,"shapeThird":0,"shapeFirst":0},"props":[{"texture":-1,"prop_id":0,"drawable":-1},{"texture":-1,"prop_id":1,"drawable":-1},{"texture":-1,"prop_id":2,"drawable":-1},{"texture":-1,"prop_id":6,"drawable":-1},{"texture":-1,"prop_id":7,"drawable":-1}],"hair":{"texture":0,"highlight":0,"color":0,"style":0},"model":"mp_m_freemode_01","headOverlays":{"sunDamage":{"color":0,"style":0,"secondColor":0,"opacity":0},"makeUp":{"color":0,"style":0,"secondColor":0,"opacity":0},"eyebrows":{"color":0,"style":0,"secondColor":0,"opacity":0},"blush":{"color":0,"style":0,"secondColor":0,"opacity":0},"bodyBlemishes":{"color":0,"style":0,"secondColor":0,"opacity":0},"blemishes":{"color":0,"style":0,"secondColor":0,"opacity":0},"chestHair":{"color":0,"style":0,"secondColor":0,"opacity":0},"beard":{"color":0,"style":0,"secondColor":0,"opacity":0},"lipstick":{"color":0,"style":0,"secondColor":0,"opacity":0},"complexion":{"color":0,"style":0,"secondColor":0,"opacity":0},"moleAndFreckles":{"color":0,"style":0,"secondColor":0,"opacity":0},"ageing":{"color":0,"style":0,"secondColor":0,"opacity":0}}}', 7, 0, NULL, 787, 0, '[]', '', 0, NULL, NULL, NULL, NULL, NULL, NULL),
	(2, '8d580e801963852f52c994e1670bf722827124622', '484-18-4141', '769922509071188029', '["steam:11000013686089d","license:8d580e801963852f52c994e1670bf72282712462","discord:769922509071188029","fivem:1960258","license2:8d580e801963852f52c994e1670bf72282712462","ip:192.168.56.1"]', '["3:cc077f28431fa19894cc74682b876a16f91ba9f80c67091d23aac3c8facde368","4:b1935b98a8f674840660712d7798d22c70dfc30bf32b30cb653391b4b8efb89c","4:11b93297c91005da8452ed77e889149c89ae7f3e837716246497d60aa854f74f","4:48c188328bef7df121cebd1e47b38e9c776bec9c0b58667439830058cb0ab8ea","2:013b2e51a3c2d7a2599d82f499ca82f44b40bd39bc5b0b3e12fd0464ebe1afef","5:0e234737953e812d5cf09c41c95369bf9b816b0669207ba4c2713dbba4272361"]', '2025-12-20 17:57:53', '2025-12-20 17:57:54', 'https://r2.fivemanage.com/jnFlnukrREoazOSLNY1VW/male.png', '{"black_money":0,"money":4300,"bank":20500,"th_coin":0}', 'admin', '[{"slot":1,"name":"item_free_car","count":1},{"slot":2,"name":"phone","metadata":{"durability":1766656674,"degrade":7200},"count":1},{"slot":3,"name":"money","count":4300},{"slot":4,"name":"new_player_card","metadata":{"durability":1766483874,"degrade":4320},"count":1},{"slot":5,"name":"bread","metadata":{"durability":1766311074,"degrade":1440},"count":8},{"slot":6,"name":"sprunk","metadata":{"durability":1766311074,"degrade":1440},"count":9},{"slot":7,"name":"lockpick","metadata":{"durability":1766354274,"degrade":2160},"count":3},{"slot":8,"name":"reskin_card","count":1},{"slot":9,"name":"ems_medikit","count":8},{"slot":10,"name":"WEAPON_PETROLCAN","metadata":{"durability":100,"components":[],"ammo":100,"weight":15000.0},"count":1}]', 'ambulance', 2, '[]', '{"health":200,"callsign":"NO CALLSIGN","disease":"none","armor":0,"status":{"thirst":76,"stress":0,"hunger":96},"jobDuty":true,"licenses":{"therotical":{"name":"therotical","has":false,"label":"Student Permit"},"car":{"name":"car","has":false,"label":"Car License"},"boat":{"name":"boat","has":false,"label":"Boat License"},"motorcycle":{"name":"motorcycle","has":false,"label":"Motorcycle License"},"weapon":{"name":"weapon","has":false,"label":"Weapon License"}}}', '{"x":417.71868896484377,"y":-641.2088012695313,"z":28.4879150390625,"heading":303.3070983886719}', 'Ziee', 'Oliveroz', '02/02/2002', 'm', 200, '{"grade":{"level":0,"name":"none"},"name":"none","isboss":false,"label":"No Gang Affiliaton"}', '{"headOverlays":{"blemishes":{"color":0,"secondColor":0,"opacity":0,"style":0},"bodyBlemishes":{"color":0,"secondColor":0,"opacity":0,"style":0},"moleAndFreckles":{"color":0,"secondColor":0,"opacity":0,"style":0},"chestHair":{"color":0,"secondColor":0,"opacity":0,"style":0},"blush":{"color":0,"secondColor":0,"opacity":0,"style":0},"ageing":{"color":0,"secondColor":0,"opacity":0,"style":0},"beard":{"color":0,"secondColor":0,"opacity":0,"style":0},"makeUp":{"color":0,"secondColor":0,"opacity":0,"style":0},"eyebrows":{"color":0,"secondColor":0,"opacity":0,"style":0},"complexion":{"color":0,"secondColor":0,"opacity":0,"style":0},"lipstick":{"color":0,"secondColor":0,"opacity":0,"style":0},"sunDamage":{"color":0,"secondColor":0,"opacity":0,"style":0}},"faceFeatures":{"chinHole":0,"jawBoneBackSize":0,"noseBoneTwist":0,"eyeBrownHigh":0,"nosePeakLowering":0,"jawBoneWidth":0,"noseWidth":0,"chinBoneLenght":0,"cheeksWidth":0,"noseBoneHigh":0,"cheeksBoneWidth":0,"chinBoneLowering":0,"eyesOpening":0,"eyeBrownForward":0,"neckThickness":0,"lipsThickness":0,"nosePeakHigh":0,"cheeksBoneHigh":0,"nosePeakSize":0,"chinBoneSize":0},"tattoos":[],"eyeColor":-1,"hair":{"highlight":0,"color":0,"texture":0,"style":0},"model":"mp_m_freemode_01","headBlend":{"thirdMix":0,"skinMix":0,"shapeFirst":0,"skinFirst":0,"skinSecond":0,"skinThird":0,"shapeMix":0,"shapeThird":0,"shapeSecond":0},"components":[{"component_id":0,"drawable":0,"texture":0},{"component_id":1,"drawable":0,"texture":0},{"component_id":2,"drawable":0,"texture":0},{"component_id":3,"drawable":0,"texture":0},{"component_id":4,"drawable":0,"texture":0},{"component_id":5,"drawable":0,"texture":0},{"component_id":6,"drawable":0,"texture":0},{"component_id":7,"drawable":0,"texture":0},{"component_id":8,"drawable":0,"texture":0},{"component_id":9,"drawable":0,"texture":0},{"component_id":10,"drawable":0,"texture":0},{"component_id":11,"drawable":0,"texture":0}],"props":[{"prop_id":0,"drawable":-1,"texture":-1},{"prop_id":1,"drawable":-1,"texture":-1},{"prop_id":2,"drawable":-1,"texture":-1},{"prop_id":6,"drawable":-1,"texture":-1},{"prop_id":7,"drawable":-1,"texture":-1}]}', 7, 0, NULL, 3420, 0, '[]', '', 0, NULL, NULL, NULL, NULL, NULL, NULL),
	(3, '8d580e801963852f52c994e1670bf722827124623', '088-32-8259', '769922509071188029', '["steam:11000013686089d","license:8d580e801963852f52c994e1670bf72282712462","discord:769922509071188029","fivem:1960258","license2:8d580e801963852f52c994e1670bf72282712462","ip:192.168.56.1"]', '["3:cc077f28431fa19894cc74682b876a16f91ba9f80c67091d23aac3c8facde368","4:b1935b98a8f674840660712d7798d22c70dfc30bf32b30cb653391b4b8efb89c","4:11b93297c91005da8452ed77e889149c89ae7f3e837716246497d60aa854f74f","4:48c188328bef7df121cebd1e47b38e9c776bec9c0b58667439830058cb0ab8ea","2:013b2e51a3c2d7a2599d82f499ca82f44b40bd39bc5b0b3e12fd0464ebe1afef","5:0e234737953e812d5cf09c41c95369bf9b816b0669207ba4c2713dbba4272361"]', '2025-12-20 17:59:31', '2025-12-20 17:59:32', 'https://r2.fivemanage.com/jnFlnukrREoazOSLNY1VW/male.png', '{"black_money":0,"money":5000,"bank":20050,"th_coin":0}', 'admin', '[{"slot":1,"name":"item_free_car","count":1},{"slot":2,"name":"phone","metadata":{"durability":1766656772,"degrade":7200},"count":1},{"slot":3,"name":"money","count":5000},{"slot":4,"name":"new_player_card","metadata":{"durability":1766483972,"degrade":4320},"count":1},{"slot":5,"name":"bread","metadata":{"durability":1766311172,"degrade":1440},"count":10},{"slot":6,"name":"sprunk","metadata":{"durability":1766311172,"degrade":1440},"count":10},{"slot":7,"name":"lockpick","metadata":{"durability":1766354372,"degrade":2160},"count":3},{"slot":8,"name":"reskin_card","count":1}]', 'unemployed', 0, '[]', '{"health":0,"callsign":"NO CALLSIGN","disease":"none","armor":0,"status":{"thirst":46,"stress":0,"hunger":46},"jobDuty":false,"licenses":{"therotical":{"name":"therotical","has":false,"label":"Student Permit"},"car":{"name":"car","has":false,"label":"Car License"},"boat":{"name":"boat","has":false,"label":"Boat License"},"motorcycle":{"name":"motorcycle","has":false,"label":"Motorcycle License"},"weapon":{"name":"weapon","has":false,"label":"Weapon License"}}}', '{"x":418.29888916015627,"y":-642.5933837890625,"z":28.2857666015625,"heading":22.67716407775879}', 'Ziee', 'Oliverzz', '02/02/2002', 'm', 200, '{"grade":{"level":0,"name":"none"},"name":"none","isboss":false,"label":"No Gang Affiliaton"}', '{"headOverlays":{"chestHair":{"secondColor":0,"color":0,"opacity":0,"style":0},"bodyBlemishes":{"secondColor":0,"color":0,"opacity":0,"style":0},"moleAndFreckles":{"secondColor":0,"color":0,"opacity":0,"style":0},"ageing":{"secondColor":0,"color":0,"opacity":0,"style":0},"complexion":{"secondColor":0,"color":0,"opacity":0,"style":0},"lipstick":{"secondColor":0,"color":0,"opacity":0,"style":0},"beard":{"secondColor":0,"color":0,"opacity":0,"style":0},"makeUp":{"secondColor":0,"color":0,"opacity":0,"style":0},"eyebrows":{"secondColor":0,"color":0,"opacity":0,"style":0},"blush":{"secondColor":0,"color":0,"opacity":0,"style":0},"blemishes":{"secondColor":0,"color":0,"opacity":0,"style":0},"sunDamage":{"secondColor":0,"color":0,"opacity":0,"style":0}},"faceFeatures":{"chinHole":0,"jawBoneBackSize":0,"noseBoneTwist":0,"nosePeakSize":0,"nosePeakLowering":0,"jawBoneWidth":0,"noseWidth":0,"chinBoneLenght":0,"cheeksWidth":0,"noseBoneHigh":0,"cheeksBoneWidth":0,"chinBoneLowering":0,"eyesOpening":0,"lipsThickness":0,"neckThickness":0,"cheeksBoneHigh":0,"nosePeakHigh":0,"chinBoneSize":0,"eyeBrownHigh":0,"eyeBrownForward":0},"tattoos":[],"headBlend":{"thirdMix":0,"skinMix":0,"shapeFirst":0,"skinFirst":0,"skinSecond":0,"skinThird":0,"shapeMix":0,"shapeThird":0,"shapeSecond":0},"hair":{"highlight":0,"color":0,"texture":0,"style":0},"model":"mp_m_freemode_01","eyeColor":-1,"components":[{"component_id":0,"drawable":0,"texture":0},{"component_id":1,"drawable":0,"texture":0},{"component_id":2,"drawable":0,"texture":0},{"component_id":3,"drawable":0,"texture":0},{"component_id":4,"drawable":0,"texture":0},{"component_id":5,"drawable":0,"texture":0},{"component_id":6,"drawable":0,"texture":0},{"component_id":7,"drawable":0,"texture":0},{"component_id":8,"drawable":0,"texture":0},{"component_id":9,"drawable":0,"texture":0},{"component_id":10,"drawable":0,"texture":0},{"component_id":11,"drawable":0,"texture":0}],"props":[{"prop_id":0,"drawable":-1,"texture":-1},{"prop_id":1,"drawable":-1,"texture":-1},{"prop_id":2,"drawable":-1,"texture":-1},{"prop_id":6,"drawable":-1,"texture":-1},{"prop_id":7,"drawable":-1,"texture":-1}]}', 7, 1, NULL, 3322, 0, '[]', '', 0, NULL, NULL, NULL, NULL, NULL, NULL),
	(4, '8d580e801963852f52c994e1670bf722827124624', '649-98-7405', '769922509071188029', '["license:8d580e801963852f52c994e1670bf72282712462","discord:769922509071188029","fivem:1960258","license2:8d580e801963852f52c994e1670bf72282712462","ip:192.168.56.1"]', '["3:b9dd434ecf8175821be56bcc1b6f9642dcd15cf384ffb1c1167ab787064bac0f","4:d467174102692f3cc70d70fbd3a2cc5ade1d8f3acae381c2a29e4e0ee331fc26","4:cd433230f982fb256fa706ea5280cdb70a0baf4769e67b89ce39f0a433443540","4:887f5c7b8303bcd04b366ac306e69fac28bf8378edddb30c78babee4346f8448","2:ddee567d069e28b0a4caf786b7cf06852186cd336b3da5dac20855816d1dbfb1","5:2910de86d36552a74ca0240576c47bc3b4ebf29c514f7bf142d2dc467b44e502"]', '2026-01-03 00:37:11', '2026-01-03 00:37:12', 'https://r2.fivemanage.com/jnFlnukrREoazOSLNY1VW/male.png', '{"money":200,"bank":50010,"black_money":0,"th_coin":0}', 'user', '[{"count":1,"name":"welcome_kit","slot":1},{"metadata":{"lastname":"Qakwsndsqkn","identifier":"8d580e801963852f52c994e1670bf722827124624","mugShot":"none","cardtype":"id_card","durability":1767803970,"sex":"m","degrade":7200,"badge":"none","isSv":true,"nationality":"Los Santos","firstname":"Asdknadkln","birthdate":"02/02/2002"},"count":1,"name":"id_card","slot":2},{"count":9,"name":"ems_medikit","slot":3},{"count":200,"name":"money","slot":4},{"metadata":{"degrade":4320,"durability":1767631941},"count":1,"name":"radio","slot":5}]', 'ambulance', 2, '[]', '{"armor":0,"health":200,"callsign":"NO CALLSIGN","status":{"thirst":88,"hunger":88,"stress":0},"jobDuty":true,"licenses":{"car":{"has":false,"label":"Car License","name":"car"},"boat":{"has":false,"label":"Boat License","name":"boat"},"therotical":{"has":false,"label":"Student Permit","name":"therotical"},"motorcycle":{"has":false,"label":"Motorcycle License","name":"motorcycle"},"weapon":{"has":false,"label":"Weapon License","name":"weapon"}},"disease":"none"}', '{"heading":252.28346252441407,"x":-1031.142822265625,"y":-2729.274658203125,"z":20.1640625}', 'Asdknadkln', 'Qakwsndsqkn', '02/02/2002', 'm', 200, '{"grade":{"name":"none","level":0},"label":"No Gang Affiliaton","name":"none","isboss":false}', '{"eyeColor":-1,"components":[{"texture":0,"component_id":0,"drawable":0},{"texture":0,"component_id":1,"drawable":0},{"texture":0,"component_id":2,"drawable":0},{"texture":0,"component_id":3,"drawable":0},{"texture":0,"component_id":4,"drawable":0},{"texture":0,"component_id":5,"drawable":0},{"texture":0,"component_id":6,"drawable":0},{"texture":0,"component_id":7,"drawable":0},{"texture":0,"component_id":8,"drawable":0},{"texture":0,"component_id":9,"drawable":0},{"texture":0,"component_id":10,"drawable":0},{"texture":0,"component_id":11,"drawable":0}],"faceFeatures":{"jawBoneBackSize":0,"cheeksWidth":0,"noseBoneHigh":0,"lipsThickness":0,"nosePeakHigh":0,"cheeksBoneWidth":0,"chinHole":0,"chinBoneLenght":0,"nosePeakLowering":0,"eyeBrownHigh":0,"noseBoneTwist":0,"nosePeakSize":0,"neckThickness":0,"eyeBrownForward":0,"eyesOpening":0,"noseWidth":0,"jawBoneWidth":0,"cheeksBoneHigh":0,"chinBoneSize":0,"chinBoneLowering":0},"tattoos":[],"headBlend":{"shapeSecond":0,"skinThird":0,"skinMix":0,"shapeMix":0,"skinSecond":0,"thirdMix":0,"skinFirst":0,"shapeFirst":0,"shapeThird":0},"props":[{"texture":-1,"prop_id":0,"drawable":-1},{"texture":-1,"prop_id":1,"drawable":-1},{"texture":-1,"prop_id":2,"drawable":-1},{"texture":-1,"prop_id":6,"drawable":-1},{"texture":-1,"prop_id":7,"drawable":-1}],"hair":{"texture":0,"highlight":0,"color":0,"style":0},"headOverlays":{"sunDamage":{"style":0,"color":0,"secondColor":0,"opacity":0},"makeUp":{"style":0,"color":0,"secondColor":0,"opacity":0},"eyebrows":{"style":0,"color":0,"secondColor":0,"opacity":0},"blush":{"style":0,"color":0,"secondColor":0,"opacity":0},"bodyBlemishes":{"style":0,"color":0,"secondColor":0,"opacity":0},"chestHair":{"style":0,"color":0,"secondColor":0,"opacity":0},"moleAndFreckles":{"style":0,"color":0,"secondColor":0,"opacity":0},"beard":{"style":0,"color":0,"secondColor":0,"opacity":0},"lipstick":{"style":0,"color":0,"secondColor":0,"opacity":0},"blemishes":{"style":0,"color":0,"secondColor":0,"opacity":0},"complexion":{"style":0,"color":0,"secondColor":0,"opacity":0},"ageing":{"style":0,"color":0,"secondColor":0,"opacity":0}},"model":"mp_m_freemode_01"}', 7, 0, NULL, 943, 0, '[]', '', 0, NULL, NULL, NULL, NULL, NULL, NULL);

-- Dumping structure for table cfx_cs_v3.vehicles
CREATE TABLE IF NOT EXISTS `vehicles` (
  `name` varchar(60) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `model` varchar(60) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `price` int(11) NOT NULL,
  `category` varchar(60) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`model`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table cfx_cs_v3.vehicles: ~294 rows (approximately)
INSERT INTO `vehicles` (`name`, `model`, `price`, `category`) VALUES
	('Adder', 'adder', 900000, 'super'),
	('Akuma', 'akuma', 7500, 'motorcycles'),
	('Alpha', 'alpha', 60000, 'sports'),
	('Ardent', 'ardent', 1150000, 'sportsclassics'),
	('Asea', 'asea', 5500, 'sedans'),
	('Autarch', 'autarch', 1955000, 'super'),
	('Avarus', 'avarus', 18000, 'motorcycles'),
	('Bagger', 'bagger', 13500, 'motorcycles'),
	('Baller', 'baller2', 40000, 'suvs'),
	('Baller Sport', 'baller3', 60000, 'suvs'),
	('Banshee', 'banshee', 70000, 'sports'),
	('Banshee 900R', 'banshee2', 255000, 'super'),
	('Bati 801', 'bati', 12000, 'motorcycles'),
	('Bati 801RR', 'bati2', 19000, 'motorcycles'),
	('Bestia GTS', 'bestiagts', 55000, 'sports'),
	('BF400', 'bf400', 6500, 'motorcycles'),
	('Bf Injection', 'bfinjection', 16000, 'offroad'),
	('Bifta', 'bifta', 12000, 'offroad'),
	('Bison', 'bison', 45000, 'vans'),
	('Blade', 'blade', 15000, 'muscle'),
	('Blazer', 'blazer', 6500, 'offroad'),
	('Blazer Sport', 'blazer4', 8500, 'offroad'),
	('blazer5', 'blazer5', 1755600, 'offroad'),
	('Blista', 'blista', 8000, 'compacts'),
	('BMX (velo)', 'bmx', 160, 'motorcycles'),
	('Bobcat XL', 'bobcatxl', 32000, 'vans'),
	('Brawler', 'brawler', 45000, 'offroad'),
	('Brioso R/A', 'brioso', 18000, 'compacts'),
	('Brioso 300 Widebody', 'brioso3', 25000, 'compacts'),
	('Btype', 'btype', 62000, 'sportsclassics'),
	('Btype Hotroad', 'btype2', 155000, 'sportsclassics'),
	('Btype Luxe', 'btype3', 85000, 'sportsclassics'),
	('Buccaneer', 'buccaneer', 18000, 'muscle'),
	('Buccaneer Rider', 'buccaneer2', 24000, 'muscle'),
	('Buffalo', 'buffalo', 12000, 'sports'),
	('Buffalo S', 'buffalo2', 20000, 'sports'),
	('Bullet', 'bullet', 90000, 'super'),
	('Burrito', 'burrito3', 19000, 'vans'),
	('Calico GTF', 'calico', 585000, 'sports'),
	('Camper', 'camper', 42000, 'vans'),
	('Caracara 4x4', 'caracara2', 632000, 'offroad'),
	('Carbonizzare', 'carbonizzare', 75000, 'sports'),
	('Carbon RS', 'carbonrs', 18000, 'motorcycles'),
	('Casco', 'casco', 30000, 'sportsclassics'),
	('Cavalcade', 'cavalcade2', 55000, 'suvs'),
	('Cheetah', 'cheetah', 375000, 'super'),
	('Chimera', 'chimera', 38000, 'motorcycles'),
	('Chino', 'chino', 15000, 'muscle'),
	('Chino Luxe', 'chino2', 19000, 'muscle'),
	('Cliffhanger', 'cliffhanger', 9500, 'motorcycles'),
	('Cognoscenti Cabrio', 'cogcabrio', 55000, 'coupes'),
	('Cognoscenti', 'cognoscenti', 55000, 'sedans'),
	('Comet', 'comet2', 65000, 'sports'),
	('Comet Retro Custom', 'comet3', 650000, 'sports'),
	('Comet Safari', 'comet4', 742000, 'sports'),
	('Comet SR', 'comet5', 850000, 'sports'),
	('Comet S2', 'comet6', 941000, 'sports'),
	('Comet S2 Cabrio', 'comet7', 1255000, 'sports'),
	('Contender', 'contender', 70000, 'suvs'),
	('Coquette', 'coquette', 65000, 'sports'),
	('Coquette Classic', 'coquette2', 40000, 'sportsclassics'),
	('Coquette BlackFin', 'coquette3', 55000, 'muscle'),
	('Cruiser (velo)', 'cruiser', 510, 'motorcycles'),
	('Cyclone', 'cyclone', 1890000, 'super'),
	('Cypher', 'cypher', 1300000, 'sports'),
	('Daemon', 'daemon', 11500, 'motorcycles'),
	('Daemon High', 'daemon2', 13500, 'motorcycles'),
	('Defiler', 'defiler', 9800, 'motorcycles'),
	('Deluxo', 'deluxo', 4721500, 'sportsclassics'),
	('Dominator', 'dominator', 35000, 'muscle'),
	('Dominator GTX', 'dominator3', 241000, 'muscle'),
	('Dominator ASP', 'dominator7', 1030000, 'muscle'),
	('Dominator GTT', 'dominator8', 1230000, 'muscle'),
	('Dominator GT', 'dominator9', 2140000, 'muscle'),
	('Double T', 'double', 28000, 'motorcycles'),
	('8F Drafter', 'drafter', 562000, 'sports'),
	('Draugur', 'draugur', 3650000, 'offroad'),
	('Dubsta', 'dubsta', 45000, 'suvs'),
	('Dubsta Luxuary', 'dubsta2', 60000, 'suvs'),
	('Bubsta 6x6', 'dubsta3', 120000, 'offroad'),
	('Dukes', 'dukes', 28000, 'muscle'),
	('Dune Buggy', 'dune', 8000, 'offroad'),
	('Elegy Retro Custom', 'elegy', 1500000, 'sports'),
	('Elegy RH8', 'elegy2', 38500, 'sports'),
	('Emperor', 'emperor', 8500, 'sedans'),
	('Enduro', 'enduro', 5500, 'motorcycles'),
	('Entity XXR', 'entity2', 625000, 'super'),
	('Entity MT', 'entity3', 825000, 'super'),
	('Entity XF', 'entityxf', 425000, 'super'),
	('Esskey', 'esskey', 4200, 'motorcycles'),
	('Euros', 'euros', 653200, 'sports'),
	('Hotring Everon', 'everon2', 412000, 'sports'),
	('Exemplar', 'exemplar', 32000, 'coupes'),
	('F620', 'f620', 40000, 'coupes'),
	('Faction', 'faction', 20000, 'muscle'),
	('Faction Rider', 'faction2', 30000, 'muscle'),
	('Faction XL', 'faction3', 40000, 'muscle'),
	('Faggio', 'faggio', 1900, 'motorcycles'),
	('Vespa', 'faggio2', 2800, 'motorcycles'),
	('Felon', 'felon', 42000, 'coupes'),
	('Felon GT', 'felon2', 55000, 'coupes'),
	('Feltzer', 'feltzer2', 55000, 'sports'),
	('Stirling GT', 'feltzer3', 65000, 'sportsclassics'),
	('Fixter (velo)', 'fixter', 225, 'motorcycles'),
	('FMJ', 'fmj', 185000, 'super'),
	('Fhantom', 'fq2', 17000, 'suvs'),
	('Fugitive', 'fugitive', 12000, 'sedans'),
	('Furore GT', 'furoregt', 45000, 'sports'),
	('Fusilade', 'fusilade', 40000, 'sports'),
	('Futo', 'futo', 361000, 'sports'),
	('Futo GTX', 'futo2', 796400, 'sports'),
	('Gargoyle', 'gargoyle', 16500, 'motorcycles'),
	('Gauntlet', 'gauntlet', 30000, 'muscle'),
	('Gauntlet Hellfire', 'gauntlet4', 996400, 'muscle'),
	('Gang Burrito', 'gburrito', 45000, 'vans'),
	('Burrito', 'gburrito2', 29000, 'vans'),
	('Glendale', 'glendale', 6500, 'sedans'),
	('Grabger', 'granger', 50000, 'suvs'),
	('Gresley', 'gresley', 47500, 'suvs'),
	('Growler', 'growler', 1525000, 'sports'),
	('GT 500', 'gt500', 785000, 'sportsclassics'),
	('Guardian', 'guardian', 45000, 'offroad'),
	('Hakuchou', 'hakuchou', 31000, 'motorcycles'),
	('Hakuchou Sport', 'hakuchou2', 55000, 'motorcycles'),
	('Hermes', 'hermes', 535000, 'muscle'),
	('Hexer', 'hexer', 12000, 'motorcycles'),
	('Hotknife', 'hotknife', 125000, 'muscle'),
	('Huntley S', 'huntley', 40000, 'suvs'),
	('Hustler', 'hustler', 625000, 'muscle'),
	('Infernus', 'infernus', 180000, 'super'),
	('Innovation', 'innovation', 23500, 'motorcycles'),
	('Intruder', 'intruder', 7500, 'sedans'),
	('Issi', 'issi2', 10000, 'compacts'),
	('Itali GTO', 'italigto', 1300000, 'sports'),
	('Itali RSX', 'italirsx', 2200000, 'sports'),
	('Jackal', 'jackal', 38000, 'coupes'),
	('Jester', 'jester', 65000, 'sports'),
	('Jester(Racecar)', 'jester2', 135000, 'sports'),
	('Jester Classic', 'jester3', 550000, 'sports'),
	('Jester RR', 'jester4', 856000, 'sports'),
	('Journey', 'journey', 6500, 'vans'),
	('Kamacho', 'kamacho', 345000, 'offroad'),
	('Blista Kanjo', 'kanjo', 475000, 'sports'),
	('Kanjo SJ', 'kanjosj', 652000, 'sports'),
	('Khamelion', 'khamelion', 38000, 'sports'),
	('Kuruma', 'kuruma', 30000, 'sports'),
	('Landstalker', 'landstalker', 35000, 'suvs'),
	('Landstalker XL', 'landstalker2', 652000, 'suvs'),
	('RE-7B', 'le7b', 325000, 'super'),
	('LM87', 'lm87', 1805620, 'super'),
	('Lynx', 'lynx', 40000, 'sports'),
	('Mamba', 'mamba', 70000, 'sports'),
	('Manana', 'manana', 12800, 'sportsclassics'),
	('Manchez', 'manchez', 5300, 'motorcycles'),
	('Massacro', 'massacro', 65000, 'sports'),
	('Massacro(Racecar)', 'massacro2', 130000, 'sports'),
	('Mesa', 'mesa', 16000, 'suvs'),
	('Mesa Trail', 'mesa3', 40000, 'suvs'),
	('Minivan', 'minivan', 13000, 'vans'),
	('Monroe', 'monroe', 55000, 'sportsclassics'),
	('The Liberator', 'monster', 210000, 'offroad'),
	('Moonbeam', 'moonbeam', 18000, 'vans'),
	('Moonbeam Rider', 'moonbeam2', 35000, 'vans'),
	('Nemesis', 'nemesis', 5800, 'motorcycles'),
	('Neon', 'neon', 1500000, 'sports'),
	('Nero', 'nero', 2355000, 'super'),
	('Nero Custom', 'nero2', 2855000, 'super'),
	('Nightblade', 'nightblade', 35000, 'motorcycles'),
	('Nightshade', 'nightshade', 65000, 'muscle'),
	('9F', 'ninef', 65000, 'sports'),
	('9F Cabrio', 'ninef2', 80000, 'sports'),
	('Novak', 'novak', 865000, 'suvs'),
	('Omnis', 'omnis', 35000, 'sports'),
	('Oracle XS', 'oracle2', 35000, 'coupes'),
	('Osiris', 'osiris', 160000, 'super'),
	('Panto', 'panto', 10000, 'compacts'),
	('Paradise', 'paradise', 19000, 'vans'),
	('Pariah', 'pariah', 1420000, 'sports'),
	('Patriot', 'patriot', 55000, 'suvs'),
	('PCJ-600', 'pcj', 6200, 'motorcycles'),
	('Penumbra', 'penumbra', 28000, 'sports'),
	('Pfister', 'pfister811', 85000, 'super'),
	('Phoenix', 'phoenix', 12500, 'muscle'),
	('Picador', 'picador', 18000, 'muscle'),
	('Pigalle', 'pigalle', 20000, 'sportsclassics'),
	('Postlude', 'postlude', 365222, 'coupes'),
	('Prairie', 'prairie', 12000, 'compacts'),
	('Premier', 'premier', 8000, 'sedans'),
	('Primo Custom', 'primo2', 14000, 'sedans'),
	('X80 Proto', 'prototipo', 2500000, 'super'),
	('Radius', 'radi', 29000, 'suvs'),
	('raiden', 'raiden', 1375000, 'sports'),
	('Rapid GT', 'rapidgt', 35000, 'sports'),
	('Rapid GT Convertible', 'rapidgt2', 45000, 'sports'),
	('Rapid GT3', 'rapidgt3', 885000, 'sportsclassics'),
	('Reaper', 'reaper', 150000, 'super'),
	('Rebel', 'rebel2', 35000, 'offroad'),
	('Rebla', 'rebla', 623100, 'suvs'),
	('Regina', 'regina', 5000, 'sedans'),
	('Remus', 'remus', 120000, 'sports'),
	('Retinue', 'retinue', 615000, 'sportsclassics'),
	('Revolter', 'revolter', 1610000, 'sports'),
	('Rhinehart', 'rhinehart', 212456, 'sedans'),
	('riata', 'riata', 380000, 'offroad'),
	('Rocoto', 'rocoto', 45000, 'suvs'),
	('RT3000', 'rt3000', 520000, 'sports'),
	('Ruffian', 'ruffian', 6800, 'motorcycles'),
	('Ruiner 2', 'ruiner2', 5745600, 'muscle'),
	('Rumpo', 'rumpo', 15000, 'vans'),
	('Rumpo Trail', 'rumpo3', 19500, 'vans'),
	('Sabre Turbo', 'sabregt', 20000, 'muscle'),
	('Sabre GT', 'sabregt2', 25000, 'muscle'),
	('Sanchez', 'sanchez', 5300, 'motorcycles'),
	('Sanchez Sport', 'sanchez2', 5300, 'motorcycles'),
	('Sanctus', 'sanctus', 25000, 'motorcycles'),
	('Sandking', 'sandking', 55000, 'offroad'),
	('Savestra', 'savestra', 990000, 'sportsclassics'),
	('SC 1', 'sc1', 1603000, 'super'),
	('Schafter', 'schafter2', 25000, 'sedans'),
	('Schafter V12', 'schafter3', 50000, 'sports'),
	('Scorcher (velo)', 'scorcher', 280, 'motorcycles'),
	('Seminole', 'seminole', 25000, 'suvs'),
	('Sentinel', 'sentinel', 32000, 'coupes'),
	('Sentinel XS', 'sentinel2', 40000, 'coupes'),
	('Sentinel3', 'sentinel3', 650000, 'sports'),
	('Sentinel Classic Widebody', 'sentinel4', 950000, 'sports'),
	('Seven 70', 'seven70', 39500, 'sports'),
	('ETR1', 'sheava', 220000, 'super'),
	('Shotaro Concept', 'shotaro', 320000, 'motorcycles'),
	('Slam Van', 'slamvan3', 11500, 'muscle'),
	('Sovereign', 'sovereign', 22000, 'motorcycles'),
	('Stinger', 'stinger', 80000, 'sportsclassics'),
	('Stinger GT', 'stingergt', 75000, 'sportsclassics'),
	('Itali GTO Stinger TT', 'stingertt', 3000000, 'sports'),
	('Streiter', 'streiter', 500000, 'sports'),
	('Stretch', 'stretch', 90000, 'sedans'),
	('Stromberg', 'stromberg', 3185350, 'sports'),
	('Sugoi', 'sugoi', 750000, 'sports'),
	('Sultan', 'sultan', 15000, 'sports'),
	('Sultan Classic', 'sultan2', 845621, 'sports'),
	('Sultan RS Classic', 'sultan3', 1105630, 'sports'),
	('Sultan RS', 'sultanrs', 65000, 'super'),
	('Super Diamond', 'superd', 130000, 'sedans'),
	('Surano', 'surano', 50000, 'sports'),
	('Surfer', 'surfer', 12000, 'vans'),
	('T20', 't20', 300000, 'super'),
	('Tailgater', 'tailgater', 30000, 'sedans'),
	('Tailgater S', 'tailgater2', 364500, 'sedans'),
	('Tampa', 'tampa', 16000, 'muscle'),
	('Drift Tampa', 'tampa2', 80000, 'sports'),
	('Tempesta', 'tempesta', 230000, 'super'),
	('10F', 'tenf', 1200000, 'sports'),
	('10F Widebody', 'tenf2', 1200000, 'sports'),
	('Thrust', 'thrust', 24000, 'motorcycles'),
	('Toros', 'toros', 475200, 'suvs'),
	('Tri bike (velo)', 'tribike3', 520, 'motorcycles'),
	('Trophy Truck', 'trophytruck', 60000, 'offroad'),
	('Trophy Truck Limited', 'trophytruck2', 80000, 'offroad'),
	('Tropos', 'tropos', 40000, 'sports'),
	('Turismo R', 'turismor', 350000, 'super'),
	('Tyrus', 'tyrus', 600000, 'super'),
	('Vacca', 'vacca', 120000, 'super'),
	('Vader', 'vader', 7200, 'motorcycles'),
	('Vectre', 'vectre', 900000, 'sports'),
	('Verlierer', 'verlierer2', 70000, 'sports'),
	('Vigero', 'vigero', 12500, 'muscle'),
	('Vigero ZX', 'vigero2', 842000, 'muscle'),
	('Vigero ZX Convertible', 'vigero3', 1000000, 'muscle'),
	('Virgo', 'virgo', 14000, 'muscle'),
	('Viseris', 'viseris', 875000, 'sportsclassics'),
	('Visione', 'visione', 2250000, 'super'),
	('Voltic', 'voltic', 90000, 'super'),
	('Voodoo', 'voodoo', 7200, 'muscle'),
	('Vortex', 'vortex', 9800, 'motorcycles'),
	('V-STR', 'vstr', 550000, 'sports'),
	('Warrener', 'warrener', 4000, 'sedans'),
	('Washington', 'washington', 9000, 'sedans'),
	('Weevil', 'weevil', 160000, 'compacts'),
	('Weevil Custom', 'weevil2', 630000, 'muscle'),
	('Windsor', 'windsor', 95000, 'coupes'),
	('Windsor Drop', 'windsor2', 125000, 'coupes'),
	('Woflsbane', 'wolfsbane', 9000, 'motorcycles'),
	('XLS', 'xls', 32000, 'suvs'),
	('Yosemite', 'yosemite', 485000, 'muscle'),
	('Youga', 'youga', 10800, 'vans'),
	('Youga Luxuary', 'youga2', 14500, 'vans'),
	('Z190', 'z190', 900000, 'sportsclassics'),
	('Zentorno', 'zentorno', 1500000, 'super'),
	('Zion', 'zion', 36000, 'coupes'),
	('Zion Cabrio', 'zion2', 45000, 'coupes'),
	('Zombie', 'zombiea', 9500, 'motorcycles'),
	('Zombie Luxuary', 'zombieb', 12000, 'motorcycles'),
	('ZR350', 'zr350', 1500000, 'sports'),
	('Z-Type', 'ztype', 220000, 'sportsclassics');

-- Dumping structure for table cfx_cs_v3.xt_prison
CREATE TABLE IF NOT EXISTS `xt_prison` (
  `identifier` varchar(100) NOT NULL,
  `jailtime` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`identifier`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table cfx_cs_v3.xt_prison: ~5 rows (approximately)
INSERT INTO `xt_prison` (`identifier`, `jailtime`) VALUES
	('8d580e801963852f52c994e1670bf72282712462', 0),
	('8d580e801963852f52c994e1670bf722827124621', 0),
	('8d580e801963852f52c994e1670bf722827124622', 0),
	('8d580e801963852f52c994e1670bf722827124623', 0),
	('8d580e801963852f52c994e1670bf722827124624', 0);

-- Dumping structure for table cfx_cs_v3.xt_prison_items
CREATE TABLE IF NOT EXISTS `xt_prison_items` (
  `owner` varchar(60) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `data` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  UNIQUE KEY `owner` (`owner`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table cfx_cs_v3.xt_prison_items: ~0 rows (approximately)

-- Dumping structure for table cfx_cs_v3.licenses
CREATE TABLE IF NOT EXISTS `licenses` (
  `type` varchar(60) NOT NULL,
  `label` varchar(60) NOT NULL,
  PRIMARY KEY (`type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table cfx_cs_v3.licenses: ~1 rows (approximately)
INSERT IGNORE INTO `licenses` (`type`, `label`) VALUES
	('weapon', 'Weapon License');

-- Dumping structure for table cfx_cs_v3.user_licenses
CREATE TABLE IF NOT EXISTS `user_licenses` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `type` varchar(60) NOT NULL,
  `owner` varchar(60) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `type` (`type`),
  KEY `owner` (`owner`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping structure for trigger cfx_cs_v3.gksphone_instagram_create_comment_notification
SET @OLDTMP_SQL_MODE=@@SQL_MODE, SQL_MODE='IGNORE_SPACE,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION';
DELIMITER //
CREATE TRIGGER `gksphone_instagram_create_comment_notification` AFTER INSERT ON `gksphone_instagram_comments` FOR EACH ROW BEGIN
                DECLARE post_owner_id BIGINT;
                SELECT user_id INTO post_owner_id FROM gksphone_instagram_posts WHERE post_id = NEW.post_id;
                IF post_owner_id != NEW.user_id THEN
                    INSERT INTO gksphone_instagram_notifications (user_id, actor_id, notification_type, post_id, comment_id)
                    VALUES (NEW.user_id, post_owner_id, 'comment', NEW.post_id, NEW.comment_id);
                END IF;
            END//
DELIMITER ;
SET SQL_MODE=@OLDTMP_SQL_MODE;

-- Dumping structure for trigger cfx_cs_v3.gksphone_instagram_create_like_notification
SET @OLDTMP_SQL_MODE=@@SQL_MODE, SQL_MODE='IGNORE_SPACE,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION';
DELIMITER //
CREATE TRIGGER `gksphone_instagram_create_like_notification` AFTER INSERT ON `gksphone_instagram_post_likes` FOR EACH ROW BEGIN
                DECLARE post_owner_id BIGINT;
                SELECT user_id INTO post_owner_id FROM gksphone_instagram_posts WHERE post_id = NEW.post_id;

                IF post_owner_id != NEW.user_id THEN
                    INSERT INTO gksphone_instagram_notifications (user_id, actor_id, notification_type, post_id)
                    VALUES (NEW.user_id, post_owner_id, 'like', NEW.post_id);
                END IF;
            END//
DELIMITER ;
SET SQL_MODE=@OLDTMP_SQL_MODE;

-- Dumping structure for trigger cfx_cs_v3.gksphone_instagram_update_comment_count
SET @OLDTMP_SQL_MODE=@@SQL_MODE, SQL_MODE='IGNORE_SPACE,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION';
DELIMITER //
CREATE TRIGGER `gksphone_instagram_update_comment_count` AFTER INSERT ON `gksphone_instagram_comments` FOR EACH ROW BEGIN
                UPDATE gksphone_instagram_posts SET comments_count = comments_count + 1 WHERE post_id = NEW.post_id;
            END//
DELIMITER ;
SET SQL_MODE=@OLDTMP_SQL_MODE;

-- Dumping structure for trigger cfx_cs_v3.gksphone_instagram_update_comment_count_delete
SET @OLDTMP_SQL_MODE=@@SQL_MODE, SQL_MODE='IGNORE_SPACE,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION';
DELIMITER //
CREATE TRIGGER `gksphone_instagram_update_comment_count_delete` AFTER DELETE ON `gksphone_instagram_comments` FOR EACH ROW BEGIN
                UPDATE gksphone_instagram_posts SET comments_count = comments_count - 1 WHERE post_id = OLD.post_id;
            END//
DELIMITER ;
SET SQL_MODE=@OLDTMP_SQL_MODE;

-- Dumping structure for trigger cfx_cs_v3.gksphone_instagram_update_comment_likes_count
SET @OLDTMP_SQL_MODE=@@SQL_MODE, SQL_MODE='IGNORE_SPACE,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION';
DELIMITER //
CREATE TRIGGER `gksphone_instagram_update_comment_likes_count` AFTER INSERT ON `gksphone_instagram_comment_likes` FOR EACH ROW BEGIN
                UPDATE gksphone_instagram_comments SET likes_count = likes_count + 1 WHERE comment_id = NEW.comment_id;
            END//
DELIMITER ;
SET SQL_MODE=@OLDTMP_SQL_MODE;

-- Dumping structure for trigger cfx_cs_v3.gksphone_instagram_update_comment_likes_count_delete
SET @OLDTMP_SQL_MODE=@@SQL_MODE, SQL_MODE='IGNORE_SPACE,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION';
DELIMITER //
CREATE TRIGGER `gksphone_instagram_update_comment_likes_count_delete` AFTER DELETE ON `gksphone_instagram_comment_likes` FOR EACH ROW BEGIN
                UPDATE gksphone_instagram_comments SET likes_count = likes_count - 1 WHERE comment_id = OLD.comment_id;
            END//
DELIMITER ;
SET SQL_MODE=@OLDTMP_SQL_MODE;

-- Dumping structure for trigger cfx_cs_v3.gksphone_instagram_update_follow_counts
SET @OLDTMP_SQL_MODE=@@SQL_MODE, SQL_MODE='IGNORE_SPACE,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION';
DELIMITER //
CREATE TRIGGER `gksphone_instagram_update_follow_counts` AFTER INSERT ON `gksphone_instagram_follows` FOR EACH ROW BEGIN
                IF NEW.is_accepted = TRUE THEN
                    UPDATE gksphone_instagram_users SET followers_count = followers_count + 1 WHERE user_id = NEW.following_id;
                    UPDATE gksphone_instagram_users SET following_count = following_count + 1 WHERE user_id = NEW.follower_id;
                    INSERT INTO gksphone_instagram_notifications (user_id, actor_id, notification_type) VALUES (NEW.follower_id, NEW.following_id, 'follow');
                END IF;
            END//
DELIMITER ;
SET SQL_MODE=@OLDTMP_SQL_MODE;

-- Dumping structure for trigger cfx_cs_v3.gksphone_instagram_update_follow_counts_delete
SET @OLDTMP_SQL_MODE=@@SQL_MODE, SQL_MODE='IGNORE_SPACE,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION';
DELIMITER //
CREATE TRIGGER `gksphone_instagram_update_follow_counts_delete` AFTER DELETE ON `gksphone_instagram_follows` FOR EACH ROW BEGIN
                IF OLD.is_accepted = TRUE THEN
                    UPDATE gksphone_instagram_users SET followers_count = followers_count - 1 WHERE user_id = OLD.following_id;
                    UPDATE gksphone_instagram_users SET following_count = following_count - 1 WHERE user_id = OLD.follower_id;
                END IF;
            END//
DELIMITER ;
SET SQL_MODE=@OLDTMP_SQL_MODE;

-- Dumping structure for trigger cfx_cs_v3.gksphone_instagram_update_follow_counts_update
SET @OLDTMP_SQL_MODE=@@SQL_MODE, SQL_MODE='IGNORE_SPACE,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION';
DELIMITER //
CREATE TRIGGER `gksphone_instagram_update_follow_counts_update` AFTER UPDATE ON `gksphone_instagram_follows` FOR EACH ROW BEGIN
                IF NEW.is_accepted = TRUE THEN
                    UPDATE gksphone_instagram_users SET followers_count = followers_count + 1 WHERE user_id = NEW.following_id;
                    UPDATE gksphone_instagram_users SET following_count = following_count + 1 WHERE user_id = NEW.follower_id;
                    INSERT INTO gksphone_instagram_notifications (user_id, actor_id, notification_type) VALUES (NEW.follower_id, NEW.following_id, 'follow');
                END IF;
            END//
DELIMITER ;
SET SQL_MODE=@OLDTMP_SQL_MODE;

-- Dumping structure for trigger cfx_cs_v3.gksphone_instagram_update_posts_count
SET @OLDTMP_SQL_MODE=@@SQL_MODE, SQL_MODE='IGNORE_SPACE,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION';
DELIMITER //
CREATE TRIGGER `gksphone_instagram_update_posts_count` AFTER INSERT ON `gksphone_instagram_posts` FOR EACH ROW BEGIN
                UPDATE gksphone_instagram_users SET posts_count = posts_count + 1 WHERE user_id = NEW.user_id;
            END//
DELIMITER ;
SET SQL_MODE=@OLDTMP_SQL_MODE;

-- Dumping structure for trigger cfx_cs_v3.gksphone_instagram_update_posts_count_delete
SET @OLDTMP_SQL_MODE=@@SQL_MODE, SQL_MODE='IGNORE_SPACE,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION';
DELIMITER //
CREATE TRIGGER `gksphone_instagram_update_posts_count_delete` AFTER DELETE ON `gksphone_instagram_posts` FOR EACH ROW BEGIN
                UPDATE gksphone_instagram_users SET posts_count = posts_count - 1 WHERE user_id = OLD.user_id;
            END//
DELIMITER ;
SET SQL_MODE=@OLDTMP_SQL_MODE;

-- Dumping structure for trigger cfx_cs_v3.gksphone_instagram_update_post_likes_count
SET @OLDTMP_SQL_MODE=@@SQL_MODE, SQL_MODE='IGNORE_SPACE,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION';
DELIMITER //
CREATE TRIGGER `gksphone_instagram_update_post_likes_count` AFTER INSERT ON `gksphone_instagram_post_likes` FOR EACH ROW BEGIN
                UPDATE gksphone_instagram_posts SET likes_count = likes_count + 1 WHERE post_id = NEW.post_id;
            END//
DELIMITER ;
SET SQL_MODE=@OLDTMP_SQL_MODE;

-- Dumping structure for trigger cfx_cs_v3.gksphone_instagram_update_post_likes_count_delete
SET @OLDTMP_SQL_MODE=@@SQL_MODE, SQL_MODE='IGNORE_SPACE,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION';
DELIMITER //
CREATE TRIGGER `gksphone_instagram_update_post_likes_count_delete` AFTER DELETE ON `gksphone_instagram_post_likes` FOR EACH ROW BEGIN
                UPDATE gksphone_instagram_posts SET likes_count = likes_count - 1 WHERE post_id = OLD.post_id;
            END//
DELIMITER ;
SET SQL_MODE=@OLDTMP_SQL_MODE;

-- Removing temporary table and create final VIEW structure
DROP TABLE IF EXISTS `gksphone_instagram_active_stories_v2`;
CREATE ALGORITHM=UNDEFINED SQL SECURITY DEFINER VIEW `gksphone_instagram_active_stories_v2` AS SELECT 
                s.story_id,
                s.user_id,
                s.media_url,
                s.media_type,
                s.created_at,
                s.expires_at,
                u.username,
                u.profile_picture_url,
                u.is_verified,
                TIMESTAMPDIFF(HOUR, s.created_at, NOW()) as hours_ago,
                TIMESTAMPDIFF(MINUTE, s.created_at, NOW()) as minutes_ago
            FROM  gksphone_instagram_stories s
            JOIN  gksphone_instagram_users u ON s.user_id = u.user_id
            WHERE s.expires_at > NOW() 
            AND u.is_active = TRUE
            ORDER BY s.created_at ASC ;

-- Removing temporary table and create final VIEW structure
DROP TABLE IF EXISTS `gksphone_instagram_conversations_v1`;
CREATE ALGORITHM=UNDEFINED SQL SECURITY DEFINER VIEW `gksphone_instagram_conversations_v1` AS SELECT 
                c.conversation_id,
                c.created_by,
                c.updated_at,
                cp.user_id as participant_id,
                u2.user_id as other_user_id,
                u2.username as other_username,
                u2.profile_picture_url as other_profile_picture,
                u2.is_verified as other_is_verified,
                m.message_text as last_message,
                m.message_type as last_message_type,
                m.created_at as last_message_time,
                m.sender_id as last_message_sender_id,
                u3.username as last_message_sender_username,
                COUNT(CASE 
                    WHEN m2.is_read = FALSE 
                    AND m2.sender_id != cp.user_id 
                    AND (cp.messages_deleted_at IS NULL OR m2.created_at > cp.messages_deleted_at)
                    THEN 1 
                END) as unread_count
            FROM gksphone_instagram_conversations c
            JOIN gksphone_instagram_conversation_participants cp ON c.conversation_id = cp.conversation_id
            LEFT JOIN gksphone_instagram_conversation_participants cp2 ON c.conversation_id = cp2.conversation_id 
                AND cp2.user_id != cp.user_id
            LEFT JOIN gksphone_instagram_users u2 ON cp2.user_id = u2.user_id 
                AND u2.is_active = TRUE
            LEFT JOIN gksphone_instagram_messages m ON c.conversation_id = m.conversation_id 
                AND (cp.messages_deleted_at IS NULL OR m.created_at > cp.messages_deleted_at)
                AND m.message_id = (
                    SELECT MAX(message_id) 
                    FROM gksphone_instagram_messages 
                    WHERE conversation_id = c.conversation_id
                    AND (cp.messages_deleted_at IS NULL OR created_at > cp.messages_deleted_at)
                )
            LEFT JOIN gksphone_instagram_users u3 ON m.sender_id = u3.user_id
            LEFT JOIN gksphone_instagram_messages m2 ON c.conversation_id = m2.conversation_id
            WHERE cp.user_id IS NOT NULL
                AND u2.user_id IS NOT NULL
                AND (cp.messages_deleted_at IS NULL OR m.message_id IS NOT NULL)
            GROUP BY c.conversation_id, cp.user_id, u2.user_id, m.message_id ;

/*!40103 SET TIME_ZONE=IFNULL(@OLD_TIME_ZONE, 'system') */;
/*!40101 SET SQL_MODE=IFNULL(@OLD_SQL_MODE, '') */;
/*!40014 SET FOREIGN_KEY_CHECKS=IFNULL(@OLD_FOREIGN_KEY_CHECKS, 1) */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40111 SET SQL_NOTES=IFNULL(@OLD_SQL_NOTES, 1) */;

-- ================================
-- KODEBYKARL-UI TABLES
-- ================================

-- Source: resources/[CFX-CS-Standalone]/kodebykarl-ui/Module/cfx-keydi-invoice/sql/keydi_invoices.sql
CREATE TABLE IF NOT EXISTS `keydi_invoices` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `reference` VARCHAR(16) NOT NULL,
    `kind` VARCHAR(16) NOT NULL DEFAULT 'personal',
    `invoice_type` VARCHAR(64) NOT NULL DEFAULT 'Personal',
    `title` VARCHAR(80) NOT NULL,
    `description` VARCHAR(255) DEFAULT NULL,
    `amount` INT NOT NULL DEFAULT 0,
    `vat` INT NOT NULL DEFAULT 0,
    `total` INT NOT NULL DEFAULT 0,
    `due_date` VARCHAR(32) DEFAULT NULL,
    `sender_identifier` VARCHAR(64) NOT NULL,
    `sender_name` VARCHAR(80) NOT NULL,
    `sender_job` VARCHAR(50) DEFAULT NULL,
    `receiver_identifier` VARCHAR(64) NOT NULL,
    `receiver_name` VARCHAR(80) NOT NULL,
    `status` VARCHAR(16) NOT NULL DEFAULT 'unpaid',
    `payment_method` VARCHAR(16) DEFAULT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `paid_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `reference` (`reference`),
    KEY `receiver_identifier` (`receiver_identifier`),
    KEY `sender_identifier` (`sender_identifier`),
    KEY `status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- Source: resources/[CFX-CS-Standalone]/kodebykarl-ui/Module/cfx-keydi-ipad/sql/install.sql
CREATE TABLE IF NOT EXISTS `grim_parties` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `name` VARCHAR(32) NOT NULL,
    `leader_identifier` VARCHAR(72) NOT NULL,
    `password` VARCHAR(32) DEFAULT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_grim_parties_leader` (`leader_identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `grim_party_members` (
    `party_id` INT NOT NULL,
    `identifier` VARCHAR(72) NOT NULL,
    `name` VARCHAR(64) NOT NULL DEFAULT '',
    `is_leader` TINYINT(1) NOT NULL DEFAULT 0,
    `joined_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`identifier`),
    INDEX `idx_grim_party_members_party` (`party_id`),
    CONSTRAINT `fk_grim_party_members_party`
        FOREIGN KEY (`party_id`) REFERENCES `grim_parties` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `grim_lb_turfwar` (
    `gang_name` VARCHAR(64) NOT NULL,
    `gang_label` VARCHAR(96) NOT NULL DEFAULT '',
    `claims` INT NOT NULL DEFAULT 0,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`gang_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `grim_lb_traphouse` (
    `identifier` VARCHAR(72) NOT NULL,
    `name` VARCHAR(96) NOT NULL DEFAULT '',
    `kills` INT NOT NULL DEFAULT 0,
    `deaths` INT NOT NULL DEFAULT 0,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `grim_lb_party` (
    `party_id` INT NOT NULL,
    `party_name` VARCHAR(64) NOT NULL DEFAULT '',
    `kills` INT NOT NULL DEFAULT 0,
    `deaths` INT NOT NULL DEFAULT 0,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`party_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `grim_lb_players` (
    `identifier` VARCHAR(72) NOT NULL,
    `name` VARCHAR(96) NOT NULL DEFAULT '',
    `kills` INT NOT NULL DEFAULT 0,
    `deaths` INT NOT NULL DEFAULT 0,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- Source: resources/[CFX-CS-Standalone]/kodebykarl-ui/Module/cfx-keydi-playtimeshop/sql/install.sql
CREATE TABLE IF NOT EXISTS `grim_playtime_coins` (
    `identifier` VARCHAR(60) NOT NULL,
    `coins` INT NOT NULL DEFAULT 0,
    `total_earned` INT NOT NULL DEFAULT 0,
    `progress_seconds` INT NOT NULL DEFAULT 0,
    `player_name` VARCHAR(80) DEFAULT NULL,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`identifier`),
    KEY `coins` (`coins`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- Source: resources/[CFX-CS-Standalone]/kodebykarl-ui/Module/cfx-keydi-university/sql/install.sql
CREATE TABLE IF NOT EXISTS `university_applications` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `identifier` VARCHAR(72) NOT NULL,
  `citizen_name` VARCHAR(128) NOT NULL DEFAULT '',
  `program_id` VARCHAR(32) NOT NULL,
  `program_code` VARCHAR(16) NOT NULL,
  `program_label` VARCHAR(128) NOT NULL,
  `status` ENUM('pending','approved','denied','cancelled') NOT NULL DEFAULT 'pending',
  `reviewed_by` VARCHAR(72) DEFAULT NULL,
  `reviewed_name` VARCHAR(128) DEFAULT NULL,
  `note` VARCHAR(255) DEFAULT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_university_apps_identifier` (`identifier`),
  KEY `idx_university_apps_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- Source: resources/[CFX-CS-Standalone]/kodebykarl-ui/Module/cfx-keydi-vip/sql/install.sql
CREATE TABLE IF NOT EXISTS `grim_vip` (
    `identifier` VARCHAR(72) NOT NULL,
    `tier` VARCHAR(16) NOT NULL DEFAULT 'vip1',
    `label` VARCHAR(64) DEFAULT NULL,
    `started_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `expires_at` TIMESTAMP NOT NULL,
    `auto_renew` TINYINT(1) NOT NULL DEFAULT 0,
    `granted_by` VARCHAR(64) DEFAULT NULL,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`identifier`),
    INDEX `idx_grim_vip_expires` (`expires_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

