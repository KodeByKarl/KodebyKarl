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
