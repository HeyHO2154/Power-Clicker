import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'MainPage/Mining.dart';
import 'MainPage/Upgrade.dart';
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

  @override
  void initState() {
    super.initState();
    _fetchUserPoints();
    _fetchUserRank();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchUserRank();
    _fetchUserPoints();
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
      final List users = jsonDecode(response.body);
      int rank = users.indexWhere((user) => user['user_id'] == Login.userId) + 1;

      setState(() {
        userRank = rank;
      });
    } else {
      print('Failed to load user rank');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          if (userRank <= 20)
            Positioned.fill(
              child: Opacity(
                opacity: 0.5,
                child: Image.asset(
                  'assets/cat.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          RefreshIndicator(
            onRefresh: _fetchUserPoints,
            child: SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  SizedBox(height: 100),
                  Row(
                    children: [
                      Icon(Icons.person, color: Colors.grey.shade800, size: 30),
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
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.attach_money, color: Colors.grey, size: 30),
                      SizedBox(width: 8),
                      Text(
                        '보유 포인트: ',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        '${userPoints}P',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.purpleAccent,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 30),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 40.0),
                    child: Image.asset(
                      'assets/Logo.png',
                      width: 500,
                      height: 200,
                    ),
                  ),
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
                        borderRadius: BorderRadius.circular(30),
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
                        borderRadius: BorderRadius.circular(30),
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
                        borderRadius: BorderRadius.circular(30),
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
            ),
          ),
        ],
      ),
    );
  }
}
