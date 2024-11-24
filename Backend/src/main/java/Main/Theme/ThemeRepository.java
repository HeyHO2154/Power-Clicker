package Main.Theme;

import org.springframework.data.jpa.repository.JpaRepository;

public interface ThemeRepository extends JpaRepository<Theme, String> {
    // 필요한 경우 추가적인 쿼리 메서드 작성 가능
}
