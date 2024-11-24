package Main.Item;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import Main.User.User;

@RestController
@RequestMapping("/item")
public class ItemController {

    @Autowired
    private ItemService itemService;

    @PostMapping("/items")
    public ResponseEntity<Item> setItems(@RequestBody Item request) {
    	Item items = itemService.setItems(
        		request.getUser_id(), 
        		request.getJudge_baton(), 
        		request.getPolitical_speach(), 
        		request.getBulletproof());
        return ResponseEntity.ok(items);
    }
}
