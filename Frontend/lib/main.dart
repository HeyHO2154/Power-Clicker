import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'MainPage/MainPage.dart';
import 'Login.dart';

void main() {
  // 아래꺼 주석 해제하면 전체화면됨
  // WidgetsFlutterBinding.ensureInitialized();
  // SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {

  //매번 아이피 가져오기 귀찮아서, 이리 설정
  static const String url = 'http://10.0.2.2:8080';
  static const String url2 = 'ws://10.0.2.2:8080';
  static String user_id = ''; //향후 본인 아이디는 모두 이걸로 통일
  static String currentLanguage = 'ENG'; // 기본 언어 설정
  static String currentTheme = 'cat';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      //home: MainPage(),
      home: HomePage(), // 홈 페이지를 초기 화면으로 설정
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    _initializeLanguageSetting(); // 언어 설정 불러오기
    _initializeThemeSetting(); // 테마 설정 불러오기
    _checkLoginStatus();
    _resetPreferences(); //디버그용 초기화
  }

  // SharedPreferences 초기화 함수 - 디버깅용
  Future<void> _resetPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // 로컬 저장소 초기화
    print('로컬 저장소 초기화 완료');
  }

  //언어 설정 불러오기
  Future<void> _initializeLanguageSetting() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedLanguage = prefs.getString('language'); // 저장된 언어 확인
    if (savedLanguage != null) {
      MyApp.currentLanguage = savedLanguage; // 저장된 언어로 설정
    } else {
      MyApp.currentLanguage = 'ENG'; // 기본 언어 설정
    }
  }

  //테마 설정 불러오기
  Future<void> _initializeThemeSetting() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedTheme = prefs.getString('currentTheme'); // 저장된 언어 확인
    if (savedTheme != null) {
      MyApp.currentTheme = savedTheme; // 저장된 언어로 설정
    } else {
      MyApp.currentLanguage = 'defaults'; // 기본 언어 설정
    }
  }



  Future<void> _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('user_id'); // 로컬 저장소에서 아이디 확인

    // 아이디가 저장되어 있으면 MainPage로 이동
    if (userId != null) {
      MyApp.user_id = userId; //로컬 저장소에 있는 아이디를 메인으로 설정
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MainPage()),
      );
    } else {
      // 아이디가 없으면 LoginPage로 이동
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: CircularProgressIndicator()), // 로딩 화면
    );
  }
}
