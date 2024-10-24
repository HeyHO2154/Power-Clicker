package Main;


import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.socket.config.annotation.EnableWebSocket;

@SpringBootApplication
@Configuration
@EnableWebSocket
public class MainBackend {

	public static void main(String[] args) {
		SpringApplication.run(MainBackend.class, args);
	}

}
