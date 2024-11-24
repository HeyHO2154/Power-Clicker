DROP DATABASE IF EXISTS hsj;
CREATE DATABASE hsj;

USE hsj;

CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_name VARCHAR(255) NOT NULL UNIQUE,
    points INT DEFAULT 0,
    exp_level INT DEFAULT 0,
    exp_rank INT DEFAULT 0,
    login_first TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    login_recent TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE theme (
    id INT AUTO_INCREMENT PRIMARY KEY,
    theme_name VARCHAR(255) NOT NULL
);
INSERT INTO theme (theme_name) VALUES ('크리스마스');
INSERT INTO theme (theme_name) VALUES ('숲 속 친구들');

CREATE TABLE item (
    id INT AUTO_INCREMENT PRIMARY KEY,
    item_name VARCHAR(255) NOT NULL
);
INSERT INTO item (item_name) VALUES ('방망이');

CREATE TABLE user_theme (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    theme_id INT NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (theme_id) REFERENCES theme(id) ON DELETE CASCADE
);

CREATE TABLE user_item (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    item_id INT NOT NULL,
    count INT DEFAULT 0,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (item_id) REFERENCES item(id) ON DELETE CASCADE
);

INSERT INTO users (user_name) VALUES ('test');
#UPDATE users SET point = 1094 WHERE id = '3';
