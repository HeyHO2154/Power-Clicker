package Main.WebSocket;

import java.net.URI;
import java.util.Map;
import java.util.Queue;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.LinkedBlockingQueue;
import java.util.stream.Collectors;
import java.util.stream.Stream;

import org.springframework.stereotype.Component;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;
import org.springframework.web.socket.handler.TextWebSocketHandler;

@Component
public class WebSocketGame extends TextWebSocketHandler {
	private final ConcurrentHashMap<String, WebSocketSession> sessions = new ConcurrentHashMap<>();
    private final Queue<String> waitingQueue = new LinkedBlockingQueue<>(); // 대기열

    @Override
    public void afterConnectionEstablished(WebSocketSession session) throws Exception {
        URI uri = session.getUri();
        if (uri != null) {
            Map<String, String> queryParams = parseQueryParams(uri);
            String userId = queryParams.get("user_id");

            if (userId != null) {
                sessions.put(userId, session);
                waitingQueue.offer(userId); // 대기열에 사용자 추가
                System.out.println("User connected: " + userId);

                // 연결 확인 메시지
                session.sendMessage(new TextMessage("CONNECTED"));

                // 대기열 확인
                checkAndStartGame();
            } else {
                session.close();
            }
        }
    }

    private void checkAndStartGame() throws Exception {
        while (waitingQueue.size() >= 2) {
            // 대기열에서 2명 꺼내기
            String player1 = waitingQueue.poll();
            String player2 = waitingQueue.poll();

            if (player1 != null && player2 != null) {
                String sessionId = UUID.randomUUID().toString(); // 고유 세션 ID 생성
                WebSocketSession session1 = sessions.get(player1);
                WebSocketSession session2 = sessions.get(player2);

                if (session1 != null && session2 != null) {
                    // 두 플레이어에게 세션 ID 전송
                    session1.sendMessage(new TextMessage("START_GAME:" + sessionId));
                    session2.sendMessage(new TextMessage("START_GAME:" + sessionId));

                    System.out.println("Game started between " + player1 + " and " + player2 + " with session ID: " + sessionId);
                }
            }
        }
    }

    @Override
    protected void handleTextMessage(WebSocketSession session, TextMessage message) throws Exception {
        System.out.println("Received: " + message.getPayload());
    }

    @Override
    public void afterConnectionClosed(WebSocketSession session, org.springframework.web.socket.CloseStatus status) throws Exception {
        String userId = sessions.entrySet()
                .stream()
                .filter(entry -> entry.getValue().equals(session))
                .map(Map.Entry::getKey)
                .findFirst()
                .orElse(null);

        if (userId != null) {
            sessions.remove(userId);
            waitingQueue.remove(userId); // 대기열에서 제거
            System.out.println("User disconnected: " + userId);
        }
    }

    private Map<String, String> parseQueryParams(URI uri) {
        String query = uri.getQuery();
        if (query == null || query.isEmpty()) {
            return Map.of();
        }

        return Stream.of(query.split("&"))
                .map(param -> param.split("=", 2))
                .collect(Collectors.toMap(
                        parts -> parts[0],
                        parts -> parts.length > 1 ? parts[1] : ""
                ));
    }
}
