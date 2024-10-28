// UserController.java
package Main.User;

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

@RestController
@RequestMapping("/api")
public class UserController {

	private List<Map<String, String>> chatMessages = new ArrayList<>(); // userId와 message를 함께 저장하는 리스트

    @PostMapping("/sendMessage")
    public ResponseEntity<?> sendMessage(@RequestBody Map<String, String> request) {
        String userId = request.get("user_id");
        String message = request.get("message");

        if (chatMessages.size() >= 20) {
            chatMessages.remove(0);  // 10개 초과 시 맨 앞 메시지 삭제
        }
        chatMessages.add(Map.of("userId", userId, "message", message));

        return ResponseEntity.ok(Collections.singletonMap("message", "Message sent successfully"));
    }

    @GetMapping("/getMessages")
    public List<Map<String, String>> getMessages() {
        return chatMessages;
    }

	
    @Autowired
    private UserRepository userRepository;

    @PostMapping("/register")
    public ResponseEntity<?> registerUser(@RequestBody Map<String, String> request) {
        String userId = request.get("user_id");
        Optional<User> existingUser = userRepository.findByUserId(userId);

        if (existingUser.isPresent()) {
            return ResponseEntity
                    .status(HttpStatus.BAD_REQUEST)
                    .contentType(MediaType.APPLICATION_JSON_UTF8)  // UTF-8로 설정
                    .body(Collections.singletonMap("message", "중복된 닉네임입니다."));
        }

        User newUser = new User();
        newUser.setUserId(userId);
        newUser.setPoint(0); // 초기 포인트 설정
        userRepository.save(newUser);
        return ResponseEntity
                .ok()
                .contentType(MediaType.APPLICATION_JSON_UTF8)  // UTF-8로 설정
                .body(Collections.singletonMap("success", true));
    }
    
    // UserController.java (유저 리스트 가져오기)
    @GetMapping("/users")
    public List<Map<String, Object>> getAllUsers() {
        List<User> users = userRepository.findAllByOrderByPointDesc();
        List<Map<String, Object>> result = new ArrayList<>();

        for (User user : users) {
            Map<String, Object> userData = new HashMap<>();
            userData.put("user_id", user.getUserId());
            userData.put("point", user.getPoint());
            result.add(userData);
        }

        return result;
    }
    
 // 아이디 변경 메서드
    @PostMapping("/updateUserId")
    public ResponseEntity<?> updateUserId(@RequestBody Map<String, String> request) {
        String currentUserId = request.get("user_id"); // 현재 사용 중인 아이디
        String newUserId = request.get("new_user_id"); // 변경할 아이디

        // 새 아이디의 중복 검사
        Optional<User> existingUser = userRepository.findByUserId(newUserId);
        if (existingUser.isPresent()) {
            return ResponseEntity
                    .status(HttpStatus.CONFLICT)
                    .body(Collections.singletonMap("message", "이미 존재하는 아이디입니다."));
        }

        // 현재 사용자 정보 가져오기
        Optional<User> userOptional = userRepository.findByUserId(currentUserId);
        if (userOptional.isPresent()) {
            User user = userOptional.get();
            user.setUserId(newUserId); // 아이디 변경
            userRepository.save(user);
            return ResponseEntity
                    .ok(Collections.singletonMap("message", "아이디가 성공적으로 변경되었습니다."));
        } else {
            return ResponseEntity
                    .status(HttpStatus.NOT_FOUND)
                    .body(Collections.singletonMap("message", "사용자를 찾을 수 없습니다."));
        }
    }

    
    // UserController.java (포인트 감소)
    @PostMapping("/decrease")
    public ResponseEntity<?> decreasePoints(@RequestBody Map<String, Object> request) {
        String userId = (String) request.get("user_id");
        int pointsToDecrease = (int) request.get("points");

        Optional<User> userOptional = userRepository.findByUserId(userId);

        if (userOptional.isPresent()) {
            User user = userOptional.get();
            if (user.getPoint() >= pointsToDecrease) {
                user.setPoint(user.getPoint() - pointsToDecrease);
                userRepository.save(user);
                return ResponseEntity.ok(Collections.singletonMap("message", "포인트가 " + pointsToDecrease + " 감소되었습니다."));
            } else {
                return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                        .body(Collections.singletonMap("message", "포인트가 충분하지 않습니다."));
            }
        }

        return ResponseEntity.status(HttpStatus.NOT_FOUND).body(Collections.singletonMap("message", "유저를 찾을 수 없습니다."));
    }
    
    // UserController.java (포인트 증가 - 광질하기)
    @PostMapping("/increase")
    public ResponseEntity<?> increasePoints(@RequestBody Map<String, Object> request) {
        String userId = (String) request.get("user_id");
        int pointsToAdd = (int) request.get("points");

        Optional<User> userOptional = userRepository.findByUserId(userId);

        if (userOptional.isPresent()) {
            User user = userOptional.get();
            user.setPoint(user.getPoint() + pointsToAdd);
            userRepository.save(user);
            return ResponseEntity.ok(Collections.singletonMap("message", "포인트가 증가했습니다."));
        }

        return ResponseEntity.status(HttpStatus.NOT_FOUND).body(Collections.singletonMap("message", "유저를 찾을 수 없습니다."));
    }

    // 포인트 조회 메서드
    @GetMapping("/getPoints")
    public ResponseEntity<?> getPoints(@RequestParam String user_id) {
        Optional<User> user = userRepository.findByUserId(user_id);

        if (user.isPresent()) {
            // 유저가 존재하면 포인트 정보를 반환
            Map<String, Object> response = new HashMap<>();
            response.put("user_id", user.get().getUserId());
            response.put("points", user.get().getPoint());
            return ResponseEntity.ok(response);
        } else {
            // 유저가 없을 경우
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(Collections.singletonMap("message", "User not found"));
        }
    }

}
