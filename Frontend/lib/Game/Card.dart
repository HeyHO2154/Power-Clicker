import 'package:flutter/material.dart';

class CardPage extends StatelessWidget {
  final String sessionId;

  CardPage({required this.sessionId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: Colors.black,
        ),
        child: Center(
          child: Text(
            "카드 게임 세션: $sessionId",
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
