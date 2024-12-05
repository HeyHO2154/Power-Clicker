package Main.WebSocket;

import java.util.Objects;
import java.util.Queue;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.LinkedBlockingQueue;

import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;
import org.springframework.web.socket.handler.TextWebSocketHandler;

public class GameWebSocketLobby extends TextWebSocketHandler {
    private final ConcurrentHashMap<String, WebSocketSession> sessions = new ConcurrentHashMap<>();
    private final Queue<String> waitingQueue = new LinkedBlockingQueue<>();

    @Override
    public void afterConnectionEstablished(WebSocketSession session) throws Exception {
        String userId = Objects.requireNonNull(session.getUri()).getQuery().split("=")[1];
        sessions.put(userId, session);
        waitingQueue.offer(userId);
        System.out.println("로비 연결됨 : "+userId+" , "+waitingQueue);
        if (waitingQueue.size() >= 2) {
            checkAndStartGame();
        }
    }

    @Override
    public void afterConnectionClosed(WebSocketSession session, org.springframework.web.socket.CloseStatus status) throws Exception {
        String userId = getUserId(session);
        sessions.remove(userId);
        System.out.println("로비 해제됨 : "+userId);
    }

    private String getUserId(WebSocketSession session) {
        return session.getUri().getQuery().split("=")[1];
    }

    private void checkAndStartGame() throws Exception {
        while (waitingQueue.size() >= 2) {
            String player1 = waitingQueue.poll();
            String player2 = waitingQueue.poll();

            if (player1 != null && player2 != null) {
                WebSocketSession session1 = sessions.get(player1);
                WebSocketSession session2 = sessions.get(player2);

                if (session1 != null && session2 != null) {
                	session1.sendMessage(new TextMessage("START_GAME"));
                    session2.sendMessage(new TextMessage("START_GAME"));

                    System.out.println("Game started between " + player1 + " and " + player2);
                }
            }
        }
    }

}
