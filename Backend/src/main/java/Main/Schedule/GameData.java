package Main.Schedule;

import java.util.ArrayList;
import java.util.List;

import Main.Schedule.object.Dynasty;
import Main.Schedule.object.Faction;
import Main.Schedule.object.Region;

public class GameData {
    private long id = 0;    
    private List<Faction> factions = new ArrayList<>();
    private List<Region> regions = new ArrayList<>();
    private List<Dynasty> dynasties = new ArrayList<>();
    
    // 생성자
    public GameData() {
        //자연 생성
        Faction nature = new Faction("자연", 0, null);
        factions.add(nature);
        //최초 지역 생성
        Region firstLand = new Region(id++, "태초의 땅", factions.get(0), (int) (Math.random()*4));
        regions.add(firstLand);
        factions.get(0).getOccupies().add(firstLand);
    }
    
	public long getId() {
		//아이디는 매번 1씩 자동 증가
		return id++;
	}
	public void setId(long id) {
		this.id = id;
	}
	public List<Faction> getFactions() {
		return factions;
	}
	public void setFactions(List<Faction> factions) {
		this.factions = factions;
	}
	public List<Region> getRegions() {
		return regions;
	}
	public void setRegions(List<Region> regions) {
		this.regions = regions;
	}
	public List<Dynasty> getDynasties() {
		return dynasties;
	}
	public void setDynasties(List<Dynasty> dynasties) {
		this.dynasties = dynasties;
	}
    
    
    
}
