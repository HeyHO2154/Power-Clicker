import 'package:flutter/material.dart';
import 'dart:math';

import '../Login.dart';

class Farming extends StatefulWidget {
  @override
  _FarmingState createState() => _FarmingState();
}

class _FarmingState extends State<Farming> {
  Random random = Random();
  int totalPoints = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // 상단 박스
          Container(
            width: double.infinity, // 좌우로 꽉 채움
            padding: EdgeInsets.symmetric(vertical: 30), // 상하 padding만 설정
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange, Colors.brown.shade400], // 오렌지색과 갈색 그라데이션
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(20), // 아래쪽만 둥근 모서리
              ),
            ),
            child: Column(
              children: [
                Text(
                  "${Login.userId} : ${totalPoints}P",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.yellow, // 글씨가 잘 보이도록 설정
                  ),
                ),
                Text(
                  "광물을 클릭해서 포인트를 모으세요!",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black, // 글씨가 잘 보이도록 설정
                  ),
                ),
                SizedBox(height: 8), // 줄바꿈을 위한 여백
                Text(
                  "(광물 클릭시 10% 확률로 피버타임 발생)",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54, // 부가 설명 글씨는 조금 연하게 설정
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                'Farming 기능을 여기에 구현하세요!',
                style: TextStyle(fontSize: 24, color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
