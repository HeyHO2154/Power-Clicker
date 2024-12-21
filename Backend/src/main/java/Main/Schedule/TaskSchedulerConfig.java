package Main.Schedule;


import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import Main.Schedule.object.Dynasty;
import Main.Schedule.object.Faction;
import Main.Schedule.object.Player;
import Main.Schedule.object.Region;

@Component
public class TaskSchedulerConfig {
	
	@Autowired
    private SchedulerService schedulerService;

	//클래스 필드
	private long id = 0;
	private Faction nature = new Faction(id++, 0);
	
	// 생성자 또는 초기화 블록에서 실행
    public TaskSchedulerConfig() {
    	//자연에 최초 지형 생성
        nature.getOccupy().add(new Region(id++, nature));
    }
	
    // 매 작업 완료 후, 1초 뒤 실행 (1000ms)
    @Scheduled(fixedDelay = 1000)
    public void scheduleTask() {
        schedulerService.incrementCounter();
        
        //새 가문 생성
        Dynasty dynasty = new Dynasty(id++, false);
        Player player = new Player(id++, "name"+id, true, 0);
        nature.getOccupy().get((int) (Math.random()*nature.getOccupy().size())).addNomad(dynasty);

    }
}
