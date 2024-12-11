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
}