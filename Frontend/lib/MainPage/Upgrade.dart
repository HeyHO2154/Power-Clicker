// upgrade.dart
import 'package:flutter/material.dart';

class Upgrade extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('업그레이드'),
      ),
      body: Center(
        child: Text('자동 클릭커 1일 = 5천원', style: TextStyle(fontSize: 24)),
      ),
    );
  }
}
