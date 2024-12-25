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
        Faction nature = new Faction(id++, "자연", 0, null);
        factions.add(nature);
        //최초 5지역 생성
        initialLand("태초의 땅");
        initialLand("북부의 땅");
        initialLand("서부의 땅");
        initialLand("동부의 땅");
        initialLand("남부의 땅");

        nature.getOccupies().get(0).getAdjacent().add(nature.getOccupies().get(1));
        nature.getOccupies().get(0).getAdjacent().add(nature.getOccupies().get(2));
        nature.getOccupies().get(0).getAdjacent().add(nature.getOccupies().get(3));
        nature.getOccupies().get(0).getAdjacent().add(nature.getOccupies().get(4));
        nature.getOccupies().get(1).getAdjacent().add(nature.getOccupies().get(0));
        nature.getOccupies().get(2).getAdjacent().add(nature.getOccupies().get(0));
        nature.getOccupies().get(3).getAdjacent().add(nature.getOccupies().get(0));
        nature.getOccupies().get(4).getAdjacent().add(nature.getOccupies().get(0));
        
        nature.setCapital(nature.getOccupies().get(0));       
    }
    
    private void initialLand(String name) {
    	Region firstLand = new Region(id++, name, factions.get(0), 0);
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
