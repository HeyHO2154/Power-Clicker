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
INSERT INTO users (user_id, point) VALUES ('ts2t', 1000);
INSERT INTO users (user_id, point) VALUES ('as2asd', 100);
INSERT INTO users (user_id, point) VALUES ('f2s', 200);
INSERT INTO users (user_id, point) VALUES ('g2dsdd', 150);
INSERT INTO users (user_id, point) VALUES ('te2awst', 300);
INSERT INTO users (user_id, point) VALUES ('1324', 424);
INSERT INTO users (user_id, point) VALUES ('s2ss', 999511);
SELECT * FROM users;
UPDATE users SET point = 0 WHERE user_id = 'Gabin';
