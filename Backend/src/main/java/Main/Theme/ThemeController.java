package Main.Theme;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/theme")
public class ThemeController {

    @Autowired
    private ThemeService themeService;

    @PostMapping("/themes")
    public ResponseEntity<Theme> setItems(@RequestBody Theme request) {
    	Theme themes = themeService.setThemes(
        		request.getUser_id(), 
        		request.getChristmas(), 
        		request.getForest_friends(), 
        		request.getZombies());
        return ResponseEntity.ok(themes);
    }
    
}
