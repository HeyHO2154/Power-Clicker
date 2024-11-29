package Main.PowerClicker;

import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import Main.User.User;

@RestController
@RequestMapping("/api")
public class PowerrController {
	
	static Map<String, Integer> war = new HashMap<>();
	

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
	 
	@PostMapping("/war")
	public ResponseEntity<Void> war(@RequestBody Map<String, String> request) {
	    Optional<User> attackerUser = userRepository.findById(request.get("attacker"));
	    Optional<User> defenderUser = userRepository.findById(request.get("defender"));
	    if (attackerUser.isPresent() && defenderUser.isPresent()) {
	    	User defender = defenderUser.get();
	    	if(defender.getPoints()>=100) {
	    		defender.setPoints(defender.getPoints()-100);
	    		userRepository.save(defender);
	    	}
	    } 
	    return ResponseEntity.ok().build(); // 응답 본문 없이 상태 코드 200 반환
	}

 
}