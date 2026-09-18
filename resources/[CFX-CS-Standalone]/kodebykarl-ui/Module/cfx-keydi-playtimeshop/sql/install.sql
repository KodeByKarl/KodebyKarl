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
