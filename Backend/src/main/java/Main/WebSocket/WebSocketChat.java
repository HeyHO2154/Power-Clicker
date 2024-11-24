package Main.WebSocket;

import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.CopyOnWriteArraySet;

import org.springframework.stereotype.Component;
import org.springframework.web.socket.CloseStatus;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;
import org.springframework.web.socket.handler.TextWebSocketHandler;

import com.fasterxml.jackson.databind.ObjectMapper;

@Component
public class WebSocketChat extends TextWebSocketHandler {

    // 접속된 클라이언트들
    private final Set<WebSocketSession> sessions = new CopyOnWriteArraySet<>();
    private final Map<WebSocketSession, String> sessionUserMap = new HashMap<>(); // 세션과 userId 매핑
    private Set<String> users = new HashSet<>(); // 대기 중인 유저들(userId 값)

    // 세션 연결 이후
    @Override
    public void afterConnectionEstablished(WebSocketSession session) throws Exception {
        System.out.println("연결됨: " + session.getId());
        sessions.add(session); // 세션 추가
    }

    // 서버 -> 클라이언트
    public void broadcast(Set<String> users) throws Exception {
        ObjectMapper objectMapper = new ObjectMapper();
        // Set을 JSON 문자열로 변환
        String usersJson = objectMapper.writeValueAsString(users);
        // 모든 세션에 메시지 전송
        for (WebSocketSession session : sessions) {
            if (session.isOpen()) {
                session.sendMessage(new TextMessage(usersJson));
            }
        }
    }

    // 클라이언트 -> 서버
    @Override
    protected void handleTextMessage(WebSocketSession session, TextMessage message) throws Exception {
        // 메시지 파싱
        String payload = message.getPayload();
        System.out.println("Received message: " + payload);

        // JSON 데이터를 파싱
        ObjectMapper objectMapper = new ObjectMapper();
        Map<String, String> data = objectMapper.readValue(payload, Map.class);
        String userId = data.get("user_id");

        if (userId != null) {
            users.add(userId); // 유저 추가
            sessionUserMap.put(session, userId); // 세션과 userId 매핑
            broadcast(users); // 유저 목록 브로드캐스트
        }
    }

    // 세션 연결 해제
    @Override
    public void afterConnectionClosed(WebSocketSession session, CloseStatus status) throws Exception {
        sessions.remove(session); // 세션 제거
        String userId = sessionUserMap.remove(session); // 세션과 연결된 userId 제거
        if (userId != null) {
            users.remove(userId); // users 목록에서 제거
            broadcast(users); // 업데이트된 유저 목록 브로드캐스트
        }
        System.out.println("해제됨: " + session.getId());
    }
}
