package Main.PowerClicker;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Queue;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import Main.User.User;

@RestController
@RequestMapping("/api")
public class PowerrController {
	
	static Map<String, List<String>> war = new HashMap<>();
	

	@Autowired
	private PowerRepository userRepository;
	
	//유저 리스트 가져오기
	@GetMapping("/users")
	public List<Map<String, Object>> getAllUsers() {
	    List<User> users = userRepository.findAllByOrderByPointsDesc();
	    List<Map<String, Object>> result = new ArrayList<>();
	
	    for (User user : users) {
	        Map<String, Object> userData = new HashMap<>();
	        userData.put("user_id", user.getUser_id());
	        userData.put("points", user.getPoints());
	        result.add(userData);
	    }	
	    return result;
	}
	 
	//공격하기
	@PostMapping("/war")
	public ResponseEntity<Void> war(@RequestBody Map<String, String> request) {
	    Optional<User> attackerUser = userRepository.findById(request.get("attacker"));
	    Optional<User> defenderUser = userRepository.findById(request.get("defender"));
	    if (attackerUser.isPresent() && defenderUser.isPresent()) {
	    	User attacker = attackerUser.get();
	    	User defender = defenderUser.get();
	    	if(defender.getPoints()>=100) {
	    		defender.setPoints(defender.getPoints()-100);
	    		userRepository.save(defender);
	    		//전쟁기록 남기기
	    		if (!war.containsKey(defender.getUser_id())) {
	    			war.put(defender.getUser_id(), new LinkedList<>());
	    		}
	    		if (!war.get(defender.getUser_id()).contains(attacker.getUser_id())) {
	    			war.get(defender.getUser_id()).add(attacker.getUser_id());
	    		}
	    	}
	    }
	    return ResponseEntity.ok().build(); // 응답 본문 없이 상태 코드 200 반환
	}
	//전쟁기록 가져오기
	@PostMapping("/warRecord")
	public List<String> warRecord(@RequestBody Map<String, String> request) {
		Optional<User> userWarRecord = userRepository.findById(request.get("user_id"));
		List<String> result = new ArrayList<>();
		if (userWarRecord.isPresent()) {
			User user = userWarRecord.get();
			if(war.containsKey(user.getUser_id())) {
				result = war.get(user.getUser_id());
				war.remove(user.getUser_id());
				return result;
			}
		}
	    return result;
	}

 
}