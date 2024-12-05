import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:async';
import 'dart:convert';
import '../main.dart';
import '../MainPage/MainPage.dart';

class CardPage extends StatefulWidget {
  @override
  _CardPageState createState() => _CardPageState();
}

class _CardPageState extends State<CardPage> {
  bool isLoading = true;
  int points = 0;
  String opponentId = ""; // 상대방 ID 저장
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

  Future<void> _getPointValue(int n) async {
    final url = Uri.parse('${MyApp.url}/user/point');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': MyApp.user_id, 'points': n}),
      );

      if (response.statusCode == 200 && mounted) {
        setState(() {
          points = int.parse(response.body);
        });
      }
    } catch (e) {
      print('Error fetching points: $e');
    }
  }

  void _connectToWebSocket() {
    // 기존 사용자별 WebSocket 채널 생성
    channel = WebSocketChannel.connect(
      Uri.parse('${MyApp.url2}/game?user_id=${MyApp.user_id}'),
    );

    // 사용자별 구독 관리
    channel!.stream.listen(
          (message) {
        print('Received message: $message');
        if (message.startsWith('OPPONENT:')) {
          // OPPONENT 메시지에서 상대방 ID 추출
          String opponent = message.split(':')[1];
          setState(() {
            opponentId = opponent;
          });
          print('Your opponent is: $opponent');
        }
      },
      onError: (error) {
        print('WebSocket error: $error');
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
      },
      onDone: () {
        print('WebSocket closed');
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
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
                padding:
                const EdgeInsets.only(top: 40.0, bottom: 0, right: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back,
                        color: Color(0xFFB8860B),
                        size: 40,
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
                    Text(
                      '카드',
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
                    Row(
                      children: [
                        Image.asset(
                          'assets/UI/coin.png',
                          height: 50,
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
                        "곧 게임을 시작합니다!\n당신의 상대: $opponentId",
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
