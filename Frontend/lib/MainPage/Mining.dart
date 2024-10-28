import 'package:flutter/material.dart';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'dart:async';

import '../Login.dart'; // 타이머 사용을 위해 추가

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
  int userRank = 0; // 사용자 등수 저장 변수

  VideoPlayerController? _videoPlayerController; // 비디오 플레이어 컨트롤러 추가

  // 이미지 파일 목록
  final List<String> catImages = [
    'assets/cat1.png',
    'assets/cat2.png',
    'assets/cat3.png',
    'assets/cat4.png',
    'assets/cat5.png',
    'assets/cat6.png',
    'assets/cat7.png',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserId(); // 사용자 ID 불러오기
    _fetchUserRank(); // 초기화 시 등수 불러오기

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
      await _loadPoints(); // userId를 사용하여 포인트 불러오기
      await _fetchUserRank(); // 등수도 불러오기
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
      Uri.parse('${Login.url}/api/getPoints?user_id=$userId'),
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

  Future<void> _fetchUserRank() async {
    if (userId == null) return;

    final response = await http.get(
      Uri.parse('${Login.url}/api/users'),
    );

    if (response.statusCode == 200) {
      final List users = jsonDecode(utf8.decode(response.bodyBytes)); // UTF-8로 디코딩
      int rank = users.indexWhere((user) => user['user_id'] == userId) + 1;

      setState(() {
        userRank = rank;
      });
    } else {
      print('Failed to load user rank');
    }
  }


  void _generateCircle() {
    double size = random.nextDouble() * 50 + 50; // 크기 랜덤
    Color color = Color((random.nextDouble() * 0xFFFFFF).toInt()).withOpacity(1.0); // 색상 랜덤
    Offset position = Offset(random.nextDouble() * 300, random.nextDouble() * 600); // 위치 랜덤
    int circleId = DateTime.now().millisecondsSinceEpoch; // 고유 ID 생성

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
              int points = ((100 - size) / 10).round() + 1; // 원의 크기가 작을수록 큰 점수 부여
              if (isFeverTime) {
                points *= 1; // 피버 타임이면 1배로 증가 => 지금 피버타임 0.5초로 줄어서 1배가 맞음
              }
              totalPoints += points;
              _showScoreMessage(points, position); // 점수 메시지 표시
              _updatePoints(points); // 서버에 포인트 업데이트

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
          // userRank가 40등 이하일 경우 cat 이미지, 그렇지 않으면 원을 표시
          child: userRank <= 40
              ? Image.asset(
            catImages[random.nextInt(catImages.length)],
            width: size,
            height: size,
          )
              : Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Color((random.nextDouble() * 0xFFFFFF).toInt()).withOpacity(1.0),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ));
    });

    // 피버 타임이 아닌 경우 1~3초 간격으로 새로운 원 생성
    if (!isFeverTime) {
      Future.delayed(Duration(seconds: random.nextInt(2) + 1), _generateCircle);
    }
  }


  // 피버 타임을 시작하는 함수
  void _startFeverTime() {

    setState(() {
      isFeverTime = true; // 피버 타임 시작
      feverProbability = 1; // 피버 타임 확률 초기화

      // 등수가 30 이하인 경우에만 비디오 재생
      if (userRank <= 30) {
        // 피버 타임 시작 시 비디오 재생
        _videoPlayerController?.play();
      }


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

  Future<void> _updatePoints(int points) async {
    if (userId == null) return;

    // 서버로 포인트 업데이트 요청 보내기
    final response = await http.post(
      Uri.parse('${Login.url}/api/increase'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': userId, 'points': points}),
    );

    if (response.statusCode == 200) {
      print('Points updated successfully');
    } else {
      print('Failed to update points');
    }
  }

  // 점수 메시지를 표시하고 3초 후에 사라지게 하는 함수
  void _showScoreMessage(int points, Offset position) {
    final messageId = DateTime.now().millisecondsSinceEpoch; // 고유 ID 생성

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
    return Scaffold(
      body: Column(
        children: [
          // 상단 박스
          Container(
            width: double.infinity, // 좌우로 꽉 채움
            padding: EdgeInsets.symmetric(vertical: 30), // 상하 padding만 설정
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade600, Colors.grey.shade400], // 하늘색과 회색 그라데이션
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(20), // 아래쪽만 둥근 모서리
              ),
            ),
            child: Column(
              children: [
                Text(
                  "${totalPoints}P",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.yellow, // 글씨가 잘 보이도록 설정
                  ),
                ),
                Text(
                  "광물을 클릭해서 포인트를 모으세요!",
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
                        text: "( 광물 클릭시 ",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white70,
                        ),
                      ),
                      TextSpan(
                        text: "$feverProbability%",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.cyan.shade200, // 확률 부분만 핑크 색상
                        ),
                      ),
                      TextSpan(
                        text: " 확률로 ",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white70,
                        ),
                      ),
                      TextSpan(
                        text: "피버타임 ",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.pink.shade200,
                        ),
                      ),
                      TextSpan(
                        text: " 발생 )",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                )
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
                        if (_videoPlayerController != null && _videoPlayerController!.value.isInitialized && userRank <= 30)  //피버타임에 고양이 영상 재생, 30등 이상 특권
                          AspectRatio(
                            aspectRatio: _videoPlayerController!.value.aspectRatio,
                            child: VideoPlayer(_videoPlayerController!),
                          ),
                        Text(
                          '피버 타임!!',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        Text(
                          '(획득 포인트 2배)',
                          style: TextStyle(
                            fontSize: 20,
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
    );
  }
}
