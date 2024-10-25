import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class War extends StatefulWidget {
  @override
  _WarState createState() => _WarState();
}

class _WarState extends State<War> {
  List<Map<String, dynamic>> users = [];
  String? userId; // 본인 아이디 저장
  Map<String, dynamic>? currentUser; // 본인의 유저 정보 저장

  // 포인트 감소량 설정을 위한 변수
  int meDecrease = 9; // 본인 포인트 감소량
  int otherDecrease = 10; // 상대방 포인트 감소량

  @override
  void initState() {
    super.initState();
    _loadUserId(); // 본인 아이디 불러오기
  }

  Future<void> _loadUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getString('user_id');
    });
    _loadUsers(); // 유저 목록 불러오기
  }

  Future<void> _loadUsers() async {
    final response = await http.get(Uri.parse('http://10.0.2.2:8080/api/users'));
    if (response.statusCode == 200) {
      List<Map<String, dynamic>> allUsers = List<Map<String, dynamic>>.from(jsonDecode(response.body));

      setState(() {
        // 유저 목록을 포인트 기준으로 정렬
        allUsers.sort((a, b) => b['point'].compareTo(a['point']));
        users = allUsers;
        // 본인 정보 설정
        currentUser = allUsers.firstWhere(
              (user) => user['user_id'] == userId,
          orElse: () => {'user_id': userId, 'point': 0}, // 기본 값을 제공
        );
      });
    }
  }

  // 포인트 감소 요청을 보내는 메서드
  void _decreasePoints(String targetUserId) async {
    if (userId == null || currentUser == null) return;

    int currentUserPoints = currentUser!['point'];
    final targetUser = users.firstWhere((user) => user['user_id'] == targetUserId, orElse: () => {});
    int targetUserPoints = targetUser['point'] ?? 0;

    // 본인 또는 상대방의 포인트가 감소시킬 포인트보다 적으면 전쟁을 막음
    if (currentUserPoints < meDecrease || targetUserPoints < otherDecrease) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('본인이나 상대방의 포인트가 부족하여 전쟁을 할 수 없습니다.')),
      );
      return;
    }

    // 상대방의 포인트 감소
    await http.post(
      Uri.parse('http://10.0.2.2:8080/api/decrease'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': targetUserId,
        'points': otherDecrease, // 상대방의 포인트 감소량
      }),
    );

    // 본인의 포인트 감소
    await http.post(
      Uri.parse('http://10.0.2.2:8080/api/decrease'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'points': meDecrease, // 본인의 포인트 감소량
      }),
    );

    _loadUsers(); // 갱신된 유저 정보 다시 불러오기
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // 상단 설명 박스 (화면의 좌우를 꽉 채우기)
          Container(
            width: double.infinity, // 좌우로 꽉 채움
            padding: EdgeInsets.symmetric(vertical: 30), // 상하 padding만 설정
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
            child: Column(
              children: [
                Text(
                  "상대를 클릭해서 순위를 끌어내리세요!",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white, // 글씨가 잘 보이도록 설정
                  ),
                ),
                SizedBox(height: 8), // 줄바꿈을 위한 여백
                Text(
                  "(본인 9포인트로, 상대 10포인트 감소)",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.yellow.shade500, // 부가 설명 글씨는 조금 연하게 설정
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                bool isCurrentUser = user['user_id'] == userId;

                // 등수에 따른 밑줄 추가
                Widget divider = Container();
                if (index == 0) {
                  divider = Divider(thickness: 2, color: Colors.yellow.shade800); // 1등 밑줄
                } else if (index == 2) {
                  divider = Divider(thickness: 1.5, color: Colors.purple); // 3등 밑줄
                } else if (index == 4) {
                  divider = Divider(thickness: 1, color: Colors.green); // 4등 밑줄
                } else if (index == 9) {
                  divider = Divider(thickness: 0.5, color: Colors.red); // 10등 밑줄
                }

                return Column(
                  children: [
                    ListTile(
                      leading: Row(
                        mainAxisSize: MainAxisSize.min, // 공간을 최소화해서 사람 아이콘과 등수가 붙어서 나타나게 함
                        children: [
                          Text(
                            '${index + 1}등', // 등수 표시
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: index < 10 ? FontWeight.bold : FontWeight.normal, // 10등까지는 Bold
                            ),
                          ),
                          SizedBox(width: 10), // 아이콘과 등수 사이 간격
                          Icon(
                            Icons.person,
                            size: 40,
                            color: _getUserColor(index, isCurrentUser), // 아이콘 색상 설정
                          ),
                        ],
                      ),
                      title: Text(
                        '[ ${user["user_id"]} ] ${user["point"]}P',
                        style: TextStyle(
                          fontWeight: isCurrentUser || index < 10 ? FontWeight.bold : FontWeight.normal, // 본인 또는 10등까지 Bold
                          fontSize: 18,
                          color: isCurrentUser ? Colors.blue : Colors.black, // 본인은 파란색
                        ),
                      ),
                      onTap: isCurrentUser
                          ? null // 본인은 클릭 불가
                          : () {
                        _decreasePoints(user['user_id']); // 포인트 감소 요청
                      },
                    ),
                    divider, // 해당 구간 밑에 구분선 추가
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 유저의 순위에 따라 색상 반환
  Color _getUserColor(int index, bool isCurrentUser) {
    if (isCurrentUser) {
      return Colors.blue;
    } else if (index == 0) {
      return Colors.yellow.shade700;
    } else if (index <= 2) {
      return Colors.purple;
    } else if (index <= 4) {
      return Colors.green;
    } else if (index <= 9) {
      return Colors.red;
    } else {
      return Colors.grey;
    }
  }
}
