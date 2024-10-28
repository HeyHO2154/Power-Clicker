import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'MainPage/Mining.dart';
import 'MainPage/Upgrade.dart';
import 'MainPage/VIP.dart';
import 'MainPage/War.dart';
import 'MainPage/Farming.dart';
import 'Login.dart';

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int userPoints = 0;
  int userRank = 0;
  ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchUserPoints();
    _fetchUserRank();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // _fetchUserRank()와 _fetchUserPoints()는 호출하지 않음
  }


  Future<void> _fetchUserPoints() async {
    if (Login.userId == null) return;

    final response = await http.get(
      Uri.parse('${Login.url}/api/getPoints?user_id=${Login.userId}'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        userPoints = data['points'];
      });
    } else {
      print('Failed to load points');
    }
  }

  Future<void> _fetchUserRank() async {
    final response = await http.get(
      Uri.parse('${Login.url}/api/users'),
    );

    if (response.statusCode == 200) {
      final List users = jsonDecode(utf8.decode(response.bodyBytes)); // UTF-8로 디코딩
      int rank = users.indexWhere((user) => user['user_id'] == Login.userId) + 1;

      setState(() {
        userRank = rank;
      });
      print("Current userRank: $userRank"); // userRank 값 확인
    } else {
      print('Failed to load user rank');
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // cat.png 배경 이미지 (50등 이하일 때만)
          if (userRank <= 50)
            Positioned.fill(
              child: Opacity(
                opacity: 0.5,
                child: Image.asset(
                  'assets/cat.png',
                  fit: BoxFit.fill,
                  alignment: Alignment.bottomCenter,
                ),
              ),
            ),
          // 자유 스크롤 가능
          SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              children: [
                SizedBox(height: 60),
                Container(
                  color: Colors.white.withOpacity(0.7), // 반투명 배경 색상 설정
                  padding: EdgeInsets.all(16), // 적당한 내부 여백 추가
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.person, color: Colors.grey.shade700, size: 30),
                          SizedBox(width: 8),
                          Text(
                            '${Login.userId}',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.purpleAccent.shade700,
                            ),
                          ),
                          Text(
                            '님 환영합니다!',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.attach_money, color: Colors.grey.shade700, size: 30),
                          SizedBox(width: 8),
                          Text(
                            '보유 포인트: ',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          Text(
                            '${userPoints}P',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.pinkAccent.shade200,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 0.0),
                  child: Image.asset(
                    'assets/Logo.png',
                    width: 500,
                    height: 200,
                  ),
                ),
                // VIP 대화방 버튼 (10등 이하일 때만 표시)
                if (userRank <= 10)
                  ElevatedButton(
                    onPressed: () async {
                      await Navigator.push(
                          context, MaterialPageRoute(builder: (context) => Vip()));
                      _fetchUserPoints();
                      _fetchUserRank();
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.yellow.shade900,
                      backgroundColor: Colors.yellowAccent,
                      padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      '대화하기',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    await Navigator.push(
                        context, MaterialPageRoute(builder: (context) => War()));
                    _fetchUserPoints();
                    _fetchUserRank();
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.pink,
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    '전쟁하기',
                    style: TextStyle(fontSize: 20),
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    await Navigator.push(
                        context, MaterialPageRoute(builder: (context) => Mining()));
                    _fetchUserPoints();
                    _fetchUserRank();
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    '광질하기',
                    style: TextStyle(fontSize: 20),
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    await Navigator.push(
                        context, MaterialPageRoute(builder: (context) => Farming()));
                    _fetchUserPoints();
                    _fetchUserRank();
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.orange,
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    '농사하기',
                    style: TextStyle(fontSize: 20),
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    await Navigator.push(
                        context, MaterialPageRoute(builder: (context) => Upgrade()));
                    _fetchUserPoints();
                    _fetchUserRank();
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.blue,
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    '업그레이드',
                    style: TextStyle(fontSize: 20),
                  ),
                ),
                SizedBox(height: 140),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

