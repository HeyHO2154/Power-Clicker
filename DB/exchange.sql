USE hsj;

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

