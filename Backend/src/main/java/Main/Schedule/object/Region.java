package Main.Schedule.object;

import java.util.ArrayList;
import java.util.List;

public class Region {
    private long id;
    private int type;	// 0:초지, 1:사막, 2:설원, 3:정글
    private String name;
    private Faction occupy; 
    private List<Region> adjacent = new ArrayList<>();
    private List<Dynasty> settled = new ArrayList<>();
    private List<Dynasty> nomad = new ArrayList<>();
    
    private Dynasty[] office = new Dynasty[3]; //관직
    private int money = 0;
    private List<Person> army = new ArrayList<>();

    // 생성자
    public Region(long id, String name, Faction occupy, int type) {
        this.id = id;
        this.name = name;
        this.occupy = occupy;
        this.type = type;
    }

    // Getter & Setter
    public long getId() {
        return id;
    }

    public void setId(long id) {
        this.id = id;
    }

    public Faction getOccupy() {
        return occupy;
    }

    public void setOccupy(Faction occupy) {
        this.occupy = occupy;
    }

    public List<Region> getAdjacent() {
        return adjacent;
    }

    public void addAdjacent(Region region) {
        this.adjacent.add(region);
    }

    public List<Dynasty> getSettled() {
        return settled;
    }

    public void addSettled(Dynasty dynasty) {
        this.settled.add(dynasty);
    }

    public List<Dynasty> getNomad() {
        return nomad;
    }

    public void addNomad(Dynasty dynasty) {
        this.nomad.add(dynasty);
    }

	public String getName() {
		return name;
	}

	public void setName(String name) {
		this.name = name;
	}

	public int getType() {
		return type;
	}

	public void setType(int type) {
		this.type = type;
	}

	public int getMoney() {
		return money;
	}

	public void setMoney(int money) {
		this.money = money;
	}

	public List<Person> getArmy() {
		return army;
	}

	public void setArmy(List<Person> army) {
		this.army = army;
	}

	public Dynasty[] getOffice() {
		return office;
	}

	public void setOffice(Dynasty[] office) {
		this.office = office;
	}
}
