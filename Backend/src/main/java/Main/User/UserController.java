package Main.User;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/user")
public class UserController {

    @Autowired
    private UserService userService;

    @PostMapping("/login")
    public ResponseEntity<String> loginOrRegister(@RequestBody User request) {
    	//아이디와 비번 불일치 시 null 반환, 그 외 로그인 or 신규등록 처리
        String userId = userService.loginOrRegister(request.getUser_id(), request.getUser_pw());
        return ResponseEntity.ok(userId);
    }
    
    @PostMapping("/name")
    public ResponseEntity<String> setName(@RequestBody User request) {
    	//최초 확인시(getName같이) ''로 넘어오는데, 이때는 DB업데이트 없이 닉네임만 반환해줌
        String userName = userService.setName(request.getUser_id(), request.getUser_name());
        return ResponseEntity.ok(userName);
    }
    
    @PostMapping("/point")
    public ResponseEntity<Integer> setPoints(@RequestBody User request) {
        Integer points = userService.setPoints(request.getUser_id(), request.getPoints());
        return ResponseEntity.ok(points);
    }
    
    @PostMapping("/level")
    public ResponseEntity<Integer> setLevels(@RequestBody User request) {
        Integer exp_level = userService.setLevels(request.getUser_id(), request.getExp_level());
        return ResponseEntity.ok(exp_level);
    }
    
    @PostMapping("/rank")
    public ResponseEntity<Integer> setRanks(@RequestBody User request) {
        Integer exp_rank = userService.setRanks(request.getUser_id(), request.getExp_rank());
        return ResponseEntity.ok(exp_rank);
    }
}
