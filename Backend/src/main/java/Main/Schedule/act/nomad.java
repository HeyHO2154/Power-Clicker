package Main.Schedule.act;

import Main.Schedule.GameData;
import Main.Schedule.object.Dynasty;
import Main.Schedule.object.Faction;
import Main.Schedule.object.Region;

public class nomad {
	public static GameData act(GameData gamedata, int num) {
		Dynasty dynasty = gamedata.getDynasties().get(num);
		System.out.print(dynasty.getName()+" 턴: ");
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
				if(dynasty.getLocation().getAdjacent().size() >= 4) {
					System.out.println("탐험 불가, "+dynasty.getLocation().getName()+"에 대기");
					break;
				}
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
		
		return gamedata;
	}
}
