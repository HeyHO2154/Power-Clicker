import 'dart:convert';
import 'package:frontend/MainPage/MainPage.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';
import 'Shop.dart';

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

  @override
  void initState() {
    super.initState();
    _initializeData();
    _initializeDescriptions();
  }

  // 비동기 작업을 순차적으로 실행하는 함수
  Future<void> _initializeData() async {
    await _getUserName();
    await _getPointValue(900);
    await _getLevelValue(90);
    await _getRankValue(9);
    await _getItems(1, 2, 3);
    await _getThemes(true, false, false);
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
      if(user_name == ''){
        user_name = response.body;
      }else if (response.body != user_name) {
        setState(() {
          _getPointValue(-1000);
          user_name = response.body;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(lang('중복된 닉네임 입니다.')),
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

  Future<void> _getThemes(bool christmas, bool forest_friends, bool zombies) async {
    final url = Uri.parse('${MyApp.url}/theme/themes');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': MyApp.user_id,
        'christmas': christmas,
        'forest_friends': forest_friends,
        'zombies': zombies
      }),
    );
    if (response.statusCode == 200) {
      // JSON 데이터를 Map으로 변환
      final Map<String, dynamic> itemData = jsonDecode(response.body);
      setState(() {
        _themeMap = itemData; // _themeMap은 Map<String, dynamic> 타입으로 선언되어야 함
      });
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
              image: AssetImage('assets/Theme/${MyApp.currentTheme}/MyInfo.jpg'),
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
                              '$points',
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
                      _buildItemSection(), // 아이템 섹션 추가
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
                lang('랭크 설명'),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      lang('닉네임'),
                      style: TextStyle(
                        fontSize: 18,
                        color: Color(0xFFD4AF37),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
                  ],
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
                Text(
                  lang('(닉네임 변경 시 1,000 코인 소모)'),
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
            '${lang('레벨')}: ${(exp_level / 100).floor()+1}',
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
            child: _themeMap.isEmpty || _themeMap.keys.length <= 1
                ? Center(
              child: Text(
                lang('테마 데이터가 없습니다.'),
                style: TextStyle(color: Colors.white),
              ),
            )
                : ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _themeMap.keys.length - 1, // user_id 제외
              itemBuilder: (context, index) {
                final themeKey = _themeMap.keys.elementAt(index + 1);
                final isUnlocked = _themeMap[themeKey] == true;
                final isActive = MyApp.currentTheme == themeKey; // 현재 활성화된 테마인지 확인
                final themeImage = 'assets/Theme/$themeKey.png';

                return GestureDetector(
                  onTap: () {
                    _showDetailDialog(
                      context,
                      themeNames[index],
                      themeImage,
                      themeDescriptions[themeNames[index]] ?? lang('설명이 없습니다.'),
                      isTheme: true, // 테마임을 명시
                      themeKey: themeKey, // 현재 테마 키 전달
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
                          themeNames[index],
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
              lang('아이템 데이터가 없습니다.'),
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
                    itemNames[index],
                    itemImage,
                    itemDescriptions[itemNames[index]] ?? lang('설명이 없습니다.'),
                    isTheme: false, // 아이템임을 명시
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
                      itemNames[index],
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
      String title,
      String imagePath,
      String description, {
        bool isTheme = false,
        String themeKey = '',
      }) {
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
              // 이미지
              Image.asset(
                imagePath,
                width: 100,
                height: 100,
                fit: BoxFit.cover,
              ),
              SizedBox(height: 10),
              // 이름
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  color: Color(0xFFD4AF37),
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              // 설명
              Text(
                description,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            if (isTheme && _themeMap[themeKey] == true) // 활성화 가능한 테마
              TextButton(
                onPressed: () {
                  _setTheme(themeKey);
                  Navigator.of(context).pop(); // 다이얼로그 닫기
                },
                child: Text(
                  lang('해당 테마로 변경'),
                  style: TextStyle(
                    color: Color(0xFFD4AF37),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (isTheme && _themeMap[themeKey] == false) // 잠긴 테마의 경우
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // 다이얼로그 닫기
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => Shop()), // Shop.dart로 이동
                  );
                },
                child: Text(
                  lang('상점으로 이동'),
                  style: TextStyle(
                    color: Color(0xFFD4AF37),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (!isTheme) // 아이템의 경우
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // 다이얼로그 닫기
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => Shop()), // Shop.dart로 이동
                  );
                },
                child: Text(
                  lang('상점으로 이동'),
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

  Future<void> _setTheme(String currentTheme) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('currentTheme', currentTheme); // 로컬 저장소에 테마 저장
    setState(() {
      MyApp.currentTheme = currentTheme; // 앱의 현재 테마 업데이트
    });
  }

  // 클래스 필드로 선언
  List<String> themeNames = [];
  List<String> itemNames = [];
  Map<String, String> themeDescriptions = {};
  Map<String, String> itemDescriptions = {};
  void _initializeDescriptions() {
    themeNames = [lang('마피아'), lang('크리스마스'), lang('숲속 친구들'), lang('좀비 사태')];
    itemNames = [lang('판사 봉'), lang('정치적 연설'), lang('방탄복')];
    themeDescriptions = {
      lang('마피아'): lang('클래식한 마피아 테마입니다. 마피아, 경찰, 의사 등 여러 직업이 등장하며, 시민들은 마피아의 살인을 막아야 합니다.'),
      lang('크리스마스'): lang('크리스마스 테마는 따뜻한 연말 분위기를 표현합니다. 루돌프, 산타, 요정 등 여러 캐릭터가 등장하며, 그린치의 가짜 선물을 저지하세요!'),
      lang('숲속 친구들'): lang('숲속 친구들 테마는 귀여운 동물들이 함께하는 테마입니다. 사슴, 다람쥐, 고슴도치 등 여러 귀여운 동물들이 등장하며, 사냥꾼을 막아야 합니다.'),
      lang('좀비 사태'): lang('좀비 사태 테마는 스릴 넘치는 생존 테마입니다. 여러 생존자들이 등장하며, 생존자 캠프에 몰래 들어온 감염자를 색출해야 합니다!'),
    };
    itemDescriptions = {
      lang('판사 봉'): lang('표를 행사할 때 2표를 행사합니다.'),
      lang('정치적 연설'): lang('5% 확률로 투표로 인한 처형을 회피합니다.'),
      lang('방탄복'): lang('5% 확률로 마피아의 살인을 회피합니다.'),
    };
  }

  String lang(String textKey) {
    final localizedTexts = {
      'KOR': {
        '내 정보': '내 정보',
        '중복된 닉네임 입니다.': '중복된 닉네임 입니다.',
        '닉네임': '닉네임',
        '연승': '연승',
        '닉네임 변경': '닉네임 변경',
        '(닉네임 변경 시 1,000 코인 소모)': '(닉네임 변경 시 1,000 코인 소모)',
        '랭크 정보': '랭크 정보',
        '랭크 설명': '같이하기 플레이에서 승리하면 연승이 쌓이고, 패배하면 연승이 깎입니다. 각 랭크는 연승 점수에 따라 결정되며, 랭크 구간별로 티어가 나뉘어집니다.',
        '확인': '확인',
        '브론즈': '브론즈',
        '실버': '실버',
        '골드': '골드',
        '플레티넘': '플레티넘',
        '다이아몬드': '다이아몬드',
        '마스터': '마스터',
        '그랜드 마스터': '그랜드 마스터',
        '레전드': '레전드',
        '레벨': '레벨',
        '경험치': '경험치',
        '보유 테마': '보유 테마',
        '테마 데이터가 없습니다.': '테마 데이터가 없습니다.',
        '설명이 없습니다.': '설명이 없습니다.',
        '보유 아이템': '보유 아이템',
        '아이템 데이터가 없습니다.': '아이템 데이터가 없습니다.',
        '마피아': '마피아',
        '클래식한 마피아 테마입니다. 마피아, 경찰, 의사 등 여러 직업이 등장하며, 시민들은 마피아의 살인을 막아야 합니다.':
        '클래식한 마피아 테마입니다. 마피아, 경찰, 의사 등 여러 직업이 등장하며, 시민들은 마피아의 살인을 막아야 합니다.',
        '크리스마스': '크리스마스',
        '크리스마스 테마는 따뜻한 연말 분위기를 표현합니다. 루돌프, 산타, 요정 등 여러 캐릭터가 등장하며, 그린치의 가짜 선물을 저지하세요!':
        '크리스마스 테마는 따뜻한 연말 분위기를 표현합니다. 루돌프, 산타, 요정 등 여러 캐릭터가 등장하며, 그린치의 가짜 선물을 저지하세요!',
        '숲속 친구들': '숲속 친구들',
        '숲속 친구들 테마는 귀여운 동물들이 함께하는 테마입니다. 사슴, 다람쥐, 고슴도치 등 여러 귀여운 동물들이 등장하며, 사냥꾼을 막아야 합니다.':
        '숲속 친구들 테마는 귀여운 동물들이 함께하는 테마입니다. 사슴, 다람쥐, 고슴도치 등 여러 귀여운 동물들이 등장하며, 사냥꾼을 막아야 합니다.',
        '좀비 사태': '좀비 사태',
        '좀비 사태 테마는 스릴 넘치는 생존 테마입니다. 여러 생존자들이 등장하며, 생존자 캠프에 몰래 들어온 감염자를 색출해야 합니다!':
        '좀비 사태 테마는 스릴 넘치는 생존 테마입니다. 여러 생존자들이 등장하며, 생존자 캠프에 몰래 들어온 감염자를 색출해야 합니다!',
        '판사 봉': '판사 봉',
        '표를 행사할 때 2표를 행사합니다.': '표를 행사할 때 2표를 행사합니다.',
        '정치적 연설': '정치적 연설',
        '5% 확률로 투표로 인한 처형을 회피합니다.': '5% 확률로 투표로 인한 처형을 회피합니다.',
        '방탄복': '방탄복',
        '5% 확률로 마피아의 살인을 회피합니다.': '5% 확률로 마피아의 살인을 회피합니다.',
        '해당 테마로 변경': '해당 테마로 변경',
        '상점으로 이동': '상점으로 이동',
      },
      'ENG': {
        '내 정보': 'My Info',
        '중복된 닉네임 입니다.': 'This nickname is already taken.',
        '닉네임': 'Name',
        '연승': 'Win',
        '닉네임 변경': 'Change Name',
        '(닉네임 변경 시 1,000 코인 소모)': '(Changing nickname costs 1,000 coins)',
        '랭크 정보': 'Rank Information',
        '랭크 설명': 'Winning in multiplayer games will increase your winning streak, while losing will decrease it. Each rank is determined by the streak score, and tiers are divided accordingly.',
        '확인': 'OK',
        '브론즈': 'Bronze',
        '실버': 'Silver',
        '골드': 'Gold',
        '플레티넘': 'Platinum',
        '다이아몬드': 'Diamond',
        '마스터': 'Master',
        '그랜드 마스터': 'Grand Master',
        '레전드': 'Legend',
        '레벨': 'Level',
        '경험치': 'Experience',
        '보유 테마': 'Owned Themes',
        '테마 데이터가 없습니다.': 'No theme data available.',
        '설명이 없습니다.': 'No description available.',
        '보유 아이템': 'Owned Items',
        '아이템 데이터가 없습니다.': 'No item data available.',
        '마피아': 'Mafia',
        '클래식한 마피아 테마입니다. 마피아, 경찰, 의사 등 여러 직업이 등장하며, 시민들은 마피아의 살인을 막아야 합니다.':
        'A classic mafia theme with roles like Mafia, Police, and Doctor. Citizens must prevent Mafia murders.',
        '크리스마스': 'Christmas',
        '크리스마스 테마는 따뜻한 연말 분위기를 표현합니다. 루돌프, 산타, 요정 등 여러 캐릭터가 등장하며, 그린치의 가짜 선물을 저지하세요!':
        'The Christmas theme brings warm holiday vibes with characters like Rudolph, Santa, and elves. Stop the Grinch!',
        '숲속 친구들': 'Forest Friends',
        '숲속 친구들 테마는 귀여운 동물들이 함께하는 테마입니다. 사슴, 다람쥐, 고슴도치 등 여러 귀여운 동물들이 등장하며, 사냥꾼을 막아야 합니다.':
        'The Forest Friends theme features adorable animals like deer, squirrels, and hedgehogs. Prevent the hunters!',
        '좀비 사태': 'Zombie Apocalypse',
        '좀비 사태 테마는 스릴 넘치는 생존 테마입니다. 여러 생존자들이 등장하며, 생존자 캠프에 몰래 들어온 감염자를 색출해야 합니다!':
        'The Zombie Apocalypse theme offers thrilling survival gameplay. Find the infected infiltrators in survivor camps!',
        '판사 봉': 'Judge\'s Gavel',
        '표를 행사할 때 2표를 행사합니다.': 'Casts 2 votes instead of 1.',
        '정치적 연설': 'Political Speech',
        '5% 확률로 투표로 인한 처형을 회피합니다.': '5% chance to avoid execution during voting.',
        '방탄복': 'Bulletproof Vest',
        '5% 확률로 마피아의 살인을 회피합니다.': '5% chance to avoid Mafia assassination.',
        '해당 테마로 변경': 'Change to this theme',
        '상점으로 이동': 'Go to shop',
      },
      'CHN': {
        '내 정보': '我的信息',
        '중복된 닉네임 입니다.': '昵称已被占用。',
        '닉네임': '昵称',
        '연승': '连胜',
        '닉네임 변경': '更改昵称',
        '(닉네임 변경 시 1,000 코인 소모)': '（更改昵称需要花费 1,000 金币）',
        '랭크 정보': '等级信息',
        '랭크 설명': '在多人游戏中获胜会增加连胜记录，而失败会减少连胜记录。每个等级由连胜分数决定，并按等级划分。',
        '확인': '确认',
        '브론즈': '青铜',
        '실버': '白银',
        '골드': '黄金',
        '플레티넘': '铂金',
        '다이아몬드': '钻石',
        '마스터': '大师',
        '그랜드 마스터': '宗师',
        '레전드': '传奇',
        '레벨': '等级',
        '경험치': '经验值',
        '보유 테마': '已拥有的主题',
        '테마 데이터가 없습니다.': '没有主题数据。',
        '설명이 없습니다.': '没有说明。',
        '보유 아이템': '已拥有的物品',
        '아이템 데이터가 없습니다.': '没有物品数据。',
        '마피아': '黑手党',
        '클래식한 마피아 테마입니다. 마피아, 경찰, 의사 등 여러 직업이 등장하며, 시민들은 마피아의 살인을 막아야 합니다.':
        '经典的黑手党主题，包含黑手党、警察、医生等多个角色。市民需要阻止黑手党的谋杀。',
        '크리스마스': '圣诞节',
        '크리스마스 테마는 따뜻한 연말 분위기를 표현합니다. 루돌프, 산타, 요정 등 여러 캐릭터가 등장하며, 그린치의 가짜 선물을 저지하세요!':
        '圣诞主题展现温暖的年末氛围。包含鲁道夫、圣诞老人、小精灵等多个角色，阻止格林奇的假礼物！',
        '숲속 친구들': '森林朋友',
        '숲속 친구들 테마는 귀여운 동물들이 함께하는 테마입니다. 사슴, 다람쥐, 고슴도치 등 여러 귀여운 동물들이 등장하며, 사냥꾼을 막아야 합니다.':
        '森林朋友主题充满可爱的小动物，如鹿、松鼠和刺猬。阻止猎人！',
        '좀비 사태': '僵尸危机',
        '좀비 사태 테마는 스릴 넘치는 생존 테마입니다. 여러 생존자들이 등장하며, 생존자 캠프에 몰래 들어온 감염자를 색출해야 합니다!':
        '僵尸危机主题带来紧张刺激的生存体验。找出潜入幸存者营地的感染者！',
        '판사 봉': '法官槌',
        '표를 행사할 때 2표를 행사합니다.': '投票时可投两票。',
        '정치적 연설': '政治演讲',
        '5% 확률로 투표로 인한 처형을 회피합니다.': '有5%的几率避免投票处决。',
        '방탄복': '防弹背心',
        '5% 확률로 마피아의 살인을 회피합니다.': '有5%的几率躲避黑手党的刺杀。',
        '해당 테마로 변경': '更改为此主题',
        '상점으로 이동': '前往商店',
      },
      'JPN': {
        '내 정보': '私の情報',
        '중복된 닉네임 입니다.': '重複したニックネームです。',
        '닉네임': '名前',
        '연승': '連勝',
        '닉네임 변경': '名前変更',
        '(닉네임 변경 시 1,000 코인 소모)': '（ニックネーム変更には1,000コインが必要です）',
        '랭크 정보': 'ランク情報',
        '랭크 설명': 'マルチプレイで勝利すると連勝が増え、敗北すると連勝が減ります。各ランクは連勝スコアによって決まり、ティアごとに分かれています。',
        '확인': '確認',
        '브론즈': 'ブロンズ',
        '실버': 'シルバー',
        '골드': 'ゴールド',
        '플레티넘': 'プラチナ',
        '다이아몬드': 'ダイヤモンド',
        '마스터': 'マスター',
        '그랜드 마스터': 'グランドマスター',
        '레전드': 'レジェンド',
        '레벨': 'レベル',
        '경험치': '経験値',
        '보유 테마': '所持テーマ',
        '테마 데이터가 없습니다.': 'テーマデータがありません。',
        '설명이 없습니다.': '説明がありません。',
        '보유 아이템': '所持アイテム',
        '아이템 데이터가 없습니다.': 'アイテムデータがありません。',
        '마피아': 'マフィア',
        '클래식한 마피아 테마입니다. 마피아, 경찰, 의사 등 여러 직업이 등장하며, 시민들은 마피아의 살인을 막아야 합니다.':
        'クラシックなマフィアテーマです。マフィア、警察、医者などの役割が登場し、市民はマフィアの殺人を防がなければなりません。',
        '크리스마스': 'クリスマス',
        '크리스마스 테마는 따뜻한 연말 분위기를 표현합니다. 루돌프, 산타, 요정 등 여러 캐릭터가 등장하며, 그린치의 가짜 선물을 저지하세요!':
        'クリスマステーマは暖かい年末の雰囲気を表現しています。ルドルフ、サンタ、小人などが登場し、グリンチの偽プレゼントを阻止してください！',
        '숲속 친구들': '森の仲間たち',
        '숲속 친구들 테마는 귀여운 동물들이 함께하는 테마입니다. 사슴, 다람쥐, 고슴도치 등 여러 귀여운 동물들이 등장하며, 사냥꾼을 막아야 합니다.':
        '森の仲間たちテーマは可愛い動物たちが登場します。鹿、リス、ハリネズミなどが登場し、ハンターを阻止してください。',
        '좀비 사태': 'ゾンビ危機',
        '좀비 사태 테마는 스릴 넘치는 생존 테마입니다. 여러 생존자들이 등장하며, 생존자 캠프에 몰래 들어온 감염자를 색출해야 합니다!':
        'ゾンビ危機テーマはスリリングなサバイバルテーマです。多くの生存者が登場し、生存者キャンプに忍び込んだ感染者を見つけてください！',
        '판사 봉': '裁判官の槌',
        '표를 행사할 때 2표를 행사합니다.': '投票時に2票を行使できます。',
        '정치적 연설': '政治演説',
        '5% 확률로 투표로 인한 처형을 회피합니다.': '5%の確率で投票による処刑を回避します。',
        '방탄복': '防弾チョッキ',
        '5% 확률로 마피아의 살인을 회피합니다.': '5%の確率でマフィアの殺人を回避します。',
        '해당 테마로 변경': 'このテーマに変更',
        '상점으로 이동': 'ショップに移動',
      },
      'GER': {
        '내 정보': 'Meine Info',
        '중복된 닉네임 입니다.': 'Der Benutzername ist bereits vergeben.',
        '닉네임': 'Namen',
        '연승': 'Siegesserie',
        '닉네임 변경': 'ändern',
        '(닉네임 변경 시 1,000 코인 소모)': '(Das Ändern des Benutzernamens kostet 1.000 Münzen)',
        '랭크 정보': 'Ranginformationen',
        '랭크 설명': 'Gewinne im Multiplayer-Modus erhöhen deine Siegesserie, während Verluste sie verringern. Jeder Rang wird durch den Siegesserien-Score bestimmt, und Tiers werden entsprechend unterteilt.',
        '확인': 'Bestätigen',
        '브론즈': 'Bronze',
        '실버': 'Silber',
        '골드': 'Gold',
        '플레티넘': 'Platin',
        '다이아몬드': 'Diamant',
        '마스터': 'Meister',
        '그랜드 마스터': 'Großmeister',
        '레전드': 'Legende',
        '레벨': 'Level',
        '경험치': 'Erfahrungspunkte',
        '보유 테마': 'Besitzte Themen',
        '테마 데이터가 없습니다.': 'Keine Themen-Daten verfügbar.',
        '설명이 없습니다.': 'Keine Beschreibung verfügbar.',
        '보유 아이템': 'Besitzte Gegenstände',
        '아이템 데이터가 없습니다.': 'Keine Gegenstands-Daten verfügbar.',
        '마피아': 'Mafia',
        '클래식한 마피아 테마입니다. 마피아, 경찰, 의사 등 여러 직업이 등장하며, 시민들은 마피아의 살인을 막아야 합니다.':
        'Dies ist ein klassisches Mafia-Thema. Mafia, Polizei, Arzt und andere Rollen treten auf, und die Bürger müssen die Morde der Mafia verhindern.',
        '크리스마스': 'Weihnachten',
        '크리스마스 테마는 따뜻한 연말 분위기를 표현합니다. 루돌프, 산타, 요정 등 여러 캐릭터가 등장하며, 그린치의 가짜 선물을 저지하세요!':
        'Das Weihnachtsthema vermittelt eine warme Jahresendstimmung. Rudolph, Santa, Elfen und andere Charaktere treten auf. Stoppen Sie die gefälschten Geschenke des Grinch!',
        '숲속 친구들': 'Waldfreunde',
        '숲속 친구들 테마는 귀여운 동물들이 함께하는 테마입니다. 사슴, 다람쥐, 고슴도치 등 여러 귀여운 동물들이 등장하며, 사냥꾼을 막아야 합니다.':
        'Das Waldfreunde-Thema bringt niedliche Tiere zusammen. Hirsche, Eichhörnchen, Igel und andere süße Tiere erscheinen, und Sie müssen die Jäger aufhalten.',
        '좀비 사태': 'Zombie-Krise',
        '좀비 사태 테마는 스릴 넘치는 생존 테마입니다. 여러 생존자들이 등장하며, 생존자 캠프에 몰래 들어온 감염자를 색출해야 합니다!':
        'Das Zombie-Krisenthema ist ein spannendes Überlebensthema. Viele Überlebende erscheinen, und Sie müssen die Infizierten im Überlebenslager aufdecken!',
        '판사 봉': 'Richterhammer',
        '표를 행사할 때 2표를 행사합니다.': 'Sie können bei der Abstimmung zwei Stimmen abgeben.',
        '정치적 연설': 'Politische Rede',
        '5% 확률로 투표로 인한 처형을 회피합니다.': 'Mit einer Wahrscheinlichkeit von 5% wird die Hinrichtung durch Abstimmung vermieden.',
        '방탄복': 'Kugelsichere Weste',
        '5% 확률로 마피아의 살인을 회피합니다.': 'Mit einer Wahrscheinlichkeit von 5% wird ein Mord der Mafia vermieden.',
        '해당 테마로 변경': 'Thema ändern',
        '상점으로 이동': 'Zum Shop gehen',
      },
      'FRA': {
        '내 정보': 'Mes info',
        '중복된 닉네임 입니다.': 'Le pseudo est déjà utilisé.',
        '닉네임': 'Pseudo',
        '연승': 'Victoires',
        '닉네임 변경': 'changement',
        '(닉네임 변경 시 1,000 코인 소모)': '(Changer de pseudo coûte 1 000 pièces)',
        '랭크 정보': 'Informations sur les rangs',
        '랭크 설명': 'Gagner en mode multijoueur augmente votre série de victoires, tandis que perdre la diminue. Chaque rang est déterminé par le score de série de victoires, et les niveaux sont divisés en conséquence.',
        '확인': 'Confirmer',
        '브론즈': 'Bronze',
        '실버': 'Argent',
        '골드': 'Or',
        '플레티넘': 'Platine',
        '다이아몬드': 'Diamant',
        '마스터': 'Maître',
        '그랜드 마스터': 'Grand Maître',
        '레전드': 'Légende',
        '레벨': 'Niveau',
        '경험치': 'Expérience',
        '보유 테마': 'Thèmes possédés',
        '테마 데이터가 없습니다.': 'Pas de données de thème.',
        '설명이 없습니다.': 'Pas de description disponible.',
        '보유 아이템': 'Objets possédés',
        '아이템 데이터가 없습니다.': 'Pas de données d\'objet.',
        '마피아': 'Mafia',
        '클래식한 마피아 테마입니다. 마피아, 경찰, 의사 등 여러 직업이 등장하며, 시민들은 마피아의 살인을 막아야 합니다.':
        'Un thème classique Mafia. Avec des rôles comme mafia, policier, médecin, les citoyens doivent empêcher les meurtres de la mafia.',
        '크리스마스': 'Noël',
        '크리스마스 테마는 따뜻한 연말 분위기를 표현합니다. 루돌프, 산타, 요정 등 여러 캐릭터가 등장하며, 그린치의 가짜 선물을 저지하세요!':
        'Le thème de Noël capture l\'ambiance chaleureuse des fêtes de fin d\'année. Empêchez les faux cadeaux du Grinch avec des personnages comme Rudolph, le Père Noël, et les lutins.',
        '숲속 친구들': 'Amis de la forêt',
        '숲속 친구들 테마는 귀여운 동물들이 함께하는 테마입니다. 사슴, 다람쥐, 고슴도치 등 여러 귀여운 동물들이 등장하며, 사냥꾼을 막아야 합니다.':
        'Le thème Amis de la forêt présente des animaux adorables comme des cerfs, des écureuils, et des hérissons. Empêchez les chasseurs !',
        '좀비 사태': 'Apocalypse zombie',
        '좀비 사태 테마는 스릴 넘치는 생존 테마입니다. 여러 생존자들이 등장하며, 생존자 캠프에 몰래 들어온 감염자를 색출해야 합니다!':
        'Le thème Apocalypse zombie est centré sur la survie intense. Trouvez les infectés infiltrés dans le camp des survivants !',
        '판사 봉': 'Marteau du juge',
        '표를 행사할 때 2표를 행사합니다.': 'Donne 2 votes lors d\'une élection.',
        '정치적 연설': 'Discours politique',
        '5% 확률로 투표로 인한 처형을 회피합니다.': '5 % de chance d\'éviter une exécution par vote.',
        '방탄복': 'Gilet pare-balles',
        '5% 확률로 마피아의 살인을 회피합니다.': '5 % de chance d\'éviter une attaque de la mafia.',
        '해당 테마로 변경': 'Changer pour ce thème',
        '상점으로 이동': 'Aller à la boutique',
      },
      'RUS': {
        '내 정보': 'Моя информация',
        '중복된 닉네임 입니다.': 'Это имя пользователя уже занято.',
        '닉네임': 'имя',
        '연승': 'победа',
        '닉네임 변경': 'изменять',
        '(닉네임 변경 시 1,000 코인 소모)': '(Изменение имени пользователя стоит 1 000 монет)',
        '랭크 정보': 'Информация о рангах',
        '랭크 설명': 'Победа в многопользовательских играх увеличивает серию побед, а поражение уменьшает её. Каждый ранг определяется количеством побед, а ранги делятся на уровни.',
        '확인': 'Подтвердить',
        '브론즈': 'Бронза',
        '실버': 'Серебро',
        '골드': 'Золото',
        '플레티넘': 'Платина',
        '다이아몬드': 'Алмаз',
        '마스터': 'Мастер',
        '그랜드 마스터': 'Гранд Мастер',
        '레전드': 'Легенда',
        '레벨': 'Уровень',
        '경험치': 'Опыт',
        '보유 테마': 'Доступные темы',
        '테마 데이터가 없습니다.': 'Нет данных о темах.',
        '설명이 없습니다.': 'Описание отсутствует.',
        '보유 아이템': 'Доступные предметы',
        '아이템 데이터가 없습니다.': 'Нет данных о предметах.',
        '마피아': 'Мафия',
        '클래식한 마피아 테마입니다. 마피아, 경찰, 의사 등 여러 직업이 등장하며, 시민들은 마피아의 살인을 막아야 합니다.':
        'Классическая тема Мафии. Роли включают мафию, полицию и врача. Граждане должны остановить убийства мафии.',
        '크리스마스': 'Рождество',
        '크리스마스 테마는 따뜻한 연말 분위기를 표현합니다. 루돌프, 산타, 요정 등 여러 캐릭터가 등장하며, 그린치의 가짜 선물을 저지하세요!':
        'Тема Рождества передает теплую атмосферу праздника. Защитите подарки от Гринча с помощью Рудольфа, Санты и эльфов.',
        '숲속 친구들': 'Лесные друзья',
        '숲속 친구들 테마는 귀여운 동물들이 함께하는 테마입니다. 사슴, 다람쥐, 고슴도치 등 여러 귀여운 동물들이 등장하며, 사냥꾼을 막아야 합니다.':
        'Тема Лесных друзей включает милых животных, таких как олени, белки и ежики. Остановите охотников!',
        '좀비 사태': 'Зомби-апокалипсис',
        '좀비 사태 테마는 스릴 넘치는 생존 테마입니다. 여러 생존자들이 등장하며, 생존자 캠프에 몰래 들어온 감염자를 색출해야 합니다!':
        'Тема Зомби-апокалипсиса сосредоточена на выживании. Найдите зараженных, которые проникли в лагерь выживших!',
        '판사 봉': 'Молот судьи',
        '표를 행사할 때 2표를 행사합니다.': 'Дает 2 голоса на голосовании.',
        '정치적 연설': 'Политическая речь',
        '5% 확률로 투표로 인한 처형을 회피합니다.': '5 % шанс избежать казни по голосованию.',
        '방탄복': 'Бронежилет',
        '5% 확률로 마피아의 살인을 회피합니다.': '5 % шанс избежать убийства мафией.',
        '해당 테마로 변경': 'Переключиться на эту тему',
        '상점으로 이동': 'Перейти в магазин',
      },
      'ESP': {
        '내 정보': 'Mi información',
        '중복된 닉네임 입니다.': 'El nombre de usuario ya está en uso.',
        '닉네임': 'Nombre',
        '연승': 'Victorias',
        '닉네임 변경': 'Cambiar',
        '(닉네임 변경 시 1,000 코인 소모)': '(Cambiar el nombre de usuario cuesta 1,000 monedas)',
        '랭크 정보': 'Información de rangos',
        '랭크 설명': 'Ganar en partidas multijugador aumenta tu racha de victorias, mientras que perder la disminuye. Cada rango se determina por el puntaje de racha y los niveles se dividen en consecuencia.',
        '확인': 'Confirmar',
        '브론즈': 'Bronce',
        '실버': 'Plata',
        '골드': 'Oro',
        '플레티넘': 'Platino',
        '다이아몬드': 'Diamante',
        '마스터': 'Maestro',
        '그랜드 마스터': 'Gran Maestro',
        '레전드': 'Leyenda',
        '레벨': 'Nivel',
        '경험치': 'Experiencia',
        '보유 테마': 'Temas disponibles',
        '테마 데이터가 없습니다.': 'No hay datos de temas.',
        '설명이 없습니다.': 'No hay descripción.',
        '보유 아이템': 'Objetos disponibles',
        '아이템 데이터가 없습니다.': 'No hay datos de objetos.',
        '마피아': 'Mafia',
        '클래식한 마피아 테마입니다. 마피아, 경찰, 의사 등 여러 직업이 등장하며, 시민들은 마피아의 살인을 막아야 합니다.':
        'El tema clásico de la mafia. Incluye roles como mafia, policía y médico. Los ciudadanos deben detener a la mafia.',
        '크리스마스': 'Navidad',
        '크리스마스 테마는 따뜻한 연말 분위기를 표현합니다. 루돌프, 산타, 요정 등 여러 캐릭터가 등장하며, 그린치의 가짜 선물을 저지하세요!':
        'El tema navideño transmite una cálida atmósfera festiva. Protege los regalos del Grinch con la ayuda de Rodolfo, Santa y los elfos.',
        '숲속 친구들': 'Amigos del bosque',
        '숲속 친구들 테마는 귀여운 동물들이 함께하는 테마입니다. 사슴, 다람쥐, 고슴도치 등 여러 귀여운 동물들이 등장하며, 사냥꾼을 막아야 합니다.':
        'El tema de los amigos del bosque presenta adorables animales como ciervos, ardillas y erizos. ¡Detén a los cazadores!',
        '좀비 사태': 'Apocalipsis zombi',
        '좀비 사태 테마는 스릴 넘치는 생존 테마입니다. 여러 생존자들이 등장하며, 생존자 캠프에 몰래 들어온 감염자를 색출해야 합니다!':
        'El tema del apocalipsis zombi se centra en la supervivencia. Encuentra a los infectados infiltrados en el campamento.',
        '판사 봉': 'Mazo del juez',
        '표를 행사할 때 2표를 행사합니다.': 'Permite emitir 2 votos en las votaciones.',
        '정치적 연설': 'Discurso político',
        '5% 확률로 투표로 인한 처형을 회피합니다.': '5% de probabilidad de evitar la ejecución por votación.',
        '방탄복': 'Chaleco antibalas',
        '5% 확률로 마피아의 살인을 막을 수 있습니다.': '5% de probabilidad de evitar un asesinato de la mafia.',
        '해당 테마로 변경': 'Cambiar a este tema',
        '상점으로 이동': 'Ir a la tienda',
      },
      'ARA': {
        '내 정보': 'معلوماتي',
        '중복된 닉네임 입니다.': 'اسم المستخدم موجود بالفعل.',
        '닉네임': 'اسم',
        '연승': 'انتصار',
        '닉네임 변경': 'يتغير',
        '(닉네임 변경 시 1,000 코인 소모)': '(تغيير اسم المستخدم يكلف 1,000 عملة)',
        '랭크 정보': 'معلومات الرتبة',
        '랭크 설명': 'الفوز في الألعاب متعددة اللاعبين يزيد من سلسلة انتصاراتك، بينما يؤدي الخسارة إلى تقليلها. يتم تحديد كل رتبة بناءً على نتيجة السلسلة، وتنقسم الرتب وفقًا لذلك.',
        '확인': 'تأكيد',
        '브론즈': 'برونزي',
        '실버': 'فضي',
        '골드': 'ذهبي',
        '플레티넘': 'بلاتيني',
        '다이아몬드': 'ألماسي',
        '마스터': 'ماستر',
        '그랜드 마스터': 'الماستر الكبير',
        '레전드': 'أسطورة',
        '레벨': 'المستوى',
        '경험치': 'نقاط الخبرة',
        '보유 테마': 'الثيمات المتاحة',
        '테마 데이터가 없습니다.': 'لا توجد بيانات للثيمات.',
        '설명이 없습니다.': 'لا يوجد وصف.',
        '보유 아이템': 'العناصر المتاحة',
        '아이템 데이터가 없습니다.': 'لا توجد بيانات للعناصر.',
        '마피아': 'المافيا',
        '클래식한 마피아 테마입니다. 마피아, 경찰, 의사 등 여러 직업이 등장하며, 시민들은 마피아의 살인을 막아야 합니다.':
        'ثيم المافيا الكلاسيكي. يتضمن أدوار مثل المافيا والشرطة والطبيب. يجب على المواطنين منع القتل من قبل المافيا.',
        '크리스마스': 'الكريسماس',
        '크리스마스 테마는 따뜻한 연말 분위기를 표현합니다. 루돌프, 산타, 요정 등 여러 캐릭터가 등장하며, 그린치의 가짜 선물을 저지하세요!':
        'ثيم الكريسماس يعبر عن أجواء احتفالية دافئة. احمِ الهدايا من غرينش بمساعدة رودولف وسانتا والأقزام.',
        '숲속 친구들': 'أصدقاء الغابة',
        '숲속 친구들 테마는 귀여운 동물들이 함께하는 테마입니다. 사슴, 다람쥐, 고슴도치 등 여러 귀여운 동물들이 등장하며, 사냥꾼을 막아야 합니다.':
        'ثيم أصدقاء الغابة يقدم حيوانات لطيفة مثل الغزلان والسناجب والقنافذ. أوقف الصيادين!',
        '좀비 사태': 'كارثة الزومبي',
        '좀비 사태 테마는 스릴 넘치는 생존 테마입니다. 여러 생존자들이 등장하며, 생존자 캠프에 몰래 들어온 감염자를 색출해야 합니다!':
        'ثيم كارثة الزومبي يركز على البقاء. اكتشف المصابين الذين تسللوا إلى المعسكر.',
        '판사 봉': 'مطرقة القاضي',
        '표를 행사할 때 2표를 행사합니다.': 'يمكنك التصويت مرتين في الانتخابات.',
        '정치적 연설': 'خطاب سياسي',
        '5% 확률로 투표로 인한 처형을 회피합니다.': 'فرصة 5% لتجنب الإعدام عن طريق التصويت.',
        '방탄복': 'بي تي اس',
        '5% 확률로 마피아의 살인을 막을 수 있습니다.': 'فرصة 5% لتجنب جريمة قتل من المافيا.',
        '해당 테마로 변경': 'تغيير إلى هذا الثيم',
        '상점으로 이동': 'اذهب إلى المتجر',
      },

    };

    return localizedTexts[MyApp.currentLanguage]?[textKey] ?? textKey;
  }



}
