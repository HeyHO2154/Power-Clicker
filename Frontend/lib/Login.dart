import 'package:flutter/material.dart';
import 'package:frontend/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart'; // Google Fonts 패키지 추가
import 'MainPage/MainPage.dart';

class Login extends StatefulWidget {
  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {

  @override
  void initState() {
    super.initState();
    //_clearLocalData(); // 로컬 데이터 초기화 함수 호출
    UserLogin();
  }

  Future<void> _clearLocalData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // 저장된 모든 데이터 삭제
  }

  Future<void> UserLogin() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userName = prefs.getString('user_name');

    try {
      final response = await http.post(
        Uri.parse('${MyApp.url}/api/Login'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({'user_name': userName}),
      );

      if (response.statusCode == 200) {
        MyApp.user_name = response.body;
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => MainPage()));
      } else {
        UserLogin();
      }
    } catch (e) {
      print('서버 접속 실패');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(), // 무한 로딩 화면
      ),
    );
  }
}