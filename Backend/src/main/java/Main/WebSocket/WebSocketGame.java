package Main.WebSocket;

import java.net.URI;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.stream.Collectors;
import java.util.stream.Stream;

import org.springframework.stereotype.Component;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;
import org.springframework.web.socket.handler.TextWebSocketHandler;

@Component
public class WebSocketGame extends TextWebSocketHandler {
    private ConcurrentHashMap<String, WebSocketSession> sessions = new ConcurrentHashMap<>();

    @Override
    public void afterConnectionEstablished(WebSocketSession session) throws Exception {
        URI uri = session.getUri();
        if (uri != null) {
            Map<String, String> queryParams = parseQueryParams(uri);
            String userId = queryParams.get("user_id");

            if (userId != null) {
                sessions.put(userId, session);
                System.out.println("User connected: " + userId);

                // 연결 확인 메시지 보내기
                session.sendMessage(new TextMessage("CONNECTED"));

                // 접속자 두 명 이상이면 알림
                if (sessions.size() == 2) {
                    for (WebSocketSession s : sessions.values()) {
                        s.sendMessage(new TextMessage("START_GAME"));
                    }
                }
            } else {
                session.close();
            }
        }
    }

    @Override
    protected void handleTextMessage(WebSocketSession session, TextMessage message) throws Exception {
        System.out.println("Received: " + message.getPayload());
    }

    @Override
    public void afterConnectionClosed(WebSocketSession session, org.springframework.web.socket.CloseStatus status) throws Exception {
        sessions.values().remove(session);
        System.out.println("Connection closed: " + session.getId());
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
