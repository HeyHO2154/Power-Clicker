import 'package:flutter/material.dart';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async'; // 타이머 사용을 위해 추가

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
  String? scoreMessage; // 획득한 점수 메시지
  Offset? messagePosition; // 점수 메시지의 위치
  bool isFeverTime = false; // 피버 타임 여부
  Timer? feverTimer; // 피버 타임 타이머

  @override
  void initState() {
    super.initState();
    _loadUserId(); // 사용자 ID 불러오기
  }

  Future<void> _loadUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('user_id'); // 저장된 userId 불러오기
    if (userId != null) {
      await _loadPoints(); // userId를 사용하여 포인트 불러오기
    }
    setState(() {
      isLoading = false; // 포인트 불러오기가 완료된 후 로딩 상태 해제
    });
    _generateCircle(); // 원 생성 시작
  }

  Future<void> _loadPoints() async {
    if (userId == null) return;

    // 서버로부터 포인트 가져오기
    final response = await http.get(
      Uri.parse('http://10.0.2.2:8080/api/getPoints?user_id=$userId'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        totalPoints = data['points']; // 포인트 업데이트
      });
    } else {
      print('Failed to load points');
    }
  }

  void _generateCircle() {
    double size = random.nextDouble() * 50 + 50; // 크기 랜덤 (작을수록 큰 점수)
    Color color = Color((random.nextDouble() * 0xFFFFFF).toInt()).withOpacity(1.0); // 색상 랜덤
    Offset position = Offset(random.nextDouble() * 300, random.nextDouble() * 600); // 위치 랜덤

    if (!mounted) return; // 위젯이 트리에 없으면 함수 중단

    setState(() {
      // 새로운 원을 생성하기 전에 기존 원을 지움
      circles.clear();

      circles.add(Positioned(
        left: position.dx,
        top: position.dy,
        child: GestureDetector(
          onTap: () {
            setState(() {
              // 원의 크기에 따라 점수 증가
              int points = 100 - size.toInt(); // 원이 작을수록 큰 점수
              if (isFeverTime) {
                points *= 2; // 피버 타임이면 2배로 증가
              }
              totalPoints += points;
              circles.clear(); // 클릭된 원 삭제
              _showScoreMessage(points, position); // 점수 메시지 표시
              _updatePoints(points); // 서버에 포인트 업데이트

              // 10% 확률로 피버 타임 활성화 (중첩 방지)
              if (!isFeverTime && random.nextInt(100) < 10) {
                _startFeverTime();
              }
            });
          },
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        ),
      ));
    });

    // 피버 타임이 아닌 경우 1~5초 간격으로 새로운 원 생성
    if (!isFeverTime) {
      Future.delayed(Duration(seconds: random.nextInt(5) + 1), _generateCircle);
    }
  }

  // 피버 타임을 시작하는 함수
  void _startFeverTime() {
    setState(() {
      isFeverTime = true; // 피버 타임 시작
    });

    // 피버 타임 동안 원이 1초마다 생성
    feverTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      _generateCircle();
    });

    // 10초 후 피버 타임 종료
    Future.delayed(Duration(seconds: 10), () {
      setState(() {
        isFeverTime = false; // 피버 타임 종료
        feverTimer?.cancel(); // 타이머 중지
        _generateCircle(); // 다시 1~5초 간격으로 원 생성
      });
    });
  }

  Future<void> _updatePoints(int points) async {
    if (userId == null) return;

    // 서버로 포인트 업데이트 요청 보내기
    final response = await http.post(
      Uri.parse('http://10.0.2.2:8080/api/increase'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': userId, 'points': points}),
    );

    if (response.statusCode == 200) {
      print('Points updated successfully');
    } else {
      print('Failed to update points');
    }
  }

  // 점수 메시지를 표시하고 1초 후에 사라지게 하는 함수
  void _showScoreMessage(int points, Offset position) {
    setState(() {
      scoreMessage = '+$points'; // 획득한 점수 메시지 설정
      messagePosition = position; // 점수 메시지 위치 설정
    });

    // 1초 후에 메시지를 사라지게 함
    Future.delayed(Duration(seconds: 1), () {
      setState(() {
        scoreMessage = null;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('광질하기'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: isLoading
                  ? CircularProgressIndicator() // 로딩 중일 때 표시
                  : Text(
                '포인트: $totalPoints', // 포인트 실시간 표시
                style: TextStyle(fontSize: 20),
              ),
            ),
          )
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator()) // 로딩 중일 때 표시
          : Stack(
        children: [
          ...circles,
          if (scoreMessage != null && messagePosition != null)
            Positioned(
              left: messagePosition!.dx,
              top: messagePosition!.dy - 30, // 원 위쪽에 표시
              child: Text(
                scoreMessage!,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),
          if (isFeverTime)
            Center(
              child: Text(
                '피버 타임!!',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
