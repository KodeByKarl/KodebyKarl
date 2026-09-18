ALTER TABLE `users` ADD COLUMN IF NOT EXISTS `avatar` LONGTEXT NOT NULL DEFAULT 'https://r2.fivemanage.com/jnFlnukrREoazOSLNY1VW/male.png';
ALTER TABLE `users` ADD COLUMN IF NOT EXISTS `playtime` INT(10) NOT NULL DEFAULT 0;
ALTER TABLE `users` MODIFY COLUMN `gang` LONGTEXT NULL;

UPDATE `users`
SET `gang` = CONCAT(
  '{"name":"', IF(`gang` IS NULL OR `gang` = '' OR `gang` = 'none', 'none', `gang`),
  '","label":"', IF(`gang` IS NULL OR `gang` = '' OR `gang` = 'none', 'No Gang', `gang`),
  '","isboss":false,"grade":{"name":"', IF(COALESCE(`gang_grade`, 0) = 0, 'Member', 'Rank'),
  '","level":', COALESCE(`gang_grade`, 0), '}}'
)
WHERE `gang` IS NULL OR `gang` = '' OR `gang` NOT LIKE '{%';

SELECT COUNT(*) AS total, SUM(`gang` LIKE '{%') AS json_gangs FROM `users`;
SHOW COLUMNS FROM `users` WHERE Field IN ('avatar', 'playtime', 'gang');
