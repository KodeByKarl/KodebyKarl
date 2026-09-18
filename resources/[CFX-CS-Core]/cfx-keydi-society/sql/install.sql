CREATE TABLE IF NOT EXISTS `cfx_society_accounts` (
    `name` VARCHAR(64) NOT NULL,
    `label` VARCHAR(64) NOT NULL,
    `balance` BIGINT NOT NULL DEFAULT 0,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `cfx_society_ledger` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `account` VARCHAR(64) NOT NULL,
    `action` VARCHAR(16) NOT NULL,
    `amount` BIGINT NOT NULL,
    `balance_after` BIGINT NOT NULL,
    `identifier` VARCHAR(64) DEFAULT NULL,
    `note` VARCHAR(255) DEFAULT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `account` (`account`),
    KEY `created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
