DROP DATABASE IF EXISTS hsj;
CREATE DATABASE hsj;

USE hsj;

CREATE TABLE users (
    user_id VARCHAR(255) NOT NULL PRIMARY KEY,
    user_pw VARCHAR(255) NOT NULL,
    user_name VARCHAR(255) NOT NULL,
    points INT DEFAULT 0,
    exp_level INT DEFAULT 0,
    exp_rank INT DEFAULT 0,
	login_first TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    login_recent TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE attack (
    victim_id VARCHAR(255) NOT NULL UNIQUE PRIMARY KEY,
    attacker VARCHAR(255) NOT NULL,
    points INT DEFAULT 0,
    message VARCHAR(255),
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

#이거 밑에 아이템이랑 테마, 각각 별도의 테이블 만들어서 각 테마와 아이템 종류마다 고유 아이디 부여하고
#중간 테이블로 유저와 해당 테마 또는 아이템 테이블을 이어줘야 테마나 아이템 중에 하나 지워질때 ON DELETE CASCADE로
#한꺼번에 보유자들의 해당 아이템 또는 테마 데이터 삭제 가능

#매주 랜덤하게 테마 1개 판매
CREATE TABLE theme (
    user_id VARCHAR(255) NOT NULL UNIQUE PRIMARY KEY,
    defaults BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);
#새로 추가는 아래 작성하면 됨(지우는건 DROP)
ALTER TABLE theme
ADD COLUMN christmas BOOLEAN DEFAULT FALSE,
ADD COLUMN forest_friends BOOLEAN DEFAULT FALSE,
ADD COLUMN zombies BOOLEAN DEFAULT FALSE;
#ADD COLUMN irobots BOOLEAN DEFAULT FALSE; <- 추후 누가 잠입한 AI인지의 컨셉 테마 추가

#매일 3개씩 아이템 랜덤 판매, 게임에서 아이템 자동 사용(0개 될때까지)
CREATE TABLE item (
    user_id VARCHAR(255) NOT NULL UNIQUE PRIMARY KEY,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);
#새로 추가는 아래 작성하면 됨(지우는건 DROP)
ALTER TABLE item
ADD COLUMN judge_baton INT DEFAULT 0, #2표 행사
ADD COLUMN political_speach INT DEFAULT 0, #재판으로 처형 회피(25%)
ADD COLUMN bulletproof INT DEFAULT 0; #마피아 공격 1회 생존(25%)

#ADD COLUMN bribed_vote INT DEFAULT 0, #4표 행사
#ADD COLUMN tear_of_truth INT DEFAULT 0, #재판으로 처형 회피(50%)
#ADD COLUMN counter_strike INT DEFAULT 0; #마피아 공격 1회 생존(50%)

#AI 성격과 공론화를 볼 수 있는 아이템?

#회원가입할때 users에 추가하면서 동시에 theme과 item에도 추가시켜줘야함(그래야 자동으로 연결돼서, 삭제시 한꺼번에 삭제해줌)
INSERT INTO users (user_id, user_pw, user_name) VALUES ('test', '1234', 'test');
INSERT INTO theme (user_id) VALUES ('test');
INSERT INTO item (user_id) VALUES ('test');

#전체 조회(JOIN 사용)
SELECT * FROM users
LEFT JOIN theme ON users.user_id = theme.user_id
LEFT JOIN item ON users.user_id = item.user_id;
UPDATE users SET points = 899 WHERE user_id = 'adad';


