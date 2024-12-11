package Main.Asset;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.CrudRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface AssetRepository extends CrudRepository<Theme, Long> {

    @Query("SELECT t.themeName FROM Theme t WHERE t.userId = :userId AND t.themeCheck = true")
    List<String> findUserThemes(String userId);
    
    // 특정 사용자의 테마 이름 조회
    Optional<Theme> findByUserIdAndThemeName(String userId, String themeName);
    
}