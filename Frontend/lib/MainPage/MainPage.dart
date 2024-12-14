import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import '../main.dart';
import '../Game/Card.dart';
import 'Lobby.dart';
import 'Shop.dart';
import 'MyInfo.dart';

class MainPage extends StatefulWidget {
  static String? currentUserId;

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int points = 0;

  @override
  void initState() {
    super.initState();
    _getPointValue();
  }

  Future<void> _getPointValue() async {
    final url = Uri.parse('${MyApp.url}/user/point');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': MyApp.user_id, 'points': 0}), //여기서의 points는 더해줄 값을 의미(0은 단순 포인트 조회)
    );

    if (response.statusCode == 200) {
      setState(() {
        points = int.parse(response.body);
      });
    }
  }

  Future<void> _setLanguage(String languageCode) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', languageCode); // 로컬 저장소에 언어 저장
    setState(() {
      MyApp.currentLanguage = languageCode; // 앱의 현재 언어 업데이트
    });
  }


  String formatWithComma(int number) {
    return NumberFormat('#,###').format(number);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // 뒤로 가기 키 막기
        return false;
      },
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/Theme/${MyApp.currentTheme}.png'),
              fit: BoxFit.cover, // 배경 이미지를 화면에 맞게 조정
              colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.5), BlendMode.darken), // 어두운 필터 적용
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween, // 공간을 위아래로 맞춤
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical:20.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween, // 양쪽 끝에 배치
                            children: [
                              // 왼쪽: 국기
                              GestureDetector(
                                onTap: _showLanguageSelection, // 언어 선택 창 호출
                                child: Image.asset(
                                  'assets/UI/Langs/${MyApp.currentLanguage}.jpg', // 기본 국기 아이콘
                                  height: 40, // 아이콘 크기
                                ),
                              ),
                              // 오른쪽: 코인
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => Shop()),
                                  );
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.5), // 반투명 검은색
                                    borderRadius: BorderRadius.circular(20), // 모서리 둥글게
                                  ),
                                  padding: EdgeInsets.symmetric(horizontal: 15, vertical: 0), // 내부 여백
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min, // 내용에 맞게 크기 조정
                                    children: [
                                      Image.asset(
                                        'assets/UI/coin.png',
                                        height: 50, // 아이콘 크기 설정
                                      ),
                                      SizedBox(width: 5), // 아이콘과 텍스트 간격
                                      Text(
                                        '${formatWithComma(points)}',
                                        style: TextStyle(
                                          fontSize: 25,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.amberAccent, // 금색 강조
                                          shadows: [
                                            Shadow(blurRadius: 4, color: Colors.black38, offset: Offset(2, 2))
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          lang('파워 클리커'),
                          style: TextStyle(
                            fontSize: 45,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFD4AF37), // 제목을 금색으로
                            shadows: [
                              Shadow(
                                blurRadius: 15,
                                color: Colors.black54,
                                offset: Offset(4, 4),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: AspectRatio(
                                      aspectRatio: 1.0,
                                      child: _buildMenuButton(
                                        context,
                                        lang('같이하기'),
                                        'assets/Game/${MyApp.currentTheme}/2.png',
                                        50,
                                        LobbyPage(),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: AspectRatio(
                                      aspectRatio: 1.0,
                                      child: _buildMenuButton(
                                        context,
                                        lang('혼자하기'),
                                        'assets/Game/${MyApp.currentTheme}/1.png',
                                        50,
                                        CardPage(online: false),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: AspectRatio(
                                      aspectRatio: 1.0,
                                      child: _buildMenuButton(
                                        context,
                                        lang('내 정보'),
                                        'assets/UI/Ranks/최상위.png',
                                        50,
                                        MyInfo(),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: AspectRatio(
                                      aspectRatio: 1.0,
                                      child: _buildMenuButton(
                                        context,
                                        lang('상점'),
                                        'assets/UI/coin.png',
                                        60,
                                        Shop(),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox()
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
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
                  height: 310, // 적절한 높이 설정
                  child: GridView.builder(
                    shrinkWrap: true,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3, // 3개씩 한 행에 배치
                      crossAxisSpacing: 10, // 가로 간격
                      mainAxisSpacing: 0, // 세로 간격
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

  Widget _buildMenuButton(
      BuildContext context,
      String text,
      String icon,
      double icon_size,
      Widget nextPage,
      ) {
    return OutlinedButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => nextPage),
        );
      },
      style: OutlinedButton.styleFrom(
        padding: EdgeInsets.all(16),
        backgroundColor: Color(0xFF2C2C34).withOpacity(0.8), // 어두운 배경
        side: BorderSide(color: Color(0xFFD4AF37), width: 2), // 금색 테두리
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10), // 부드러운 곡선
        ),
        shadowColor: Colors.black,
        elevation: 10,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            icon,
            height: icon_size,
          ),
          SizedBox(height: 8),
          Text(
            text,
            textAlign: TextAlign.center, // 가운데 정렬
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [
                Shadow(blurRadius: 5, color: Colors.black54, offset: Offset(2, 2)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String lang(String textKey) {
    final localizedTexts = {
      'KOR': {
        '혼자하는 마피아': '혼자하는 마피아',
        '혼자 하기': '혼자 하기',
        '같이 하기': '같이 하기',
        '내 저장고': '내 저장고',
        '상점': '상점',
        '언어 선택': '언어 선택',
        '파워 클리커': '파워 클리커',
        '광질하기': '광질하기',
        '살아남기': '살아남기',
        '순위표': '순위표',
        '카드게임': '카드게임',
        '같이하기': '같이하기',
        '혼자하기': '혼자하기',
        '내 정보': '내 정보',
      },
      'ENG': {
        '혼자하는 마피아': 'Solo Mafia',
        '혼자 하기': 'Single Play',
        '같이 하기': 'Multi Play',
        '내 저장고': 'My Storage',
        '상점': 'Shop',
        '언어 선택': 'Language Selection',
        '파워 클리커': 'Power Clicker',
        '광질하기': 'Mining',
        '살아남기': 'Survive',
        '순위표': 'Leaderboard',
        '카드게임': 'Card Game',
        '같이하기': 'Play Together',
        '혼자하기': 'Play Alone',
        '내 정보': 'My Info',
      },
      'CHN': {
        '혼자하는 마피아': '单人游戏',
        '혼자 하기': '单人模式',
        '같이 하기': '多人模式',
        '내 저장고': '我的储物柜',
        '상점': '商店',
        '언어 선택': '语言选择',
        '파워 클리커': '功率点击器',
        '광질하기': '挖矿',
        '살아남기': '生存',
        '순위표': '排行榜',
        '카드게임': '卡牌游戏',
        '같이하기': '一起玩',
        '혼자하기': '单独玩',
        '내 정보': '我的信息'
      },
      'JPN': {
        '혼자하는 마피아': '一人マフィア',
        '혼자 하기': '一人でプレイ',
        '같이 하기': 'みんなでプレイ',
        '내 저장고': '私の保管庫',
        '상점': 'ショップ',
        '언어 선택': '言語選択',
        '파워 클리커': 'パワークリッカー',
        '광질하기': '採掘する',
        '살아남기': '生き残る',
        '순위표': 'ランキング表',
        '카드게임': 'カードゲーム',
        '같이하기': '一緒に遊ぶ',
        '혼자하기': '一人で遊ぶ',
        '내 정보': '私の情報',
      },
      'GER': {
        '혼자하는 마피아': 'Solo-Mafia',
        '혼자 하기': 'Alleine spielen',
        '같이 하기': 'Zusammen spielen',
        '내 저장고': 'Mein Lager',
        '상점': 'Shop',
        '언어 선택': 'Sprachauswahl',
        '파워 클리커': 'Leistungsklicker',
        '광질하기': 'Bergbau',
        '살아남기': 'Überleben',
        '순위표': 'Bestenliste',
        '카드게임': 'Kartenspiel',
        '같이하기': 'Zusammen spielen',
        '혼자하기': 'Alleine spielen',
        '내 정보': 'Meine Infos'
      },
      'FRA': {
        '혼자하는 마피아': 'Mafia Solo',
        '혼자 하기': 'Jouer seul',
        '같이 하기': 'Jouer ensemble',
        '내 저장고': 'Mon stockage',
        '상점': 'Boutique',
        '언어 선택': 'Sélection de langue',
        '파워 클리커': 'Cliqueur Puissant',
        '광질하기': 'Extraction',
        '살아남기': 'Survivre',
        '순위표': 'Classement',
        '카드게임': 'Jeu de cartes',
        '같이하기': 'Jouer ensemble',
        '혼자하기': 'Jouer seul',
        '내 정보': 'Mes informations'
      },
      'RUS': {
        '혼자하는 마피아': 'Соло-мафия',
        '혼자 하기': 'Играть одному',
        '같이 하기': 'Играть вместе',
        '내 저장고': 'Моё хранилище',
        '상점': 'Магазин',
        '언어 선택': 'Выбор языка',
        '파워 클리커': 'Мощный Кликер',
        '광질하기': 'Добыча',
        '살아남기': 'Выжить',
        '순위표': 'Таблица лидеров',
        '카드게임': 'Карточная игра',
        '같이하기': 'Играть вместе',
        '혼자하기': 'Играть в одиночку',
        '내 정보': 'Моя информация'
      },
      'ESP': {
        '혼자하는 마피아': 'Mafia Solo',
        '혼자 하기': 'Jugar solo',
        '같이 하기': 'Jugar juntos',
        '내 저장고': 'Mi almacenamiento',
        '상점': 'Tienda',
        '언어 선택': 'Selección de idioma',
        '파워 클리커': 'Clicador Potente',
        '광질하기': 'Minería',
        '살아남기': 'Sobrevivir',
        '순위표': 'clasificación',
        '카드게임': 'Juego de cartas',
        '같이하기': 'Jugar juntos',
        '혼자하기': 'Jugar solo',
        '내 정보': 'Mi información'
      },
      'ARA': {
        '혼자하는 마피아': 'مافيا منفردة',
        '혼자 하기': 'اللعب منفرداً',
        '같이 하기': 'اللعب معاً',
        '내 저장고': 'مخزني',
        '상점': 'المتجر',
        '언어 선택': 'اختيار اللغة',
        '파워 클리커': 'النقر القوي',
        '광질하기': 'التعدين',
        '살아남기': 'البقاء',
        '순위표': 'جدول التصنيف',
        '카드게임': 'لعبة البطاقات',
        '같이하기': 'اللعب معًا',
        '혼자하기': 'اللعب وحدك',
        '내 정보': 'معلوماتي'
      },
    };

    return localizedTexts[MyApp.currentLanguage]?[textKey] ?? textKey;
  }
}
