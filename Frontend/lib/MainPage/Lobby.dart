import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import '../Game/Card.dart';
import 'dart:async';
import 'dart:convert';
import '../main.dart';
import 'MainPage.dart';
import 'package:intl/intl.dart';

class LobbyPage extends StatefulWidget {
  @override
  _LobbyPageState createState() => _LobbyPageState();
}

class _LobbyPageState extends State<LobbyPage> {
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
      Uri.parse('${MyApp.url2}/lobby?user_id=${MyApp.user_id}'),
    );

    // 사용자별 구독 관리
    channel!.stream.listen(
          (message) {
        print('Received message: $message');
        if (message.startsWith('START:')) {
          String opponentId = message.split(':')[1].trim();
          //pushReplacement는 기존의 페이지를 새로운 페이지로 대체해서, 사실상 dispose 발동
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => CardPage(online: true, opponent: opponentId),
            ),
          );
        }
      },
    );
  }

  String formatWithComma(int number) {
    return NumberFormat('#,###').format(number);
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
                  'assets/Game/Cat/table.jpg'),
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
                      lang("로비") ,
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
                          '${formatWithComma(points)}',
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
                      Image.asset(
                        'assets/Game/rule.png',
                        height: 200,
                      ),
                      SizedBox(height: 20),
                      Text(
                        lang("상대를 찾고 있습니다..."),
                        style: TextStyle(
                          fontSize: 25,
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
                      CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.amberAccent)),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          // push는 뒤로가기 누르면 이전 페이지로 돌아옴(소켓으로 끌고오기용으로 push썼음)
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CardPage(online: false), // MiniGamePage를 구현해야 함
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black54, // 어두운 배경
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.games, color: Colors.amberAccent, size: 24),
                            SizedBox(width: 10),
                            Text(
                              lang("기다리는 동안 혼자하기"),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.amberAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        lang("게임 중 상대를 찾으면 자동으로 시작됩니다."),
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.white70,
                          fontWeight: FontWeight.w400,
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

String lang(String textKey) {
  final localizedTexts = {
    'KOR': {
      '로비': '로비',
      '상대를 찾고 있습니다...': '상대를 찾고 있습니다...',
      '기다리는 동안 게임하기': '기다리는 동안 게임하기',
      '게임 중 상대를 찾으면 자동으로 시작됩니다.': '게임 중 상대를 찾으면 자동으로 시작됩니다.',
      '기다리는 동안 혼자하기': '기다리는 동안 혼자하기',
    },
    'ENG': {
      '로비': 'Lobby',
      '상대를 찾고 있습니다...': 'Searching for an opponent...',
      '기다리는 동안 게임하기': 'Play a game while waiting',
      '게임 중 상대를 찾으면 자동으로 시작됩니다.': 'If an opponent is found during the game, it will start automatically.',
      '기다리는 동안 혼자하기': 'Play alone while waiting',
    },
    'ARA': {
      '로비': 'الردهة',
      '상대를 찾고 있습니다...': 'جارٍ البحث عن خصم...',
      '기다리는 동안 게임하기': 'العب لعبة أثناء الانتظار',
      '게임 중 상대를 찾으면 자동으로 시작됩니다.': 'إذا تم العثور على خصم أثناء اللعب، فسيبدأ تلقائيًا.',
      '기다리는 동안 혼자하기': 'اللعب منفردًا أثناء الانتظار',
    },
    'CHN': {
      '로비': '大厅',
      '상대를 찾고 있습니다...': '正在寻找对手...',
      '기다리는 동안 게임하기': '等待时玩游戏',
      '게임 중 상대를 찾으면 자동으로 시작됩니다.': '游戏中找到对手会自动开始。',
      '기다리는 동안 혼자하기': '等待时单独游戏',
    },
    'JPN': {
      '로비': 'ロビー',
      '상대를 찾고 있습니다...': '対戦相手を探しています...',
      '기다리는 동안 게임하기': '待っている間にゲームをプレイする',
      '게임 중 상대를 찾으면 자동으로 시작됩니다.': 'ゲーム中に相手が見つかった場合、自動的に開始します。',
      '기다리는 동안 혼자하기': '待ちながら一人でプレイ',
    },
    'GER': {
      '로비': 'Lobby',
      '상대를 찾고 있습니다...': 'Suche nach einem Gegner...',
      '기다리는 동안 게임하기': 'Spielen Sie ein Spiel, während Sie warten',
      '게임 중 상대를 찾으면 자동으로 시작됩니다.': 'Wenn während des Spiels ein Gegner gefunden wird, startet es automatisch.',
      '기다리는 동안 혼자하기': 'Allein spielen während des Wartens',
    },
    'RUS': {
      '로비': 'Лобби',
      '상대를 찾고 있습니다...': 'Ищем соперника...',
      '기다리는 동안 게임하기': 'Играйте в игру, пока ждете',
      '게임 중 상대를 찾으면 자동으로 시작됩니다.': 'Если во время игры найден соперник, она начнется автоматически.',
      '기다리는 동안 혼자하기': 'Играть в одиночку во время ожидания',
    },
    'FRA': {
      '로비': 'Hall',
      '상대를 찾고 있습니다...': 'Recherche d\'un adversaire...',
      '기다리는 동안 게임하기': 'Jouez à un jeu en attendant',
      '게임 중 상대를 찾으면 자동으로 시작됩니다.': 'Si un adversaire est trouvé pendant le jeu, il commencera automatiquement.',
      '기다리는 동안 혼자하기': 'Jouer seul en attendant',
    },
    'ESP': {
      '로비': 'Vestíbulo',
      '상대를 찾고 있습니다...': 'Buscando un oponente...',
      '기다리는 동안 게임하기': 'Juega un juego mientras esperas',
      '게임 중 상대를 찾으면 자동으로 시작됩니다.': 'Si se encuentra un oponente durante el juego, comenzará automáticamente.',
      '기다리는 동안 혼자하기': 'Jugar solo mientras esperas',
    },
  };
  return localizedTexts[MyApp.currentLanguage]?[textKey] ?? textKey;
}