package Main.Asset;


import jakarta.persistence.*;

@Entity
@Table(name = "theme")
public class Theme {

    @Id
    @Column(name = "user_id")
    private String userId;

    @Column(name = "theme_name", unique = true, nullable = false)
    private String themeName;

    @Column(name = "theme_check", nullable = false)
    private boolean themeCheck;

    // Getters and setters
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

    public boolean isThemeCheck() {
        return themeCheck;
    }

    public void setThemeCheck(boolean themeCheck) {
        this.themeCheck = themeCheck;
    }
}
