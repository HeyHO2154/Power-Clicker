package Main.Schedule.object;

import java.time.LocalDateTime;

public class Product {
	
	/*
	 * 일반 아이템은 Dynasty에서 int[] 단위로 관리
	 * 여기는 가공을 통한 2차 생산품 전용
	 */
	private int type;	//빵류, 무기류, 의류, 주류
	private int level;	//1~5레벨
	private String name;
	private Person who;
    private LocalDateTime when;

    // 생성자
    public Product(int type, int level, String name, Person who) {
    	this.type = type;
    	this.level = level;
    	this.name = name;
    	this.who = who;
    	this.when = LocalDateTime.now();
    }

	public int getType() {
		return type;
	}

	public void setType(int type) {
		this.type = type;
	}

	public int getLevel() {
		return level;
	}

	public void setLevel(int level) {
		this.level = level;
	}

	public String getName() {
		return name;
	}

	public void setName(String name) {
		this.name = name;
	}

	public Person getWho() {
		return who;
	}

	public void setWho(Person who) {
		this.who = who;
	}

	public LocalDateTime getWhen() {
		return when;
	}

	public void setWhen(LocalDateTime when) {
		this.when = when;
	}
    
}
