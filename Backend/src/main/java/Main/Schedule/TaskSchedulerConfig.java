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
    	
    	System.err.println("인접 지역 확인");
    	for (int i = 0; i < gamedata.getRegions().size(); i++) {
			System.out.print(gamedata.getRegions().get(i).getName()+": ");
			for (int j = 0; j < gamedata.getRegions().get(i).getAdjacent().size(); j++) {
				System.out.print(gamedata.getRegions().get(i).getAdjacent().get(j).getName()+" ");
			}
			System.out.println();
		}

    }
}
