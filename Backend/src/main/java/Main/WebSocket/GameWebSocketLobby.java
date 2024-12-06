package Main.WebSocket;

import java.util.ArrayList;
import java.util.List;
import java.util.Objects;
import java.util.concurrent.ConcurrentHashMap;

import org.springframework.stereotype.Component;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;
import org.springframework.web.socket.handler.TextWebSocketHandler;

@Component
public class GameWebSocketLobby extends TextWebSocketHandler {
    private final ConcurrentHashMap<String, WebSocketSession> Lobby = new ConcurrentHashMap<>();
    public List<ConcurrentHashMap<String, WebSocketSession>> ActiveGame = new ArrayList<>();

    @Override
    public void afterConnectionEstablished(WebSocketSession session) throws Exception {
        String userId = Objects.requireNonNull(session.getUri()).getQuery().split("=")[1];
        Lobby.put(userId, session);
        System.out.println("로비 연결됨 : "+userId+" , "+Lobby);
		if(Lobby.size()==2) {
			ConcurrentHashMap<String, WebSocketSession> Game = new ConcurrentHashMap<>();  		
			for (String user_id : Lobby.keySet()) {
			    Game.put(user_id, Lobby.get(user_id));
			    Lobby.get(user_id).sendMessage(new TextMessage("START_GAME"));
			}
			// 게임에 추가된 플레이어를 로비에서 제거
            for (String user_id : Game.keySet()) {
                Lobby.remove(user_id);
            }
    		ActiveGame.add(Game);
		}
    }

    @Override
    public void afterConnectionClosed(WebSocketSession session, org.springframework.web.socket.CloseStatus status) throws Exception {
        String userId = getUserId(session);
        Lobby.remove(userId);
        System.out.println("로비 해제됨 : "+userId);
    }

    private String getUserId(WebSocketSession session) {
        return session.getUri().getQuery().split("=")[1];
    }
}
