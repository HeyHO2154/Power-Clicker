import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'MainPage/Mining.dart';
import 'MainPage/Upgrade.dart';
import 'MainPage/War.dart';
import 'MainPage/Farming.dart';
import 'Login.dart'; // Login.dart 파일을 import

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  String? userId; // 사용자 ID
  int userPoints = 0;
  bool isLoading = true; // 로딩 상태 변수

  @override
  void initState() {
    super.initState();
    _loadUserId(); // 사용자 ID 불러오기
  }
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadUserId(); // 메인 페이지로 돌아올 때마다 포인트 다시 불러오기
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
        userPoints = data['points']; // 포인트 업데이트
      });
    } else {
      print('Failed to load points');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          SizedBox(height: 100),
          // 상단에 닉네임과 포인트 표시
          Row(
            children: [
              Icon(Icons.person, color: Colors.grey, size: 24),
              SizedBox(width: 8),
              Text(
                '${Login.userId}', // Login.userId 사용
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.purpleAccent.shade700,
                ),
              ),
              Text(
                '님 환영합니다!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.attach_money, color: Colors.grey, size: 24),
              SizedBox(width: 8),
              Text(
                '보유 포인트: ',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              Text(
                '${userPoints}P',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.purpleAccent,
                ),
              ),
            ],
          ),
          SizedBox(height: 30),
          // 로고 추가
          Padding(
            padding: const EdgeInsets.only(bottom: 50.0),
            child: Image.asset(
              'assets/Logo.png',
              width: 500,
              height: 200,
            ),
          ),
          SizedBox(height: 10),

          // 전쟁하기 버튼
          ElevatedButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => War()));
            },
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.pink,
              padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: Text(
              '전쟁하기',
              style: TextStyle(fontSize: 20),
            ),
          ),
          SizedBox(height: 20),

          // 광질하기 버튼
          ElevatedButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => Mining()));
            },
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.green,
              padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: Text(
              '광질하기',
              style: TextStyle(fontSize: 20),
            ),
          ),
          SizedBox(height: 20),

          // 농사하기 버튼
          ElevatedButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => Farming()));
            },
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.orange,
              padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: Text(
              '농사하기',
              style: TextStyle(fontSize: 20),
            ),
          ),
          SizedBox(height: 20),

          // 업그레이드 버튼
          ElevatedButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => Upgrade()));
            },
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.blue,
              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: Text(
              '업그레이드',
              style: TextStyle(fontSize: 20),
            ),
          ),
        ],
      ),
    );
  }
}
