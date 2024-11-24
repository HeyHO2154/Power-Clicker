DROP DATABASE IF EXISTS hsj;
CREATE DATABASE hsj;

USE hsj;

CREATE TABLE users (
	id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    user_id VARCHAR(255) NOT NULL,
    point INT DEFAULT 0
);

SET SQL_SAFE_UPDATES = 0;
DELETE FROM users;
SET SQL_SAFE_UPDATES = 1;

INSERT INTO users (user_id, point) VALUES ('BOT1', 10);
INSERT INTO users (user_id, point) VALUES ('BOT2', 20);
INSERT INTO users (user_id, point) VALUES ('BOT3', 30);
INSERT INTO users (user_id, point) VALUES ('BOT4', 40);
INSERT INTO users (user_id, point) VALUES ('BOT5', 50);
INSERT INTO users (user_id, point) VALUES ('BOT6', 60);
INSERT INTO users (user_id, point) VALUES ('BOT7', 70);
INSERT INTO users (user_id, point) VALUES ('BOT8', 80);
INSERT INTO users (user_id, point) VALUES ('BOT9', 90);
INSERT INTO users (user_id, point) VALUES ('BOT10', 100);
INSERT INTO users (user_id, point) VALUES ('BOT11', 110);
INSERT INTO users (user_id, point) VALUES ('BOT12', 120);
INSERT INTO users (user_id, point) VALUES ('BOT13', 130);
INSERT INTO users (user_id, point) VALUES ('BOT14', 140);
INSERT INTO users (user_id, point) VALUES ('BOT15', 150);
INSERT INTO users (user_id, point) VALUES ('BOT16', 160);
INSERT INTO users (user_id, point) VALUES ('BOT17', 170);
INSERT INTO users (user_id, point) VALUES ('BOT18', 180);
INSERT INTO users (user_id, point) VALUES ('BOT19', 190);
INSERT INTO users (user_id, point) VALUES ('BOT20', 200);
INSERT INTO users (user_id, point) VALUES ('BOT21', 210);
INSERT INTO users (user_id, point) VALUES ('BOT22', 220);
INSERT INTO users (user_id, point) VALUES ('BOT23', 230);
INSERT INTO users (user_id, point) VALUES ('BOT24', 240);
INSERT INTO users (user_id, point) VALUES ('BOT25', 250);
INSERT INTO users (user_id, point) VALUES ('BOT26', 260);
INSERT INTO users (user_id, point) VALUES ('BOT27', 270);
INSERT INTO users (user_id, point) VALUES ('BOT28', 280);
INSERT INTO users (user_id, point) VALUES ('BOT29', 290);
INSERT INTO users (user_id, point) VALUES ('BOT30', 300);
INSERT INTO users (user_id, point) VALUES ('BOT31', 310);
INSERT INTO users (user_id, point) VALUES ('BOT32', 320);
INSERT INTO users (user_id, point) VALUES ('BOT33', 330);
INSERT INTO users (user_id, point) VALUES ('BOT34', 340);
INSERT INTO users (user_id, point) VALUES ('BOT35', 350);
INSERT INTO users (user_id, point) VALUES ('BOT36', 360);
INSERT INTO users (user_id, point) VALUES ('BOT37', 370);
INSERT INTO users (user_id, point) VALUES ('BOT38', 380);
INSERT INTO users (user_id, point) VALUES ('BOT39', 390);
INSERT INTO users (user_id, point) VALUES ('BOT40', 400);
INSERT INTO users (user_id, point) VALUES ('BOT41', 410);
INSERT INTO users (user_id, point) VALUES ('BOT42', 420);
INSERT INTO users (user_id, point) VALUES ('BOT43', 430);
INSERT INTO users (user_id, point) VALUES ('BOT44', 440);
INSERT INTO users (user_id, point) VALUES ('BOT45', 450);
INSERT INTO users (user_id, point) VALUES ('BOT46', 460);
INSERT INTO users (user_id, point) VALUES ('BOT47', 470);
INSERT INTO users (user_id, point) VALUES ('BOT48', 480);
INSERT INTO users (user_id, point) VALUES ('BOT49', 490);
INSERT INTO users (user_id, point) VALUES ('BOT50', 500);
INSERT INTO users (user_id, point) VALUES ('BOT51', 510);
INSERT INTO users (user_id, point) VALUES ('BOT52', 520);
INSERT INTO users (user_id, point) VALUES ('BOT53', 530);
INSERT INTO users (user_id, point) VALUES ('BOT54', 540);
INSERT INTO users (user_id, point) VALUES ('BOT55', 550);
INSERT INTO users (user_id, point) VALUES ('BOT56', 560);
INSERT INTO users (user_id, point) VALUES ('BOT57', 570);
INSERT INTO users (user_id, point) VALUES ('BOT58', 580);
INSERT INTO users (user_id, point) VALUES ('BOT59', 590);
INSERT INTO users (user_id, point) VALUES ('BOT60', 600);


SELECT * FROM users;

#SET SQL_SAFE_UPDATES = 0;
#UPDATE users SET point = 0 WHERE id = 1;
#SET SQL_SAFE_UPDATES = 1;

