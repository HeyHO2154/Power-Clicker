// mainPage.dart
import 'package:flutter/material.dart';

import 'MainPage/Mining.dart';
import 'MainPage/Upgrade.dart';
import 'MainPage/War.dart';

class MainPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Main Page'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => Mining()));
              },
              child: Text('광질하기'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => War()));
              },
              child: Text('전쟁하기'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => Upgrade()));
              },
              child: Text('업그레이드'),
            ),
          ],
        ),
      ),
    );
  }
}
