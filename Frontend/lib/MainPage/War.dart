import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../main.dart';
import 'MainPage.dart';
import 'Shop.dart';

class War extends StatefulWidget {
  @override
  _WarState createState() => _WarState();
}

class _WarState extends State<War> {
  List<Map<String, dynamic>> users = [];
  Map<String, dynamic>? currentUser;
  ScrollController _scrollController = ScrollController();
  int minAttack = 50;
  int userPoints = 0; // 사용자 포인트 변수 추가

  @override
  void initState() {
    super.initState();
    _getPointValue(0);
    _getWarRecords(MyApp.user_id);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _getPointValue(n) async {
    final url = Uri.parse('${MyApp.url}/user/point');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': MyApp.user_id, 'points': n}), //여기서의 points는 더해줄 값을 의미(0은 단순 포인트 조회)
    );

    if (response.statusCode == 200) {
      setState(() {
        userPoints = int.parse(response.body);
      });
    }

    await _loadUsers(); //순위페이지라는 특수성 때문에 추가함
  }

  Future<void> _loadUsers() async {
    final response = await http.get(Uri.parse('${MyApp.url}/api/users'));
    if (response.statusCode == 200) {
      List<Map<String, dynamic>> allUsers = List<Map<String, dynamic>>.from(
          jsonDecode(utf8.decode(response.bodyBytes))); // UTF-8로 디코딩
      setState(() {
        allUsers.sort((a, b) => b['points'].compareTo(a['points']));
        users = allUsers;
        currentUser = allUsers.firstWhere(
              (user) => user['user_id'] == MyApp.user_id,
          orElse: () => {'user_id': MyApp.user_id, 'points': 0},
        );
      });
    }
    _scrollToCurrentUser();
  }

  void _scrollToCurrentUser() {
    if (currentUser != null) {
      int userIndex = users.indexWhere((user) => user['user_id'] == MyApp.user_id);
      if (userIndex != -1) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          double scrollPosition = userIndex * 70.0;
          double screenHeight = MediaQuery.of(context).size.height;
          double middleOffset = (screenHeight / 2) - 35;

          _scrollController.animateTo(
            (scrollPosition - middleOffset).clamp(0.0, _scrollController.position.maxScrollExtent),
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        });
      }
    }
  }

  void _getWarRecords(String userId) async {
    final url = Uri.parse('${MyApp.url}/api/warRecord');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': userId}), // 유저 ID 전달
    );

    if (response.statusCode == 200) {
      // JSON 데이터 파싱
      List<String> attackers = List<String>.from(jsonDecode(response.body));

      if (attackers.isNotEmpty) {
        _showWarRecordsDialog(attackers);
      }
    }
  }

  void _showWarRecordsDialog(List<String> attackers) {
    String content = attackers.map((attacker) => attackers).join("\n");

    _showCustomDialog(
      context: context,
      title: lang("공격 기록"),
      content: content,
      onConfirm: () {
      },
    );
  }


  void _decreasePoints(String targetUserId) async {
    final url = Uri.parse('${MyApp.url}/api/war');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'attacker': MyApp.user_id, 'defender': targetUserId}), //여기서의 points는 더해줄 값을 의미(0은 단순 포인트 조회)
    );

    if (response.statusCode == 200) {
      await _getPointValue(0); // 포인트 다시 불러오기
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
      // 뒤로가기 방지
      return false;
    },
    child: Scaffold(
      body: Column(
        children: [
          // 상단 박스
          Container(
            width: double.infinity, // 좌우로 꽉 채움
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.pink.shade900, Colors.red],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(20), // 아래쪽만 둥근 모서리
              ),
            ),
            child: Row(
              children: [
                // 뒤로가기 버튼
                IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color: Colors.white, // 버튼 색상
                    size: 40, // 아이콘 크기
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
                Center(
                  child: Column(
                    children: [
                      SizedBox(height: 5),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => Shop()),
                          );
                        },
                        child: Row(
                          children: [
                            Text(
                              '$userPoints',
                              style: TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.w600,
                                color: Colors.amberAccent, // 금색 강조
                                shadows: [Shadow(blurRadius: 4, color: Colors.black38, offset: Offset(2, 2))],
                              ),
                            ),
                            Image.asset(
                              'assets/UI/coin.png',
                              height: 50, // 아이콘 크기 설정
                            ),
                          ],
                        ),
                      ),
                      Text(
                        lang("상대를 클릭해서 공격하세요!"),
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      Text(
                        lang("(50% 확률로 승리 또는 패배)"),
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                bool isCurrentUser = user['user_id'] == MyApp.user_id;

                // 닉네임의 픽셀 너비를 제한 (예: 최대 200px)
                String truncatedNickname = getTruncatedText(
                  user["user_id"],
                  MediaQuery.of(context).size.width * 0.4,
                  TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                );

                // 구간 설명 박스 위젯
                Widget benefitBox = Container(); // 기본적으로 빈 컨테이너
                if (index == 0) {
                  benefitBox = _buildBenefitBox(0, "${lang("최상위")}", Colors.blueGrey.shade100);
                } else if (index == 5) {
                  benefitBox = _buildBenefitBox(1, "${lang("그랜드마스터")}", Colors.yellowAccent.shade400);
                } else if (index == 15) {
                  benefitBox = _buildBenefitBox(2, "${lang("마스터")}", Colors.green.shade300);
                } else if (index == 30) {
                  benefitBox = _buildBenefitBox(3, "${lang("다이아몬드")}", Colors.cyan.shade200);
                } else if (index == 50) {
                  benefitBox = _buildBenefitBox(4, "${lang("플레티넘")}", Colors.purple.shade200);
                } else if (index == 75) {
                  benefitBox = _buildBenefitBox(5, "${lang("골드")}", Colors.yellow.shade700);
                } else if (index == 105) {
                  benefitBox = _buildBenefitBox(6, "${lang("실버")}", Colors.grey);
                } else if (index == 140) {
                  benefitBox = _buildBenefitBox(7, "${lang("브론즈")}", Colors.brown.shade300);
                }

                return Column(
                  children: [
                    benefitBox,
                    ListTile(
                      leading: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '#${index + 1}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: index < 10 ? FontWeight.bold : FontWeight.bold,
                              color: _getUserColor(index, isCurrentUser), // 구역 색상 적용
                            ),
                          ),
                          SizedBox(width: 10),
                          Image.asset(
                            _getImagePath(index), // 특정 구간별 이미지 경로 가져오기
                            width: 40,
                            height: 40,
                          ),
                        ],
                      ),
                      title: Row(
                        children: [
                          // 닉네임 부분에만 색상 적용 (본인은 withOpacity(1), 다른 사람은 withOpacity(0.8))
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getUserColor(index, isCurrentUser)
                                  .withOpacity(isCurrentUser ? 0.6 : 0.3), // 본인은 불투명, 다른 사람은 약간 투명
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              truncatedNickname, // 여기서 20자 제한된 닉네임 사용
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          // 포인트는 기존 텍스트 스타일로 표시
                          Text(
                            '${user["points"]}P',
                            style: TextStyle(
                              fontWeight: FontWeight.normal,
                              fontSize: 18,
                              color: isCurrentUser ? Colors.blue : Colors.black,
                            ),
                          ),
                        ],
                      ),
                      // 클릭 시 포인트 감소 기능을 호출
                      onTap: isCurrentUser
                          ? null
                          : () async {
                        final int targetPoints = user['points']; // 상대방의 포인트
                        if (userPoints >= minAttack && targetPoints >= 100) {
                          final random = Random().nextBool(); // 50% 확률
                          if (random) {
                            // 공격 성공
                            _showCustomDialog(
                              context: context,
                              title: lang("공격 성공!"),
                              content: lang("상대의 100 코인을 파괴했습니다!"),
                              onConfirm: () {
                                _decreasePoints(user['user_id']); // 포인트 감소 호출
                              },
                            );
                          } else {
                            // 공격 실패
                            _showCustomDialog(
                              context: context,
                              title: lang("공격 실패.."),
                              content: lang("당신의 50 코인이 사라졌습니다.."),
                              onConfirm: () {
                                _getPointValue(-50); // 자신의 포인트 감소
                              },
                            );
                          }
                        } else {
                          // 포인트가 부족한 경우
                          _showCustomDialog(
                            context: context,
                            title: lang("포인트 부족"),
                            content: lang("당신 또는 상대 포인트가 부족하여 공격할 수 없습니다."),
                            onConfirm: () {
                              // 포인트 부족 시 특별한 동작이 없으면 비워둡니다.
                            },
                          );
                        }
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    )
    );
  }

  Color _getUserColor(int index, bool isCurrentUser) {
    if (isCurrentUser) {
      return Colors.blue;
    } else if (index <= 4) {
      return Colors.blueGrey.shade100;
    } else if (index <= 14) {
      return Colors.yellowAccent.shade400;
    } else if (index <= 29) {
      return Colors.green;
    } else if (index <= 49) {
      return Colors.cyan.shade200;
    } else if (index <= 74) {
      return Colors.purple.shade200;
    } else if (index <= 104) {
      return Colors.yellow.shade700;
    } else if (index <= 139) {
      return Colors.grey;
    } else {
      return Colors.brown.shade500;
    }
  }
}

//글자수 생략
String getTruncatedText(String text, double maxWidth, TextStyle textStyle) {
  final TextPainter textPainter = TextPainter(
    text: TextSpan(text: text, style: textStyle),
    maxLines: 1,
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: maxWidth);

  if (textPainter.didExceedMaxLines) {
    for (int i = text.length - 1; i >= 0; i--) {
      final TextPainter truncatedTextPainter = TextPainter(
        text: TextSpan(text: text.substring(0, i) + '...', style: textStyle),
        maxLines: 1,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: maxWidth);

      if (!truncatedTextPainter.didExceedMaxLines) {
        return text.substring(0, i) + '...';
      }
    }
  }
  return text; // 제한에 걸리지 않으면 원래 텍스트 반환
}


// 구간 설명 박스를 위한 메서드
Widget _buildBenefitBox(int teer, String text1, Color color) {
  // 이미지 파일명을 TOP 순위에 따라 결정
  String imagePath;
  if (teer == 0) {
    imagePath = 'assets/UI/Ranks/최상위.png';
  } else if (teer == 1) {
    imagePath = 'assets/UI/Ranks/그마.png';
  } else if (teer == 2) {
    imagePath = 'assets/UI/Ranks/마스터.png';
  } else if (teer == 3) {
    imagePath = 'assets/UI/Ranks/다이아.png';
  } else if (teer == 4) {
    imagePath = 'assets/UI/Ranks/플레티넘.png';
  } else if (teer == 5) {
    imagePath = 'assets/UI/Ranks/골드.png';
  } else if (teer == 6) {
    imagePath = 'assets/UI/Ranks/실버.png';
  } else {
    imagePath = 'assets/UI/Ranks/브론즈.png'; // 기본 이미지
  }
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4.0),
    child: Stack(
      alignment: Alignment.center,
      children: [
        Divider(thickness: 10, color: color), // 구간별 선 색상
        Container(
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 18),
          alignment: Alignment.center,
          constraints: BoxConstraints(maxWidth: 290), // 너비 제한 추가
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 순위 아이콘
              Image.asset(
                imagePath,
                width: 50,
              ),
              Text(
                text1,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,  // 첫째 줄 폰트 크기
                  fontWeight: FontWeight.bold,
                  color: Colors.black,  // 첫째 줄 글자색
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

String _getImagePath(int index) {
  if (index <= 4) {
    return 'assets/UI/Ranks/최상위.png'; // 최상위
  } else if (index <= 14) {
    return 'assets/UI/Ranks/그마.png'; // 그랜드마스터
  } else if (index <= 29) {
    return 'assets/UI/Ranks/마스터.png'; // 마스터
  } else if (index <= 49) {
    return 'assets/UI/Ranks/다이아.png'; // 다이아몬드
  } else if (index <= 74) {
    return 'assets/UI/Ranks/플레티넘.png'; // 플레티넘
  } else if (index <= 104) {
    return 'assets/UI/Ranks/골드.png'; // 골드
  } else if (index <= 139) {
    return 'assets/UI/Ranks/실버.png'; // 실버
  } else {
    return 'assets/UI/Ranks/브론즈.png'; // 브론즈
  }
}


void _showCustomDialog({
  required BuildContext context,
  required String title,
  required String content,
  required VoidCallback onConfirm,
}) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15), // 다이얼로그의 모서리를 둥글게 설정
        ),
        backgroundColor: Colors.black87, // 다이얼로그 배경색
        child: Padding(
          padding: const EdgeInsets.all(20.0), // 내부 여백
          child: Column(
            mainAxisSize: MainAxisSize.min, // 내용에 맞게 크기를 최소화
            children: [
              // 제목
              Text(
                title,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFD4AF37), // 금색
                  shadows: [
                    Shadow(
                      color: Colors.black45,
                      offset: Offset(2, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 15),
              // 내용
              Text(
                content,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              // 버튼
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // 확인 버튼
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // 다이얼로그 닫기
                      onConfirm(); // 확인 버튼 클릭 시 실행될 콜백
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFD4AF37), // 금색 배경
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    child: Text(
                      lang("확인"),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
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
      '공격 기록': '공격 기록',
      '상대를 클릭해서 공격하세요!': '상대를 클릭해서 공격하세요!',
      '(50% 확률로 승리 또는 패배)': '(50% 확률로 승리 또는 패배)',
      '플레이어': '플레이어',
      '공격 성공!': '공격 성공!',
      '상대의 100 코인을 파괴했습니다!': '상대의 100 코인을 파괴했습니다!',
      '공격 실패..': '공격 실패..',
      '당신의 50 코인이 사라졌습니다..': '당신의 50 코인이 사라졌습니다..',
      '포인트 부족': '포인트 부족',
      '당신 또는 상대 포인트가 부족하여 공격할 수 없습니다.': '당신 또는 상대 포인트가 부족하여 공격할 수 없습니다.',
      '확인': '확인',
      '최상위': '최상위',
      '그랜드마스터': '그랜드마스터',
      '마스터': '마스터',
      '다이아몬드': '다이아몬드',
      '플레티넘': '플레티넘',
      '골드': '골드',
      '실버': '실버',
      '브론즈': '브론즈',
    },
    'ENG': {
      '공격 기록': 'Attack History',
      '상대를 클릭해서 공격하세요!': 'Click on a player to attack!',
      '(50% 확률로 승리 또는 패배)': '(50% chance of victory or defeat)',
      '플레이어': 'Player',
      '공격 성공!': 'Attack Successful!',
      '상대의 100 코인을 파괴했습니다!': 'Destroyed 100 of your opponent\'s coins!',
      '공격 실패..': 'Attack Failed..',
      '당신의 50 코인이 사라졌습니다..': 'You lost 50 coins..',
      '포인트 부족': 'Insufficient Points',
      '당신 또는 상대 포인트가 부족하여 공격할 수 없습니다.': 'You or your opponent have insufficient points to attack.',
      '확인': 'OK',
      '최상위': 'Top Tier',
      '그랜드마스터': 'Grandmaster',
      '마스터': 'Master',
      '다이아몬드': 'Diamond',
      '플레티넘': 'Platinum',
      '골드': 'Gold',
      '실버': 'Silver',
      '브론즈': 'Bronze',
    },
    'ARA': {
      '공격 기록': 'سجل الهجوم',
      '상대를 클릭해서 공격하세요!': 'اضغط على لاعب للهجوم!',
      '(50% 확률로 승리 또는 패배)': '(فرصة 50٪ للفوز أو الهزيمة)',
      '플레이어': 'لاعب',
      '공격 성공!': 'الهجوم ناجح!',
      '상대의 100 코인을 파괴했습니다!': 'دمرت 100 قطعة نقدية من خصمك!',
      '공격 실패..': 'فشل الهجوم..',
      '당신의 50 코인이 사라졌습니다..': 'لقد فقدت 50 قطعة نقدية..',
      '포인트 부족': 'نقاط غير كافية',
      '당신 또는 상대 포인트가 부족하여 공격할 수 없습니다.': 'أنت أو خصمك لديكما نقاط غير كافية للهجوم.',
      '확인': 'تأكيد',
      '최상위': 'القمة',
      '그랜드마스터': 'جراند ماستر',
      '마스터': 'ماستر',
      '다이아몬드': 'ألماس',
      '플레티넘': 'بلاتينيوم',
      '골드': 'ذهبي',
      '실버': 'فضي',
      '브론즈': 'برونزي',
    },
    'CHN': {
      '공격 기록': '攻击记录',
      '상대를 클릭해서 공격하세요!': '点击玩家进行攻击！',
      '(50% 확률로 승리 또는 패배)': '(50% 胜负几率)',
      '플레이어': '玩家',
      '공격 성공!': '攻击成功！',
      '상대의 100 코인을 파괴했습니다!': '摧毁了对方的100金币！',
      '공격 실패..': '攻击失败..',
      '당신의 50 코인이 사라졌습니다..': '你失去了50金币..',
      '포인트 부족': '积分不足',
      '당신 또는 상대 포인트가 부족하여 공격할 수 없습니다.': '您或对方积分不足，无法进行攻击。',
      '확인': '确认',
      '최상위': '顶级',
      '그랜드마스터': '宗师',
      '마스터': '大师',
      '다이아몬드': '钻石',
      '플레티넘': '铂金',
      '골드': '黄金',
      '실버': '白银',
      '브론즈': '青铜',
    },
    'JPN': {
      '공격 기록': 'هجوم السجل',
      '상대를 클릭해서 공격하세요!': 'クリックして攻撃してください！',
      '(50% 확률로 승리 또는 패배)': '（50％の確率で勝利または敗北）',
      '플레이어': 'プレイヤー',
      '공격 성공!': '攻撃成功！',
      '상대의 100 코인을 파괴했습니다!': '相手の100コインを破壊しました！',
      '공격 실패..': '攻撃失敗..',
      '당신의 50 코인이 사라졌습니다..': 'あなたの50コインが失われました..',
      '포인트 부족': 'ポイント不足',
      '당신 또는 상대 포인트가 부족하여 공격할 수 없습니다.': 'あなたまたは相手のポイントが不足しており、攻撃できません。',
      '확인': '確認',
      '최상위': '最上位',
      '그랜드마스터': 'グランドマスター',
      '마스터': 'マスター',
      '다이아몬드': 'ダイヤモンド',
      '플레티넘': 'プラチナ',
      '골드': 'ゴールド',
      '실버': 'シルバー',
      '브론즈': 'ブロンズ',
    },
    'GER': {
      '공격 기록': 'Angriffsprotokoll',
      '상대를 클릭해서 공격하세요!': 'Klicken Sie, um anzugreifen!',
      '(50% 확률로 승리 또는 패배)': '(50 % gewinnen oder verlieren)',
      '플레이어': 'Spieler',
      '공격 성공!': 'Angriff erfolgreich!',
      '상대의 100 코인을 파괴했습니다!': 'Sie haben 100 Münzen des Gegners zerstört!',
      '공격 실패..': 'Angriff fehlgeschlagen..',
      '당신의 50 코인이 사라졌습니다..': 'Ihre 50 Münzen sind verschwunden..',
      '포인트 부족': 'Nicht genügend Punkte',
      '당신 또는 상대 포인트가 부족하여 공격할 수 없습니다.': 'Sie oder der Gegner haben nicht genügend Punkte, um anzugreifen.',
      '확인': 'Bestätigen',
      '최상위': 'Oberste Ebene',
      '그랜드마스터': 'Großmeister',
      '마스터': 'Meister',
      '다이아몬드': 'Diamant',
      '플레티넘': 'Platin',
      '골드': 'Gold',
      '실버': 'Silber',
      '브론즈': 'Bronze',
    },
    'FRA': {
      '공격 기록': 'Historique des attaques',
      '상대를 클릭해서 공격하세요!': 'Cliquez pour attaquer !',
      '(50% 확률로 승리 또는 패배)': '(50 % de victoire ou de défaite)',
      '플레이어': 'Joueur',
      '공격 성공!': 'Attaque réussie !',
      '상대의 100 코인을 파괴했습니다!': 'Vous avez détruit 100 pièces de votre adversaire !',
      '공격 실패..': 'Échec de l\'attaque..',
      '당신의 50 코인이 사라졌습니다..': 'Vous avez perdu 50 pièces..',
      '포인트 부족': 'Points insuffisants',
      '당신 또는 상대 포인트가 부족하여 공격할 수 없습니다.': 'Vous ou votre adversaire n\'avez pas assez de points pour attaquer.',
      '확인': 'Confirmer',
      '최상위': 'Niveau supérieur',
      '그랜드마스터': 'Grand maître',
      '마스터': 'Maître',
      '다이아몬드': 'Diamant',
      '플레티넘': 'Platine',
      '골드': 'Or',
      '실버': 'Argent',
      '브론즈': 'Bronze',
    },
    'RUS': {
      '공격 기록': 'Запись атак',
      '상대를 클릭해서 공격하세요!': 'Нажмите, чтобы атаковать!',
      '(50% 확률로 승리 또는 패배)': '(50% шанс на победу)',
      '플레이어': 'Игрок',
      '공격 성공!': 'Атака успешна!',
      '상대의 100 코인을 파괴했습니다!': 'Вы уничтожили 100 монет соперника!',
      '공격 실패..': 'Атака не удалась..',
      '당신의 50 코인이 사라졌습니다..': 'Ваши 50 монет исчезли..',
      '포인트 부족': 'Недостаточно очков',
      '당신 또는 상대 포인트가 부족하여 공격할 수 없습니다.': 'У вас или у соперника недостаточно очков для атаки.',
      '확인': 'Подтвердить',
      '최상위': 'Высший уровень',
      '그랜드마스터': 'Грандмастер',
      '마스터': 'Мастер',
      '다이아몬드': 'Алмаз',
      '플레티넘': 'Платина',
      '골드': 'Золото',
      '실버': 'Серебро',
      '브론즈': 'Бронза',
    },
    'ESP': {
      '공격 기록': 'Historial de ataques',
      '상대를 클릭해서 공격하세요!': '¡Haz clic para atacar!',
      '(50% 확률로 승리 또는 패배)': '(50% de ganar)',
      '플레이어': 'Jugador',
      '공격 성공!': '¡Ataque exitoso!',
      '상대의 100 코인을 파괴했습니다!': '¡Has destruido 100 monedas del oponente!',
      '공격 실패..': 'Ataque fallido..',
      '당신의 50 코인이 사라졌습니다..': 'Has perdido 50 monedas..',
      '포인트 부족': 'Puntos insuficientes',
      '당신 또는 상대 포인트가 부족하여 공격할 수 없습니다.': 'Tú o tu oponente no tenéis suficientes puntos para atacar.',
      '확인': 'Confirmar',
      '최상위': 'Nivel superior',
      '그랜드마스터': 'Gran maestro',
      '마스터': 'Maestro',
      '다이아몬드': 'Diamante',
      '플레티넘': 'Platino',
      '골드': 'Oro',
      '실버': 'Plata',
      '브론즈': 'Bronce',
    },

  };

  return localizedTexts[MyApp.currentLanguage]?[textKey] ?? textKey;
}
