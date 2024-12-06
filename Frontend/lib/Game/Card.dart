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
  int countdown = 11;
  int myPoints = 0;
  int opponentPoints = 0;
  String opponentId = "";
  String serverMessage = "";
  List<int> myCards = [1, 1, 1, 1, 1];
  List<int> opponentCards = [0,0,0,0,0];
  List<int> opponentCards2 = [0,0,0,0,0];
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
          });
          _startCountdown(); // 내가 아직 카드를 전송하지 않은 경우,  카운트다운 시작
          _getPointValue(opponent, 0);
          _shuffleMyCards(); // 상대방 ID를 받은 후 내 카드 섞기
        } else if (message.startsWith('RESULT:')) {
          // 상대방 카드 데이터 수신
          List<int> receivedCards = List<int>.from(jsonDecode(message.split(':')[1]));
          opponentCards2 = receivedCards;
          if (isWaitingForResult) {
            _Result(); // 내가 이미 카드를 전송한 상태면 상대 카드를 즉시 공개
          }
        } else if (message.startsWith('QUIT:')) {
          setState(() {
            isWaitingForResult = true;
            serverMessage = "상대가 게임을 나갔습니다";
            myCards = [0, 0, 0, 0, 0];
          });
        } else if (message.startsWith('KICK:')) {
          setState(() {
            isWaitingForResult = true;
            serverMessage = "상대가 제한시간 초과되었습니다!";
            myCards = [0, 0, 0, 0, 0];
          });
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

  void _startCountdown() {
    Timer.periodic(Duration(seconds: 1), (timer) {
      if (countdown >= 0 && mounted && !isWaitingForResult) {
        countdown--;
        setState(() {
          serverMessage = "교환할 카드를 골라주세요 (${countdown-1})";
        });
        if(countdown<=0){
          channel!.sink.add("TIMEOUT:${MyApp.user_id}");
          setState(() {
            isWaitingForResult = true;
            serverMessage = "제한시간 초과!";
            myCards = [0, 0, 0, 0, 0];
          });
        }
      }
    });
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
    print(opponentCards2);
    // 상대 카드가 이미 도착했으면 즉시 공개
    if (!opponentCards2.every((card) => card == 0)) {
      setState(() {
        opponentCards = opponentCards2;
      });
      _Result();
    }else{
      setState(() {
        serverMessage = "상대를 기다리는 중..";
      });
    }
  }

  void _Result() {
    // 점수 계산
    int myScore = checkCard(myCards); // 내 카드 점수 계산
    int opponentScore = checkCard(opponentCards2); // 상대 카드 점수 계산

    String resultMessage;

    if (myScore > opponentScore) {
      // 내가 이겼을 때
      resultMessage = "이겼습니다! +100점";
      _getPointValue(MyApp.user_id, 100); // 점수 추가
    } else if (myScore < opponentScore) {
      // 내가 졌을 때
      resultMessage = "졌습니다. -50점";
      _getPointValue(MyApp.user_id, -50); // 점수 차감
    } else {
      // 무승부
      resultMessage = "무승부입니다!";
    }

    // 결과 메시지 업데이트
    setState(() {
      countdown = 11;
      opponentCards = opponentCards2;
      serverMessage = resultMessage;
      _getPointValue(MyApp.user_id, 0); // 점수 차감
      _getPointValue(opponentId, 0);
    });

    Future.delayed(Duration(seconds: 7), () {
      setState(() {
        _getPointValue(MyApp.user_id, 0); // 점수 차감
        _getPointValue(opponentId, 0);
        serverMessage = "교환할 카드를 골라주세요";
        _shuffleMyCards();
        opponentCards = [0,0,0,0,0];
        opponentCards2 = [0,0,0,0,0];
        selectedCards = [false, false, false, false, false];
        isWaitingForResult = false; // 결과 대기 상태
      });
    });
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
              image: AssetImage('assets/Game/table.jpg'),
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
                          serverMessage,
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly, // 버튼 사이 동일한 간격
                            children: [
                              _buildActionButton(
                                text: '추가 베팅',
                                onTap: isWaitingForResult ? null : () => _updateSelectedCards(),
                              ),
                              _buildActionButton(
                                text: '카드 변경',
                                onTap: isWaitingForResult ? null : () => _updateSelectedCards(),
                              ),
                            ],
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

int checkCard(List<int> cards) {
  List<int> num = List.filled(6, 0);

  // 각 숫자의 개수를 카운트
  for (int card in cards) {
    num[card - 1]++;
  }

  int max = -1;
  int min = -1;
  int maxIndex = -1;
  int minIndex = -1;

  for (int i = 0; i < num.length; i++) {
    if (num[i] > max) {
      max = num[i];
      maxIndex = i + 1;
    } else if (num[i] >= min && num[i] != 0) {
      min = num[i];
      minIndex = i + 1;
    }
  }

  print("$maxIndex가 $max장");
  print("$minIndex가 $min장");

  if (max == 5) return 600 + maxIndex * 10;
  if (max == 4) return 500 + maxIndex * 10 + minIndex;
  if (max == 3) {
    if (min == 2) return 400 + maxIndex * 10 + minIndex;
    return 300 + maxIndex * 10 + minIndex;
  }
  if (max == 2) {
    if (min == 2) return 200 + maxIndex * 10 + minIndex;
    return 100 + maxIndex * 10 + minIndex;
  }
  return minIndex;
}

Widget _buildActionButton({required String text, VoidCallback? onTap}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      width: 160, // 버튼 너비
      height: 50, // 버튼 높이
      decoration: BoxDecoration(
        color: onTap == null ? Colors.grey : Colors.black54, // 비활성화 시 회색
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Color(0xFFD4AF37), // 금색 테두리
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 6,
            offset: Offset(2, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: onTap == null ? Colors.black54 : Colors.white,
          ),
        ),
      ),
    ),
  );
}
