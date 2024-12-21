package Main.Schedule.object;

import java.util.ArrayList;
import java.util.List;

public class Dynasty {
    private long id;
    private boolean playable;
    private List<Player> member = new ArrayList<>();

    // 생성자
    public Dynasty(long id, boolean playable) {
        this.id = id;
        this.playable = playable;
    }

	public long getId() {
		return id;
	}

	public void setId(long id) {
		this.id = id;
	}

	public boolean isPlayable() {
		return playable;
	}

	public void setPlayable(boolean playable) {
		this.playable = playable;
	}

	public List<Player> getMember() {
		return member;
	}

	public void setMember(List<Player> member) {
		this.member = member;
	}
    
    
}
