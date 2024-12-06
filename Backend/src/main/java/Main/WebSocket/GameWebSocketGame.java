package Main.WebSocket;

import java.util.Objects;
import java.util.concurrent.ConcurrentHashMap;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;
import org.springframework.web.socket.handler.TextWebSocketHandler;

@Component
public class GameWebSocketGame extends TextWebSocketHandler {

    private final ConcurrentHashMap<String, WebSocketSession> sessions = new ConcurrentHashMap<>();

    @Autowired
    private GameWebSocketLobby lobby;

    @Override
    public void afterConnectionEstablished(WebSocketSession session) throws Exception {
        String userId = Objects.requireNonNull(session.getUri()).getQuery().split("=")[1];
        sessions.put(userId, session);
        System.out.println("게임 연결됨 : " + userId);

        ConcurrentHashMap<String, WebSocketSession> userGame = null;
        for (ConcurrentHashMap<String, WebSocketSession> game : lobby.ActiveGame) {
            if (game.containsKey(userId)) {
                userGame = game;
                break;
            }
        }
        if (userGame != null) {
            for (String opponentId : userGame.keySet()) {
                if (!opponentId.equals(userId)) {
                    // 메시지 전송
                    session.sendMessage(new TextMessage("OPPONENT:" + opponentId));
                    System.out.println("게임 매칭 완료: " + userId + " vs " + opponentId);
                    break;
                }
            }
        } else {
            System.out.println("ActiveGame에서 사용자를 찾을 수 없습니다: " + userId);
        }
    }
    
    @Override
    public void handleTextMessage(WebSocketSession session, TextMessage message) throws Exception {
        String userId = getUserId(session);
        String payload = message.getPayload();

        ConcurrentHashMap<String, WebSocketSession> userGame = null;
        for (ConcurrentHashMap<String, WebSocketSession> game : lobby.ActiveGame) {
            if (game.containsKey(userId)) {
                userGame = game;
                break;
            }
        }
        if (userGame == null) return;
        
        if (payload.startsWith("CARDS:")) {
            String cardData = payload.split(":")[1];

            // 상대방에게 카드 데이터를 전송
            for (String opponentId : userGame.keySet()) {
                if (!opponentId.equals(userId)) {
                    WebSocketSession opponentSession = sessions.get(opponentId);
                    if (opponentSession != null && opponentSession.isOpen()) {
                        opponentSession.sendMessage(new TextMessage("RESULT:" + cardData));
                        System.out.println("카드 전달됨: " + userId + " -> " + opponentId + " : " + cardData);
                    }
                    break;
                }
            }
        }
        if (payload.startsWith("TIMEOUT:")) {
            // 상대방 연결 해제
            for (String opponentId : userGame.keySet()) {
                if (!opponentId.equals(userId)) {
                    WebSocketSession opponentSession = sessions.get(opponentId);
                    if (opponentSession != null && opponentSession.isOpen()) {
                        opponentSession.sendMessage(new TextMessage("KICK:"+opponentId));
                    }
                    break;
                }
            }
        }
    }

    @Override
    public void afterConnectionClosed(WebSocketSession session, org.springframework.web.socket.CloseStatus status) throws Exception {
    	String userId = getUserId(session);
  
        ConcurrentHashMap<String, WebSocketSession> userGame = null;
        for (ConcurrentHashMap<String, WebSocketSession> game : lobby.ActiveGame) {
            if (game.containsKey(userId)) {
                userGame = game;
                break;
            }
        }
        if (userGame != null) {
            for (String opponentId : userGame.keySet()) {
                if (!opponentId.equals(userId)) {
                	WebSocketSession opponentSession = sessions.get(opponentId);
                	opponentSession.sendMessage(new TextMessage("QUIT:" + userId));
                    System.out.println("게임 종료: " + userId + " vs " + opponentId);
                    break;
                }
            }
        } else {
            System.out.println("ActiveGame에서 사용자를 찾을 수 없습니다: " + userId);
        }
        
        sessions.remove(userId);
        System.out.println("게임 해제됨 : " + userId);
    }

    private String getUserId(WebSocketSession session) {
        return session.getUri().getQuery().split("=")[1];
    }
}
