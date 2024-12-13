import 'dart:convert';
import 'package:frontend/MainPage/MainPage.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import '../main.dart';
import 'Shop.dart';
import 'package:intl/intl.dart';

class MyInfo extends StatefulWidget {
  @override
  _MyInfoPageState createState() => _MyInfoPageState();
}

class _MyInfoPageState extends State<MyInfo> {
  final TextEditingController nicknameController = TextEditingController();
  String user_name = '';
  int exp_level = 0;
  int exp_rank = 0;
  int points = 0; // 예시 포인트 값
  Map<String, dynamic> _themeMap = {}; // 테마 데이터를 저장할 Map
  Map<String, dynamic> _itemMap = {}; // 아이템 데이터를 저장할 Map

  //랭크 정보
  String rankTitle = '브론즈';
  String rankImage = 'assets/UI/Ranks/브론즈.png';

  //현헹 테마와 아이템
  List<String> Theme = ['Cat','Christmas','Forest','Mafia'];
  List<String> Theme_name = ['고양이','크리스마스','숲 친구','마피아'];
  List<bool> Theme_check = [true, false, false, false];
  List<String> Theme_info = [
    '귀여운 고양이들이 나오는 기본 테마입니다.',
    '크리스마스 분위기를 한껏 느껴보세요',
    '숲속 친구들과 함께 자연을 즐겨요',
    '마피아 특유의 클래식함과 긴장감을 느껴보세요'];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  // 비동기 작업을 순차적으로 실행하는 함수
  Future<void> _initializeData() async {
    await _getUserName();
    await _getPointValue(0);
    await _getLevelValue(0);
    await _getRankValue(0);
    await _getItems(0, 0, 0);
    await _buyTheme(Theme[0]);  //고양이는 기본적으로 구매
    setState(() {
      _getThemes(MyApp.user_id);
      Theme_name = [lang('고양이'),lang('크리스마스'),lang('숲속 친구들'),lang('마피아')];
      Theme_info = [
        lang('귀여운 고양이들이 나오는 기본 테마입니다'),
        lang('크리스마스 분위기를 한껏 느껴보세요'),
        lang('숲속 친구들과 함께 자연을 즐겨요'),
        lang('마피아 특유의 클래식함과 긴장감을 느껴보세요')];
    });
  }

  // 닉네임 업데이트 함수
  Future<void> _getUserName() async{
    final url = Uri.parse('${MyApp.url}/user/name');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(
          {'user_id': MyApp.user_id, 'user_name': nicknameController.text}),
    );

    if (response.statusCode == 200) {
      if(user_name == ""){
        user_name = response.body;
      }else if (response.body != user_name) {
        setState(() {
          _getPointValue(-1000);
          user_name = response.body;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(lang('중복된 닉네임 입니다')),
            backgroundColor: Colors.grey.shade700,
          ),
        );
      }
    }
    nicknameController.clear();
  }

  Future<void> _getPointValue(int num) async {
    final url = Uri.parse('${MyApp.url}/user/point');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': MyApp.user_id, 'points': num}), //여기서의 points는 더해줄 값을 의미(0은 단순 포인트 조회)
    );
    if (response.statusCode == 200) {
      setState(() {
        points = int.parse(response.body);
      });
    }
  }

  Future<void> _getLevelValue(int num) async {
    final url = Uri.parse('${MyApp.url}/user/level');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': MyApp.user_id, 'exp_level': num}),
    );
    if (response.statusCode == 200) {
      setState(() {
        exp_level = int.parse(response.body);
      });
    }
  }

  Future<void> _getRankValue(int num) async {
    final url = Uri.parse('${MyApp.url}/user/rank');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': MyApp.user_id, 'exp_rank': num}),
    );
    if (response.statusCode == 200) {
      setState(() {
        exp_rank = int.parse(response.body);
        _updateRankInfo();
      });
    }
  }

  Future<void> _getThemes(String userId) async {
    try {
      // API 호출
      final response = await http.get(Uri.parse('${MyApp.url}/asset/themes?user_id=$userId'));

      // 상태 코드 확인
      if (response.statusCode == 200) {
        // JSON 응답 파싱
        List<dynamic> data = jsonDecode(response.body);
        List<String> ownedThemes = List<String>.from(data);

        // Theme_name과 비교하여 Theme_check 업데이트
        for (int i = 0; i < Theme_name.length; i++) {
          Theme_check[i] = ownedThemes.contains(Theme[i]);
        }

        // 상태 갱신
        setState(() {});
      } else {
        // 에러 발생 시 로그 출력
        print('Failed to fetch themes. Status code: ${response.statusCode}');
      }
    } catch (e) {
      // 네트워크 또는 기타 오류 처리
      print('Error fetching themes: $e');
    }
  }
  Future<void> _setTheme(String currentTheme) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('currentTheme', currentTheme); // 로컬 저장소에 테마 저장
    setState(() {
      MyApp.currentTheme = currentTheme; // 앱의 현재 테마 업데이트
    });
    await MyApp.bgmPlayer.stop();
    await MyApp.bgmPlayer.play(AssetSource('Sound/BGM/${MyApp.currentTheme}.mp3')); //노래 바꾸기
  }
  Future<void> _buyTheme(String themeId) async {
    try {
      await http.post(
        Uri.parse('${MyApp.url}/asset/buyTheme'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'userId': MyApp.user_id, // 현재 사용자 ID
          'themeName': themeId,   // 구매할 테마 ID
        }),
      );
    } catch (e) {
      print('Error while purchasing theme: $e');
    }
  }


  Future<void> _getItems(int judge_baton, int political_speach, int bulletproof) async {
    final url = Uri.parse('${MyApp.url}/item/items');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': MyApp.user_id,
        'judge_baton': judge_baton,
        'political_speach': political_speach,
        'bulletproof': bulletproof
      }),
    );
    if (response.statusCode == 200) {
      // JSON 데이터를 Map으로 변환
      final Map<String, dynamic> itemData = jsonDecode(response.body);
      setState(() {
        _itemMap = itemData; // _itemMap은 Map<String, dynamic> 타입으로 선언되어야 함
      });
    }
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
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.5), BlendMode.darken),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 20.0, bottom: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // 뒤로 가기 버튼
                      IconButton(
                        icon: Icon(
                          Icons.arrow_back,
                          color: Color(0xFFB8860B), // 어두운 황금색
                          size: 40, // 아이콘 크기 (원하는 크기로 설정)
                        ),
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MainPage(),
                            ),
                          );
                        },
                      ),
                      // 내 정보 제목
                      Text(
                        lang('내 정보'),
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFD4AF37),
                          shadows: [
                            Shadow(
                              blurRadius: 10,
                              color: Colors.black54,
                              offset: Offset(4, 4),
                            ),
                          ],
                        ),
                      ),
                      // 코인 아이콘과 포인트 표시
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => Shop()),
                          );
                        },
                        child: Row(
                          children: [
                            Image.asset(
                              'assets/UI/coin.png',
                              height: 50, // 아이콘 크기 설정
                            ),
                            Text(
                              '${formatWithComma(points)}',
                              style: TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.w600,
                                color: Colors.amberAccent, // 금색 강조
                                shadows: [Shadow(blurRadius: 4, color: Colors.black38, offset: Offset(2, 2))],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    children: [
                      _buildNicknameSection(),
                      _buildLevelAndExperienceSection(),
                      _buildThemeSection(),
                      //_buildItemSection(), // 아이템 섹션 추가
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showRankDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black87,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          contentPadding: EdgeInsets.all(16),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                lang('랭크 정보'),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFD4AF37),
                ),
              ),
              SizedBox(height: 20),
              // 랭크 정보 리스트
              ...[
                {'title': lang('레전드'), 'image': 'assets/UI/Ranks/최상위.png', 'range': '(70~)'},
                {'title': lang('그랜드 마스터'), 'image': 'assets/UI/Ranks/그마.png', 'range': '(60~69)'},
                {'title': lang('마스터'), 'image': 'assets/UI/Ranks/마스터.png', 'range': '(50~59)'},
                {'title': lang('다이아몬드'), 'image': 'assets/UI/Ranks/다이아.png', 'range': '(40~49)'},
                {'title': lang('플레티넘'), 'image': 'assets/UI/Ranks/플레티넘.png', 'range': '(30~39)'},
                {'title': lang('골드'), 'image': 'assets/UI/Ranks/골드.png', 'range': '(20~29)'},
                {'title': lang('실버'), 'image': 'assets/UI/Ranks/실버.png', 'range': '(10~19)'},
                {'title': lang('브론즈'), 'image': 'assets/UI/Ranks/브론즈.png', 'range': '(0~9)'},
              ].map((rank) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Image.asset(
                        rank['image']!,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      ),
                      SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(
                                rank['title']!,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 8), // 이름과 구간 사이 간격
                              Text(
                                rank['range']!,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey, // 옅은 회색
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
              SizedBox(height: 20),
              // 설명 텍스트
              Text(
                lang('다른 유저와 승리시 +1, 패배시 -1이 적용됩니다'),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // 다이얼로그 닫기
              },
              child: Text(
                lang('확인'),
                style: TextStyle(
                  color: Color(0xFFD4AF37),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }


// 닉네임 섹션에서 랭크 이미지 클릭 이벤트 추가
  Widget _buildNicknameSection() {
    return Container(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Color(0xFFD4AF37), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 8,
            offset: Offset(4, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // 왼쪽에 이미지 섹션
          Column(
            children: [
              Text(
                rankTitle,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              GestureDetector(
                onTap: () => _showRankDialog(context), // 랭크 정보 다이얼로그 호출
                child: Container(
                  width: 80, // 이미지 크기 조절
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      rankImage,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 4),
              Text(
                '${lang('연승')}: ${exp_rank} / ${((exp_rank / 10).floor() + 1) * 10}',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          SizedBox(width: 16), // 이미지와 텍스트 사이 간격
          // 오른쪽에 닉네임 변경 섹션
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lang('닉네임'),
                  style: TextStyle(
                    fontSize: 18,
                    color: Color(0xFFD4AF37),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                TextField(
                  controller: nicknameController,
                  decoration: InputDecoration(
                    hintText: user_name,
                    hintStyle: TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: Colors.black54,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.white70),
                    ),
                  ),
                  style: TextStyle(color: Colors.white),
                ),
                SizedBox(height: 5),
                ElevatedButton(
                  onPressed:
                  points >= 1000 ? _getUserName : null, // 포인트가 1000 이상일 때만 활성화
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFD4AF37), // 비활성화일 때도 금색 유지
                    disabledForegroundColor: Colors.grey.withOpacity(0.38),
                    disabledBackgroundColor: Colors.grey.withOpacity(0.35),
                    foregroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(lang('닉네임 변경')),
                ),
                Text(
                  lang('(변경에 1,000 코인)'),
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 랭크 정보 업데이트 함수
  void _updateRankInfo() {
    if (exp_rank < 10) {
      rankTitle = lang('브론즈');
      rankImage = 'assets/UI/Ranks/브론즈.png';
    } else if (exp_rank < 20) {
      rankTitle = lang('실버');
      rankImage = 'assets/UI/Ranks/실버.png';
    } else if (exp_rank < 30) {
      rankTitle = lang('골드');
      rankImage = 'assets/UI/Ranks/골드.png';
    } else if (exp_rank < 40) {
      rankTitle = lang('플레티넘');
      rankImage = 'assets/UI/Ranks/플레티넘.png';
    } else if (exp_rank < 50) {
      rankTitle = lang('다이아몬드');
      rankImage = 'assets/UI/Ranks/다이아.png';
    } else if (exp_rank < 60) {
      rankTitle = lang('마스터');
      rankImage = 'assets/UI/Ranks/마스터.png';
    } else if (exp_rank < 70) {
      rankTitle = lang('그랜드 마스터');
      rankImage = 'assets/UI/Ranks/그마.png';
    } else {
      rankTitle = lang('레전드');
      rankImage = 'assets/UI/Ranks/최상위.png';
    }
  }

  // 레벨 및 경험치 섹션
  Widget _buildLevelAndExperienceSection() {
    return Container(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Color(0xFFD4AF37), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 8,
            offset: Offset(4, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lv. ${(exp_level / 100).floor()+1}',
            style: TextStyle(
              fontSize: 20,
              color: Color(0xFFD4AF37),
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10),
          Text(
          '${lang('경험치')}: ${exp_level-((exp_level / 100).floor())*100} / 100',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
          SizedBox(height: 10),
          LinearProgressIndicator(
            value: (exp_level-((exp_level / 100).floor())*100) / 100, // 진행률 계산
            minHeight: 8,
            backgroundColor: Colors.white24,
            color: Color(0xFFD4AF37), // 금색 막대
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSection() {
    return Container(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Color(0xFFD4AF37), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 8,
            offset: Offset(4, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lang('보유 테마'),
            style: TextStyle(
              fontSize: 20,
              color: Color(0xFFD4AF37),
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10),
          SizedBox(
            height: 140, // 테마 아이콘 높이 (이름 포함)
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: Theme.length,
              itemBuilder: (context, index) {
                final themeKey = Theme[index];
                final isUnlocked = Theme_check[index] == true;
                final isActive = MyApp.currentTheme == themeKey; // 현재 활성화된 테마인지 확인
                final themeImage = 'assets/Theme/$themeKey.png';

                return GestureDetector(
                  onTap: () {
                    _showDetailDialog(
                      context,
                      index,
                      themeImage,
                    );
                  },
                  child: Container(
                    margin: EdgeInsets.only(right: 10),
                    child: Column(
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: isActive
                                      ? Colors.green
                                      : Colors.transparent,
                                  width: isActive ? 3 : 0,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: ColorFiltered(
                                colorFilter: isUnlocked
                                    ? ColorFilter.mode(
                                  Colors.transparent,
                                  BlendMode.multiply,
                                )
                                    : ColorFilter.mode(
                                  Colors.grey,
                                  BlendMode.saturation,
                                ),
                                child: Image.asset(
                                  themeImage,
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            if (!isUnlocked)
                              Icon(
                                Icons.lock,
                                color: Colors.pinkAccent.shade700,
                                size: 50,
                              ),
                            if (isActive)
                              Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 40,
                              ),
                          ],
                        ),
                        SizedBox(height: 5),
                        Text(
                          Theme_name[index],
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemSection() {
    return Container(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Color(0xFFD4AF37), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 8,
            offset: Offset(4, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
          lang('보유 아이템'),
            style: TextStyle(
              fontSize: 20,
              color: Color(0xFFD4AF37),
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10),
          _itemMap.isEmpty || _itemMap.keys.length <= 1
              ? Center(
            child: Text(
              lang('아이템 데이터가 없습니다'),
              style: TextStyle(color: Colors.white),
            ),
          )
              : GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.8,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: _itemMap.keys.length - 1, // user_id 제외
            itemBuilder: (context, index) {
              final itemKey = _itemMap.keys.elementAt(index + 1);
              final itemCount = _itemMap[itemKey] ?? 0;
              final itemImage = 'assets/Item/$itemKey.png';

              return GestureDetector(
                onTap: () {
                  _showDetailDialog(
                    context,
                    1,
                    itemImage,
                  );
                },
                child: Column(
                  children: [
                    Image.asset(
                      itemImage,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                    SizedBox(height: 5),
                    Text(
                      "test",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'x$itemCount',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // 다이얼로그 표시 함수
  void _showDetailDialog(
      BuildContext context,
      int idx,
      String image,
      ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black87,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          contentPadding: EdgeInsets.all(16),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 30),
              Image.asset(
                image,
                width: 100,
                height: 100,
                fit: BoxFit.cover,
              ),
              SizedBox(height: 10),
              // 이름
              Text(
                Theme_name[idx],
                style: TextStyle(
                  fontSize: 20,
                  color: Color(0xFFD4AF37),
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              // 설명
              Text(
                Theme_info[idx],
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            if (Theme_check[idx]) // 활성화 가능한 테마
              TextButton(
                onPressed: () {
                  _setTheme(Theme[idx]);
                  Navigator.of(context).pop(); // 다이얼로그 닫기
                },
                child: Text(
                  lang('테마 변경'),
                  style: TextStyle(
                    color: Color(0xFFD4AF37),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (!Theme_check[idx]) // 잠긴 테마의 경우
              TextButton(
                onPressed: () {
                  if (points >= 10000) {
                    // 포인트가 충분한 경우
                    _getPointValue(-10000);
                    _buyTheme(Theme[idx]);
                    setState(() {
                      Theme_check[idx] = true;
                    });
                    _setTheme(Theme[idx]);
                    // 구매 완료 메시지 창 띄우기
                    Navigator.of(context).pop(); // 현재 상품 설명창 닫기
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          backgroundColor: Colors.black.withOpacity(0.9), // 어두운 배경
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10), // 모서리 둥글게
                          ),
                          title: Text(
                            lang('구매 완료!'),
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          content: Text(
                            '${Theme_name[idx]} ${lang('구매 완료!')}',
                            style: TextStyle(color: Colors.white),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop(); // 대화창 닫기
                              },
                              child: Text(
                                lang('확인'),
                                style: TextStyle(color: Colors.yellow),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  } else {
                    // 포인트가 부족한 경우 안내창 띄우기
                    Navigator.of(context).pop(); // 현재 상품 설명창 닫기
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          backgroundColor: Colors.black?.withOpacity(1), // 어두운 붉은 색으로 설정
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10), // 모서리 둥글게
                          ),
                          title: Text(
                            lang('잔액 부족'),
                            style: TextStyle(
                              color: Colors.yellow,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                          content: Text(
                            lang('10,000 코인이 필요합니다'),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop(); // 다이얼로그 닫기
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => Shop()), // Shop.dart로 이동
                                );
                              },
                              child: Text(
                                lang('코인 받기'),
                                style: TextStyle(
                                  color: Colors.yellowAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  }
                },
                child: Text(
                  lang('구매하기'),
                  style: TextStyle(
                    color: Color(0xFFD4AF37),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

          ],
        );
      },
    );
  }

  String lang(String textKey) {
    final localizedTexts = {
      'KOR': {
        '구매하기': '구매하기',
        '코인 받기': '코인 받기',
        '10,000 코인이 필요합니다': '10,000 코인이 필요합니다',
        '잔액 부족': '잔액 부족',
        '확인': '확인',
        '구매 완료!': '구매 완료!',
        '테마 변경': '테마 변경',
        '보유 아이템': '보유 아이템',
        '아이템 데이터가 없습니다': '아이템 데이터가 없습니다',
        '보유 테마': '보유 테마',
        '경험치': '경험치',
        '브론즈': '브론즈',
        '실버': '실버',
        '골드': '골드',
        '플레티넘': '플레티넘',
        '다이아몬드': '다이아몬드',
        '마스터': '마스터',
        '그랜드 마스터': '그랜드 마스터',
        '레전드': '레전드',
        '(변경에 1,000 코인)': '(변경에 1,000 코인)',
        '닉네임 변경': '닉네임 변경',
        '중복된 닉네임 입니다': '중복된 닉네임 입니다',
        '닉네임': '닉네임',
        '연승': '연승',
        '다른 유저와 승리시 +1, 패배시 -1이 적용됩니다': '다른 유저와 승리시 +1, 패배시 -1이 적용됩니다',
        '랭크 정보': '랭크 정보',
        '내 정보': '내 정보',
        '고양이': '고양이',
        '크리스마스': '크리스마스',
        '숲속 친구들': '숲속 친구들',
        '마피아': '마피아',
        '귀여운 고양이들이 나오는 기본 테마입니다': '귀여운 고양이들이 나오는 기본 테마입니다',
        '크리스마스 분위기를 한껏 느껴보세요': '크리스마스 분위기를 한껏 느껴보세요',
        '숲속 친구들과 함께 자연을 즐겨요': '숲속 친구들과 함께 자연을 즐겨요',
        '마피아 특유의 클래식함과 긴장감을 느껴보세요': '마피아 특유의 클래식함과 긴장감을 느껴보세요'
      },
      'ENG': {
        '구매하기': 'Buy',
        '코인 받기': 'Get Coins',
        '10,000 코인이 필요합니다': 'Need 10,000 Coins',
        '잔액 부족': 'Insufficient Balance',
        '확인': 'OK',
        '구매 완료!': 'Purchase Complete!',
        '테마 변경': 'Change Theme',
        '보유 아이템': 'Owned Items',
        '아이템 데이터가 없습니다': 'No Item Data',
        '보유 테마': 'Owned Themes',
        '경험치': 'XP',
        '브론즈': 'Bronze',
        '실버': 'Silver',
        '골드': 'Gold',
        '플레티넘': 'Platinum',
        '다이아몬드': 'Diamond',
        '마스터': 'Master',
        '그랜드 마스터': 'Grand Master',
        '레전드': 'Legend',
        '(변경에 1,000 코인)': '(Change: 1,000 Coins)',
        '닉네임 변경': 'Change Nickname',
        '중복된 닉네임 입니다': 'Nickname Exists',
        '닉네임': 'Nickname',
        '연승': 'Winning Streak',
        '다른 유저와 승리시 +1, 패배시 -1이 적용됩니다': '+1 for Win, -1 for Loss',
        '랭크 정보': 'Rank Info',
        '내 정보': 'My Info',
        '고양이': 'Cat',
        '크리스마스': 'Christmas',
        '숲속 친구들': 'Forest Friends',
        '마피아': 'Mafia',
        '귀여운 고양이들이 나오는 기본 테마입니다': 'Default Theme with Cute Cats',
        '크리스마스 분위기를 한껏 느껴보세요': 'Feel the Christmas Spirit',
        '숲속 친구들과 함께 자연을 즐겨요': 'Enjoy Nature with Forest Friends',
        '마피아 특유의 클래식함과 긴장감을 느껴보세요': 'Experience Mafia’s Classic Tension'
      },
      'ARA': {
        '구매하기': 'شراء',
        '코인 받기': 'احصل على العملات',
        '10,000 코인이 필요합니다': 'تحتاج 10,000 عملة',
        '잔액 부족': 'الرصيد غير كافٍ',
        '확인': 'موافق',
        '구매 완료!': 'تم الشراء!',
        '테마 변경': 'تغيير الثيم',
        '보유 아이템': 'العناصر المملوكة',
        '아이템 데이터가 없습니다': 'لا توجد بيانات للعناصر',
        '보유 테마': 'الثيمات المملوكة',
        '경험치': 'التجربة',
        '브론즈': 'برونزي',
        '실버': 'فضي',
        '골드': 'ذهبي',
        '플레티넘': 'بلاتيني',
        '다이아몬드': 'ماسي',
        '마스터': 'ماستر',
        '그랜드 마스터': 'جراند ماستر',
        '레전드': 'أسطورة',
        '(변경에 1,000 코인)': '(تغيير: 1,000 عملة)',
        '닉네임 변경': 'تغيير الاسم المستعار',
        '중복된 닉네임 입니다': 'الاسم المستعار مستخدم',
        '닉네임': 'الاسم المستعار',
        '연승': 'سلسلة الانتصارات',
        '다른 유저와 승리시 +1, 패배시 -1이 적용됩니다': '+1 للفوز، -1 للخسارة',
        '랭크 정보': 'معلومات التصنيف',
        '내 정보': 'معلوماتي',
        '고양이': 'قطة',
        '크리스마스': 'عيد الميلاد',
        '숲속 친구들': 'أصدقاء الغابة',
        '마피아': 'المافيا',
        '귀여운 고양이들이 나오는 기본 테마입니다': 'ثيم القطط اللطيفة الافتراضي',
        '크리스마스 분위기를 한껏 느껴보세요': 'استمتع بجو عيد الميلاد',
        '숲속 친구들과 함께 자연을 즐겨요': 'استمتع بالطبيعة مع أصدقاء الغابة',
        '마피아 특유의 클래식함과 긴장감을 느껴보세요': 'استمتع بتوتر وأناقة المافيا الكلاسيكية'
      },
      'CHN': {
        '구매하기': '购买',
        '코인 받기': '领取金币',
        '10,000 코인이 필요합니다': '需要10,000金币',
        '잔액 부족': '余额不足',
        '확인': '确认',
        '구매 완료!': '购买完成！',
        '테마 변경': '更换主题',
        '보유 아이템': '拥有的物品',
        '아이템 데이터가 없습니다': '没有物品数据',
        '보유 테마': '拥有的主题',
        '경험치': '经验值',
        '브론즈': '青铜',
        '실버': '白银',
        '골드': '黄金',
        '플레티넘': '铂金',
        '다이아몬드': '钻石',
        '마스터': '大师',
        '그랜드 마스터': '宗师',
        '레전드': '传奇',
        '(변경에 1,000 코인)': '(更换需1,000金币)',
        '닉네임 변경': '更改昵称',
        '중복된 닉네임 입니다': '昵称已被占用',
        '닉네임': '昵称',
        '연승': '连胜',
        '다른 유저와 승리시 +1, 패배시 -1이 적용됩니다': '胜+1, 败-1',
        '랭크 정보': '排名信息',
        '내 정보': '我的信息',
        '고양이': '猫咪',
        '크리스마스': '圣诞节',
        '숲속 친구들': '森林朋友',
        '마피아': '黑手党',
        '귀여운 고양이들이 나오는 기본 테마입니다': '默认可爱猫咪主题',
        '크리스마스 분위기를 한껏 느껴보세요': '尽情感受圣诞气氛',
        '숲속 친구들과 함께 자연을 즐겨요': '与森林朋友一起享受自然',
        '마피아 특유의 클래식함과 긴장감을 느껴보세요': '感受黑手党的经典与紧张'
      },
      'JPN': {
        '구매하기': '購入',
        '코인 받기': 'コインを受け取る',
        '10,000 코인이 필요합니다': '10,000コインが必要です',
        '잔액 부족': '残高不足',
        '확인': '確認',
        '구매 완료!': '購入完了！',
        '테마 변경': 'テーマ変更',
        '보유 아이템': '所有アイテム',
        '아이템 데이터가 없습니다': 'アイテムデータがありません',
        '보유 테마': '所有テーマ',
        '경험치': '経験値',
        '브론즈': 'ブロンズ',
        '실버': 'シルバー',
        '골드': 'ゴールド',
        '플레티넘': 'プラチナ',
        '다이아몬드': 'ダイヤモンド',
        '마스터': 'マスター',
        '그랜드 마스터': 'グランドマスター',
        '레전드': 'レジェンド',
        '(변경에 1,000 코인)': '(変更: 1,000コイン)',
        '닉네임 변경': 'ニックネーム変更',
        '중복된 닉네임 입니다': 'ニックネームが重複しています',
        '닉네임': 'ニックネーム',
        '연승': '連勝',
        '다른 유저와 승리시 +1, 패배시 -1이 적용됩니다': '勝利で+1、敗北で-1',
        '랭크 정보': 'ランク情報',
        '내 정보': '私の情報',
        '고양이': '猫',
        '크리스마스': 'クリスマス',
        '숲속 친구들': '森の仲間',
        '마피아': 'マフィア',
        '귀여운 고양이들이 나오는 기본 테마입니다': 'かわいい猫たちが登場する基本テーマ',
        '크리스마스 분위기를 한껏 느껴보세요': 'クリスマスの雰囲気を楽しんでください',
        '숲속 친구들과 함께 자연을 즐겨요': '森の仲間と一緒に自然を楽しもう',
        '마피아 특유의 클래식함과 긴장감을 느껴보세요': 'マフィアのクラシックな緊張感を感じてください'
      },
      'FRA': {
        '구매하기': 'Acheter',
        '코인 받기': 'Recevoir des pièces',
        '10,000 코인이 필요합니다': '10,000 pièces requises',
        '잔액 부족': 'Solde insuffisant',
        '확인': 'Confirmer',
        '구매 완료!': 'Achat réussi!',
        '테마 변경': 'Changer de thème',
        '보유 아이템': 'Objets possédés',
        '아이템 데이터가 없습니다': 'Aucune donnée d’objet',
        '보유 테마': 'Thèmes possédés',
        '경험치': 'Expérience',
        '브론즈': 'Bronze',
        '실버': 'Argent',
        '골드': 'Or',
        '플레티넘': 'Platine',
        '다이아몬드': 'Diamant',
        '마스터': 'Maître',
        '그랜드 마스터': 'Grand Maître',
        '레전드': 'Légende',
        '(변경에 1,000 코인)': '(1,000 pièces pour changer)',
        '닉네임 변경': 'Changer le pseudo',
        '중복된 닉네임 입니다': 'Pseudo déjà pris',
        '닉네임': 'Pseudo',
        '연승': 'Série de victoires',
        '다른 유저와 승리시 +1, 패배시 -1이 적용됩니다': 'Victoire: +1, Défaite: -1',
        '랭크 정보': 'Infos de rang',
        '내 정보': 'Mes infos',
        '고양이': 'Chat',
        '크리스마스': 'Noël',
        '숲속 친구들': 'Amis de la forêt',
        '마피아': 'Mafia',
        '귀여운 고양이들이 나오는 기본 테마입니다': 'Un thème de base avec des chats mignons',
        '크리스마스 분위기를 한껏 느껴보세요': 'Profitez de l’ambiance de Noël',
        '숲속 친구들과 함께 자연을 즐겨요': 'Profitez de la nature avec les amis de la forêt',
        '마피아 특유의 클래식함과 긴장감을 느껴보세요': 'Ressentez la tension classique de la mafia'
      },
      'GER': {
        '구매하기': 'Kaufen',
        '코인 받기': 'Münzen erhalten',
        '10,000 코인이 필요합니다': '10.000 Münzen benötigt',
        '잔액 부족': 'Unzureichendes Guthaben',
        '확인': 'Bestätigen',
        '구매 완료!': 'Kauf abgeschlossen!',
        '테마 변경': 'Thema ändern',
        '보유 아이템': 'Besitzgegenstände',
        '아이템 데이터가 없습니다': 'Keine Gegenstandsdaten',
        '보유 테마': 'Besitzthemen',
        '경험치': 'Erfahrung',
        '브론즈': 'Bronze',
        '실버': 'Silber',
        '골드': 'Gold',
        '플레티넘': 'Platin',
        '다이아몬드': 'Diamant',
        '마스터': 'Meister',
        '그랜드 마스터': 'Großmeister',
        '레전드': 'Legende',
        '(변경에 1,000 코인)': '(1.000 Münzen für Änderung)',
        '닉네임 변경': 'Spitznamen ändern',
        '중복된 닉네임 입니다': 'Spitzname bereits vergeben',
        '닉네임': 'Spitzname',
        '연승': 'Siegessträhne',
        '다른 유저와 승리시 +1, 패배시 -1이 적용됩니다': 'Sieg: +1, Niederlage: -1',
        '랭크 정보': 'Ranginfo',
        '내 정보': 'Meine Infos',
        '고양이': 'Katze',
        '크리스마스': 'Weihnachten',
        '숲속 친구들': 'Waldfreunde',
        '마피아': 'Mafia',
        '귀여운 고양이들이 나오는 기본 테마입니다': 'Ein Grundthema mit niedlichen Katzen',
        '크리스마스 분위기를 한껏 느껴보세요': 'Genießen Sie die Weihnachtsatmosphäre',
        '숲속 친구들과 함께 자연을 즐겨요': 'Genießen Sie die Natur mit den Waldfreunden',
        '마피아 특유의 클래식함과 긴장감을 느껴보세요': 'Erleben Sie die klassische Spannung der Mafia'
      },
      'ESP': {
        '구매하기': 'Comprar',
        '코인 받기': 'Recibir monedas',
        '10,000 코인이 필요합니다': 'Se necesitan 10.000 monedas',
        '잔액 부족': 'Saldo insuficiente',
        '확인': 'Confirmar',
        '구매 완료!': '¡Compra completada!',
        '테마 변경': 'Cambiar tema',
        '보유 아이템': 'Objetos poseídos',
        '아이템 데이터가 없습니다': 'Sin datos de objetos',
        '보유 테마': 'Temas poseídos',
        '경험치': 'Experiencia',
        '브론즈': 'Bronce',
        '실버': 'Plata',
        '골드': 'Oro',
        '플레티넘': 'Platino',
        '다이아몬드': 'Diamante',
        '마스터': 'Maestro',
        '그랜드 마스터': 'Gran Maestro',
        '레전드': 'Leyenda',
        '(변경에 1,000 코인)': '(1.000 monedas para cambiar)',
        '닉네임 변경': 'Cambiar apodo',
        '중복된 닉네임 입니다': 'Apodo ya en uso',
        '닉네임': 'Apodo',
        '연승': 'Racha ganadora',
        '다른 유저와 승리시 +1, 패배시 -1이 적용됩니다': 'Victoria: +1, Derrota: -1',
        '랭크 정보': 'Información de rango',
        '내 정보': 'Mi información',
        '고양이': 'Gato',
        '크리스마스': 'Navidad',
        '숲속 친구들': 'Amigos del bosque',
        '마피아': 'Mafia',
        '귀여운 고양이들이 나오는 기본 테마입니다': 'Un tema básico con gatos adorables',
        '크리스마스 분위기를 한껏 느껴보세요': 'Disfruta del ambiente navideño',
        '숲속 친구들과 함께 자연을 즐겨요': 'Disfruta la naturaleza con los amigos del bosque',
        '마피아 특유의 클래식함과 긴장감을 느껴보세요': 'Siente la tensión clásica de la mafia'
      },
      'RUS': {
        '구매하기': 'Купить',
        '코인 받기': 'Получить монеты',
        '10,000 코인이 필요합니다': 'Требуется 10,000 монет',
        '잔액 부족': 'Недостаточно средств',
        '확인': 'Подтвердить',
        '구매 완료!': 'Покупка завершена!',
        '테마 변경': 'Сменить тему',
        '보유 아이템': 'Доступные предметы',
        '아이템 데이터가 없습니다': 'Нет данных о предметах',
        '보유 테마': 'Доступные темы',
        '경험치': 'Опыт',
        '브론즈': 'Бронза',
        '실버': 'Серебро',
        '골드': 'Золото',
        '플레티넘': 'Платина',
        '다이아몬드': 'Алмаз',
        '마스터': 'Мастер',
        '그랜드 마스터': 'Грандмастер',
        '레전드': 'Легенда',
        '(변경에 1,000 코인)': '(1,000 монет для изменения)',
        '닉네임 변경': 'Сменить никнейм',
        '중복된 닉네임 입니다': 'Никнейм уже занят',
        '닉네임': 'Никнейм',
        '연승': 'Серия побед',
        '다른 유저와 승리시 +1, 패배시 -1이 적용됩니다': 'Победа: +1, Поражение: -1',
        '랭크 정보': 'Информация о ранге',
        '내 정보': 'Моя информация',
        '고양이': 'Кот',
        '크리스마스': 'Рождество',
        '숲속 친구들': 'Лесные друзья',
        '마피아': 'Мафия',
        '귀여운 고양이들이 나오는 기본 테마입니다': 'Основная тема с милыми котами',
        '크리스마스 분위기를 한껏 느껴보세요': 'Наслаждайтесь рождественской атмосферой',
        '숲속 친구들과 함께 자연을 즐겨요': 'Наслаждайтесь природой с лесными друзьями',
        '마피아 특유의 클래식함과 긴장감을 느껴보세요': 'Почувствуйте классическое напряжение мафии'
      }
    };
    return localizedTexts[MyApp.currentLanguage]?[textKey] ?? textKey;
  }
}
