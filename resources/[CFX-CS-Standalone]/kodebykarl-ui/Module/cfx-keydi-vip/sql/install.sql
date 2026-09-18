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
