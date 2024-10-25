import 'package:flutter/material.dart';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../Login.dart';

class Upgrade extends StatefulWidget {
  @override
  _UpgradeState createState() => _UpgradeState();
}

class _UpgradeState extends State<Upgrade> {
  Random random = Random();
  int totalPoints = 0;
  bool isFactoryActive = false;
  DateTime? factoryActivatedTime;
  Duration remainingTime = Duration.zero;

  @override
  void initState() {
    super.initState();
    _fetchPoints();
    _updateRemainingTime();
  }

  Future<void> _fetchPoints() async {
    final response = await http.get(Uri.parse("${Login.url}/api/getPoints?user_id=${Login.userId}"));

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

  Future<void> _checkAndExecutePurchase(int cost, Function onSuccess) async {
    final response = await http.get(Uri.parse("${Login.url}/api/getPoints?user_id=${Login.userId}"));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final currentPoints = data['points'];

      if (currentPoints >= cost) {
        await onSuccess();
        setState(() {
          totalPoints = currentPoints - cost;
        });
      } else {
        _showInsufficientPointsDialog();
      }
    } else {
      print("Error fetching points: ${response.body}");
    }
  }

  void _showInsufficientPointsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("포인트 부족"),
        content: Text("포인트가 부족하여 구매할 수 없습니다."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text("확인"),
          ),
        ],
      ),
    );
  }

  Future<void> _attemptNicknameChange() async {
    await _checkAndExecutePurchase(1000, () async {
      await _decreasePoints(1000);
      print("닉네임이 성공적으로 변경되었습니다.");
    });
  }

  Future<void> _attemptFactoryActivationOrExtension() async {
    await _checkAndExecutePurchase(5000, () async {
      await _decreasePoints(5000);
      setState(() {
        isFactoryActive = true;
        factoryActivatedTime = factoryActivatedTime == null
            ? DateTime.now()
            : factoryActivatedTime!.add(Duration(hours: 24));
        _updateRemainingTime();
      });
    });
  }

  void _updateRemainingTime() {
    if (factoryActivatedTime != null) {
      final now = DateTime.now();
      final duration = factoryActivatedTime!.difference(now);

      setState(() {
        remainingTime = duration > Duration.zero ? duration : Duration.zero;
        isFactoryActive = remainingTime > Duration.zero;
      });
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 상단 박스
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
                    "(공장 활성화 = 초당 1P 수익 발생)",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            // 닉네임 바꾸기
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
                          decoration: InputDecoration(
                            hintText: "${Login.userId}",
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: totalPoints >= 1000 ? _attemptNicknameChange : null,
                        child: Text("닉네임 변경 (1000 P)"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // 포인트 충전 (가로 스크롤 및 박스형태)
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
                        _buildPointBox("1,000 포인트", "1000 P", 1000, "assets/money1.png"),
                        SizedBox(width: 16),
                        _buildPointBox("5,500 포인트", "5000 P", 5500, "assets/money2.png", bonus: "+10%"),
                        SizedBox(width: 16),
                        _buildPointBox("12,000 포인트", "10000 P", 12000, "assets/money3.png", bonus: "+20%"),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // 공장 활성화
            Padding(
              padding: const EdgeInsets.all(0.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "공장",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  // 공장 이미지
                  ColorFiltered(
                    colorFilter: isFactoryActive
                        ? ColorFilter.mode(Colors.transparent, BlendMode.multiply)
                        : ColorFilter.mode(Colors.grey, BlendMode.saturation),
                    child: Image.asset("assets/factory.png",
                        width: MediaQuery.of(context).size.width - 40), // 좌우로 꽉 차게 배치
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: totalPoints >= 5000 ? _attemptFactoryActivationOrExtension : null,
                    child: Text(isFactoryActive ? "연장하기 (5000 P)" : "공장 활성화 (5000 P)"),
                  ),
                  if (isFactoryActive)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        "남은 시간: ${_formatDuration(remainingTime)}",
                        style: TextStyle(fontSize: 16, color: Colors.green),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPointBox(String points, String price, int increaseAmount, String imagePath, {String? bonus}) {
    return GestureDetector(
      onTap: () => _increasePoints(increaseAmount),
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
                Text(price, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.green)),
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
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
