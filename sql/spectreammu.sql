-- Seed spectreammu job
INSERT INTO `jobs` (`name`, `label`, `type`, `whitelisted`) VALUES
('spectreammu', 'Spectre Ammu', 'civ', 0);

-- Seed spectreammu job grades (0 = Trainee, 1 = Employee, 2 = Manager, 3 = Boss)
INSERT INTO `job_grades` (`job_name`, `grade`, `name`, `label`, `salary`, `skin_male`, `skin_female`) VALUES
('spectreammu', 0, 'trainee', 'Trainee', 0, '{}', '{}'),
('spectreammu', 1, 'employee', 'Employee', 0, '{}', '{}'),
('spectreammu', 2, 'manager', 'Manager', 0, '{}', '{}'),
('spectreammu', 3, 'boss', 'Boss', 0, '{}', '{}');

-- Seed society account for spectreammu
INSERT INTO `cfx_society_accounts` (`name`, `label`, `balance`) VALUES
('society_spectreammu', 'Spectre Ammu', 0);
