package Main.Schedule;

import org.springframework.stereotype.Service;

import Main.Schedule.act.nomad;
import Main.Schedule.object.Dynasty;
import Main.Schedule.object.Person;
import Main.Schedule.object.Region;

@Service
public class SchedulerService {

	//새로운 가문 생성
    public GameData NewDynasty(GameData gamedata) {
    	//자연 지역 중 랜덤한 위치에 스폰
    	Region location = gamedata.getFactions().get(0).getOccupies().get((int) (Math.random()*gamedata.getFactions().get(0).getOccupies().size()));
    	Dynasty dynasty = new Dynasty(gamedata.getId(), (gamedata.getId()-1)+"가문", false, location, gamedata.getFactions().get(0));
    	gamedata.getDynasties().add(dynasty);
        dynasty.getMember().add(new Person(gamedata.getId(), "이름"+(gamedata.getId()-1), (int) (Math.random()*2), 0));   
        location.addNomad(dynasty);
        return gamedata;
    }

    //모든 가문 순환
	public GameData DynastyTrun(GameData gamedata) {
		System.out.println("\n 모든 가문 순환");
        for (int i = 0; i < gamedata.getDynasties().size(); i++) {
        	Dynasty dynasty = gamedata.getDynasties().get(i);
        	System.out.print(dynasty.getName()+" 턴: ");
			if(dynasty.getFaction()==gamedata.getFactions().get(0)) {
				gamedata = nomad.act(gamedata, i);
			}else {
				System.out.print(dynasty.getFaction().getName()+"의 "+dynasty.getLocation().getName()+"에서 대기중");
				System.out.println();
			}
			
		}
		return gamedata;
	}

    
}
