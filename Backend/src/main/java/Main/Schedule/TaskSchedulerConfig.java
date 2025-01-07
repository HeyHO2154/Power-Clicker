package Main.Schedule;


import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import Main.Schedule.object.Dynasty;
import Main.Schedule.object.Faction;
import Main.Schedule.object.Region;

@Component
public class TaskSchedulerConfig {
	
	@Autowired
    private SchedulerService schedulerService;

	//게임데이터 생성
	private GameData gamedata = new GameData();
	
    // 매 작업 완료 후, 1초 뒤 실행 (1000ms)
    @Scheduled(fixedDelay = 500)
    public void scheduleTask() {
    	//새 가문 생성
    	gamedata = schedulerService.NewDynasty(gamedata); 	
        //모든 가문 순환
    	gamedata = schedulerService.DynastyTurn(gamedata);
    	//모든 영토 순환
    	gamedata = schedulerService.RegionTurn(gamedata);
    	//
    	Debug();
    	
    	

    }
    
    private void Debug() {
    	System.out.println("\n \033[31m<세력 리스트>");
    	for (int i = 0; i < gamedata.getFactions().size(); i++) {
    		Faction faction = gamedata.getFactions().get(i);
    		if(faction.getCapital()!=null) {
        		System.out.print("\n "+faction.getName()+"="+faction.getCapital().getName());
    			for (int j = 0; j < faction.getOccupies().size(); j++) {
    				Region region = faction.getOccupies().get(j);
    				if(region.getOffice()[0] != null) {
    					System.out.print("\n"+region.getOffice()[0].getName()+"의 "+region.getName()+"["+region.getArmy().size()+"병사]("+region.getMoney()+"G):");
    				}else {
    					System.out.print("\n주인없는 "+region.getName()+"["+region.getArmy().size()+"병사]("+region.getMoney()+"G):");
    				}
    				for (int k = 0; k < region.getSettled().size(); k++) {
    					Dynasty dynasty = region.getSettled().get(k);
    					System.out.print(dynasty.getName()+"["+dynasty.getMember().size()+"명]("+dynasty.getMoney()+"G),");
    				}
    			}
    			System.out.print("/ ");
    		}
		}
    	System.out.println("\n \033[32m<지역 리스트>");
    	for (int i = 0; i < gamedata.getRegions().size(); i++) {
    		Region region = gamedata.getRegions().get(i);
			System.out.print(region.getName()+"<"+region.getType()+"바이옴>=");
			for (int j = 0; j < gamedata.getRegions().get(i).getAdjacent().size(); j++) {
				System.out.print(gamedata.getRegions().get(i).getAdjacent().get(j).getName()+",");
			}
			System.out.print("/ ");
		}
    	System.out.println("\n \033[36m<가문 리스트>");
    	for (int i = 0; i < gamedata.getDynasties().size(); i++) {
    		Dynasty dynasty = gamedata.getDynasties().get(i);
			System.out.print(dynasty.getFaction().getName()+dynasty.getName()+"["+dynasty.getMember().size()+"명]("+dynasty.getMoney()+"G)");
			System.out.print("/ ");
		}
    	System.out.print("\033[0m");
    }
}
