import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../Login.dart';

class Farming extends StatefulWidget {
  @override
  _FarmingState createState() => _FarmingState();
}

class _FarmingState extends State<Farming> {
  int totalPoints = 0;
  int selectedSeeds = 1;
  String resultMessage = "";
  String currentSeason = "봄";
  final Random random = Random();
  bool isRouletteSpinning = false;
  Timer? rouletteTimer;
  String? userId;
  bool isHarvestButtonVisible = true;

  @override
  void initState() {
    super.initState();
    fetchUserId();
  }

  @override
  void dispose() {
    rouletteTimer?.cancel();
    super.dispose();
  }

  Future<void> fetchUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('user_id');
    if (userId != null) {
      fetchPoints();
    }
  }

  Future<void> fetchPoints() async {
    final response = await http.get(Uri.parse("${Login.url}/api/getPoints?user_id=$userId"));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        totalPoints = data['points'];
        selectedSeeds = min(selectedSeeds, totalPoints);
      });
    }
  }

  Future<void> decreasePoints(int points) async {
    final response = await http.post(
      Uri.parse("${Login.url}/api/decrease"),
      headers: {"Content-Type": "application/json"},
      body: json.encode({"user_id": userId, "points": points}),
    );
    if (response.statusCode == 200) {
      setState(() {
        totalPoints -= points;
      });
    } else {
      setState(() {
        resultMessage = "포인트가 부족합니다.";
      });
    }
  }

  Future<void> increasePoints(int points) async {
    await http.post(
      Uri.parse("${Login.url}/api/increase"),
      headers: {"Content-Type": "application/json"},
      body: json.encode({"user_id": userId, "points": points}),
    );
    fetchPoints();
  }

  void startRoulette() {
    setState(() {
      isRouletteSpinning = true;
      resultMessage = "";
      isHarvestButtonVisible = true;
    });

    rouletteTimer = Timer.periodic(Duration(milliseconds: 100), (timer) {
      if (mounted) {
        setState(() {
          currentSeason = getNextSeason(currentSeason);
        });
      }
    });
  }

  void stopRoulette() async {
    if (rouletteTimer != null && rouletteTimer!.isActive) {
      rouletteTimer!.cancel();
    }

    setState(() {
      isHarvestButtonVisible = false;
    });

    int slowingCount = 10;
    int interval = 200;

    Timer.periodic(Duration(milliseconds: interval), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        currentSeason = getNextSeason(currentSeason);
      });
      slowingCount--;
      interval += 100;

      if (slowingCount <= 0) {
        timer.cancel();
        final reward = calculateReward();
        setState(() {
          resultMessage = reward["message"];
        });

        Future.delayed(Duration(seconds: 3), () {
          if (mounted && reward["points"] > 0) {
            increasePoints(reward["points"]);
          }
          if (mounted) {
            setState(() {
              isRouletteSpinning = false;
            });
          }
        });
      }
    });
  }

  String getNextSeason(String current) {
    switch (current) {
      case "봄":
        return "여름";
      case "여름":
        return "가을";
      case "가을":
        return "겨울";
      default:
        return "봄";
    }
  }

  Map<String, dynamic> calculateReward() {
    switch (currentSeason) {
      case "봄":
      case "겨울":
        return {"message": "씨앗이 다 날아갔습니다!", "points": 0};
      case "여름":
        return {
          "message": "이른 수확입니다! 심었던 포인트(${selectedSeeds})를 회수합니다.",
          "points": selectedSeeds
        };
      case "가을":
        return {
          "message": "풍년입니다! 3배인 (${selectedSeeds * 3}) 포인트를 얻습니다.",
          "points": selectedSeeds * 3
        };
      default:
        return {"message": "", "points": 0};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // 상단 박스
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 30),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange, Colors.brown.shade400],
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
                  "${totalPoints}P",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.yellow,
                  ),
                ),
                Text(
                  "농사를 통해 포인트를 얻어보세요!",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "(광물 클릭시 10% 확률로 피버타임 발생)",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isRouletteSpinning
                      ? "현재의 계절: $currentSeason"
                      : "씨앗을 심고 수확을 기다리세요!",
                  style: TextStyle(fontSize: 20, color: Colors.black),
                ),
                if (!isRouletteSpinning)
                  Column(
                    children: [
                      Text("심을 씨앗을 선택하세요:"),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildSeedButton(10),
                          SizedBox(width: 10),
                          _buildSeedButton(50),
                          SizedBox(width: 10),
                          _buildSeedButton(100),
                        ],
                      ),
                    ],
                  ),
                if (isRouletteSpinning && isHarvestButtonVisible)
                  ElevatedButton(
                    onPressed: () {
                      stopRoulette();
                    },
                    child: Text("수확"),
                  ),
                SizedBox(height: 20),
                if (!isRouletteSpinning && resultMessage.isNotEmpty)
                  Text(
                    resultMessage,
                    style: TextStyle(fontSize: 18, color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeedButton(int seedCount) {
    return ElevatedButton(
      onPressed: totalPoints >= seedCount
          ? () {
        setState(() {
          selectedSeeds = seedCount;
          decreasePoints(selectedSeeds);
          startRoulette();
        });
      }
          : null,
      child: Text("$seedCount개 심기"),
    );
  }
}
