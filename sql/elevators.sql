CREATE TABLE IF NOT EXISTS `jorge_elevators` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `name` VARCHAR(100) NOT NULL,
    `interact_type` VARCHAR(20) NOT NULL DEFAULT 'marker',
    `marker_type` INT NOT NULL DEFAULT 20,
    `marker_color` VARCHAR(30) DEFAULT '100,100,255,100',
    `created_by` VARCHAR(60) DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS `jorge_elevator_floors` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `elevator_id` INT NOT NULL,
    `floor_index` INT NOT NULL DEFAULT 0,
    `label` VARCHAR(100) NOT NULL,
    `x` FLOAT NOT NULL,
    `y` FLOAT NOT NULL,
    `z` FLOAT NOT NULL,
    `heading` FLOAT NOT NULL DEFAULT 0.0,
    `restricted_job` VARCHAR(60) DEFAULT NULL,
    `restricted_grade` INT DEFAULT NULL,
    FOREIGN KEY (`elevator_id`) REFERENCES `jorge_elevators`(`id`) ON DELETE CASCADE
);
