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
  String? userId;
  Map<String, dynamic>? currentUser;
  ScrollController _scrollController = ScrollController();

  int meDecrease = 9;
  int otherDecrease = 10;
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
    final response = await http.get(Uri.parse('http://10.0.2.2:8080/api/users'));
    if (response.statusCode == 200) {
      List<Map<String, dynamic>> allUsers = List<Map<String, dynamic>>.from(jsonDecode(response.body));
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

    // 서버로부터 사용자 포인트 가져오기
    final response = await http.get(
      Uri.parse('http://10.0.2.2:8080/api/getPoints?user_id=$userId'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        userPoints = data['points']; // 사용자 포인트 업데이트
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
      Uri.parse('http://10.0.2.2:8080/api/decrease'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': targetUserId,
        'points': otherDecrease,
      }),
    );

    await http.post(
      Uri.parse('http://10.0.2.2:8080/api/decrease'),
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
                  "(본인 9포인트로, 상대 10포인트 감소)",
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

                Widget divider = Container();
                if (index == 0) {
                  divider = Divider(thickness: 2.5, color: Colors.yellow.shade800);
                } else if (index == 4) {
                  divider = Divider(thickness: 2, color: Colors.purple);
                } else if (index == 9) {
                  divider = Divider(thickness: 1.5, color: Colors.green);
                } else if (index == 19) {
                  divider = Divider(thickness: 1, color: Colors.red);
                }

                return Column(
                  children: [
                    ListTile(
                      leading: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${index + 1}등',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: index < 10 ? FontWeight.bold : FontWeight.normal,
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
                      title: Text(
                        '[ ${user["user_id"]} ] ${user["point"]}P',
                        style: TextStyle(
                          fontWeight: isCurrentUser || index < 10 ? FontWeight.bold : FontWeight.normal,
                          fontSize: 18,
                          color: isCurrentUser ? Colors.blue : Colors.black,
                        ),
                      ),
                      onTap: isCurrentUser ? null : () {
                        _decreasePoints(user['user_id']);
                      },
                    ),
                    divider,
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
    } else if (index == 0) {
      return Colors.yellow.shade700;
    } else if (index <= 4) {
      return Colors.purple;
    } else if (index <= 9) {
      return Colors.green;
    } else if (index <= 19) {
      return Colors.red;
    } else {
      return Colors.grey;
    }
  }
}
