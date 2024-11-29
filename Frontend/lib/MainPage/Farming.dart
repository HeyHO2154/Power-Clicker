import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';
import 'MainPage.dart';
import 'Shop.dart';

class Farming extends StatefulWidget {
  @override
  _FarmingState createState() => _FarmingState();
}

class _FarmingState extends State<Farming> {
  Offset circlePosition = Offset(150, 400); // 원의 초기 위치
  double circleSize = 90; // 원의 크기
  List<Map<String, dynamic>> bullets = []; // 총알 리스트
  Timer? bulletTimer; // 총알 생성 타이머
  Timer? moveTimer; // 총알 이동 타이머
  Timer? scoreTimer; // 점수 증가 타이머
  Timer? gameTimer; // 게임 시간 추적 타이머
  bool isGameOver = false; // 게임 종료 여부
  int totalPoints = 0; // 상단 포인트
  int score = 0;
  String? userId;

  // 증가 변수들
  int timeElapsed = 0; // 게임 경과 시간
  double bulletSpeedMultiplier = 1.0; // 총알 속도 증가율
  int bulletCountMultiplier = 5; // 총알 개수 증가 기준

  @override
  void initState() {
    super.initState();
    _loadUserId();
    startGame();
  }

  Future<void> _loadUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('user_id'); // 저장된 userId 불러오기
    if (userId != null) {
      await _getPointValue(0); // userId를 사용하여 포인트 불러오기
    }
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

  void startGame() {
    isGameOver = false;
    bullets.clear();
    timeElapsed = 0;

    // 게임 시간 타이머 (1초마다 시간 증가)
    gameTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        timeElapsed++;
        bulletSpeedMultiplier = 1 + (timeElapsed / 20); // 총알 속도 점진적 증가
        bulletCountMultiplier = 5 + (timeElapsed ~/ 10); // 총알 개수 점진적 증가
      });
    });

    // 총알 생성 타이머
    bulletTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      int bulletCount = Random().nextInt(bulletCountMultiplier) + 5;
      setState(() {
        for (int i = 0; i < bulletCount; i++) {
          bullets.add(_generateBullet());
        }
      });
    });

    // 총알 이동 타이머
    moveTimer = Timer.periodic(Duration(milliseconds: 50), (timer) {
      if (!isGameOver) {
        setState(() {
          for (int i = 0; i < bullets.length; i++) {
            bullets[i]['position'] = _moveBullet(bullets[i]);
          }
          _checkCollision(); // 충돌 검사
          bullets.removeWhere((bullet) => _isOffScreen(bullet['position']));
        });
      }
    });

    // 점수 증가 타이머
    scoreTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!isGameOver) {
        score += (1 + (timeElapsed ~/ 10))*2;
        setState(() {
          _getPointValue((1 + (timeElapsed ~/ 10))*2); // 경과 시간에 비례한 점수 증가
        });
      }
    });
  }

  @override
  void dispose() {
    bulletTimer?.cancel();
    moveTimer?.cancel();
    scoreTimer?.cancel();
    gameTimer?.cancel();
    super.dispose();
  }

  Map<String, dynamic> _generateBullet() {
    final random = Random();
    double x, y;
    double angle = random.nextDouble() * 2 * pi; // 랜덤 각도
    Offset direction = Offset(cos(angle), sin(angle));

    // 화면 경계에서 생성
    switch (random.nextInt(4)) {
      case 0: // 왼쪽
        x = 0;
        y = random.nextDouble() * MediaQuery
            .of(context)
            .size
            .height;
        break;
      case 1: // 오른쪽
        x = MediaQuery
            .of(context)
            .size
            .width;
        y = random.nextDouble() * MediaQuery
            .of(context)
            .size
            .height;
        break;
      case 2: // 위쪽
        x = random.nextDouble() * MediaQuery
            .of(context)
            .size
            .width;
        y = 0;
        break;
      case 3: // 아래쪽
        x = random.nextDouble() * MediaQuery
            .of(context)
            .size
            .width;
        y = MediaQuery
            .of(context)
            .size
            .height;
        break;
      default:
        x = 0;
        y = 0;
    }
    return {'position': Offset(x, y), 'direction': direction};
  }

  Offset _moveBullet(Map<String, dynamic> bullet) {
    final double speed = (Random().nextInt(3) + 5) * bulletSpeedMultiplier;
    final position = bullet['position'];
    final direction = bullet['direction'];
    return position.translate(direction.dx * speed, direction.dy * speed);
  }

  void _checkCollision() {
    for (final bullet in bullets) {
      if ((bullet['position'] - circlePosition).distance < circleSize / 2) {
        setState(() {
          isGameOver = true;
        });
        bulletTimer?.cancel();
        moveTimer?.cancel();
        scoreTimer?.cancel();
        gameTimer?.cancel();
        break;
      }
    }
  }

  bool _isOffScreen(Offset position) {
    return position.dx < 0 ||
        position.dy < 0 ||
        position.dx > MediaQuery
            .of(context)
            .size
            .width ||
        position.dy > MediaQuery
            .of(context)
            .size
            .height;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (!isGameOver) {
      setState(() {
        double newX = circlePosition.dx + details.delta.dx;
        double newY = circlePosition.dy + details.delta.dy;

        // 좌우 경계 제한
        newX = newX.clamp(
            0.0,
            MediaQuery.of(context).size.width - circleSize
        );

        // 상단은 0.0, 하단은 화면 높이 - circleSize - 200으로 제한
        newY = newY.clamp(
            0.0,
            MediaQuery.of(context).size.height - circleSize - 200
        );

        // 위치 업데이트
        circlePosition = Offset(newX, newY);
      });
    }
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
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange.shade600, Colors.grey.shade400],
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
                  SizedBox(width:10),
                  Center(
                    child: Column(
                      children: [
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
                          "총알을 피해 오래 살아남으세요!",
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                        Text(
                          "(난이도: ${bulletSpeedMultiplier.toStringAsFixed(2)}x)",
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque, // 빈 화면도 터치 이벤트 감지
                onPanUpdate: (details) {
                  // 화면 전체에서 드래그로 고양이 움직이기
                  _onDragUpdate(details);
                },
                child: Stack(
                  children: [
                    // 드래그 가능한 원 (고양이)
                    Positioned(
                      left: circlePosition.dx,
                      top: circlePosition.dy,
                      child: GestureDetector(
                        onPanUpdate: (details) {
                          // 고양이를 직접 드래그로 움직이기
                          _onDragUpdate(details);
                        },
                        child: Image.asset(
                          'assets/ccat.png', // ccat 이미지 경로
                          width: circleSize, // 이미지 크기
                          height: circleSize, // 이미지 크기
                        ),
                      ),
                    ),
                    // 강아지 (기존 동작 유지)
                    for (final bullet in bullets)
                      Positioned(
                        left: bullet['position'].dx,
                        top: bullet['position'].dy,
                        child: Image.asset(
                          'assets/ddog.png', // ddog 이미지 경로
                          width: 30, // 이미지 크기
                          height: 30, // 이미지 크기
                        ),
                      ),
                    if (isGameOver)
                      Center(
                        child: Container(
                          width: 250,
                          height: 250,
                          padding: EdgeInsets.all(20), // 내부 여백
                          decoration: BoxDecoration(
                            color: Colors.white, // 박스 배경색
                            borderRadius: BorderRadius.circular(15), // 둥근 모서리
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26, // 그림자 색상
                                blurRadius: 10, // 그림자 흐림 정도
                                offset: Offset(0, 5), // 그림자 위치
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(
                                "게임 오버!",
                                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.red),
                              ),
                              SizedBox(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text("보상 코인: ", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
                                  Text(
                                    '$score',
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
                              SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: () {
                                  // 현재 페이지를 다시 시작
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => Farming(), // 현재 페이지 위젯을 다시 로드
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: Colors.orange, // 텍스트 색상
                                  shadowColor: Colors.black, // 그림자 색상
                                  elevation: 8, // 그림자 높이
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15), // 버튼 둥근 모서리
                                  ),
                                  padding: EdgeInsets.symmetric(horizontal: 25, vertical: 13), // 버튼 내부 여백
                                ),
                                child: Text(
                                  "다시 하기",
                                  style: TextStyle(
                                    fontSize: 18, // 텍스트 크기
                                    fontWeight: FontWeight.bold, // 텍스트 두께
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
