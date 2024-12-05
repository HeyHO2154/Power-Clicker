package Main.WebSocket;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.socket.config.annotation.EnableWebSocket;
import org.springframework.web.socket.config.annotation.WebSocketConfigurer;
import org.springframework.web.socket.config.annotation.WebSocketHandlerRegistry;

@Configuration
@EnableWebSocket
public class WebSocketConfig implements WebSocketConfigurer {

    @Autowired
    private GameWebSocketLobby gameWebSocketLobby;

    @Autowired
    private GameWebSocketGame gameWebSocketGame;

    @Override
    public void registerWebSocketHandlers(WebSocketHandlerRegistry registry) {
        registry.addHandler(gameWebSocketLobby, "/lobby").setAllowedOrigins("*");
        registry.addHandler(gameWebSocketGame, "/game").setAllowedOrigins("*");
    }
}

