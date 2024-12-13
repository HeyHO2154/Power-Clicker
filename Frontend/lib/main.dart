import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'MainPage/MainPage.dart';
import 'Login.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart'; // url_launcher 패키지 import
import 'package:audioplayers/audioplayers.dart';

void main() {
  // 아래꺼 주석 해제하면 전체화면됨
  // WidgetsFlutterBinding.ensureInitialized();
  // SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {

  //매번 아이피 가져오기 귀찮아서, 이리 설정
  // static const String url = 'http://10.0.2.2:8080';
  // static const String url2 = 'ws://10.0.2.2:8080';
  static const String url = 'http://ekaf.kro.kr:25500';
  static const String url2 = 'ws://ekaf.kro.kr:25500';
  static String user_id = ''; //향후 본인 아이디는 모두 이걸로 통일
  static String currentLanguage = 'ENG'; // 기본 언어 설정
  static String currentTheme = 'Cat';
  static String version = '4.0'; //로그인시 벡엔드 버전과 다르면 접속 거부

  static AudioPlayer bgmPlayer = AudioPlayer(); // 배경 음악 플레이어

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
    //_resetPreferences(); //디버그용 초기화
    _initializeSetting(); // 로컬 저장소 불러오기
    _checkLoginStatus();
  }

  // SharedPreferences 초기화 함수 - 디버깅용
  Future<void> _resetPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // 로컬 저장소 초기화
    print('로컬 저장소 초기화 완료');
  }

  //언어 설정 불러오기
  Future<void> _initializeSetting() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedLanguage = prefs.getString('language'); // 저장된 언어 확인
    String? savedTheme = prefs.getString('currentTheme'); // 저장된 언어 확인
    if (savedLanguage != null) {
      MyApp.currentLanguage = savedLanguage; // 저장된 언어로 설정
    } else {
      MyApp.currentLanguage = 'ENG'; // 기본 언어 설정
    }
    if (savedTheme != null) {
      MyApp.currentTheme = savedTheme; // 저장된 언어로 설정
    } else {
      MyApp.currentTheme = 'Cat'; // 기본 언어 설정
    }
    //배경음악 재생
    await MyApp.bgmPlayer.setReleaseMode(ReleaseMode.loop);
    await MyApp.bgmPlayer.play(AssetSource('Sound/BGM/${MyApp.currentTheme}.mp3'));
  }

  Future<void> _checkLoginStatus() async {
    //서버 버전 동일성 체크
    final uri = Uri.parse('${MyApp.url}/main/version?version=${MyApp.version}');
    try {
      final response = await http.get(uri);
      if (response.body == 'true') {
        //버전이 동일한 경우
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String? userId = prefs.getString('user_id'); // 로컬 저장소에서 아이디 확인
        //아이디가 저장되어 있으면 MainPage로 이동
        if (userId != null) {
          MyApp.user_id = userId; //로컬 저장소에 있는 아이디를 메인으로 설정
          final url = Uri.parse('${MyApp.url}/user/login');
          http.post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'user_id': userId, 'user_pw': 0}),
          );
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
    } catch (e) {
      print("Error: $e");
    }
  }

  Future<void> _launchPlayStore() async {
    const playStoreUrl =
        'https://play.google.com/store/apps/details?id=com.hsj.powerclicker&pcampaignid=web_share';
    if (await canLaunch(playStoreUrl)) {
      await launch(playStoreUrl);
    } else {
      throw 'Could not launch $playStoreUrl';
    }
  }

  // 언어 설정 저장 함수
  Future<void> _setLanguage(String languageCode) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', languageCode); // 로컬 저장소에 언어 저장
    setState(() {
      MyApp.currentLanguage = languageCode; // 앱의 현재 언어 업데이트
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
                'assets/Theme/${MyApp.currentTheme}.png'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.5),
              BlendMode.darken,
            ),
          ),
        ),
        child: Stack(
          children: [
            // 좌측 상단 언어 변경 국기 아이콘
            Positioned(
              top: 60,
              left: 20,
              child: GestureDetector(
                onTap: _showLanguageSelection,
                child: Image.asset(
                  'assets/UI/Langs/${MyApp.currentLanguage}.jpg',
                  height: 40, // 국기 아이콘 크기
                ),
              ),
            ),
            // 가운데 업데이트 메시지와 버튼
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    lang('새 버전이 출시되었습니다!'),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          blurRadius: 8,
                          color: Colors.black54,
                          offset: Offset(3, 3),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _launchPlayStore,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amberAccent, // 버튼 배경색
                      foregroundColor: Colors.black, // 텍스트 색상
                      padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10), // 둥근 모서리
                      ),
                      elevation: 5, // 그림자
                    ),
                    child: Text(
                      lang('업데이트'),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

// 언어 선택 다이얼로그
  void _showLanguageSelection() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.grey.shade300.withOpacity(0.9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(22.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  lang('언어 선택'),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 5),
                Container(
                  height: 310, // 적절한 높이 설정
                  child: GridView.builder(
                    shrinkWrap: true,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3, // 3개씩 한 행에 배치
                      crossAxisSpacing: 10, // 가로 간격
                      mainAxisSpacing: 10, // 세로 간격
                    ),
                    itemCount: 9, // 9개 국기
                    itemBuilder: (context, index) {
                      final languages = [
                        'KOR',
                        'ENG',
                        'CHN',
                        'JPN',
                        'GER',
                        'FRA',
                        'RUS',
                        'ESP',
                        'ARA'
                      ];
                      final lang = languages[index];
                      return GestureDetector(
                        onTap: () async {
                          await _setLanguage(lang); // 언어 설정 저장
                          Navigator.pop(context);
                        },
                        child: Image.asset(
                          'assets/UI/Langs/$lang.jpg',
                          height: 60,
                          width: 60,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

String lang(String textKey) {
  final localizedTexts = {
    'KOR': {
      '언어 선택': '언어 선택',
      '새 버전이 출시되었습니다!': '새 버전이 출시되었습니다!',
      '업데이트': '업데이트',
    },
    'ENG': {
      '언어 선택': 'Select Language',
      '새 버전이 출시되었습니다!': 'A new version has been released!',
      '업데이트': 'Update',
    },
    'ARA': {
      '언어 선택': 'اختيار اللغة',
      '새 버전이 출시되었습니다!': 'تم إصدار نسخة جديدة!',
      '업데이트': 'تحديث',
    },
    'CHN': {
      '언어 선택': '选择语言',
      '새 버전이 출시되었습니다!': '新版本已发布！',
      '업데이트': '更新',
    },
    'JPN': {
      '언어 선택': '言語選択',
      '새 버전이 출시되었습니다!': '新しいバージョンがリリースされました！',
      '업데이트': '更新',
    },
    'GER': {
      '언어 선택': 'Sprache wählen',
      '새 버전이 출시되었습니다!': 'Eine neue Version wurde veröffentlicht!',
      '업데이트': 'Aktualisieren',
    },
    'RUS': {
      '언어 선택': 'Выбор языка',
      '새 버전이 출시되었습니다!': 'Выпущена новая версия!',
      '업데이트': 'Обновить',
    },
    'FRA': {
      '언어 선택': 'Choisir la langue',
      '새 버전이 출시되었습니다!': 'Une nouvelle version a été publiée!',
      '업데이트': 'Mettre à jour',
    },
    'ESP': {
      '언어 선택': 'Seleccionar idioma',
      '새 버전이 출시되었습니다!': '¡Se ha lanzado una nueva versión!',
      '업데이트': 'Actualizar',
    },
  };

  return localizedTexts[MyApp.currentLanguage]?[textKey] ?? textKey;
}
