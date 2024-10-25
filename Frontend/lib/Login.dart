import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart'; // Google Fonts 패키지 추가
import 'MainPage.dart';

class Login extends StatefulWidget {
  static String? userId;
  static String url = 'http://10.0.2.2:8080'; // URL을 전역적으로 사용 가능하게 설정

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController _controller = TextEditingController();
  String _errorMessage = "";
  bool _isTextFieldEnabled = true; // TextField 활성화/비활성화 상태를 위한 변수
  bool _isErrorState = false; // 중복된 닉네임 상태를 위한 변수

  @override
  void initState() {
    super.initState();
    _clearLocalData(); // 로컬 데이터 초기화 함수 호출
    _checkUserId();
  }

  Future<void> _clearLocalData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // 저장된 모든 데이터 삭제
  }

  Future<void> _checkUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedUserId = prefs.getString('user_id');

    if (savedUserId != null) {
      try {
        final response = await http.post(
          Uri.parse('${Login.url}/api/register'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'user_id': savedUserId}),
        );

        if (response.statusCode == 400) {
          final result = jsonDecode(response.body);
          if (result['message'] == "중복된 닉네임입니다.") {
            Login.userId = savedUserId;
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => MainPage()));
          }
        } else {
          setState(() {
            _errorMessage = '서버 연결에 문제가 있습니다. 다시 시도해주세요.';
          });
        }
      } catch (e) {
        setState(() {
          _errorMessage = '서버가 닫혀 있어 작동할 수 없습니다.';
        });
      }
    }
  }

  Future<void> _registerUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedUserId = prefs.getString('user_id');

    try {
      // 백엔드에 저장된 user_id가 존재하는지 확인 요청
      final response = await http.post(
        Uri.parse('${Login.url}/api/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': savedUserId ?? _controller.text}),
      );

      // 서버에 저장된 아이디가 이미 존재하는 경우
      if (response.statusCode == 400) {
        final result = jsonDecode(response.body);
        if (result['message'] == "중복된 닉네임입니다.") {
          // 기존 저장된 아이디로 로그인 진행
          Login.userId = savedUserId;
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => MainPage()));
          return;
        }
      }
      // 새로운 회원가입 요청을 진행할 경우
      else if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['success']) {
          // 새로 입력된 아이디로 회원가입 완료
          prefs.setString('user_id', _controller.text);
          Login.userId = _controller.text;
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => MainPage()));
        } else {
          setState(() {
            _errorMessage = result['message'];
            _isTextFieldEnabled = false;
            _controller.clear();
            _isErrorState = true;
          });
        }
      } else {
        // 서버가 열려 있으나 예기치 않은 오류 발생
        setState(() {
          _errorMessage = '알 수 없는 오류가 발생했습니다.';
        });
      }
    } catch (e) {
      // 서버 연결이 되지 않는 경우
      setState(() {
        _errorMessage = '서버 연결에 문제가 있습니다. 인터넷 환경을 확인해주세요.';
      });
    }
  }


  // 입력 필드를 다시 활성화하는 함수
  void _enableTextField() {
    setState(() {
      _isTextFieldEnabled = true;
      _errorMessage = ""; // 에러 메시지 제거
      _isErrorState = false; // 에러 상태 해제
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/Logo.png', // 로고 이미지 파일 경로
            width: 600, // 로고 너비 설정
            height: 200, // 로고 높이 설정
          ),
          Text(
            "인터넷을 연결하고 '참여하기'를 눌러주세요!", // 문구 추가
            style: TextStyle(fontSize: 16, color: Colors.black), // 스타일 설정
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: GestureDetector(
              onTap: () {
                if (!_isTextFieldEnabled) {
                  _enableTextField(); // 클릭하면 에러 메시지 제거 및 TextField 활성화
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: _isErrorState ? Colors.green.shade100 : Colors.white, // 중복 닉네임이면 바로 초록색으로 변경
                  borderRadius: BorderRadius.circular(12), // 둥근 모서리
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2), // 그림자 색상
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: Offset(2, 5), // 그림자 위치 설정
                    ),
                  ],
                ),
                child: TextField(
                  controller: _controller,
                  enabled: _isTextFieldEnabled, // TextField 활성화/비활성화 상태
                  maxLength: 20, // 닉네임을 10글자 이하로 제한
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.person, color: Colors.grey), // 아이콘 추가 (사람 모양)
                    hintText: '사용하실 닉네임을 적어주세요',
                    hintStyle: TextStyle(color: Colors.grey), // 힌트 텍스트 색상
                    filled: true,
                    fillColor: Colors.white, // 내부 배경 하얀색
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12), // 둥근 모서리
                      borderSide: BorderSide(color: Colors.grey.shade300), // 연한 회색 테두리
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.green.shade300), // 비활성화 상태 테두리
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.blueAccent, width: 2), // 활성화 상태 테두리 (파란색)
                    ),
                    counterText: '', // 글자 수 카운터 없애기
                  ),
                  style: TextStyle(color: Colors.black), // 입력된 텍스트 색상
                ),
              ),
            ),
          ),
          if (_errorMessage.isNotEmpty) // 에러 메시지가 있는 경우만 표시
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                _errorMessage,
                style: GoogleFonts.notoSans( // notoSans 폰트 사용
                  color: Colors.red, // 에러 메시지를 빨간색으로 표시
                  fontSize: 16, // 폰트 크기 설정 (필요에 맞게 수정)
                ),
              ),
            ),
          SizedBox(height: 20,),
          ElevatedButton(
            onPressed: _registerUser,
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white, backgroundColor: Colors.green, // 텍스트 색상
              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10), // 버튼 패딩 설정
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30), // 둥근 모서리
              ),
            ),
            child: Text(
              '참여하기',
              style: GoogleFonts.notoSans(fontSize: 20), // 텍스트 크기 및 폰트 설정
            ),
          ),
        ],
      ),
    );
  }
}