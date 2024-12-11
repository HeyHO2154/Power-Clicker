package Main.Asset;

import java.util.List;

import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.CrudRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface AssetRepository extends CrudRepository<Theme, String> {

    @Query("SELECT t.themeName FROM Theme t WHERE t.userId = :userId AND t.themeCheck = true")
    List<String> findUserThemes(String userId);
}