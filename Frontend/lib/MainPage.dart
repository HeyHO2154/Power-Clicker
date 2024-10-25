import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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
  int userPoints = 0;

  @override
  void initState() {
    super.initState();
    _fetchUserPoints(); // 포인트 정보 불러오기
  }

  Future<void> _fetchUserPoints() async {
    if (Login.userId == null) return; // userId가 null일 경우 반환

    final response = await http.post(
      Uri.parse('${Login.url}/api/getPoints'), // 쿼리 파라미터 없이 URL만 사용
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': Login.userId}), // userId를 body에 담아 전달
    );

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      setState(() {
        userPoints = result['points']; // 보유 포인트 업데이트
      });
    } else {
      print('Failed to fetch user points');
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
