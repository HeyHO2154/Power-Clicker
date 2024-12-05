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
    private GameWebSocketLobby lobby; // Spring에서 관리 중인 인스턴스를 주입받음

    @Override
    public void afterConnectionEstablished(WebSocketSession session) throws Exception {
        String userId = Objects.requireNonNull(session.getUri()).getQuery().split("=")[1];
        sessions.put(userId, session);
        System.out.println("게임 연결됨 : "+userId);
        
        ConcurrentHashMap<String, WebSocketSession> userGame = null;
        for (ConcurrentHashMap<String, WebSocketSession> game : lobby.ActiveGame) {
            if (game.containsKey(userId)) {
                userGame = game;
                break;
            }
        }
        if (userGame != null) {
            // 상대방 ID 찾기
            for (String opponentId : userGame.keySet()) {
                if (!opponentId.equals(userId)) { // 상대방 ID 확인
                    WebSocketSession opponentSession = userGame.get(opponentId);
                    // 접속한 유저에게 상대방 ID 전송
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
    public void afterConnectionClosed(WebSocketSession session, org.springframework.web.socket.CloseStatus status) throws Exception {
        String userId = getUserId(session);
        sessions.remove(userId);
        System.out.println("게임 해제됨 : "+userId);
    }

    private String getUserId(WebSocketSession session) {
        return session.getUri().getQuery().split("=")[1];
    }

}
