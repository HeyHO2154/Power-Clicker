package Main.Asset;

import java.util.List;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/asset")
public class AssetController {

    @Autowired
    private AssetService assetService;

    @GetMapping("/themes")
    public ResponseEntity<List<String>> themes(@RequestParam("user_id") String userId) {
        List<String> themes = assetService.getUserThemes(userId);
        return ResponseEntity.ok(themes);
    }
    
    @PostMapping("/buyTheme")
    public void buyTheme(@RequestBody Map<String, String> request) {
    	assetService.buyTheme(request.get("userId"), request.get("themeName"));
    }
}