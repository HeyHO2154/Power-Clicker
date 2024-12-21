package Main.Schedule.object;

import java.util.ArrayList;
import java.util.List;

public class Region {
    private long id;
    private Faction occupy;
    private List<Region> adjacent = new ArrayList<>();
    private List<Dynasty> settled = new ArrayList<>();
    private List<Dynasty> nomad = new ArrayList<>();

    // 생성자
    public Region(long id, Faction occupy) {
        this.id = id;
        this.occupy = occupy;
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
}
