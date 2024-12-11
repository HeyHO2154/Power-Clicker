package Main.Asset;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

@Entity
@Table(name = "theme")
public class Theme {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY) // AUTO_INCREMENT에 매핑
    private Long id; // PRIMARY KEY

    private String userId; // user_id 컬럼에 매핑
    private String themeName; // theme_name 컬럼에 매핑
    private Boolean themeCheck = true; // theme_check 컬럼에 매핑, 기본값 true

    // 기본 생성자
    public Theme() {
    }

    // 생성자
    public Theme(String userId, String themeName, Boolean themeCheck) {
        this.userId = userId;
        this.themeName = themeName;
        this.themeCheck = themeCheck;
    }

    // Getter와 Setter
    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getUserId() {
        return userId;
    }

    public void setUserId(String userId) {
        this.userId = userId;
    }

    public String getThemeName() {
        return themeName;
    }

    public void setThemeName(String themeName) {
        this.themeName = themeName;
    }

    public Boolean getThemeCheck() {
        return themeCheck;
    }

    public void setThemeCheck(Boolean themeCheck) {
        this.themeCheck = themeCheck;
    }

    @Override
    public String toString() {
        return "Theme{" +
                "id=" + id +
                ", userId='" + userId + '\'' +
                ", themeName='" + themeName + '\'' +
                ", themeCheck=" + themeCheck +
                '}';
    }
}
