package Main.Schedule;

import org.springframework.stereotype.Service;

import Main.Schedule.object.Dynasty;
import Main.Schedule.object.Player;

@Service
public class SchedulerService {

	//새로운 가문 생성
    public GameData NewDynasty(GameData gamedata) {
    	Dynasty dynasty = new Dynasty(gamedata.getId(), false);
    	gamedata.getDynasties().add(dynasty);
        dynasty.getMember().add(new Player(gamedata.getId(), "name"+(gamedata.getId()-1), true, 0));
        //자연 지역 중 랜덤한 위치에 스폰
        gamedata.getFactions().get(0).getOccupy().get((int) (Math.random()*gamedata.getFactions().get(0).getOccupy().size())).addNomad(dynasty);
        return gamedata;
    }

    
}
