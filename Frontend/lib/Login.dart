// login.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'MainPage.dart';

class Login extends StatefulWidget {
  static String? userId;

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController _controller = TextEditingController();
  String _errorMessage = "";

  @override
  void initState() {
    super.initState();
    _checkUserId();
  }

  Future<void> _checkUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedUserId = prefs.getString('user_id');
    if (savedUserId != null) {
      Login.userId = savedUserId;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => MainPage()));
    }
  }

  Future<void> _registerUser() async {
    final response = await http.post(
      Uri.parse('http://10.0.2.2:8080/api/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': _controller.text}),
    );

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      if (result['success']) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setString('user_id', _controller.text);
        Login.userId = _controller.text;
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => MainPage()));
      } else {
        setState(() {
          _errorMessage = result['message']; // "중복 닉네임입니다" 메시지 처리
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextField(
            controller: _controller,
            decoration: InputDecoration(hintText: '닉네임을 입력하세요'),
          ),
          ElevatedButton(
            onPressed: _registerUser,
            child: Text('로그인'),
          ),
          if (_errorMessage.isNotEmpty)
            Text(
              _errorMessage,
              style: TextStyle(color: Colors.red),
            ),
        ],
      ),
    );
  }
}
