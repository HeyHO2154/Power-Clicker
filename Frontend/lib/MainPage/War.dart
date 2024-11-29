import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../Login.dart';
import '../main.dart';
import 'MainPage.dart';
import 'Shop.dart';

class War extends StatefulWidget {
  @override
  _WarState createState() => _WarState();
}

class _WarState extends State<War> {
  List<Map<String, dynamic>> users = [];
  String? userId;
  Map<String, dynamic>? currentUser;
  ScrollController _scrollController = ScrollController();

  int meDecrease = -50;
  int otherDecrease = -100;
  int userPoints = 0; // 사용자 포인트 변수 추가

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getString('user_id');
    });
    await _loadUsers();
    await _getPointValue(0); // 사용자 포인트 불러오기
    _scrollToCurrentUser(); // 화면 들어올 때 한 번만 스크롤 위치 설정
  }

  Future<void> _loadUsers() async {
    final response = await http.get(Uri.parse('${MyApp.url}/api/users'));
    if (response.statusCode == 200) {
      List<Map<String, dynamic>> allUsers = List<Map<String, dynamic>>.from(
          jsonDecode(utf8.decode(response.bodyBytes))); // UTF-8로 디코딩
      setState(() {
        allUsers.sort((a, b) => b['points'].compareTo(a['points']));
        users = allUsers;
        currentUser = allUsers.firstWhere(
              (user) => user['user_id'] == userId,
          orElse: () => {'user_id': userId, 'points': 0},
        );
      });
    }
  }
  Future<void> _getPointValue(n) async {
    final url = Uri.parse('${MyApp.url}/user/point');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': MyApp.user_id, 'points': n}), //여기서의 points는 더해줄 값을 의미(0은 단순 포인트 조회)
    );

    if (response.statusCode == 200) {
      setState(() {
        userPoints = int.parse(response.body);
      });
    }
  }


  void _scrollToCurrentUser() {
    if (currentUser != null) {
      int userIndex = users.indexWhere((user) => user['user_id'] == userId);
      if (userIndex != -1) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          double scrollPosition = userIndex * 70.0;
          double screenHeight = MediaQuery.of(context).size.height;
          double middleOffset = (screenHeight / 2) - 35;

          _scrollController.animateTo(
            (scrollPosition - middleOffset).clamp(0.0, _scrollController.position.maxScrollExtent),
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        });
      }
    }
  }

  void _decreasePoints(String targetUserId) async {
    if (userId == null || currentUser == null) return;

    int currentUserPoints = currentUser!['points'];
    final targetUser = users.firstWhere((user) => user['user_id'] == targetUserId, orElse: () => {});
    int targetUserPoints = targetUser['points'] ?? 0;

    if (currentUserPoints < meDecrease*-1 || targetUserPoints < otherDecrease*-1 ) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You or Others have small point to War..')),
      );
      return;
    }

    final url = Uri.parse('${MyApp.url}/user/point');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': userId, 'points': meDecrease}), //여기서의 points는 더해줄 값을 의미(0은 단순 포인트 조회)
    );

    if (response.statusCode == 200) {
      setState(() {
        userPoints = int.parse(response.body);
      });
    }

    final url2 = Uri.parse('${MyApp.url}/user/point');
    final response2 = await http.post(
      url2,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': targetUserId, 'points': otherDecrease}), //여기서의 points는 더해줄 값을 의미(0은 단순 포인트 조회)
    );

    if (response2.statusCode == 200) {
      setState(() {
        userPoints = int.parse(response2.body);
      });
    }

    await _loadUsers();
    await _getPointValue(0); // 포인트 다시 불러오기
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
                colors: [Colors.pink.shade900, Colors.red],
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
                SizedBox(width:15),
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
                              '$userPoints',
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
                        "상대를 클릭해서 공격하세요!",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      Text(
                        "(최소 공격 100 코인 이상)",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                bool isCurrentUser = user['user_id'] == userId;

                // 구간 설명 박스 위젯
                Widget benefitBox = Container(); // 기본적으로 빈 컨테이너
                if (index == 0) {
                  benefitBox = _buildBenefitBox("TOP 10 Player", Colors.yellow.shade700);
                } else if (index == 10) {
                  benefitBox = _buildBenefitBox("TOP 20 Player", Colors.purple.shade200);
                } else if (index == 20) {
                  benefitBox = _buildBenefitBox("TOP 30 Player", Colors.green.shade300);
                } else if (index == 30) {
                  benefitBox = _buildBenefitBox("TOP 40 Player", Colors.orange.shade300);
                } else if (index == 40) {
                  benefitBox = _buildBenefitBox("TOP 50 Player", Colors.red.shade300);
                } else if (index == 50) {
                  benefitBox = _buildBenefitBox("Other Player", Colors.grey);
                }

                return Column(
                  children: [
                    benefitBox,
                    ListTile(
                      leading: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '#${index + 1}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: index < 10 ? FontWeight.bold : FontWeight.bold,
                              color: _getUserColor(index, isCurrentUser), // 구역 색상 적용
                            ),
                          ),
                          SizedBox(width: 10),
                          Icon(
                            Icons.person,
                            size: 40,
                            color: _getUserColor(index, isCurrentUser),
                          ),
                        ],
                      ),
                      title: Row(
                        children: [
                          // 닉네임 부분에만 색상 적용 (본인은 withOpacity(1), 다른 사람은 withOpacity(0.8))
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getUserColor(index, isCurrentUser)
                                  .withOpacity(isCurrentUser ? 0.6 : 0.3), // 본인은 불투명, 다른 사람은 약간 투명
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${user["user_id"]}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          // 포인트는 기존 텍스트 스타일로 표시
                          Text(
                            '${user["points"]}P',
                            style: TextStyle(
                              fontWeight: FontWeight.normal,
                              fontSize: 18,
                              color: isCurrentUser ? Colors.blue : Colors.black,
                            ),
                          ),
                        ],
                      ),
// 클릭 시 포인트 감소 기능을 호출
                      onTap: isCurrentUser ? null : () {
                        _decreasePoints(user['user_id']);
                      },

                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    )
    );
  }

  Color _getUserColor(int index, bool isCurrentUser) {
    if (isCurrentUser) {
      return Colors.blue;
    } else if (index <= 9) {
      return Colors.yellow.shade700;
    } else if (index <= 19) {
      return Colors.purple;
    } else if (index <= 29) {
      return Colors.green;
    } else if (index <= 39) {
      return Colors.orange;
    } else if (index <= 49) {
      return Colors.red;
    } else {
      return Colors.grey;
    }
  }
}
// 구간 설명 박스를 위한 메서드
Widget _buildBenefitBox(String text1, Color color) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4.0),
    child: Stack(
      alignment: Alignment.center,
      children: [
        Divider(thickness: 2, color: color), // 구간별 선 색상
        Container(
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 18),
          alignment: Alignment.center,
          constraints: BoxConstraints(maxWidth: 290), // 너비 제한 추가
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 첫째 줄 텍스트
              Text(
                text1,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,  // 첫째 줄 폰트 크기
                  fontWeight: FontWeight.bold,
                  color: Colors.black,  // 첫째 줄 글자색
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}


