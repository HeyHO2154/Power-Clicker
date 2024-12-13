DROP DATABASE IF EXISTS hsj;
CREATE DATABASE hsj;

USE hsj;

CREATE TABLE users (
    user_id VARCHAR(255) NOT NULL PRIMARY KEY,
    user_pw VARCHAR(255) NOT NULL,
    user_name VARCHAR(255) NOT NULL,
    points INT DEFAULT 1000,
    exp_level INT DEFAULT 0,
    exp_rank INT DEFAULT 0,
	login_first TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    login_recent TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

#테마 테이블
CREATE TABLE theme (
    id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    user_id VARCHAR(255) NOT NULL,
    theme_name VARCHAR(255) NOT NULL,
    theme_check BOOL DEFAULT true,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

#아이템 테이블
CREATE TABLE item (
	id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    user_id VARCHAR(255) NOT NULL,
    item_name VARCHAR(255) NOT NULL,
    item_num INT DEFAULT 0,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

#테스트 유저 추가
INSERT INTO users (user_id, user_pw, user_name, points, exp_level, exp_rank) VALUES ('test','google0380','testName',99999,99999,99999);

#전체 조회(JOIN 사용)
SELECT * FROM users
LEFT JOIN theme ON users.user_id = theme.user_id
LEFT JOIN item ON users.user_id = item.user_id;
UPDATE users SET points = 123456 WHERE user_id = 'as';


