package Main.WebSocket;

import java.util.LinkedList;
import java.util.Objects;
import java.util.Queue;
import java.util.concurrent.ConcurrentHashMap;

import org.springframework.stereotype.Component;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;
import org.springframework.web.socket.handler.TextWebSocketHandler;

@Component
public class GameWebSocketLobby extends TextWebSocketHandler {
	
	/*
	 * 지금, 같이하기에서 대기중 연습게임하다가 나가도 로비에 잔존하는 유령 대기자 버그 있음(추후 고치기)
	 */
	
    private final ConcurrentHashMap<String, WebSocketSession> CARD1 = new ConcurrentHashMap<>();
    public Queue<String> Waiting = new LinkedList<>();

    @Override
    public void afterConnectionEstablished(WebSocketSession session) throws Exception {
        String userId = Objects.requireNonNull(session.getUri()).getQuery().split("=")[1];
        CARD1.put(userId, session);
        System.out.println("로비 연결됨 : "+userId+" , "+CARD1);
        if(Waiting.size()==0) {
        	//대기자가 없으면, 대기자에 추가
        	Waiting.add(userId);
        }else {
        	//누군가 있으면, 연결
        	for (String opponentId : CARD1.keySet()) {
        		if(opponentId == Waiting.peek() && !opponentId.equals(userId)) {
        			Waiting.poll();
        			CARD1.get(userId).sendMessage(new TextMessage("START:"+opponentId));
        			CARD1.get(opponentId).sendMessage(new TextMessage("START:"+userId));
        			CARD1.remove(opponentId);
        			CARD1.remove(userId);
        			System.out.println("로비 해제됨 : "+opponentId);
        			System.out.println("로비 해제됨 : "+userId);
        		}
			}
        }
    }

    @Override
    public void afterConnectionClosed(WebSocketSession session, org.springframework.web.socket.CloseStatus status) throws Exception {
        String userId = session.getUri().getQuery().split("=")[1];
        CARD1.remove(userId);
        Waiting.remove(userId);
        System.out.println("로비 해제됨 : "+userId);
    }

}
