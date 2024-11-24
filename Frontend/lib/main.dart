import 'package:flutter/material.dart';
import 'Login.dart';
import 'MainPage/MainPage.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {

  //전역 변수
  static const String url = 'http://10.0.2.2:8080';
  static const String url2 = 'ws://10.0.2.2:8080';
  static String user_name = ''; //향후 본인 아이디는 모두 이걸로 통일
  static String currentLanguage = 'ENG';
  static String currentTheme = '';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Power Clicker',
      home: Login(),
    );
  }
}