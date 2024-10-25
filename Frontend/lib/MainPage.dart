import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'MainPage/Mining.dart';
import 'MainPage/Upgrade.dart';
import 'MainPage/War.dart';
import 'MainPage/Farming.dart'; // Farming.dart 파일을 import

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  String? userId;
  int userPoints = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getString('user_id');
    });
    _fetchUserPoints(); // 포인트 정보 불러오기
  }

  Future<void> _fetchUserPoints() async {
    final response = await http.get(Uri.parse('http://10.0.2.2:8080/api/getPoints?user_id=$userId'));
    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      setState(() {
        userPoints = result['points']; // 보유 포인트 업데이트
      });
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
              Icon(Icons.person, color: Colors.grey, size: 24), // 사용자 아이콘 추가
              SizedBox(width: 8),
              Text(
                '$userId', // 닉네임 부분만 보라색
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
              Icon(Icons.attach_money, color: Colors.grey, size: 24), // 포인트 아이콘 추가
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
                '${userPoints}P', // 포인트 값과 "P"만 오렌지색으로 설정
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
            padding: const EdgeInsets.only(bottom: 50.0), // 로고와 버튼 사이 간격 설정
            child: Image.asset(
              'assets/Logo.png', // 로고 이미지 경로
              width: 500, // 로고 너비
              height: 200, // 로고 높이
            ),
          ),
          SizedBox(height: 10),

          // 전쟁하기 버튼 (첫번째 버튼)
          ElevatedButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => War()));
            },
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white, backgroundColor: Colors.pink, // 텍스트 색상
              padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15), // 버튼 패딩 설정
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30), // 둥근 모서리
              ),
            ),
            child: Text(
              '전쟁하기',
              style: TextStyle(fontSize: 20), // 텍스트 크기 설정
            ),
          ),
          SizedBox(height: 20), // 버튼 사이 간격

          // 광질하기 버튼 (두번째 버튼)
          ElevatedButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => Mining()));
            },
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white, backgroundColor: Colors.green, // 텍스트 색상
              padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15), // 버튼 패딩 설정
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30), // 둥근 모서리
              ),
            ),
            child: Text(
              '광질하기',
              style: TextStyle(fontSize: 20), // 텍스트 크기 설정
            ),
          ),
          SizedBox(height: 20), // 버튼 사이 간격

          // 농사하기 버튼 (세번째 버튼)
          ElevatedButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => Farming()));
            },
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white, backgroundColor: Colors.orange, // 텍스트 색상
              padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15), // 버튼 패딩 설정
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30), // 둥근 모서리
              ),
            ),
            child: Text(
              '농사하기',
              style: TextStyle(fontSize: 20), // 텍스트 크기 설정
            ),
          ),
          SizedBox(height: 20), // 버튼 사이 간격

          // 업그레이드 버튼 (네번째 버튼)
          ElevatedButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => Upgrade()));
            },
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white, backgroundColor: Colors.blue, // 텍스트 색상
              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15), // 버튼 패딩 설정
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30), // 둥근 모서리
              ),
            ),
            child: Text(
              '업그레이드',
              style: TextStyle(fontSize: 20), // 텍스트 크기 설정
            ),
          ),
        ],
      ),
    );
  }
}
