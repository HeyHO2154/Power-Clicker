package Main.Item;

import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

@Entity
@Table(name = "item") // MySQL에서 users 테이블과 매핑
public class Item {

    @Id
    private String user_id; // 기본 키이자 외래 키
    private int judge_baton;
    private int political_speach;
    private int bulletproof;
    
	public String getUser_id() {
		return user_id;
	}
	public void setUser_id(String user_id) {
		this.user_id = user_id;
	}
	public int getJudge_baton() {
		return judge_baton;
	}
	public void setJudge_baton(int judge_baton) {
		this.judge_baton = judge_baton;
	}
	public int getPolitical_speach() {
		return political_speach;
	}
	public void setPolitical_speach(int political_speach) {
		this.political_speach = political_speach;
	}
	public int getBulletproof() {
		return bulletproof;
	}
	public void setBulletproof(int bulletproof) {
		this.bulletproof = bulletproof;
	}   
    
}
