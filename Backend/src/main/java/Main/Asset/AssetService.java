package Main.Asset;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class AssetService {

    @Autowired
    private AssetRepository assetRepository;

    public List<String> getUserThemes(String userId) {
        return assetRepository.findUserThemes(userId);
    }
    
    public boolean buyTheme(String userId, String themeName) {
    	if (assetRepository.findByUserIdAndThemeName(userId, themeName).isPresent()) return false; // 테마가 이미 존재하면 false 반환
    	Theme newTheme = new Theme();
        newTheme.setUserId(userId);
        newTheme.setThemeName(themeName);
        newTheme.setThemeCheck(true);
        assetRepository.save(newTheme);
        return true;
    }
}