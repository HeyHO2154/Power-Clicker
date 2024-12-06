import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math'; // 랜덤 숫자 생성용
import '../main.dart';
import '../MainPage/MainPage.dart';

class CardPage extends StatefulWidget {
  @override
  _CardPageState createState() => _CardPageState();
}

class _CardPageState extends State<CardPage> {
  bool isLoading = true;
  bool isWaitingForResult = false; // 결과 대기 상태
  int myPoints = 0;
  int opponentPoints = 0;
  String opponentId = "";
  String serverMessage = "";
  List<int> myCards = [1, 1, 1, 1, 1];
  List<int> opponentCards = [0,0,0,0,0];
  List<bool> selectedCards = [false, false, false, false, false];
  WebSocketChannel? channel;

  @override
  void initState() {
    super.initState();
    _connectToWebSocket();
    _getPointValue(MyApp.user_id, 0);
  }

  @override
  void dispose() {
    channel?.sink.close();
    super.dispose();
  }

  Future<void> _getPointValue(String id, int n) async {
    final url = Uri.parse('${MyApp.url}/user/point');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': id, 'points': n}),
      );

      if (response.statusCode == 200 && mounted) {
        setState(() {
          if (MyApp.user_id != id) {
            opponentPoints = int.parse(response.body);
          } else {
            myPoints = int.parse(response.body);
          }
        });
      }
    } catch (e) {
      print('Error fetching points: $e');
    }
  }

  void _connectToWebSocket() {
    channel = WebSocketChannel.connect(
      Uri.parse('${MyApp.url2}/game?user_id=${MyApp.user_id}'),
    );

    channel!.stream.listen(
          (message) {
        print('Received message: $message');

        if (message.startsWith('OPPONENT:')) {
          String opponent = message.split(':')[1];
          setState(() {
            opponentId = opponent;
            serverMessage = "교환할 카드를 골라주세요";
          });
          _getPointValue(opponent, 0);
          _shuffleMyCards(); // 상대방 ID를 받은 후 내 카드 섞기
        } else if (message.startsWith('RESULT:')) {
          // 상대방 카드 데이터 수신
          List<int> receivedCards = List<int>.from(jsonDecode(message.split(':')[1]));
          if (isWaitingForResult) {
            // 내가 이미 카드를 전송한 상태면 상대 카드를 즉시 공개
            setState(() {
              opponentCards = receivedCards;
            });
          } else {
            // 내가 아직 카드를 전송하지 않은 경우, 데이터만 저장
            opponentCards = receivedCards;
          }
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

  void _shuffleMyCards() {
    final random = Random();
    setState(() {
      myCards = List.generate(5, (_) => random.nextInt(6) + 1); // 1~6의 랜덤 숫자 5개 생성
    });
    print('My cards shuffled: $myCards');
  }

  void _updateSelectedCards() {
    final random = Random();
    List<int> newCards = List.from(myCards);
    for (int i = 0; i < selectedCards.length; i++) {
      if (selectedCards[i]) {
        newCards[i] = random.nextInt(6) + 1; // 선택된 카드만 다시 섞음
      }
    }
    setState(() {
      myCards = newCards;
      selectedCards = [false, false, false, false, false]; // 선택 초기화
      isWaitingForResult = true; // 결과 대기 상태
    });

    // 변경된 카드 배열을 서버로 전송
    _sendCardsToServer(newCards);
  }

  void _sendCardsToServer(List<int> cards) {
    if (channel != null) {
      // 서버에서 기대하는 포맷으로 메시지를 전송
      String cardData = "CARDS:${cards}";
      channel!.sink.add(cardData);
      print('Sent cards to server: $cardData');
    }

    // 상대 카드가 이미 도착했으면 즉시 공개
    if (opponentCards != [0,0,0,0,0]) {
      setState(() {
        opponentCards;
      });
    }
  }


  // 카드 번호에 따라 카드 이미지 경로 반환
  String _getCardImagePath(int cardNumber) {
    if(cardNumber==0){
      return 'assets/Game/Cards/back.png';
    }
    return 'assets/Game/Cards/cat$cardNumber.png';
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/Theme/${MyApp.currentTheme}/MainPage.jpg'),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.5),
                BlendMode.darken,
              ),
            ),
          ),
          child: Column(
            children: [
              // 상단 커스텀 바
              Padding(
                padding: const EdgeInsets.only(top: 40.0, bottom: 10.0, right: 10.0),
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
                      '카드 게임',
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
                    SizedBox(width: 50),
                  ],
                ),
              ),
              // 카드 게임 영역
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 상대방 카드 영역
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: List.generate(5, (index) {
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(5),
                                child: Image.asset(
                                  _getCardImagePath(opponentCards[index]),
                                  width: 75,
                                  fit: BoxFit.cover,
                                ),
                              );
                            }),
                          ),
                          SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              SizedBox(width: 20),
                              Text(
                                "$opponentId",
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 10),
                              Row(
                                children: [
                                  Image.asset(
                                    'assets/UI/coin.png',
                                    height: 40,
                                  ),
                                  SizedBox(width: 5),
                                  Text(
                                    '$opponentPoints',
                                    style: TextStyle(
                                      fontSize: 30,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.amberAccent,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // 중간 공간: 설명서 이미지 및 메시지
                    Column(
                      children: [
                        Image.asset(
                          'assets/Game/rule.png',
                          width: 150,
                        ),
                        SizedBox(height: 10),
                        Text(
                          isWaitingForResult
                              ? '상대를 기다리는 중...'
                              : serverMessage.isEmpty
                              ? '...'
                              : serverMessage,
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                    // 플레이어 카드 영역
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              SizedBox(width: 20),
                              Text(
                                "${MyApp.user_id}",
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 10),
                              Row(
                                children: [
                                  Image.asset(
                                    'assets/UI/coin.png',
                                    height: 40,
                                  ),
                                  SizedBox(width: 5),
                                  Text(
                                    '$myPoints',
                                    style: TextStyle(
                                      fontSize: 30,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.amberAccent,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: List.generate(5, (index) {
                              return GestureDetector(
                                onTap: isWaitingForResult
                                    ? null
                                    : () {
                                  setState(() {
                                    selectedCards[index] = !selectedCards[index];
                                  });
                                },
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(5),
                                      child: Image.asset(
                                        _getCardImagePath(myCards[index]),
                                        width: 75,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    if (selectedCards[index])
                                      Positioned.fill(
                                        child: Container(
                                          color: Colors.black.withOpacity(0.5),
                                          child: Center(
                                            child: Icon(
                                              Icons.check,
                                              color: Colors.green,
                                              size: 30,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            }),
                          ),
                          SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: isWaitingForResult
                                ? null
                                : () {
                              _updateSelectedCards();
                            },
                            child: Text(
                              '카드 변경',
                              style: TextStyle(fontSize: 20),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
