import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../Login.dart';

class Farming extends StatefulWidget {
  @override
  _FarmingState createState() => _FarmingState();
}

class _FarmingState extends State<Farming> {
  Offset circlePosition = Offset(150, 400); // 원의 초기 위치
  double circleSize = 90; // 원의 크기
  List<Map<String, dynamic>> bullets = []; // 총알 리스트, 방향 포함
  Timer? bulletTimer; // 총알 생성 타이머
  Timer? moveTimer; // 총알 이동 타이머
  Timer? scoreTimer; // 점수 증가 타이머
  bool isGameOver = false; // 게임 종료 여부
  int totalPoints = 0; // 상단 포인트
  int localScore = 0; // 로컬에서 쌓이는 점수
  String resultMessage = ""; // 게임 상태 메시지
  String? userId;

  @override
  void initState() {
    super.initState();
    fetchUserId();
    startGame();
  }

  int userRank = 0; // 사용자 등수 변수 추가

  Future<void> fetchUserRank() async {
    if (userId == null) return;

    final response = await http.get(
      Uri.parse('${Login.url}/api/users'),
    );

    if (response.statusCode == 200) {
      final List users = jsonDecode(utf8.decode(response.bodyBytes));
      int rank = users.indexWhere((user) => user['user_id'] == userId) + 1;

      setState(() {
        userRank = rank;
      });
    } else {
      print('Failed to load user rank');
    }
  }


  Future<void> fetchUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('user_id');
    if (userId != null) {
      await fetchPoints();
      await fetchUserRank(); // 등수 불러오기
    }
  }

  Future<void> fetchPoints() async {
    final response = await http.get(Uri.parse("${Login.url}/api/getPoints?user_id=$userId"));
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

    // 총알 생성 타이머 (초당 5~10개 랜덤 생성)
    bulletTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      int bulletCount = Random().nextInt(6) + 5;
      setState(() {
        for (int i = 0; i < bulletCount; i++) {
          bullets.add(_generateBullet());
        }
      });
    });

    // 총알 이동 타이머 (0.05초마다 업데이트)
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

    // 점수 증가 타이머 (0.5초당 1P 추가)
    scoreTimer = Timer.periodic(Duration(milliseconds: 500), (timer) {
      if (!isGameOver) {
        setState(() {
          localScore += 1;
        });
      }
    });
  }

  @override
  void dispose() {
    bulletTimer?.cancel();
    moveTimer?.cancel();
    scoreTimer?.cancel();
    super.dispose();
  }

  // 총알 생성 위치와 방향 랜덤 설정
  Map<String, dynamic> _generateBullet() {
    final random = Random();
    double x, y;
    double angle = random.nextDouble() * 2 * pi; // 0~360도 각도로 랜덤 방향 설정
    Offset direction = Offset(cos(angle), sin(angle)); // 각도를 바탕으로 방향 설정

    // 랜덤한 사방의 위치에서 생성
    switch (random.nextInt(4)) {
      case 0: // 왼쪽에서 생성
        x = 0;
        y = random.nextDouble() * MediaQuery.of(context).size.height;
        break;
      case 1: // 오른쪽에서 생성
        x = MediaQuery.of(context).size.width;
        y = random.nextDouble() * MediaQuery.of(context).size.height;
        break;
      case 2: // 위쪽에서 생성
        x = random.nextDouble() * MediaQuery.of(context).size.width;
        y = 0;
        break;
      case 3: // 아래쪽에서 생성
        x = random.nextDouble() * MediaQuery.of(context).size.width;
        y = MediaQuery.of(context).size.height;
        break;
      default:
        x = 0;
        y = 0;
    }
    return {'position': Offset(x, y), 'direction': direction};
  }

  // 총알 이동 방향 설정
  Offset _moveBullet(Map<String, dynamic> bullet) {
    final double speed = Random().nextInt(6) + 5; //5~10 속도
    final position = bullet['position'];
    final direction = bullet['direction'];
    return position.translate(direction.dx * speed, direction.dy * speed);
  }

  // 충돌 검사
  void _checkCollision() {
    for (final bullet in bullets) {
      if ((bullet['position'] - circlePosition).distance < circleSize / 3) { // 정확히 닿았을 때만 게임 종료
        setState(() {
          isGameOver = true;
          resultMessage = "획득한 점수: $localScore 점";
        });
        bulletTimer?.cancel();
        moveTimer?.cancel();
        scoreTimer?.cancel();
        break;
      }
    }
  }

  // 원 위치 드래그로 업데이트
// 원 위치 드래그로 업데이트
  void _onDragUpdate(DragUpdateDetails details) {
    if (!isGameOver) {
      setState(() {
        // 상단과 하단, 좌우 제한
        final double upperBoundY = 0; // 상단 박스 아래로 내려오지 않도록 제한 (상단 박스 높이에 맞춰 조정)
        final double lowerBoundY = MediaQuery.of(context).size.height - circleSize -200;
        final double leftBoundX = 0;
        final double rightBoundX = MediaQuery.of(context).size.width - circleSize;

        // 새로운 위치 계산
        double newX = circlePosition.dx + details.delta.dx;
        double newY = circlePosition.dy + details.delta.dy;

        // x와 y 범위 제한
        newX = newX.clamp(leftBoundX, rightBoundX);
        newY = newY.clamp(upperBoundY, lowerBoundY);

        circlePosition = Offset(newX, newY);
      });
    }
  }


  // 화면 밖으로 나간 총알 제거
  bool _isOffScreen(Offset position) {
    return position.dx < 0 ||
        position.dy < 0 ||
        position.dx > MediaQuery.of(context).size.width ||
        position.dy > MediaQuery.of(context).size.height;
  }

  Future<void> _goToMenu() async {
    if (userId != null) {
      await http.post(
        Uri.parse("${Login.url}/api/increase"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"user_id": userId, "points": localScore}),
      );
    }
    Navigator.pop(context); // 메뉴로 이동 (뒤로 가기)
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // 상단 박스 - 처음 제공한 색상 그라데이션 복구
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 30),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange.shade600, Colors.grey.shade400], // 그라데이션 색상 복구
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                Text(
                  "${totalPoints}P",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.yellow,
                  ),
                ),
                Text(
                  "비를 피해 농작물을 지켜내세요!",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "( 게임이 종료되어야 보상이 주어집니다 )",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 10),
          // 실시간 점수 표시
          Text(
            "누적된 점수: $localScore 점",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                // 드래그 가능한 원
                // 드래그 가능한 원 (주황 공) 또는 ccat.png 이미지
                Positioned(
                  left: circlePosition.dx,
                  top: circlePosition.dy,
                  child: GestureDetector(
                    onPanUpdate: _onDragUpdate,
                    child: userRank <= 20
                        ? Image.asset(
                      'assets/ccat.png', // 주황 공 대신 ccat 이미지
                      width: circleSize,
                      height: circleSize,
                    )
                        : Container(
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
                    child: userRank <= 20
                        ? Image.asset(
                      'assets/ddog.png', // 파란 총알 대신 ddog 이미지
                      width: 30,
                      height: 30,
                    )
                        : Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.blue, // 파란색 총알
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),

                // 게임 종료 메시지 및 메뉴로 가기 버튼
                if (isGameOver)
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          resultMessage,
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _goToMenu,
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12), backgroundColor: Colors.orange,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Text(
                            "메뉴로 가기",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
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
    );
  }
}
