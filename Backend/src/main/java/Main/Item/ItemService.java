package Main.Item;

import java.util.Optional;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class ItemService {

    @Autowired
    private ItemRepository itemRepository;

	public Item setItems(String user_id, int judge_baton, int political_speach, int bulletproof) {
		Optional<Item> itemOptional = itemRepository.findById(user_id);
        if (itemOptional.isPresent()) {
            Item item = itemOptional.get();
            item.setJudge_baton(item.getJudge_baton() + judge_baton);
            item.setPolitical_speach(item.getPolitical_speach() + political_speach);
            item.setBulletproof(item.getBulletproof() + bulletproof);
            itemRepository.save(item);
            return item;
        }else {
        	return null;
        } 
	}

}