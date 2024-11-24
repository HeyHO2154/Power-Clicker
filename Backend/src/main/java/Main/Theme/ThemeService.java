package Main.Theme;

import java.util.Optional;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import Main.Item.Item;

@Service
public class ThemeService {

    @Autowired
    private ThemeRepository themeRepository;
    
	public Theme setThemes(String user_id, boolean christmas, boolean forest_friends, boolean zombies) {
		Optional<Theme> themeOptional = themeRepository.findById(user_id);
        if (themeOptional.isPresent()) {
        	Theme theme = themeOptional.get();
        	if(christmas) theme.setChristmas(true);
        	if(forest_friends) theme.setForest_friends(true);
        	if(zombies) theme.setZombies(true);
            themeRepository.save(theme);
            return theme;
        }else {
        	return null;
        } 
	}

}
