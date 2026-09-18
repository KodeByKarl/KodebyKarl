-- =============================================================================
-- kodebykarl-projectcars  |  Database install
-- =============================================================================
-- Import this file in HeidiSQL / phpMyAdmin / mysql CLI, OR skip it —
-- the resource also creates the table automatically on first start.
--
--   mysql -u root -p your_database < install/sql/install.sql
-- =============================================================================

CREATE TABLE IF NOT EXISTS `kodebykarl_projectcars` (
    `plate` varchar(12) NOT NULL,
    `owner` varchar(60) NOT NULL,
    `model` varchar(50) NOT NULL,
    `coord` longtext NOT NULL,
    `status` longtext NOT NULL,
    `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
    PRIMARY KEY (`plate`),
    KEY `owner` (`owner`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
