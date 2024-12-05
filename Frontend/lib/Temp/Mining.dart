import 'package:flutter/material.dart';
import 'package:frontend/main.dart';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'dart:async';

import '../MainPage/MainPage.dart';
import '../MainPage/Shop.dart'; // 타이머 사용을 위해 추가

class Mining extends StatefulWidget {
  @override
  _MiningState createState() => _MiningState();
}

class _MiningState extends State<Mining> {
  Random random = Random();
  List<Widget> circles = [];
  int totalPoints = 0; // 포인트 저장 변수
  String? userId; // 사용자 ID
  bool isLoading = true; // 로딩 상태 변수
  List<Map<String, dynamic>> scoreMessages = []; // 점수 메시지와 위치를 저장할 리스트
  bool isFeverTime = false; // 피버 타임 여부
  Timer? feverTimer; // 피버 타임 타이머
  int feverProbability = 1; // 피버 타임 발생 확률

  VideoPlayerController? _videoPlayerController; // 비디오 플레이어 컨트롤러 추가

  // 이미지 파일 목록
  final List<String> catImages = [
    'assets/cat1.png',
    'assets/cat2.png',
    'assets/cat3.png',
    'assets/cat4.png',
    'assets/cat5.png',
    'assets/cat6.png',
    'assets/cat1.png',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserId(); // 사용자 ID 불러오기

    // 비디오 플레이어 컨트롤러 초기화
    _videoPlayerController = VideoPlayerController.asset('assets/cat.mp4')
      ..initialize().then((_) {
        setState(() {
          print("비디오 초기화 성공");
        });
      }).catchError((error) {
        print("비디오 초기화 실패: $error");
      });
  }

  Future<void> _loadUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('user_id'); // 저장된 userId 불러오기
    if (userId != null) {
      await _getPointValue(0); // userId를 사용하여 포인트 불러오기
    }
    setState(() {
      isLoading = false; // 포인트 불러오기가 완료된 후 로딩 상태 해제
    });
    _generateCircle(); // 원 생성 시작
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
        totalPoints = int.parse(response.body);
      });
    }
  }


  void _generateCircle() {
    double size = random.nextDouble() * 50 + 50; // 크기 랜덤
    Color color = Color((random.nextDouble() * 0xFFFFFF).toInt()).withOpacity(
        1.0); // 색상 랜덤
    Offset position = Offset(
        random.nextDouble() * 300, random.nextDouble() * 600); // 위치 랜덤
    int circleId = DateTime
        .now()
        .millisecondsSinceEpoch; // 고유 ID 생성

    if (!mounted) return; // 위젯이 트리에 없으면 함수 중단

    setState(() {
      // 피버 타임이 아닐 때만 기존 원 삭제
      if (!isFeverTime) {
        circles.clear();
      }

      circles.add(Positioned(
        key: ValueKey(circleId), // Positioned에 고유 ID를 키로 설정
        left: position.dx,
        top: position.dy,
        child: GestureDetector(
          onTap: () {
            setState(() {
              // 원의 크기에 따라 점수 증가
              int points = ((100 - size) / 10).round() +
                  1; // 원의 크기가 작을수록 큰 점수 부여
              if (isFeverTime) {
                points *= 1; // 피버 타임이면 1배로 증가 => 지금 피버타임 0.5초로 줄어서 1배가 맞음
              }
              totalPoints += points;
              _showScoreMessage(points, position); // 점수 메시지 표시
              _getPointValue(points); // 서버에 포인트 업데이트

              // 클릭된 원만 삭제
              circles.removeWhere((circle) => circle.key == ValueKey(circleId));

              // 피버 타임 발생 로직
              if (!isFeverTime) {
                if (random.nextInt(100) < feverProbability) {
                  _startFeverTime();
                } else {
                  feverProbability++; // 피버 타임이 발생하지 않으면 확률 증가
                }
              }
            });
          },
          child: Image.asset(
            catImages[random.nextInt(catImages.length)], // 고양이 이미지를 랜덤으로 선택
            width: size, // 크기 설정
            height: size, // 크기 설정
          ),
        ),
      ));
    });

    // 피버 타임이 아닌 경우 0~2초 간격으로 새로운 원 생성
    if (!isFeverTime) {
      Future.delayed(Duration(seconds: random.nextInt(3) + 0), _generateCircle);
    }
  }


  // 피버 타임을 시작하는 함수
  void _startFeverTime() {
    setState(() {
      isFeverTime = true; // 피버 타임 시작
      feverProbability = 1; // 피버 타임 확률 초기화
      // 피버 타임 시작 시 비디오 재생
      _videoPlayerController?.play();
    });

    // 피버 타임 동안 원이 0.1초마다 생성
    feverTimer = Timer.periodic(Duration(milliseconds: 500), (timer) {
      _generateCircle();
    });

    // 10초 후 피버 타임 종료
    Future.delayed(Duration(seconds: 10), () {
      setState(() {
        isFeverTime = false; // 피버 타임 종료
        feverTimer?.cancel(); // 타이머 중지
        circles.clear();
        _generateCircle(); // 다시 1~5초 간격으로 원 생성
        // 피버 타임 종료 시 비디오 정지
        _videoPlayerController?.pause();
        _videoPlayerController?.seekTo(Duration.zero); // 비디오 시작 지점으로 되돌림
      });
    });
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose(); // 화면에서 나갈 때 비디오 플레이어 해제
    super.dispose();
  }

  // 점수 메시지를 표시하고 3초 후에 사라지게 하는 함수
  void _showScoreMessage(int points, Offset position) {
    final messageId = DateTime
        .now()
        .millisecondsSinceEpoch; // 고유 ID 생성

    setState(() {
      scoreMessages.add({
        'message': '+$points',
        'position': position,
        'id': messageId, // 고유 ID를 부여하여 메시지 식별
      });
    });

    // 3초 후에 해당 메시지 삭제
    Future.delayed(Duration(seconds: 1), () {
      setState(() {
        scoreMessages.removeWhere((msg) => msg['id'] == messageId);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // 뒤로가기 방지
        return false;
      },
      child: Scaffold(
        body: Column(
          children: [
            // 상단 박스
            Container(
              width: double.infinity, // 좌우로 꽉 채움
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade600, Colors.grey.shade400], // 초록색과 회색 그라데이션
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(20), // 아래쪽만 둥근 모서리
                ),
              ),
              child: Row(
                children: [
                  // 뒤로가기 버튼
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: Colors.white, // 버튼 색상
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
                  Center(
                    child: Column(
                      children: [
                        SizedBox(height: 5),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => Shop()),
                            );
                          },
                          child: Row(
                            children: [
                              Text(
                                '$totalPoints',
                                style: TextStyle(
                                  fontSize: 25,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.amberAccent, // 금색 강조
                                  shadows: [Shadow(blurRadius: 4, color: Colors.black38, offset: Offset(2, 2))],
                                ),
                              ),
                              Image.asset(
                                'assets/UI/coin.png',
                                height: 50, // 아이콘 크기 설정
                              ),
                            ],
                          ),
                        ),
                        Text(
                          lang("클릭해서 코인을 모으세요!"),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black, // 글씨가 잘 보이도록 설정
                          ),
                        ),
                        SizedBox(height: 8), // 줄바꿈을 위한 여백
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: "(  ",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white70,
                                ),
                              ),
                              TextSpan(
                                text: "$feverProbability%",
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.cyan.shade200, // 확률 부분만 핑크 색상
                                ),
                              ),
                              TextSpan(
                                text: " "+lang("확률")+" ",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white70,
                                ),
                              ),
                              TextSpan(
                                text: " "+lang("파티타임")+" ",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.pink.shade200,
                                ),
                              ),
                              TextSpan(
                                text: "  )",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white70,
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
            Expanded(
              child: Stack(
                children: [
                  if (isFeverTime) // 비디오 및 피버 타임 메시지를 isFeverTime 상태와 연결
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_videoPlayerController != null && _videoPlayerController!.value.isInitialized) //피버타임에 고양이 영상 재생, 30등 이상 특권
                            AspectRatio(
                              aspectRatio: _videoPlayerController!.value.aspectRatio,
                              child: VideoPlayer(_videoPlayerController!),
                            ),
                          Text(
                            lang('파티타임'),
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                          Text(
                            'x2',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  for (var message in scoreMessages)
                    Positioned(
                      left: message['position'].dx,
                      top: message['position'].dy - 30,
                      child: Text(
                        message['message'],
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ...circles,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String lang(String textKey) {
  final localizedTexts = {
    'KOR': {
      '클릭해서 코인을 모으세요!': '클릭해서 코인을 모으세요!',
      '확률': '확률',
      '파티타임': '파티타임',
    },
    'ENG': {
      '클릭해서 코인을 모으세요!': 'Click to collect coins!',
      '확률': 'Probability',
      '파티타임': 'Party Time',
    },
    'ARA': {
      '클릭해서 코인을 모으세요!': 'اضغط لجمع العملات!',
      '확률': 'احتمال',
      '파티타임': 'وقت الحفلة',
    },
    'CHN': {
      '클릭해서 코인을 모으세요!': '点击收集金币!',
      '확률': '概率',
      '파티타임': '派对时间',
    },
    'JPA': {
      '클릭해서 코인을 모으세요!': 'クリックしてコインを集めましょう！',
      '확률': '確率',
      '파티타임': 'パーティタイム',
    },
    'GER': {
      '클릭해서 코인을 모으세요!': 'Klicken, um Münzen zu sammeln!',
      '확률': 'Wahrscheinlichkeit',
      '파티타임': 'Partyzeit',
    },
    'RUS': {
      '클릭해서 코인을 모으세요!': 'Нажмите, чтобы собрать монеты!',
      '확률': 'Вероятность',
      '파티타임': 'Время вечеринки',
    },
    'FRA': {
      '클릭해서 코인을 모으세요!': 'Cliquez pour profiter !',
      '확률': 'Probabilité',
      '파티타임': 'Temps de fête',
    },
    'ESP': {
      '클릭해서 코인을 모으세요!': '¡Gana haciendo clic!',
      '확률': 'Probabilidad',
      '파티타임': 'Fiesta',
    },
  };

  return localizedTexts[MyApp.currentLanguage]?[textKey] ?? textKey;
}