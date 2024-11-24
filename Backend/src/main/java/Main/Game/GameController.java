package Main.Game;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api")
public class GameController {

    private Map<String, Game> gameSessions = new HashMap<>();

    @PostMapping("/start_game")
    public void startGame(@RequestBody Map<String, String> request) {
        String userId = request.get("userId");
        Game gameData = new Game();	// 플레이어별로 고유한 게임 데이터를 생성
        gameSessions.put(userId, gameData); //중복 요청시 초기화
    }
    
    @PostMapping("/info")
    public ResponseEntity<Map<String, Object>> info(@RequestBody Map<String, String> request) {
        String userId = request.get("userId");
        Game gameData = gameSessions.get(userId);

        Map<String, Object> response = new HashMap<>();
        response.put("player", gameData.getPlayer());  // player 정보를 반환
        response.put("Job", gameData.getJob());        // Job[] 배열 반환
        response.put("Alive_citizen", gameData.getAlive().get(1));
        response.put("Alive_mafia", gameData.getAlive().get(-1));       
        //전체 생존자 alive[]로 합침
        List<Integer> alive = new ArrayList<>();
        alive.addAll(gameData.getAlive().get(-1));
        alive.addAll(gameData.getAlive().get(1));
        alive.sort(null);
        response.put("alive", alive);        // alive[] 반환
        return ResponseEntity.ok(response);
    }

    @PostMapping("/night")
    public void night(@RequestBody Map<String, Object> request) {
        String userId = (String) request.get("userId");
        Game gameData = gameSessions.get(userId);
        
        gameData.getPick()[gameData.getPlayer()] = (Integer) request.get("target"); 
        GameLogic.Night(gameData); //밤 로직 처리
    }
    
    @PostMapping("/day")
    public ResponseEntity<Map<String, Object>> day(@RequestBody Map<String, Object> request) {
        String userId = (String) request.get("userId");
        Game gameData = gameSessions.get(userId); // 사용자에 맞는 게임 데이터를 가져옴
        
        Map<String, Object> response = new HashMap<>();
        if(GameLogic.Day(gameData)) {
        	response.put("deadPlayer", gameData.getKill());
        }else {
        	response.put("deadPlayer", 99);
        }     
        return ResponseEntity.ok(response);
    }
    
    @PostMapping("/discussion")
    public ResponseEntity<Map<String, String>> discussion(@RequestBody Map<String, Object> request) {
    	String userId = (String) request.get("userId");
        int PlayerId = (int) request.get("PlayerId");
        int Act = (int) request.get("Act");
        int FakeJob = (int) request.get("FakeJob");
        int TargetId = (int) request.get("TargetId");
        boolean IsMafia = (boolean) request.get("IsMafia");
        Game gameData = gameSessions.get(userId);

        Map<String, String> response = new HashMap<>();
        response.put("message", GameLogic.Discussion(gameData, PlayerId, Act, FakeJob, TargetId, IsMafia));
        return ResponseEntity
                .ok()
                .header("Content-Type", "application/json; charset=UTF-8")  // UTF-8로 인코딩
                .body(response);
    }
    
    @PostMapping("/vote")
    public ResponseEntity<Map<String, String>> vote(@RequestBody Map<String, Object> request) {
    	String userId = (String) request.get("userId");
        int PlayerId = (int) request.get("PlayerId");
        int TargetId = (int) request.get("TargetId");
        Game gameData = gameSessions.get(userId);

        Map<String, String> response = new HashMap<>();
        response.put("message", GameLogic.Vote(gameData, PlayerId, TargetId));
        return ResponseEntity
                .ok()
                .header("Content-Type", "application/json; charset=UTF-8")  // UTF-8로 인코딩
                .body(response);
    }

    
    @PostMapping("/execution")
    public ResponseEntity<Map<String, Integer>> getExecutionResult(@RequestBody Map<String, String> request) {
        String userId = request.get("userId"); // 요청에서 userId 추출
        Game gameData = gameSessions.get(userId); // userId에 해당하는 게임 데이터 가져옴

        // 최다 득표자 계산
        List<Integer> prisoner = new ArrayList<>();
		prisoner = GameAct.FindMaxNum(gameData.getVote());
		int result = 99;
		if(prisoner.size()==1) {
			result = prisoner.get(0);
			GameAct.Kick(prisoner.get(0), gameData);
		}
		gameData.setVote(new int[gameData.getN()]);
        
        Map<String, Integer> response = new HashMap<>();
        response.put("votedPlayer", result);
        return ResponseEntity.ok(response);
    }
    
}

