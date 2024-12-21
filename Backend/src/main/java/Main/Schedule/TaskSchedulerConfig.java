package Main.Schedule;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

@Component
public class TaskSchedulerConfig {
	
	@Autowired
    private SchedulerService schedulerService;

    // 1초마다 실행 (1000ms)
    @Scheduled(fixedDelay = 1000) //지금은 다 끝나고 1초후에 시행, fixedRate는 작업 끝났는지와 별개로 1초마다 시행
    public void scheduleTask() {
        schedulerService.incrementCounter();
    }
}
