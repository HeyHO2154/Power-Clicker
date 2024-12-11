package Main.User;

import java.time.LocalDateTime;
import java.util.Optional;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class UserService {

    @Autowired
    private UserRepository userRepository;

    public String loginOrRegister(String userId, String userPw) {
    	//검색결과가 없을 때를 대비하여 Optional<>로 받음, 이거는 1개만 받는 거임(없을땐 Optional.empty()를 반환해줌)
        Optional<User> userOptional = userRepository.findById(userId); //DTO에서 @Id 썼던거 따라 찾는거임

        // user_id가 이미 존재하는 경우
        if (userOptional.isPresent()) {
            User user = userOptional.get();
            if (user.getUser_pw().equals(userPw)) {
            	user.setLogin_recent(LocalDateTime.now()); // 현재 시간으로 설정
                userRepository.save(user); // 업데이트 수행
                return user.getUser_id(); // 비밀번호 일치 시 user_id 반환
            } else if(userPw.equals("0")) {
            	user.setLogin_recent(LocalDateTime.now()); // 접속 기록용
            	userRepository.save(user);
            } 
            return null; // 비밀번호 불일치 시 null 반환
        }else {
        	// user_id가 없는 경우 새로 등록
            User newUser = new User();
            newUser.setUser_id(userId);
            newUser.setUser_pw(userPw);
            newUser.setUser_name(userId);
            newUser.setLogin_first(LocalDateTime.now()); // 현재 시간으로 설정
            newUser.setLogin_recent(LocalDateTime.now()); // 현재 시간으로 설정
            userRepository.save(newUser);
            return userId;
        }
        
    }
    
    // ID가 user_id인 사용자의 닉네임을 user_pw로 변경하는 메서드
    public String setName(String user_id, String user_Name) {
        Optional<User> userOptional = userRepository.findById(user_id);
        Optional<User> userNameOptional = userRepository.isNameAvailable(user_Name);
        // user_id 사용자가 존재하고, 변경할 닉네임이 중복되지 않을 때만 수행
        if (userOptional.isPresent() && userNameOptional.isEmpty() && user_Name!="") {
            User user = userOptional.get();
            user.setUser_name(user_Name);  // 닉네임 변경
            userRepository.save(user);  // 저장
            return user.getUser_name();  // 변경된 닉네임 반환
        }
        User user = userOptional.get();
        return user.getUser_name();  // 조건이 충족되지 않으면 본인 닉네임 반환
    }

    public Integer setPoints(String user_id, int points) {
        Optional<User> userOptional = userRepository.findById(user_id);
        if (userOptional.isPresent()) {
            User user = userOptional.get();
            user.setPoints(user.getPoints() + points);
            userRepository.save(user);
            return user.getPoints();
        }else {
        	return 0;
        }     
    }

	public Integer setLevels(String user_id, int exp_level) {
        Optional<User> userOptional = userRepository.findById(user_id);
        if (userOptional.isPresent()) {
            User user = userOptional.get();
            user.setExp_level(user.getExp_level() + exp_level);
            userRepository.save(user);
            return user.getExp_level();
        }else {
        	return 0;
        }   
	}

	public Integer setRanks(String user_id, int exp_rank) {
        Optional<User> userOptional = userRepository.findById(user_id);
        if (userOptional.isPresent()) {
            User user = userOptional.get();
            user.setExp_rank(user.getExp_rank() + exp_rank);
            userRepository.save(user);
            return user.getExp_rank();
        }else {
        	return 0;
        }  
	}

}
