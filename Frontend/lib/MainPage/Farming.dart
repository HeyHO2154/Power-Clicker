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
    final response = await http.get(
        Uri.parse("${Login.url}/api/getPoints?user_id=$userId"));
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

  Future<void> attemptStartFarming(int seedCount) async {
    final response = await http.get(
        Uri.parse("${Login.url}/api/getPoints?user_id=$userId"));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final currentPoints = data['points'];

      if (currentPoints >= seedCount) {
        setState(() {
          selectedSeeds = seedCount;
        });
        await decreasePoints(selectedSeeds);
        startRoulette();
      } else {
        setState(() {
          resultMessage = "포인트가 부족합니다.";
        });
      }
    } else {
      setState(() {
        resultMessage = "포인트를 확인하는 중 오류가 발생했습니다.";
      });
    }
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
        return {"message": "봄은 춥습니다, 씨앗이 다 날아갔습니다!", "points": 0};
      case "겨울":
        return {"message": "겨울은 춥습니다, 씨앗이 다 날아갔습니다!", "points": 0};
      case "여름":
        return {
          "message": "이른 수확입니다! 심었던 (${selectedSeeds}) 포인트를 회수합니다.",
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

  String getSeasonIcon(String currentSeason) {
    switch (currentSeason) {
      case "봄":
        return 'assets/spring.png';
      case "여름":
        return 'assets/summer.png';
      case "가을":
        return 'assets/autumn.png';
      case "겨울":
        return 'assets/winter.png';
      default:
        return 'assets/spring.png'; // 기본값
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
                  "( 봄: x0 / 여름: x1 / 가을: x3 / 겨울: x0 )",
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
                Image.asset(
                  getSeasonIcon(currentSeason),
                  width: 100,
                  height: 100,
                ),
                SizedBox(height: 30,),
                Text(
                  isRouletteSpinning
                      ? "현재 계절: $currentSeason"
                      : "씨앗을 심고 수확 타이밍을 맞춰보세요!",
                  style: TextStyle(fontSize: 20, color: Colors.black),
                ),
                SizedBox(height: 30,),
                if (!isRouletteSpinning)
                  Column(
                    children: [
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
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      backgroundColor: Colors.brown.shade200,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      shadowColor: Colors.greenAccent,
                      elevation: 8,
                    ),
                    child: Text(
                      "수확하기",
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold, color: Colors.brown),
                    ),
                  ),
                SizedBox(height: 20),
                if (!isRouletteSpinning && resultMessage.isNotEmpty)
                  Card(
                    color: Colors.redAccent.withOpacity(0.8),
                    margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: Text(
                        resultMessage,
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
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
        attemptStartFarming(seedCount);
      }
          : null,
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        backgroundColor: totalPoints >= seedCount ? Colors.brown : Colors.grey,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        shadowColor: totalPoints >= seedCount ? Colors.orange : Colors.transparent,
        elevation: totalPoints >= seedCount ? 8 : 0,
      ),
      child: Text(
        "$seedCount개 심기",
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: totalPoints >= seedCount ? Colors.yellow.shade600 : Colors.black54,
        ),
      ),
    );
  }
}
