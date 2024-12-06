import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math'; // 랜덤 숫자 생성용
import '../main.dart';
import '../MainPage/MainPage.dart';
import 'package:audioplayers/audioplayers.dart';

class CardPage extends StatefulWidget {
  @override
  _CardPageState createState() => _CardPageState();
}

class _CardPageState extends State<CardPage> {
  bool isLoading = true;
  bool isWaitingForResult = false; // 결과 대기 상태
  int countdown = 17;
  int betting = 50;
  int myPoints = 0;
  int opponentPoints = 0;
  String opponentId = "";
  String serverMessage = "";
  List<int> myCards = [1, 1, 1, 1, 1];
  List<int> opponentCards = [0,0,0,0,0];
  List<int> opponentCards2 = [0,0,0,0,0];
  List<bool> selectedCards = [false, false, false, false, false];
  WebSocketChannel? channel;
  final AudioPlayer _audioPlayer = AudioPlayer(); // 카드 클릭 효과음 플레이어
  final AudioPlayer _bgmPlayer = AudioPlayer(); // 배경 음악 플레이어

// 배경 음악 시작 함수
  Future<void> _startBackgroundMusic() async {
    try {
      await _bgmPlayer.setReleaseMode(ReleaseMode.loop); // 반복 재생 모드
      await _bgmPlayer.play(AssetSource('Sound/CardBgm.mp3')); // 배경 음악 경로
    } catch (e) {
      print("Error starting background music: $e");
    }
  }

  // 카드 클릭 시 효과음 재생
  Future<void> _card() async {
    try {
      await _audioPlayer.play(AssetSource('Sound/card.mp3')); // 효과음 파일 경로
    } catch (e) {
      print("Error playing sound: $e");
    }
  }
  // 카드 클릭 시 효과음 재생
  Future<void> _Chaching() async {
    try {
      await _audioPlayer.play(AssetSource('Sound/Chacing.mp3')); // 효과음 파일 경로
    } catch (e) {
      print("Error playing sound: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    _startBackgroundMusic(); // 배경 음악 시작
    _connectToWebSocket();
    _getPointValue(MyApp.user_id, 0);
  }

  @override
  void dispose() {
    channel?.sink.close();
    _bgmPlayer.stop(); // 배경 음악 정지
    _bgmPlayer.dispose(); // 배경 음악 플레이어 해제
    _audioPlayer.dispose(); // 카드 클릭 효과음 플레이어 해제
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
            serverMessage = lang("상대가 게임을 나갔습니다");
            myCards = [0, 0, 0, 0, 0];
            opponentCards = [0,0,0,0,0];
            opponentCards2 = [0,0,0,0,0];
            selectedCards = [false, false, false, false, false];
          });
        } else if (message.startsWith('KICK:')) {
          setState(() {
            isWaitingForResult = true;
            serverMessage = lang("상대가 시간 초과되었습니다!");
            myCards = [0, 0, 0, 0, 0];
            opponentCards = [0,0,0,0,0];
            opponentCards2 = [0,0,0,0,0];
            selectedCards = [false, false, false, false, false];
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
          serverMessage = "${lang("교환할 카드를 고르세요")} (${countdown-1})";
        });
        if(countdown<=0){
          channel!.sink.add("TIMEOUT:${MyApp.user_id}");
          setState(() {
            isWaitingForResult = true;
            serverMessage = lang("제한시간 초과!");
            myCards = [0, 0, 0, 0, 0];
            selectedCards = [false, false, false, false, false];
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
        serverMessage = lang("상대를 기다리는 중..");
      });
    }
  }

  void _Result() async {
    // 점수 계산
    int myScore = checkCard(myCards); // 내 카드 점수 계산
    int opponentScore = checkCard(opponentCards2); // 상대 카드 점수 계산

    String resultMessage;

    if (myScore > opponentScore) {
      // 내가 이겼을 때
      _Chaching();
      resultMessage = "${lang("승리!")} +${betting}";
      _getPointValue(MyApp.user_id, betting); // 점수 추가
    } else if (myScore < opponentScore) {
      // 내가 졌을 때
      resultMessage = "${lang("패배..")} -${betting}";
      _getPointValue(MyApp.user_id, betting*-1); // 점수 차감
    } else {
      // 무승부
      resultMessage = lang("무승부");
    }

    // 결과 메시지 업데이트
    setState(() {
      countdown = 17;
      myCards.sort();
      opponentCards2.sort();
      opponentCards = List.from(opponentCards2);
      serverMessage = resultMessage;
      _getPointValue(MyApp.user_id, 0);
      _getPointValue(opponentId, 0);
    });

    await _getPointValue(MyApp.user_id, 0);
    Future.delayed(Duration(seconds: 7), () {
        if(myPoints<=0){
          channel!.sink.add("TIMEOUT:${MyApp.user_id}");
          setState(() {
            isWaitingForResult = true;
            serverMessage = lang("잔액 부족");
            myCards = [0, 0, 0, 0, 0];
            opponentCards = [0,0,0,0,0];
            opponentCards2 = [0,0,0,0,0];
            selectedCards = [false, false, false, false, false];
          });
        }else if(!myCards.every((card) => card == 0)){
          //다음 게임 초기화
          setState(() {
            _getPointValue(MyApp.user_id, 0); // 점수 차감
            _getPointValue(opponentId, 0);
            serverMessage = lang("교환할 카드를 고르세요");
            _shuffleMyCards();
            opponentCards = [0,0,0,0,0];
            opponentCards2 = [0,0,0,0,0];
            selectedCards = [false, false, false, false, false];
            isWaitingForResult = false; // 결과 대기 상태
            betting = 50;
          });
        }
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
                      lang('카드 게임'),
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
                                getTruncatedText(opponentId, MediaQuery.of(context).size.width * 0.6),
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
                                getTruncatedText(MyApp.user_id, MediaQuery.of(context).size.width * 0.6),
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
                                  _card(); // 카드 클릭 시 효과음 재생
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
                                text: lang('추가 베팅 ${betting}'),
                                onTap: isWaitingForResult
                                    ? null
                                    : () {
                                  _Chaching(); // 효과음 메서드 실행
                                  betting = 100;
                                },
                              ),
                              _buildActionButton(
                                text: lang('카드 변경'),
                                onTap: isWaitingForResult
                                    ? null
                                    : () {
                                  _Chaching(); // 효과음 메서드 실행
                                  _updateSelectedCards();
                                },
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


// 글자수 생략 함수 (내부에서 스타일 고정)
String getTruncatedText(String text, double maxWidth) {
  final TextStyle style = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  final TextPainter textPainter = TextPainter(
    text: TextSpan(text: text, style: style),
    maxLines: 1,
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: maxWidth);

  if (textPainter.didExceedMaxLines) {
    for (int i = text.length - 1; i >= 0; i--) {
      final TextPainter truncatedTextPainter = TextPainter(
        text: TextSpan(text: text.substring(0, i) + '...', style: style),
        maxLines: 1,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: maxWidth);

      if (!truncatedTextPainter.didExceedMaxLines) {
        return text.substring(0, i) + '...';
      }
    }
  }
  return text; // 제한에 걸리지 않으면 원래 텍스트 반환
}

String lang(String textKey) {
  final localizedTexts = {
    'KOR': {
      '상대가 게임을 나갔습니다': '상대가 게임을 나갔습니다',
      '상대가 시간 초과되었습니다!': '상대가 시간 초과되었습니다!',
      '교환할 카드를 고르세요': '교환할 카드를 고르세요',
      '제한시간 초과!': '제한시간 초과!',
      '상대를 기다리는 중..': '상대를 기다리는 중..',
      '승리!': '승리!',
      '패배..': '패배..',
      '무승부': '무승부',
      '카드 게임': '카드 게임',
      '추가 베팅': '추가 베팅',
      '카드 변경': '카드 변경',
    },
    'ENG': {
      '상대가 게임을 나갔습니다': 'Opponent left the game',
      '상대가 시간 초과되었습니다!': 'Opponent timed out!',
      '교환할 카드를 고르세요': 'Pick cards to exchange',
      '제한시간 초과!': 'Time is up!',
      '상대를 기다리는 중..': 'Waiting for opponent...',
      '승리!': 'Victory!',
      '패배..': 'Defeat...',
      '무승부': 'Draw',
      '카드 게임': 'Card Game',
      '추가 베팅': 'Extra Bet',
      '카드 변경': 'Change Cards',
    },
    'ARA': {
      '상대가 게임을 나갔습니다': 'انسحب الخصم',
      '상대가 시간 초과되었습니다!': 'انتهى وقت الخصم!',
      '교환할 카드를 고르세요': 'اختر البطاقات للتبديل',
      '제한시간 초과!': 'انتهى الوقت!',
      '상대를 기다리는 중..': 'انتظار الخصم...',
      '승리!': 'فوز!',
      '패배..': 'هزيمة...',
      '무승부': 'تعادل',
      '카드 게임': 'لعبة البطاقات',
      '추가 베팅': 'رهان إضافي',
      '카드 변경': 'تبديل البطاقات',
    },
    'CHN': {
      '상대가 게임을 나갔습니다': '对手退出了游戏',
      '상대가 시간 초과되었습니다!': '对手超时了！',
      '교환할 카드를 고르세요': '选择要交换的牌',
      '제한시간 초과!': '时间到！',
      '상대를 기다리는 중..': '等待对手...',
      '승리!': '胜利！',
      '패배..': '失败...',
      '무승부': '平局',
      '카드 게임': '纸牌游戏',
      '추가 베팅': '额外下注',
      '카드 변경': '更换牌',
    },
    'JPA': {
      '상대가 게임을 나갔습니다': '相手がゲームを退出しました',
      '상대가 시간 초과되었습니다!': '相手が時間切れになりました！',
      '교환할 카드를 고르세요': '交換するカードを選んでください',
      '제한시간 초과!': '時間切れ！',
      '상대를 기다리는 중..': '相手を待っています...',
      '승리!': '勝利！',
      '패배..': '敗北...',
      '무승부': '引き分け',
      '카드 게임': 'カードゲーム',
      '추가 베팅': '追加ベット',
      '카드 변경': 'カード変更',
    },
    'GER': {
      '상대가 게임을 나갔습니다': 'Gegner hat das Spiel verlassen',
      '상대가 시간 초과되었습니다!': 'Gegner hat die Zeit überschritten!',
      '교환할 카드를 고르세요': 'Wählen Sie Karten zum Tauschen',
      '제한시간 초과!': 'Zeit abgelaufen!',
      '상대를 기다리는 중..': 'Warten auf Gegner...',
      '승리!': 'Sieg!',
      '패배..': 'Niederlage...',
      '무승부': 'Unentschieden',
      '카드 게임': 'Kartenspiel',
      '추가 베팅': 'Zusatzwette',
      '카드 변경': 'Karten wechseln',
    },
    'RUS': {
      '상대가 게임을 나갔습니다': 'Противник вышел из игры',
      '상대가 시간 초과되었습니다!': 'Противник не успел по времени!',
      '교환할 카드를 고르세요': 'Выберите карты для обмена',
      '제한시간 초과!': 'Время вышло!',
      '상대를 기다리는 중..': 'Ожидание противника...',
      '승리!': 'Победа!',
      '패배..': 'Поражение...',
      '무승부': 'Ничья',
      '카드 게임': 'Карточная игра',
      '추가 베팅': 'Дополнительная ставка',
      '카드 변경': 'Смена карт',
    },
    'FRA': {
      '상대가 게임을 나갔습니다': 'Adversaire a quitté la partie',
      '상대가 시간 초과되었습니다!': 'Temps dépassé pour l’adversaire !',
      '교환할 카드를 고르세요': 'Choisissez les cartes à échanger',
      '제한시간 초과!': 'Temps écoulé !',
      '상대를 기다리는 중..': 'En attente d’adversaire...',
      '승리!': 'Victoire !',
      '패배..': 'Défaite...',
      '무승부': 'Égalité',
      '카드 게임': 'Jeu de cartes',
      '추가 베팅': 'Mise supplémentaire',
      '카드 변경': 'Changer de cartes',
    },
    'ESP': {
      '상대가 게임을 나갔습니다': 'El oponente abandonó el juego',
      '상대가 시간 초과되었습니다!': 'El oponente agotó el tiempo!',
      '교환할 카드를 고르세요': 'Elige cartas para intercambiar',
      '제한시간 초과!': '¡Tiempo agotado!',
      '상대를 기다리는 중..': 'Esperando al oponente...',
      '승리!': '¡Victoria!',
      '패배..': 'Derrota...',
      '무승부': 'Empate',
      '카드 게임': 'Juego de cartas',
      '추가 베팅': 'Apuesta adicional',
      '카드 변경': 'Cambiar cartas',
    },

  };
  return localizedTexts[MyApp.currentLanguage]?[textKey] ?? textKey;
}