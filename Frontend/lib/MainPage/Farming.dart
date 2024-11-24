import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';

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
  int localScore = 0; // 로컬에서 쌓이는 점수
  String resultMessage = ""; // 게임 상태 메시지
  String? userId;

  // 증가 변수들
  int timeElapsed = 0; // 게임 경과 시간
  double bulletSpeedMultiplier = 1.0; // 총알 속도 증가율
  int bulletCountMultiplier = 5; // 총알 개수 증가 기준

  @override
  void initState() {
    super.initState();
    fetchUserId();
    startGame();
  }

  Future<void> fetchUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('user_id');
    if (userId != null) {
      await fetchPoints();
    }
  }

  Future<void> fetchPoints() async {
    final response = await http.get(Uri.parse("${MyApp.url}/api/getPoints?user_id=$userId"));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        totalPoints = data['points'];
      });
    }
  }

  void startGame() {
    isGameOver = false;
    localScore = 0;
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
        setState(() {
          localScore += (1 + (timeElapsed ~/ 10)); // 경과 시간에 비례한 점수 증가
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
        y = random.nextDouble() * MediaQuery.of(context).size.height;
        break;
      case 1: // 오른쪽
        x = MediaQuery.of(context).size.width;
        y = random.nextDouble() * MediaQuery.of(context).size.height;
        break;
      case 2: // 위쪽
        x = random.nextDouble() * MediaQuery.of(context).size.width;
        y = 0;
        break;
      case 3: // 아래쪽
        x = random.nextDouble() * MediaQuery.of(context).size.width;
        y = MediaQuery.of(context).size.height;
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
          resultMessage = "Game Over! Total Points: +$localScore P";
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
        position.dx > MediaQuery.of(context).size.width ||
        position.dy > MediaQuery.of(context).size.height;
  }

  Future<void> _goToMenu() async {
    if (userId != null) {
      await http.post(
        Uri.parse("${MyApp.url}/api/increase"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"user_id": userId, "points": localScore}),
      );
    }
    Navigator.pop(context);
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (!isGameOver) {
      setState(() {
        double newX = circlePosition.dx + details.delta.dx;
        double newY = circlePosition.dy + details.delta.dy;

        newX = newX.clamp(0.0, MediaQuery.of(context).size.width - circleSize);
        newY = newY.clamp(100.0, MediaQuery.of(context).size.height - circleSize);

        circlePosition = Offset(newX, newY);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // 상단 정보 박스
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange.shade600, Colors.grey.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                Text(
                  "Total Points: $totalPoints P",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.yellow),
                ),
                Text(
                  "Local Score: +$localScore P",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                ),
                Text(
                  "Bullet Speed: ${bulletSpeedMultiplier.toStringAsFixed(2)}x",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
                ),
                Text(
                  "Bullet Count: $bulletCountMultiplier",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
                ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                // 드래그 가능한 원
                Positioned(
                  left: circlePosition.dx,
                  top: circlePosition.dy,
                  child: GestureDetector(
                    onPanUpdate: _onDragUpdate,
                    child: Container(
                      width: circleSize,
                      height: circleSize,
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                for (final bullet in bullets)
                  Positioned(
                    left: bullet['position'].dx,
                    top: bullet['position'].dy,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                if (isGameOver)
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(resultMessage, style: TextStyle(fontSize: 28, color: Colors.red)),
                        ElevatedButton(
                          onPressed: _goToMenu,
                          child: Text("Back to Menu"),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
