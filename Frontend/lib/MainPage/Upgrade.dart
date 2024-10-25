import 'package:flutter/material.dart';
import 'dart:math';

class Upgrade extends StatefulWidget {
  @override
  _UpgradeState createState() => _UpgradeState();
}

class _UpgradeState extends State<Upgrade> {
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
                colors: [Colors.blue.shade400, Colors.white], // 파란색과 하얀색 그라데이션
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
                  "${totalPoints}P",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.yellow, // 글씨가 잘 보이도록 설정
                  ),
                ),
                Text(
                  "업그레이드를 통해 수익성을 강화하세요!",
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
                'Upgrade 기능을 여기에 구현하세요!',
                style: TextStyle(fontSize: 24, color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
