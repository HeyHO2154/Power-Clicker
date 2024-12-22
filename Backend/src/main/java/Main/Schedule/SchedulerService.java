package Main.Schedule;

import org.springframework.stereotype.Service;

import Main.Schedule.object.Dynasty;
import Main.Schedule.object.Faction;
import Main.Schedule.object.Player;
import Main.Schedule.object.Region;

@Service
public class SchedulerService {

	//새로운 가문 생성
    public GameData NewDynasty(GameData gamedata) {
    	//자연 지역 중 랜덤한 위치에 스폰
    	Region location = gamedata.getFactions().get(0).getOccupy().get((int) (Math.random()*gamedata.getFactions().get(0).getOccupy().size()));
    	Dynasty dynasty = new Dynasty(gamedata.getId(), (gamedata.getId()-1)+"가문", false, location);
    	gamedata.getDynasties().add(dynasty);
        dynasty.getMember().add(new Player(gamedata.getId(), "이름"+(gamedata.getId()-1), true, 0));       
        location.addNomad(dynasty);
        return gamedata;
    }

    //모든 가문 순환
	public GameData DynastyTrun(GameData gamedata) {
		System.out.println("모든 가문 순환");
        for (int i = 0; i < gamedata.getDynasties().size(); i++) {
        	Dynasty dynasty = gamedata.getDynasties().get(i);
			System.out.print(dynasty.getName()+" 턴: ");
			if(dynasty.isNomad()) {
				int act = (int) (Math.random()*3);
				if(dynasty.getLocation().getAdjacent().size() == 0) {
					act = 1;
				}
				switch (act) {
					case 0:
						//인접한 지역 랜덤으로 선택
						Region moveLocation = dynasty.getLocation().getAdjacent().get((int) (Math.random()*(dynasty.getLocation().getAdjacent().size())));
						//해당 지역으로 이동
						dynasty.getLocation().getNomad().remove(dynasty);
						moveLocation.getNomad().add(dynasty);
						System.out.println(dynasty.getLocation().getName()+"에서 "+moveLocation.getName()+"로 이동");
						dynasty.setLocation(moveLocation);
						break;
					case 1:
						if(dynasty.getLocation().getAdjacent().size() >= 4) break;
						if((int) (Math.random()*gamedata.getRegions().size()) != 0) {
							System.out.println("탐험 실패, "+dynasty.getLocation().getName()+"에 대기");
							break;
						}
						//새로운 지역으로 확장
						Faction nature = gamedata.getFactions().get(0);
						Region newLand = gamedata.getRegions().get((int) (Math.random()*gamedata.getRegions().size()));
						if(newLand == dynasty.getLocation() || dynasty.getLocation().getAdjacent().contains(newLand) || newLand.getAdjacent().size()>=4) {
							newLand = new Region(gamedata.getId(), (gamedata.getId()-1)+"지역", nature);
							gamedata.getRegions().add(newLand);
							nature.getOccupy().add(newLand);
						}		             
				        //인접지역으로 추가
				        newLand.getAdjacent().add(dynasty.getLocation());
				        dynasty.getLocation().getAdjacent().add(newLand);
				        //새로운 지역으로 이동
				        dynasty.getLocation().getNomad().remove(dynasty);
				        newLand.getNomad().add(dynasty);
						System.out.println(dynasty.getLocation().getName()+"에서 "+newLand.getName()+"로 이동");
						dynasty.setLocation(newLand);
						break;
					default:
						System.out.println(dynasty.getLocation().getName()+"에 대기");
						break;
				}
			}
		}
		return gamedata;
	}

    
}
