package Main.Schedule.object;

import java.util.ArrayList;
import java.util.List;

public class Dynasty {
    private long id;
    private String name;
    private boolean playable;
    private boolean isNomad = true;
    private Region location;
    private List<Player> member = new ArrayList<>();

    // 생성자
    public Dynasty(long id, String name, boolean playable, Region location) {
        this.id = id;
        this.name = name;
        this.playable = playable;
        this.location = location;
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

	public List<Player> getMember() {
		return member;
	}

	public void setMember(List<Player> member) {
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

	public boolean isNomad() {
		return isNomad;
	}

	public void setNomad(boolean isNomad) {
		this.isNomad = isNomad;
	}
    
    
}
