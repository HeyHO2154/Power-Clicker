package Main.Schedule.object;

import java.util.ArrayList;
import java.util.List;

public class Faction {
    private long id;
    private String name;
    private int type;
    private List<Region> occupies = new ArrayList<>();
    private List<Faction> war = new ArrayList<>();

    // 생성자
    public Faction(long id, String name, int type) {
        this.id = id;
        this.name = name;
        this.type = type;
    }

    // Getter & Setter
    public long getId() {
        return id;
    }

    public void setId(long id) {
        this.id = id;
    }

    public int getType() {
        return type;
    }

    public void setType(int type) {
        this.type = type;
    }

    public List<Faction> getWar() {
        return war;
    }

    public void addWar(Faction faction) {
        this.war.add(faction);
    }

	public String getName() {
		return name;
	}

	public void setName(String name) {
		this.name = name;
	}

	public List<Region> getOccupies() {
		return occupies;
	}

	public void setOccupies(List<Region> occupies) {
		this.occupies = occupies;
	}

}
