package Main;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/main")
public class MainController {
	
	public static String Version = "4.0"; //허용되는 버전

    @GetMapping("/version")
    public ResponseEntity<Boolean> version(@RequestParam("version") String version) {
    	if(version.equals(Version)) return ResponseEntity.ok(true);
        return ResponseEntity.ok(false);
    }
}
