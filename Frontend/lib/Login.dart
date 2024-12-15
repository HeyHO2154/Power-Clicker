import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'MainPage/MainPage.dart';
import 'main.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController idController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;

  Future<void> _loginOrRegister() async {
    final userId = idController.text;
    final password = passwordController.text;

    if (userId.isEmpty || password.isEmpty) {
      _showCustomDialog(lang('경고'), lang('아이디와 비밀번호를 모두 입력해주세요!'));
      return;
    }

    setState(() {
      isLoading = true; //회원가입 요청 보내고 대기
    });

    //로그인 요청
    final url = Uri.parse('${MyApp.url}/user/login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': userId, 'user_pw': password}),
    );
    //답변에 따른 후속 처리(http 요청을 await로 보내서, 답 오고 나서야 아래가 시행)
    if (response.body != '') {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', userId); //로컬저장소에 아이디 저장
      MyApp.user_id = userId; //아이디를 메인으로 설정
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MainPage()),
      );
    } else {
      _showCustomDialog(lang('로그인 실패'), lang('비밀번호가 틀립니다.'));
    }

    setState(() {
      isLoading = false;
    });
  }

  void _showCustomDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black87, // 어두운 배경
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text(
            title,
            style: TextStyle(
              color: Colors.red.shade700, // 금색 강조
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            content,
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // 다이얼로그 닫기
              },
              style: TextButton.styleFrom(
                foregroundColor: Color(0xFFD4AF37), // 금색 버튼 텍스트
              ),
              child: Text('확인'),
            ),
          ],
        );
      },
    );
  }

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
      body: Stack(
        children: [
          // 배경 이미지와 기본 UI
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/Theme/${MyApp.currentTheme}.png'),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(0.5), BlendMode.darken),
              ),
            ),
          ),
          // 상단 좌측에 국기 아이콘 배치
          Positioned(
            top: 45, // 상단 여백
            left: 25, // 좌측 여백
            child: GestureDetector(
              onTap: _showLanguageSelection, // 언어 선택 다이얼로그 호출
              child: Image.asset(
                'assets/UI/Langs/${MyApp.currentLanguage}.jpg',
                height: 60, // 아이콘 크기
                width: 60,
              ),
            ),
          ),
          // 중앙 UI
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  lang('사용할 아이디와 비밀번호를 입력하세요'),
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.grey[300],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 40),
                TextField(
                  controller: idController,
                  decoration: InputDecoration(
                    labelText: lang('아이디'),
                    labelStyle: TextStyle(color: Colors.white),
                    filled: true,
                    fillColor: Colors.black54,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.white70),
                    ),
                  ),
                  style: TextStyle(color: Colors.white),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: lang('비밀번호'),
                    labelStyle: TextStyle(color: Colors.white),
                    filled: true,
                    fillColor: Colors.black54,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.white70),
                    ),
                  ),
                  style: TextStyle(color: Colors.white),
                ),
                SizedBox(height: 20),
                isLoading
                    ? CircularProgressIndicator(color: Color(0xFFD4AF37))
                    : ElevatedButton(
                  onPressed: _loginOrRegister,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.black, backgroundColor: Color(0xFFD4AF37),
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    textStyle: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(lang('입장하기')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


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
                  height: 280, // 적절한 높이 설정
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
                        'KOR', 'ENG', 'CHN', 'JPN', 'GER', 'FRA', 'RUS', 'ESP', 'ARA'
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

  String lang(String textKey) {
    final localizedTexts = {
      'KOR': {
        '경고': '경고',
        '아이디와 비밀번호를 모두 입력해주세요!': '아이디와 비밀번호를 모두 입력해주세요!',
        '로그인 실패': '로그인 실패',
        '비밀번호가 틀립니다.': '비밀번호가 틀립니다.',
        '혼자하는 마피아': '혼자하는 마피아',
        '최초 접속시에 뜨는 창입니다. 이후 자동 로그인 됩니다.': '최초 접속시에 뜨는 창입니다. 이후 자동 로그인 됩니다.',
        '아이디를 입력해주세요': '아이디를 입력해주세요',
        '비밀번호를 입력해주세요': '비밀번호를 입력해주세요',
        '입장하기': '입장하기',
        '언어 선택': '언어 선택',
        '파워 클리커': '파워 클리커',
        "사용할 아이디와 비밀번호를 입력하세요": "사용할 아이디와 비밀번호를 입력하세요",
        "아이디": "아이디",
        "비밀번호": "비밀번호"
      },
      'ENG': {
        '경고': 'Warning',
        '아이디와 비밀번호를 모두 입력해주세요!': 'Please enter both ID and password!',
        '로그인 실패': 'Login failed',
        '비밀번호가 틀립니다.': 'Incorrect password.',
        '혼자하는 마피아': 'Solo Mafia',
        '최초 접속시에 뜨는 창입니다. 이후 자동 로그인 됩니다.': 'This appears on first login. Auto-login afterwards.',
        '아이디를 입력해주세요': 'Please enter your ID',
        '비밀번호를 입력해주세요': 'Please enter your password',
        '입장하기': 'Enter',
        '언어 선택': 'Language Selection',
        '파워 클리커': 'Power Clicker',
        "사용할 아이디와 비밀번호를 입력하세요": "Enter the username and password to use",
        "아이디": "Username",
        "비밀번호": "Password"

      },
      'CHN': {
        '경고': '警告',
        '아이디와 비밀번호를 모두 입력해주세요!': '请输入账号和密码！',
        '로그인 실패': '登录失败',
        '비밀번호가 틀립니다.': '密码错误。',
        '혼자하는 마피아': '单人游戏',
        '최초 접속시에 뜨는 창입니다. 이후 자동 로그인 됩니다.': '首次登录时出现。之后自动登录。',
        '아이디를 입력해주세요': '请输入账号',
        '비밀번호를 입력해주세요': '请输入密码',
        '입장하기': '进入',
        '언어 선택': '语言选择',
        '파워 클리커': '功率点击器',
        "사용할 아이디와 비밀번호를 입력하세요": "请输入用户名和密码",
        "아이디": "用户名",
        "비밀번호": "密码"
      },
      'JPN': {
        '경고': '警告',
        '아이디와 비밀번호를 모두 입력해주세요!': 'IDとパスワードを入力してください！',
        '로그인 실패': 'ログイン失敗',
        '비밀번호가 틀립니다.': 'パスワードが間違っています。',
        '혼자하는 마피아': '一人マフィア',
        '최초 접속시에 뜨는 창입니다. 이후 자동 로그인 됩니다.': '初回ログイン時に表示されます。その後は自動ログインされます。',
        '아이디를 입력해주세요': 'IDを入力してください',
        '비밀번호를 입력해주세요': 'パスワードを入力してください',
        '입장하기': '入場',
        '언어 선택': '言語選択',
        '파워 클리커': 'パワークリッカー',
        "사용할 아이디와 비밀번호를 입력하세요": "使用するユーザー名とパスワードを入力してください",
        "아이디": "ユーザー名",
        "비밀번호": "パスワード"
      },
      'GER': {
        '경고': 'Warnung',
        '아이디와 비밀번호를 모두 입력해주세요!': 'Bitte geben Sie sowohl ID als auch Passwort ein!',
        '로그인 실패': 'Anmeldung fehlgeschlagen',
        '비밀번호가 틀립니다.': 'Das Passwort ist falsch.',
        '혼자하는 마피아': 'Solo-Mafia',
        '최초 접속시에 뜨는 창입니다. 이후 자동 로그인 됩니다.': 'Dies erscheint beim ersten Login. Danach automatische Anmeldung.',
        '아이디를 입력해주세요': 'Bitte geben Sie Ihre ID ein',
        '비밀번호를 입력해주세요': 'Bitte geben Sie Ihr Passwort ein',
        '입장하기': 'Eingeben',
        '언어 선택': 'Sprachauswahl',
        '파워 클리커': 'Leistungsklicker',
        "사용할 아이디와 비밀번호를 입력하세요": "Geben Sie den zu verwendenden Benutzernamen und das Passwort ein",
        "아이디": "Benutzername",
        "비밀번호": "Passwort"
      },
      'FRA': {
        '경고': 'Avertissement',
        '아이디와 비밀번호를 모두 입력해주세요!': 'Veuillez entrer à la fois ID et mot de passe !',
        '로그인 실패': 'Échec de connexion',
        '비밀번호가 틀립니다.': 'Mot de passe incorrect.',
        '혼자하는 마피아': 'Mafia Solo',
        '최초 접속시에 뜨는 창입니다. 이후 자동 로그인 됩니다.': 'Ceci apparaît lors de la première connexion. Connexion automatique ensuite.',
        '아이디를 입력해주세요': 'Veuillez entrer votre identifiant',
        '비밀번호를 입력해주세요': 'Veuillez entrer votre mot de passe',
        '입장하기': 'Entrer',
        '언어 선택': 'Sélection de langue',
        '파워 클리커': 'Cliqueur Puissant',
        "사용할 아이디와 비밀번호를 입력하세요": "Entrez le nom d'utilisateur et le mot de passe à utiliser",
        "아이디": "Nom d'utilisateur",
        "비밀번호": "Mot de passe"
      },
      'RUS': {
        '경고': 'Предупреждение',
        '아이디와 비밀번호를 모두 입력해주세요!': 'Введите ID и пароль!',
        '로그인 실패': 'Ошибка входа',
        '비밀번호가 틀립니다.': 'Неверный пароль.',
        '혼자하는 마피아': 'Соло-мафия',
        '최초 접속시에 뜨는 창입니다. 이후 자동 로그인 됩니다.': 'Появляется при первом входе. Затем автоматический вход.',
        '아이디를 입력해주세요': 'Введите ID',
        '비밀번호를 입력해주세요': 'Введите пароль',
        '입장하기': 'Войти',
        '언어 선택': 'Выбор языка',
        '파워 클리커': 'Мощный Кликер',
        "사용할 아이디와 비밀번호를 입력하세요": "Введите имя пользователя и пароль для использования",
        "아이디": "Имя пользователя",
        "비밀번호": "Пароль"
      },
      'ESP': {
        '경고': 'Advertencia',
        '아이디와 비밀번호를 모두 입력해주세요!': '¡Por favor, ingrese tanto el ID como la contraseña!',
        '로그인 실패': 'Fallo de inicio de sesión',
        '비밀번호가 틀립니다.': 'Contraseña incorrecta.',
        '혼자하는 마피아': 'Mafia Solo',
        '최초 접속시에 뜨는 창입니다. 이후 자동 로그인 됩니다.': 'Esto aparece en el primer inicio de sesión. Luego inicio automático.',
        '아이디를 입력해주세요': 'Por favor, ingrese su ID',
        '비밀번호를 입력해주세요': 'Por favor, ingrese su contraseña',
        '입장하기': 'Entrar',
        '언어 선택': 'Selección de idioma',
        '파워 클리커': 'Clicador Potente',
        "사용할 아이디와 비밀번호를 입력하세요": "Ingrese el nombre de usuario y la contraseña a utilizar",
        "아이디": "Nombre de usuario",
        "비밀번호": "Contraseña"
      },
      'ARA': {
        '경고': 'تحذير',
        '아이디와 비밀번호를 모두 입력해주세요!': 'يرجى إدخال كل من اسم المستخدم وكلمة المرور!',
        '로그인 실패': 'فشل تسجيل الدخول',
        '비밀번호가 틀립니다.': 'كلمة المرور غير صحيحة.',
        '혼자하는 마피아': 'مافيا منفردة',
        '최초 접속시에 뜨는 창입니다. 이후 자동 로그인 됩니다.': 'يظهر هذا عند تسجيل الدخول لأول مرة. تسجيل الدخول التلقائي بعد ذلك.',
        '아이디를 입력해주세요': 'يرجى إدخال اسم المستخدم',
        '비밀번호를 입력해주세요': 'يرجى إدخال كلمة المرور',
        '입장하기': 'الدخول',
        '언어 선택': 'اختيار اللغة',
        '파워 클리커': 'النقر القوي',
        "사용할 아이디와 비밀번호를 입력하세요": "أدخل اسم المستخدم وكلمة المرور",
        "아이디": "اسم المستخدم",
        "비밀번호": "كلمة المرور"
      },
    };
    return localizedTexts[MyApp.currentLanguage]?[textKey] ?? textKey;
  }
}
