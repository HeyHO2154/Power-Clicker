package Main.Schedule.object;

import java.util.ArrayList;
import java.util.List;

public class Faction {
    private long id;
    private int type;
    private List<Region> occupy = new ArrayList<>();
    private List<Faction> war = new ArrayList<>();

    // 생성자
    public Faction(long id, int type) {
        this.id = id;
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

    public List<Region> getOccupy() {
        return occupy;
    }

    public void addRegion(Region region) {
        this.occupy.add(region);
    }

    public List<Faction> getWar() {
        return war;
    }

    public void addWar(Faction faction) {
        this.war.add(faction);
    }

}
