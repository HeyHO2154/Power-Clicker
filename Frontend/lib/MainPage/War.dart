import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../Login.dart';

class War extends StatefulWidget {
  @override
  _WarState createState() => _WarState();
}

class _WarState extends State<War> {
  List<Map<String, dynamic>> users = [];
  String? userId;
  Map<String, dynamic>? currentUser;
  ScrollController _scrollController = ScrollController();

  int meDecrease = 50;
  int otherDecrease = 100;
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
    await _loadPoints(); // 사용자 포인트 불러오기
    _scrollToCurrentUser(); // 화면 들어올 때 한 번만 스크롤 위치 설정
  }

  Future<void> _loadUsers() async {
    final response = await http.get(Uri.parse('${Login.url}/api/users'));
    if (response.statusCode == 200) {
      List<Map<String, dynamic>> allUsers = List<Map<String, dynamic>>.from(
          jsonDecode(utf8.decode(response.bodyBytes))); // UTF-8로 디코딩
      setState(() {
        allUsers.sort((a, b) => b['point'].compareTo(a['point']));
        users = allUsers;
        currentUser = allUsers.firstWhere(
              (user) => user['user_id'] == userId,
          orElse: () => {'user_id': userId, 'point': 0},
        );
      });
    }
  }
  Future<void> _loadPoints() async {
    if (userId == null) return;

    final response = await http.get(
      Uri.parse('${Login.url}/api/getPoints?user_id=$userId'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes)); // UTF-8로 디코딩
      setState(() {
        userPoints = data['points'];
      });
    } else {
      print('Failed to load points');
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

    int currentUserPoints = currentUser!['point'];
    final targetUser = users.firstWhere((user) => user['user_id'] == targetUserId, orElse: () => {});
    int targetUserPoints = targetUser['point'] ?? 0;

    if (currentUserPoints < meDecrease || targetUserPoints < otherDecrease) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('본인이나 상대방의 포인트가 부족하여 전쟁을 할 수 없습니다.')),
      );
      return;
    }

    await http.post(
      Uri.parse('${Login.url}/api/decrease'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': targetUserId,
        'points': otherDecrease,
      }),
    );

    await http.post(
      Uri.parse('${Login.url}/api/decrease'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'points': meDecrease,
      }),
    );

    await _loadUsers();
    await _loadPoints(); // 포인트 다시 불러오기
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // 상단 설명 박스
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 30),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.pink.shade900, Colors.red],
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
                  "$userPoints P", // 사용자 포인트 표시
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.yellow,
                  ),
                ),
                Text(
                  "상대를 클릭해서 순위를 끌어내리세요!",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "(본인 ${meDecrease}포인트로, 상대 ${otherDecrease}포인트 감소)",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade100,
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
                  benefitBox = _buildBenefitBox("TOP 10 특권", "VIP 대화방 버튼 추가", Colors.yellow.shade700);
                } else if (index == 10) {
                  benefitBox = _buildBenefitBox("TOP 20 특권", "농사하기가 도지 피하기로 변경", Colors.purple.shade200);
                } else if (index == 20) {
                  benefitBox = _buildBenefitBox("TOP 30 특권", "피버타임에 고양이 춤 영상 추가", Colors.green.shade300);
                } else if (index == 30) {
                  benefitBox = _buildBenefitBox("TOP 40 특권", "광질하기가 고양이 터치로 변경", Colors.orange.shade300);
                } else if (index == 40) {
                  benefitBox = _buildBenefitBox("TOP 50 특권", "메인 화면에 고양이 등장", Colors.red.shade300);
                } else if (index == 50) {
                  benefitBox = _buildBenefitBox("일반 유저", "기본 기능 제공", Colors.grey);
                }

                return Column(
                  children: [
                    benefitBox,
                    ListTile(
                      leading: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${index + 1}등',
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
                            '${user["point"]}P',
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
Widget _buildBenefitBox(String text1, String text2, Color color) {
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
              SizedBox(height: 4), // 줄 간격
              // 둘째 줄 텍스트
              Text(
                text2,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,  // 둘째 줄 폰트 크기
                  fontWeight: FontWeight.bold,
                  color: Colors.white,  // 둘째 줄 글자색
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}


