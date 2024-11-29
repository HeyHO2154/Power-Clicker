package Main.PowerClicker;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

import Main.User.User;

//UserRepository.java (레포지토리)
public interface PowerRepository extends JpaRepository<User, String> {
	List<User> findAllByOrderByPointsDesc();
}
