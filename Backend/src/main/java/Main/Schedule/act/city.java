package Main.Schedule.act;

import java.util.ArrayList;

import Main.Schedule.GameData;
import Main.Schedule.object.Dynasty;
import Main.Schedule.object.Person;
import Main.Schedule.object.Region;

public class city {
	public static GameData act(GameData gamedata, int num) {
		Region region = gamedata.getRegions().get(num);
		int act = (int) (Math.random()*3);
		switch (act) {
			case 0:
			case 1:
			default:
				System.out.print(region.getOccupy().getName()+" 행동..");
				break;
		}
		
		//거주민 세금 거두기
		
		
		//인접 지역 정복
		if((int) (Math.random()*4)==0) {
			for (int i = 0; i < region.getAdjacent().size(); i++) {
				//일단은 군사가 적은 인접지역 공격
				Region target = region.getAdjacent().get(i);
				if(region.getArmy().size() > target.getArmy().size() && region.getOccupy() != target.getOccupy()) {
					//일단은 1대1 대응 전투
					for (int j = 0; j < region.getArmy().size()-target.getArmy().size(); j++) {
						region.getArmy().remove(j);
					}
					target.setArmy(new ArrayList<>());
					if(target.getOccupy().getOccupies().size()<2 && target.getOccupy()!=gamedata.getFactions().get(0)) {
						gamedata.getFactions().remove(target.getOccupy());
						System.out.print(" /"+target.getOccupy().getName()+" 멸망..");
					}else {
						target.getOccupy().getOccupies().remove(target);
					}
					target.setOccupy(region.getOccupy());
					region.getOccupy().getOccupies().add(target);
					System.out.print(" /"+target.getName()+"이 "+region.getOccupy().getName()+"의 영토가 되었습니다!");
				}
			}
		}
	
		System.out.println();
		return gamedata;
	}
}
