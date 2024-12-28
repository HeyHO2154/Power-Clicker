package Main.Schedule.object;

import java.util.ArrayList;
import java.util.List;

public class Dynasty {
    private long id;
    private String name;
    private boolean playable;
    private Region location;
    private Faction faction;
    private List<Person> member = new ArrayList<>();
    
    private String religion = null; //최초에는 무교
    
    private int money = 0;

    // 생성자
    public Dynasty(long id, String name, boolean playable, Region location, Faction faction) {
        this.id = id;
        this.name = name;
        this.playable = playable;
        this.location = location;
        this.faction = faction;
    }

	public long getId() {
		return id;
	}

	public void setId(long id) {
		this.id = id;
	}

	public boolean isPlayable() {
		return playable;
	}

	public void setPlayable(boolean playable) {
		this.playable = playable;
	}

	public List<Person> getMember() {
		return member;
	}

	public void setMember(List<Person> member) {
		this.member = member;
	}

	public Region getLocation() {
		return location;
	}

	public void setLocation(Region location) {
		this.location = location;
	}

	public String getName() {
		return name;
	}

	public void setName(String name) {
		this.name = name;
	}
	
	public Faction getFaction() {
		return faction;
	}

	public void setFaction(Faction faction) {
		this.faction = faction;
	}

	public int getMoney() {
		return money;
	}

	public void setMoney(int money) {
		this.money = money;
	}

	public String getReligion() {
		return religion;
	}

	public void setReligion(String religion) {
		this.religion = religion;
	}
    
    
}
