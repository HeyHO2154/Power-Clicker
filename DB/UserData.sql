DROP DATABASE IF EXISTS hsj;
CREATE DATABASE hsj;

USE hsj;

DROP TABLE IF EXISTS users;
CREATE TABLE users (
	id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    user_id VARCHAR(255) NOT NULL,
    point INT DEFAULT 0
);

DELETE FROM users;
INSERT INTO users (user_id, point) VALUES ('test', 1000);
INSERT INTO users (user_id, point) VALUES ('asdasd', 100);
INSERT INTO users (user_id, point) VALUES ('fas', 200);
INSERT INTO users (user_id, point) VALUES ('gdssdd', 150);
INSERT INTO users (user_id, point) VALUES ('tesawst', 300);
INSERT INTO users (user_id, point) VALUES ('1234', 424);
INSERT INTO users (user_id, point) VALUES ('sssd', 511);
SELECT * FROM users;
UPDATE users SET point = 0 WHERE id = '7';
