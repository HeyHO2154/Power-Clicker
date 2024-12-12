package Main.User;

import java.time.LocalDateTime;

import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

@Entity
@Table(name = "users") // MySQL에서 users 테이블과 매핑
public class User {

    @Id
    private String user_id;
	private String user_pw;
	private String user_name;
	private int points = 1000; //기본 천포인트
    private int exp_level;
    private int exp_rank;
    private LocalDateTime login_first;
    private LocalDateTime login_recent;
    
	public String getUser_id() {
		return user_id;
	}
	public void setUser_id(String user_id) {
		this.user_id = user_id;
	}
	public String getUser_pw() {
		return user_pw;
	}
	public void setUser_pw(String user_pw) {
		this.user_pw = user_pw;
	}
	public String getUser_name() {
		return user_name;
	}
	public void setUser_name(String user_name) {
		this.user_name = user_name;
	}
	public int getPoints() {
		return points;
	}
	public void setPoints(int points) {
		this.points = points;
	}
	public int getExp_level() {
		return exp_level;
	}
	public void setExp_level(int exp_level) {
		this.exp_level = exp_level;
	}
	public int getExp_rank() {
		return exp_rank;
	}
	public void setExp_rank(int exp_rank) {
		this.exp_rank = exp_rank;
	}
	public LocalDateTime getLogin_first() {
		return login_first;
	}
	public void setLogin_first(LocalDateTime login_first) {
		this.login_first = login_first;
	}
	public LocalDateTime getLogin_recent() {
		return login_recent;
	}
	public void setLogin_recent(LocalDateTime login_recent) {
		this.login_recent = login_recent;
	}

}
