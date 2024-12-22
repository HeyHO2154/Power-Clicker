package Main.Schedule;


import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

@Component
public class TaskSchedulerConfig {
	
	@Autowired
    private SchedulerService schedulerService;

	//클래스 필드
	private GameData gamedata = new GameData();
	
	// 생성자 또는 초기화 블록에서 실행
    public TaskSchedulerConfig() {

    }
	
    // 매 작업 완료 후, 1초 뒤 실행 (1000ms)
    @Scheduled(fixedDelay = 1000)
    public void scheduleTask() {
    	//새 가문 생성
    	gamedata = schedulerService.NewDynasty(gamedata); 	
        //모든 가문 순환
    	gamedata = schedulerService.DynastyTrun(gamedata);
    	
    	Debug();
    	
    	

    }
    
    private void Debug() {
    	System.out.println("\n \033[31m<세력 리스트>");
    	for (int i = 0; i < gamedata.getFactions().size(); i++) {
			System.out.print(gamedata.getFactions().get(i).getName()+" ");
		}
    	System.out.println("\n \033[32m<지역 리스트>");
    	for (int i = 0; i < gamedata.getRegions().size(); i++) {
			System.out.print(gamedata.getRegions().get(i).getName()+"=");
			for (int j = 0; j < gamedata.getRegions().get(i).getAdjacent().size(); j++) {
				System.out.print(gamedata.getRegions().get(i).getAdjacent().get(j).getName()+",");
			}
			System.out.print("/ ");
		}
    	System.out.println("\n \033[36m<가문 리스트>");
    	for (int i = 0; i < gamedata.getDynasties().size(); i++) {
			System.out.print(gamedata.getDynasties().get(i).getName()+"=");
			for (int j = 0; j < gamedata.getDynasties().get(i).getMember().size(); j++) {
				System.out.print(gamedata.getDynasties().get(i).getMember().get(j).getName()+",");
			}
			System.out.print("/ ");
		}
    	System.out.print("\033[0m");
    }
}
