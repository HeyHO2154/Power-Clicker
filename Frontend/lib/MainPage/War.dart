// war.dart
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
        // 본인 정보 설정
        currentUser = allUsers.firstWhere(
              (user) => user['user_id'] == userId,
          orElse: () => {'user_id': userId, 'point': 0}, // 기본 값을 제공
        );
        // 피라미드에 본인도 포함되도록 설정
        users = allUsers;
      });
    }
  }

  // 포인트 감소 요청을 두 번 보내는 메서드
  void _decreasePoints(String targetUserId, int targetUserPoints) async {
    if (userId == null || currentUser == null) return;

    int currentUserPoints = currentUser!['point'];

    // 본인 또는 상대방의 포인트가 10 미만이면 전쟁을 막음
    if (currentUserPoints < 10 || targetUserPoints < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('본인이나 상대방의 포인트가 부족하여 전쟁을 할 수 없습니다.')),
      );
      return;
    }

    // 상대방의 포인트 감소
    await http.post(
      Uri.parse('http://10.0.2.2:8080/api/decrease'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': targetUserId}),
    );

    // 본인의 포인트 감소
    await http.post(
      Uri.parse('http://10.0.2.2:8080/api/decrease'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': userId}),
    );

    _loadUsers(); // 갱신된 유저 정보 다시 불러오기
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('전쟁하기'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 상위 10명의 유저를 피라미드 방식으로 배치 (본인도 포함)
            if (users.isNotEmpty)
              Column(
                children: [
                  if (users.length >= 1) _buildUserRow([users[0]], true), // 1등 (노란색 아이콘)
                  if (users.length >= 2) _buildUserRow([users[1], users[2]], false), // 2, 3등
                  if (users.length >= 4) _buildUserRow([users[3], users[4], users[5]], false), // 4, 5, 6등
                  if (users.length >= 7)
                    _buildUserRow(users.sublist(6, users.length > 10 ? 10 : users.length), false), // 7~10등
                ],
              ),

            SizedBox(height: 20),

            // 피라미드에 본인이 포함되든 포함되지 않든 항상 피라미드 하단에 본인 표시
            if (currentUser != null)
              ListTile(
                title: Text(
                  '${currentUser!["user_id"]} - ${currentUser!["point"]}점 (본인)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
                trailing: Icon(Icons.person, size: 40, color: Colors.blue), // 본인 아이콘 파란색
                onTap: null, // 본인은 클릭되지 않음
              ),
          ],
        ),
      ),
    );
  }

  // 피라미드식 유저 배치 (아이콘 클릭)
  Widget _buildUserRow(List<Map<String, dynamic>> rowUsers, bool isTopRank) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: rowUsers.map((user) {
        bool isCurrentUser = user['user_id'] == userId; // 본인 여부 확인

        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Text(
                '${user["user_id"]}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold), // 글자 크기 크게
              ),
              Text(
                '${user["point"]}점',
                style: TextStyle(fontSize: 16), // 글자 크기 크게
              ),
              GestureDetector(
                onTap: isCurrentUser
                    ? null // 본인은 클릭 불가
                    : () {
                  _decreasePoints(user['user_id'], user['point']); // 사람 아이콘 클릭 시 포인트 감소
                },
                child: Icon(
                  Icons.person,
                  size: 40,
                  color: isCurrentUser
                      ? Colors.blue // 본인 아이콘은 파란색
                      : isTopRank
                      ? Colors.orangeAccent // 1등은 노란색
                      : Colors.red, // 나머지는 빨간색
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
