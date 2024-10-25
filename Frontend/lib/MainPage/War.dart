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
      body: ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          bool isCurrentUser = user['user_id'] == userId;
          return ListTile(
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
              '${user["user_id"]} : ${user["point"]}점',
              style: TextStyle(
                fontWeight: isCurrentUser || index < 10 ? FontWeight.bold : FontWeight.normal, // 본인 또는 10등까지 Bold
                fontSize: 18,
                color: isCurrentUser ? Colors.blue : Colors.black, // 본인은 파란색
              ),
            ),
            onTap: isCurrentUser
                ? null // 본인은 클릭 불가
                : () {
              _decreasePoints(user['user_id'], user['point']); // 사람 아이콘 클릭 시 포인트 감소
            },
          );
        },
      ),
    );
  }

  // 유저의 순위에 따라 색상 반환
  Color _getUserColor(int index, bool isCurrentUser) {
    if (isCurrentUser) {
      return Colors.blue; // 본인은 파란색
    } else if (index == 0) {
      return Colors.yellow; // 1등은 노란색
    } else if (index <= 2) {
      return Colors.orange; // ~3등은 주황색
    } else if (index <= 9) {
      return Colors.green; // ~10등은 초록색
    } else if (index <= 19) {
      return Colors.red; // 20등은 빨간색
    } else {
      return Colors.grey; // 나머지는 회색
    }
  }
}
