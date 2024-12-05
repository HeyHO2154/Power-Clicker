package Main.WebSocket;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class GameSession {
    private final String sessionId;
    private final String player1;
    private final String player2;
    private final Map<String, List<Integer>> playerCards = new HashMap<>();

    public GameSession(String sessionId, String player1, String player2) {
        this.sessionId = sessionId;
        this.player1 = player1;
        this.player2 = player2;

        // 초기 카드 생성
        playerCards.put(player1, generateRandomCards());
        playerCards.put(player2, generateRandomCards());
    }

    private List<Integer> generateRandomCards() {
        List<Integer> cards = new ArrayList<>();
        for (int i = 0; i < 5; i++) {
            cards.add((int) (Math.random() * 6) + 1);
        }
        return cards;
    }

    public List<Integer> getInitialCards(String playerId) {
        return playerCards.get(playerId);
    }

    public void handleCardChange(String playerId, List<Integer> change) {
        List<Integer> cards = playerCards.get(playerId);
        for (int i = 0; i < change.size(); i++) {
            if (change.get(i) == 1) {
                cards.set(i, (int) (Math.random() * 6) + 1);
            }
        }
    }

    public void showResult() {
        // 결과를 양 플레이어에게 전송
    }

    public boolean isPlayerInSession(String playerId) {
        return player1.equals(playerId) || player2.equals(playerId);
    }

    public boolean removePlayer(String playerId) {
        return player1.equals(playerId) || player2.equals(playerId);
    }
}
