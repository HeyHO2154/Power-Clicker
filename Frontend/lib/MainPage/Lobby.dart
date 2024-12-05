import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import '../Game/Card.dart';
import 'dart:async';
import 'dart:convert';
import '../main.dart';
import 'MainPage.dart';

class LobbyPage extends StatefulWidget {
  @override
  _LobbyPageState createState() => _LobbyPageState();
}

class _LobbyPageState extends State<LobbyPage> {
  bool isLoading = true;
  int points = 0;
  WebSocketChannel? channel;

  @override
  void initState() {
    super.initState();
    _connectToWebSocket();
    _getPointValue(0);
  }
  @override
  void dispose() {
    channel?.sink.close(); // WebSocket 닫기
    super.dispose();
  }

  Future<void> _getPointValue(n) async {
    final url = Uri.parse('${MyApp.url}/user/point');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': MyApp.user_id,
        'points': n
      }), //여기서의 points는 더해줄 값을 의미(0은 단순 포인트 조회)
    );
    if (response.statusCode == 200) {
      setState(() {
        points = int.parse(response.body);
      });
    }
  }

  // 백엔드 서버와 소켓 연결을 초기화하는 메서드
  void _connectToWebSocket() {
    channel = WebSocketChannel.connect(
      Uri.parse('${MyApp.url2}/game?user_id=${MyApp.user_id}'),
    );

    channel!.stream.listen((message) {
      print('Received message: $message');
      if (message.startsWith('START_GAME:')) {
        String sessionId = message.split(':')[1]; // 세션 ID 추출
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => CardPage(sessionId: sessionId)),
        );
      }
    }, onError: (error) {
      print('WebSocket error: $error');
    }, onDone: () {
      print('WebSocket closed');
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // 뒤로 가기 키 막기
        return false;
      },
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(
                  'assets/Theme/${MyApp.currentTheme}/MainPage.jpg'),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.5), BlendMode.darken),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(
                    top: 40.0, bottom: 0, right: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 뒤로 가기 버튼
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back,
                        color: Color(0xFFB8860B), // 어두운 황금색
                        size: 40, // 아이콘 크기
                      ),
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MainPage(),
                          ),
                        );
                      },
                    ),
                    // 내 정보 제목
                    Text(
                      '상점',
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFD4AF37),
                        shadows: [
                          Shadow(
                            blurRadius: 10,
                            color: Colors.black54,
                            offset: Offset(4, 4),
                          ),
                        ],
                      ),
                    ),
                    // 코인 아이콘과 포인트 표시
                    Row(
                      children: [
                        Image.asset(
                          'assets/UI/coin.png',
                          height: 50, // 코인 아이콘 크기
                        ),
                        SizedBox(width: 5),
                        Text(
                          '$points',
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.w600,
                            color: Colors.amberAccent,
                            shadows: [
                              Shadow(
                                blurRadius: 4,
                                color: Colors.black38,
                                offset: Offset(2, 2),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "플레이어를 찾고 있습니다...",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              blurRadius: 5,
                              color: Colors.black54,
                              offset: Offset(2, 2),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 20),
                      isLoading
                          ? CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.amberAccent),
                      )
                          : Icon(Icons.check_circle,
                          color: Colors.green, size: 50),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}