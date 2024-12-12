package Main.WebSocket;

import java.util.Arrays;
import java.util.Objects;
import java.util.concurrent.ConcurrentHashMap;

import org.springframework.stereotype.Component;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;
import org.springframework.web.socket.handler.TextWebSocketHandler;

@Component
public class GameWebSocketGame extends TextWebSocketHandler {

    private final ConcurrentHashMap<String, WebSocketSession> sessions = new ConcurrentHashMap<>();

    @Override
    public void afterConnectionEstablished(WebSocketSession session) throws Exception {
        String userId = Objects.requireNonNull(session.getUri()).getQuery().split("=")[1];
        sessions.put(userId, session);
        System.out.println("게임 연결됨 : " + userId);
    }
    
    @Override
    public void handleTextMessage(WebSocketSession session, TextMessage message) throws Exception {
        String userId = session.getUri().getQuery().split("=")[1];
        String payload = message.getPayload();
        
        System.out.println(Arrays.toString(payload.split(":")));
        if (payload.startsWith("CARDS:")) {
        	String opponentId = payload.split(":")[1];
            String cardData = payload.split(":")[2];
            // 상대방에게 카드 데이터를 전송
            WebSocketSession opponentSession = sessions.get(opponentId);
            if (opponentSession != null && opponentSession.isOpen()) {
                opponentSession.sendMessage(new TextMessage("RESULT:" + cardData));
                System.out.println("카드 전달됨: " + userId + " -> " + opponentId + " : " + cardData);
            }
        }
        if (payload.startsWith("QUIT:")) {
        	String opponentId = payload.split(":")[1];
        	WebSocketSession opponentSession = sessions.get(opponentId);
            if (opponentSession != null && opponentSession.isOpen()) {
                opponentSession.sendMessage(new TextMessage("QUIT:"));
                sessions.remove(userId);
                sessions.remove(opponentId);
            }
        }
        if (payload.startsWith("TIMEOUT:")) {
        	String opponentId = payload.split(":")[1];
        	WebSocketSession opponentSession = sessions.get(opponentId);
            if (opponentSession != null && opponentSession.isOpen()) {
                opponentSession.sendMessage(new TextMessage("KICK:"));
                sessions.remove(userId);
                sessions.remove(opponentId);
            }
        }
    }

    @Override
    public void afterConnectionClosed(WebSocketSession session, org.springframework.web.socket.CloseStatus status) throws Exception {
    	String userId = session.getUri().getQuery().split("=")[1];
        sessions.remove(userId);
        System.out.println("게임 해제됨 : " + userId);
    }

}
