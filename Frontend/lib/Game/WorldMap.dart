import 'package:flutter/material.dart';

class WorldMap extends StatefulWidget {
  @override
  _WorldMapState createState() => _WorldMapState();
}

class _WorldMapState extends State<WorldMap> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('World Map')),
      body: InteractiveViewer(
        boundaryMargin: EdgeInsets.all(0), // 드래그 여백 설정
        minScale: 1.0, // 기본 크기
        maxScale: 3.0, // 최대 확대 비율
        child: Image.asset(
          'assets/map.jpg', // 이미지 경로
          width: 2000, // 이미지 원본 가로 크기
          height: 2000, // 이미지 원본 세로 크기
          fit: BoxFit.fill, // 이미지를 원본 크기에 맞게 채움
          alignment: Alignment.topLeft, // 드래그 시작 위치
        ),
      ),
    );
  }
}
