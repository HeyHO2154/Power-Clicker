package Main.Asset;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/asset")
public class AssetController {

    @Autowired
    private AssetService assetService;

    @GetMapping("/themes")
    public ResponseEntity<List<String>> getUserThemes(@RequestParam("user_id") String userId) {
        List<String> themes = assetService.getUserThemes(userId);
        return ResponseEntity.ok(themes);
    }
}