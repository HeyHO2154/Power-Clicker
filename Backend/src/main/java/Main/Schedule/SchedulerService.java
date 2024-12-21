package Main.Schedule;

import org.springframework.stereotype.Service;

@Service
public class SchedulerService {
    private int a = 0; // 증가할 변수

    // 1초마다 실행되는 작업
    public synchronized void incrementCounter() {
        a++;
    }

    // 현재 변수 값을 반환
    public synchronized int getCounter() {
        return a;
    }
}
