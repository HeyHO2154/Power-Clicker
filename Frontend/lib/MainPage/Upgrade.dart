import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../Login.dart';

class Upgrade extends StatefulWidget {
  @override
  _UpgradeState createState() => _UpgradeState();
}

class _UpgradeState extends State<Upgrade> {
  Random random = Random();
  int totalPoints = 0;
  int FactoryTime = 10;
  bool isFactoryActive = false;
  Duration remainingTime = Duration.zero;
  Timer? countdownTimer;
  TextEditingController _userIdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchPoints();
    _loadFactoryStatus();
  }

  Future<void> _fetchPoints() async {
    final response = await http.get(
        Uri.parse("${Login.url}/api/getPoints?user_id=${Login.userId}"));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        totalPoints = data['points'];
      });
    } else {
      print("Error fetching points: ${response.body}");
    }
  }

  Future<void> _increasePoints(int points) async {
    final response = await http.post(
      Uri.parse("${Login.url}/api/increase"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"user_id": Login.userId, "points": points}),
    );

    if (response.statusCode == 200) {
      setState(() {
        totalPoints += points;
      });
    } else {
      print("Error increasing points: ${response.body}");
    }
  }

  Future<void> _decreasePoints(int points) async {
    final response = await http.post(
      Uri.parse("${Login.url}/api/decrease"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"user_id": Login.userId, "points": points}),
    );

    if (response.statusCode == 200) {
      setState(() {
        totalPoints -= points;
      });
    } else {
      print("Error decreasing points: ${response.body}");
    }
  }

  Future<void> _updateUserId() async {
    await _fetchPoints();
    if (totalPoints >= 1000) {
      final response = await http.post(
        Uri.parse("${Login.url}/api/updateUserId"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": Login.userId,
          "new_user_id": _userIdController.text,
        }),
      );

      if (response.statusCode == 200) {
        print("아이디 변경 성공: ${response.body}");
        await _updateLocalUserId(_userIdController.text);
        setState(() {
          Login.userId = _userIdController.text;
          _userIdController.clear();
        });
        _decreasePoints(1000);
      } else if (response.statusCode == 409) {
        _showErrorDialog("이미 존재하는 아이디입니다.");
      } else {
        _showErrorDialog("아이디 변경에 실패했습니다.");
      }
    } else {
      _showErrorDialog("포인트가 부족하여 아이디를 변경할 수 없습니다.");
    }
  }

  Future<void> _updateLocalUserId(String newUserId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', newUserId);
  }

  Future<void> _toggleFactoryActivation() async {
    await _fetchPoints();
    if (isFactoryActive) {
      _deactivateFactory();
    } else if (totalPoints >= 5000) {
      await _decreasePoints(5000);
      setState(() {
        isFactoryActive = true;
        remainingTime = Duration(seconds: FactoryTime);
      });
      _startCountdown();
      await _saveFactoryStatus();
    } else {
      _showErrorDialog("포인트가 부족하여 공장을 활성화할 수 없습니다.");
    }
  }

  void _deactivateFactory() {
    setState(() {
      isFactoryActive = false;
      remainingTime = Duration.zero;
      countdownTimer?.cancel();
    });
    _removeFactoryStatus();
  }

  Future<void> _startCountdown() async {
    countdownTimer?.cancel();
    countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (remainingTime.inSeconds <= 1) {
        _deactivateFactory();
      } else {
        setState(() {
          remainingTime -= Duration(seconds: 1);
        });
      }
      _saveFactoryStatus();
    });
  }

  Future<void> _extendFactoryTime() async {
    await _fetchPoints();
    if (totalPoints >= 5000 && isFactoryActive) {
      await _decreasePoints(5000);
      setState(() {
        remainingTime += Duration(seconds: FactoryTime);
      });
      _saveFactoryStatus();
    } else {
      _showErrorDialog("포인트가 부족하여 연장할 수 없습니다.");
    }
  }

  Future<void> _saveFactoryStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFactoryActive', isFactoryActive);
    await prefs.setInt('remainingTime', remainingTime.inSeconds);
    await prefs.setInt('lastUpdateTime', DateTime
        .now()
        .millisecondsSinceEpoch);
  }

  Future<void> _loadFactoryStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? savedFactoryStatus = prefs.getBool('isFactoryActive');
    int? savedRemainingTime = prefs.getInt('remainingTime');
    int? lastUpdateTime = prefs.getInt('lastUpdateTime');

    if (savedFactoryStatus != null && savedRemainingTime != null &&
        lastUpdateTime != null) {
      int elapsed = DateTime
          .now()
          .millisecondsSinceEpoch - lastUpdateTime;
      Duration elapsedTime = Duration(milliseconds: elapsed);
      Duration updatedRemainingTime = Duration(seconds: savedRemainingTime) -
          elapsedTime;

      if (savedFactoryStatus && updatedRemainingTime > Duration.zero) {
        setState(() {
          isFactoryActive = true;
          remainingTime = updatedRemainingTime;
        });
        _startCountdown();
      } else {
        _deactivateFactory();
      }
    }
  }

  Future<void> _removeFactoryStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('isFactoryActive');
    await prefs.remove('remainingTime');
    await prefs.remove('lastUpdateTime');
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: Text("에러"),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text("확인"),
              ),
            ],
          ),
    );
  }

  @override
  void dispose() {
    countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView( // SingleChildScrollView 대신 ListView로 변경
        padding: EdgeInsets.all(0), // 패딩 조정
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 30),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade400, Colors.white],
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
                  "$totalPoints P",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.yellow,
                  ),
                ),
                Text(
                  "업그레이드를 통해 수익성을 강화하세요!",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "( 공장 활성화시 1초당 1포인트 자동 증가 )",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "닉네임 바꾸기",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _userIdController,
                        decoration: InputDecoration(
                          hintText: "${Login.userId}",
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: totalPoints >= 1000 ? _updateUserId : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.lightBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        "닉네임 변경 (1000 P)",
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "포인트 충전",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(
                  height: 160,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildPointBox(
                          "1,000 포인트", "1000 P", 1000, "assets/money1.png"),
                      SizedBox(width: 16),
                      _buildPointBox(
                          "5,500 포인트", "5000 P", 5500, "assets/money2.png",
                          bonus: "+10%"),
                      SizedBox(width: 16),
                      _buildPointBox(
                          "12,000 포인트", "10000 P", 12000, "assets/money3.png",
                          bonus: "+20%"),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                "자동화 공장",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    ColorFiltered(
                      colorFilter: isFactoryActive
                          ? ColorFilter.mode(
                          Colors.transparent, BlendMode.multiply)
                          : ColorFilter.mode(Colors.grey, BlendMode.saturation),
                      child: Image.asset("assets/factory.png",
                          width: MediaQuery
                              .of(context)
                              .size
                              .width - 40),
                    ),
                    Positioned(
                      child: ElevatedButton(
                        onPressed: isFactoryActive
                            ? _extendFactoryTime
                            : _toggleFactoryActivation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isFactoryActive
                              ? Colors.green
                              : Colors.lightBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Text(
                          isFactoryActive
                              ? "연장하기 (${FactoryTime}초 추가)"
                              : "공장 활성화 (5000 P)",
                          style: TextStyle(color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
                if (isFactoryActive)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      _formatDuration(remainingTime),
                      style: TextStyle(fontSize: 16, color: Colors.red),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

  Widget _buildPointBox(String points, String price, int increaseAmount, String imagePath, {String? bonus}) {
  return GestureDetector(
    child: Stack(
      children: [
        Container(
          padding: EdgeInsets.fromLTRB(10, 20, 10, 10),
          width: 150,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.lightBlue, width: 2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(imagePath, width: 60, height: 60),
              SizedBox(height: 10),
              Text(points, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.yellow.shade900)),
              SizedBox(height: 8),
              Text(price, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey.shade500)),
            ],
          ),
        ),
        if (bonus != null)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(10),
                  bottomLeft: Radius.circular(10),
                ),
              ),
              child: Text(
                bonus,
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
      ],
    ),
  );
}

