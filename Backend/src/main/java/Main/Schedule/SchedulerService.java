package Main.Schedule;

import org.springframework.stereotype.Service;

import Main.Schedule.act.city;
import Main.Schedule.act.nomad;
import Main.Schedule.act.settled;
import Main.Schedule.object.Dynasty;
import Main.Schedule.object.Faction;
import Main.Schedule.object.Person;
import Main.Schedule.object.Region;

@Service
public class SchedulerService {

	//새로운 가문 생성
    public GameData NewDynasty(GameData gamedata) {
    	//세력 랜덤 선택
    	int rand = (int) (Math.random()*8);
    	String tempName[] = {"떠돌이","용병","무역상","탐험대","약탈자","노예상","기사단","식인종"};
    	Faction bornFaction = new Faction(tempName[rand]+gamedata.getId(), rand+1, null);
    	gamedata.getFactions().add(bornFaction);
    	//아무데나 생성
    	Faction nature = gamedata.getFactions().get(0);
    	Region location = nature.getOccupies().get((int) (Math.random()*nature.getOccupies().size()));
    	Dynasty dynasty = new Dynasty(gamedata.getId(), (gamedata.getId()-1)+"가문", false, location, bornFaction);
    	gamedata.getDynasties().add(dynasty);
        dynasty.getMember().add(new Person(gamedata.getId(), "이름"+(gamedata.getId()-1), (int) (Math.random()*2), 0, dynasty));   
        location.addNomad(dynasty);
        return gamedata;
    }

    //모든 가문 순환
	public GameData DynastyTurn(GameData gamedata) {
		System.out.println("\n 모든 가문 순환");
        for (int i = 0; i < gamedata.getDynasties().size(); i++) {
        	Dynasty dynasty = gamedata.getDynasties().get(i);
        	System.out.print(dynasty.getName()+" 턴: ");
			if(dynasty.getFaction().getCapital()==null) {
				//유목민
				gamedata = nomad.act(gamedata, i);
			}else {
				//정착민
				gamedata = settled.act(gamedata, i);
			}
			
		}
		return gamedata;
	}

	public GameData RegionTurn(GameData gamedata) {
		System.out.println("\n 모든 영토 순환");
		for (int i = 0; i < gamedata.getRegions().size(); i++) {
        	Region region = gamedata.getRegions().get(i);
        	System.out.print(region.getName()+" 턴: ");
			if(region.getOccupy()==gamedata.getFactions().get(0)) {
				System.out.println("자연");
			}else {
				gamedata = city.act(gamedata, i);
			}
			
		}
		return gamedata;
	}

    
}
