package Main.Theme;

import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

@Entity
@Table(name = "theme") // MySQL에서 users 테이블과 매핑
public class Theme {

    @Id
    private String user_id; // 기본 키이자 외래 키
    private Boolean defaults = true;
    private Boolean christmas = false;
    private Boolean forest_friends = false;
    private Boolean zombies = false;
    
	public String getUser_id() {
		return user_id;
	}
	public void setUser_id(String user_id) {
		this.user_id = user_id;
	}
	public Boolean getDefaults() {
		return defaults;
	}
	public void setDefaults(Boolean defaults) {
		this.defaults = defaults;
	}
	public Boolean getChristmas() {
		return christmas;
	}
	public void setChristmas(Boolean christmas) {
		this.christmas = christmas;
	}
	public Boolean getForest_friends() {
		return forest_friends;
	}
	public void setForest_friends(Boolean forest_friends) {
		this.forest_friends = forest_friends;
	}
	public Boolean getZombies() {
		return zombies;
	}
	public void setZombies(Boolean zombies) {
		this.zombies = zombies;
	}
     
}
