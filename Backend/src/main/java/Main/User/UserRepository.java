package Main.User;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

//UserRepository.java (레포지토리)
public interface UserRepository extends JpaRepository<User, Long> {
 Optional<User> findByUserId(String userId);
 List<User> findAllByOrderByPointDesc();
}