import 'package:flutter/material.dart';
import 'solama_service.dart';
import 'package:flutter/services.dart';
import '../MainPage/Shop.dart';
import '../MainPage/MainPage.dart';
import 'package:http/http.dart' as http;
import '../main.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:audioplayers/audioplayers.dart';
import 'translate.dart';

class Counsler extends StatefulWidget {
  @override
  _CounslerState createState() => _CounslerState();
}

class _CounslerState extends State<Counsler> {
  final TextEditingController _controller = TextEditingController();
  String _sourceLang = 'en'; // 초기 입력 언어를 저장할 변수
  String _responseMessage = 'How can I help you?';
  bool _isLoading = false;
  int points = 0;
  final AudioPlayer _audioPlayer = AudioPlayer(); // 효과음 플레이어
  final AudioPlayer _bgmPlayer = AudioPlayer(); // 배경 음악 플레이어

  // 배경 음악 시작 함수
  Future<void> _startBackgroundMusic() async {
    try {
      await _bgmPlayer.setReleaseMode(ReleaseMode.loop); // 반복 재생 모드
      await _bgmPlayer.play(AssetSource('Sound/bar.mp3')); // 배경 음악 경로
    } catch (e) {
      print("Error starting background music: $e");
    }
  }
  Future<void> _wine() async {
    try {
      await _audioPlayer.play(AssetSource('Sound/wine.mp3')); // 효과음 파일 경로
    } catch (e) {
      print("Error playing sound: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    MyApp.bgmPlayer.pause();
    _startBackgroundMusic(); // 배경 음악 시작
    _getUserName(MyApp.user_id);
    _getPointValue(0); // 순차적으로 실행하도록 별도 메서드 호출
  }
  @override
  void dispose() {
    _bgmPlayer.dispose(); // 배경 음악 플레이어 해제
    _audioPlayer.dispose(); // 카드 클릭 효과음 플레이어 해제
    MyApp.bgmPlayer.resume();
  }

  Future<void> _getPointValue(n) async {
    final url = Uri.parse('${MyApp.url}/user/point');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': MyApp.user_id,
        'points': n
      }), //여기서의 points는 더해줄 값을 의미(0은 단순 포인트 조회)
    );

    if (response.statusCode == 200) {
      setState(() {
        points = int.parse(response.body);
      });
    }
  }
  String formatWithComma(int number) {
    return NumberFormat('#,###').format(number);
  }
  // 닉네임 업데이트 함수
  Future<void> _getUserName(String id) async{
    final response = await http.post(
      Uri.parse('${MyApp.url}/user/name'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(
          {'user_id': id, 'user_name': ''}),
    );
    if (response.statusCode == 200) {
      setState(() {
        _responseMessage = '${response.body}! ${lang('어서오세요, 주문하시겠습니까?')} \n (${lang('대화당 10 코인')})';
      });
    }
  }

  void _sendMessage() async {
    final userMessage = _controller.text.trim();

    if (userMessage.isNotEmpty && points >= 10) {
      _wine(); // 효과음 재생
      setState(() {
        _responseMessage = '';
        _isLoading = true;
      });

      // 1. 입력한 언어를 영어로 번역
      String translatedInput = await translateText(userMessage, "auto", "en");
      _sourceLang = await detectInputLanguage(userMessage); //사용자 언어 감지(추후 대답용)

      // 포인트 감소
      await _getPointValue(-10);

      // 2. 번역된 메시지를 AI에게 전송
      SolamaService.streamResponse(
        prompt: translatedInput,
        onContentReceived: (content) async {
          setState(() {
            _responseMessage += content;
          });
        },
        // 3. AI 응답을 다시 사용자 언어로 번역
        onComplete: () async {
          String translatedOutput = await translateText(_responseMessage, "en", _sourceLang);
          setState(() {
            _responseMessage = translatedOutput;
            _isLoading = false;
          });
        },
        onError: (error) {
          setState(() {
            _responseMessage = error;
            _isLoading = false;
          });
        },
      );
      _controller.clear();
    } else {
      setState(() {
        if (points < 10) {
          _responseMessage = lang('죄송하지만 코인이 부족합니다..');
        } else {
          _responseMessage = lang('다시 말씀해주시겠어요?..');
        }
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
            image: AssetImage('assets/Game/counsler.png'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.0),
              BlendMode.darken,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 40.0, bottom: 15.0, right: 10),
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
                    'BAR',
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
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: ListView(
                  children: [

                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 10.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(15),
                    topRight: Radius.circular(15),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                child: Text(
                  lang('바텐더'),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.amberAccent,
                  ),
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
              ),
              padding: const EdgeInsets.only(top: 0, bottom: 16, left: 16, right: 16),
              child: Column( // 세로 정렬로 변경
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 10.0),
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.yellow.withOpacity(0.0),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _responseMessage.isNotEmpty
                          ? _responseMessage
                          : '${lang('[ 생각중.. ]')} \n \n ${lang('(영어로 입력하시면 더 정확한 답변을 얻습니다)')}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(height: 10), // 채팅 메시지와 입력 필드 사이 간격
                  Row( // 채팅 입력과 확인 버튼은 가로 정렬 유지
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          enabled: !_isLoading,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(30), // 글자 최대한도
                          ],
                          decoration: InputDecoration(
                            hintText: lang('글자를 입력하세요.. (최대 30글자)'),
                            hintStyle: TextStyle(color: Colors.grey[500]),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.8),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: _isLoading
                            ? () {} // 아무 동작도 하지 않도록 설정
                            : _sendMessage, // 로딩 중이 아닐 때만 실제 동작 실행
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isLoading
                              ? Colors.grey[400] // 로딩 중일 때 회색
                              : Colors.amberAccent, // 로딩 중이 아닐 때 노란색
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10), // 버튼의 둥근 모서리
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 12.0,
                          ),
                        ),
                        child: Text(
                          _isLoading ? lang('전송') : lang('전송'), // 로딩 중일 때 텍스트 변경
                          style: TextStyle(
                            fontSize: 18,
                            color: _isLoading ? Colors.black45 : Colors.black, // 비활성화 시 흐린 검은색
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    )
    );
  }
}

String lang(String textKey) {
  final localizedTexts = {
    "KOR": {
      "어서오세요, 주문하시겠습니까?": "어서오세요, 주문하시겠습니까?",
      "대화당 10 코인": "대화당 10 코인",
      "죄송하지만 코인이 부족합니다..": "죄송하지만 코인이 부족합니다..",
      "다시 말씀해주시겠어요?..": "다시 말씀해주시겠어요?..",
      "바텐더": "바텐더",
      "[ 생각중.. ]": "[ 생각중.. ]",
      "글자를 입력하세요.. (최대 30글자)": "글자를 입력하세요.. (최대 30글자)",
      "전송": "전송",
      "(영어로 입력하시면 더 정확한 답변을 얻습니다)": "(영어로 입력하시면 더 정확한 답변을 얻습니다)"
    },
    "ENG": {
      "어서오세요, 주문하시겠습니까?": "Welcome, may I take your order?",
      "대화당 10 코인": "10 coins per conversation",
      "죄송하지만 코인이 부족합니다..": "Sorry, you don't have enough coins..",
      "다시 말씀해주시겠어요?..": "Could you say that again?..",
      "바텐더": "Bartender",
      "[ 생각중.. ]": "[ Thinking.. ]",
      "글자를 입력하세요.. (최대 30글자)": "Enter text.. (up to 30 characters)",
      "전송": "Send",
      "(영어로 입력하시면 더 정확한 답변을 얻습니다)": "(Type in English for a more accurate response)"
    },
    "ARA": {
      "어서오세요, 주문하시겠습니까?": "مرحبًا، هل ترغب في الطلب؟",
      "대화당 10 코인": "10 عملات لكل محادثة",
      "죄송하지만 코인이 부족합니다..": "عذرًا، ليس لديك عملات كافية..",
      "다시 말씀해주시겠어요?..": "هل يمكنك إعادة ما قلته؟..",
      "바텐더": "نادل",
      "[ 생각중.. ]": "[ يفكر.. ]",
      "글자를 입력하세요.. (최대 30글자)": "أدخل النص.. (بحد أقصى 30 حرفًا)",
      "전송": "إرسال",
      "(영어로 입력하시면 더 정확한 답변을 얻습니다)": "(اكتب بالإنجليزية للحصول على إجابة دقيقة)"
    },
    "CHN": {
      "어서오세요, 주문하시겠습니까?": "欢迎光临，请问要点什么？",
      "대화당 10 코인": "每次对话10个金币",
      "죄송하지만 코인이 부족합니다..": "很抱歉，您的金币不足..",
      "다시 말씀해주시겠어요?..": "请再说一遍好吗?..",
      "바텐더": "调酒师",
      "[ 생각중.. ]": "[ 思考中.. ]",
      "글자를 입력하세요.. (최대 30글자)": "请输入文字..（最多30个字）",
      "전송": "发送",
      "(영어로 입력하시면 더 정확한 답변을 얻습니다)": "(输入英文可获得更准确的回复)"
    },
    "JPN": {
      "어서오세요, 주문하시겠습니까?": "いらっしゃいませ、ご注文は？",
      "대화당 10 코인": "1会話10コイン",
      "죄송하지만 코인이 부족합니다..": "申し訳ありません、コインが不足しています..",
      "다시 말씀해주시겠어요?..": "もう一度おっしゃっていただけますか？..",
      "바텐더": "バーテンダー",
      "[ 생각중.. ]": "[ 考え中.. ]",
      "글자를 입력하세요.. (최대 30글자)": "文字を入力してください..（最大30文字）",
      "전송": "送信",
      "(영어로 입력하시면 더 정확한 답변을 얻습니다)": "(英語で入力すると、より正確な返事が得られます)"
    },
    "GER": {
      "어서오세요, 주문하시겠습니까?": "Willkommen, was möchten Sie bestellen?",
      "대화당 10 코인": "10 Münzen pro Gespräch",
      "죄송하지만 코인이 부족합니다..": "Entschuldigung, Sie haben nicht genug Münzen..",
      "다시 말씀해주시겠어요?..": "Könnten Sie das bitte wiederholen?..",
      "바텐더": "Barkeeper",
      "[ 생각중.. ]": "[ Denkt nach.. ]",
      "글자를 입력하세요.. (최대 30글자)": "Text eingeben.. (maximal 30 Zeichen)",
      "전송": "Senden",
      "(영어로 입력하시면 더 정확한 답변을 얻습니다)": "(Geben Sie Englisch ein, um eine genauere Antwort zu erhalten)"
    },
    "RUS": {
      "어서오세요, 주문하시겠습니까?": "Добро пожаловать, что закажете?",
      "대화당 10 코인": "10 монет за разговор",
      "죄송하지만 코인이 부족합니다..": "Извините, у вас недостаточно монет..",
      "다시 말씀해주시겠어요?..": "Не могли бы вы повторить?..",
      "바텐더": "Бармен",
      "[ 생각중.. ]": "[ Думает.. ]",
      "글자를 입력하세요.. (최대 30글자)": "Введите текст.. (до 30 символов)",
      "전송": "Отправить",
      "(영어로 입력하시면 더 정확한 답변을 얻습니다)": "(Введите на английском для более точного ответа)"
    },
    "FRA": {
      "어서오세요, 주문하시겠습니까?": "Bienvenue, puis-je prendre votre commande?",
      "대화당 10 코인": "10 pièces par conversation",
      "죄송하지만 코인이 부족합니다..": "Désolé, vous n'avez pas assez de pièces..",
      "다시 말씀해주시겠어요?..": "Pourriez-vous répéter cela?..",
      "바텐더": "Barman",
      "[ 생각중.. ]": "[ Réflexion.. ]",
      "글자를 입력하세요.. (최대 30글자)": "Saisissez du texte.. (30 caractères max)",
      "전송": "Envoyer",
      "(영어로 입력하시면 더 정확한 답변을 얻습니다)": "(Tapez en anglais pour une réponse plus précise)"
    },
    "ESP": {
      "어서오세요, 주문하시겠습니까?": "Bienvenido, ¿desea ordenar?",
      "대화당 10 코인": "10 monedas por conversación",
      "죄송하지만 코인이 부족합니다..": "Lo siento, no tienes suficientes monedas..",
      "다시 말씀해주시겠어요?..": "¿Podrías repetir eso?..",
      "바텐더": "Cantinero",
      "[ 생각중.. ]": "[ Pensando.. ]",
      "글자를 입력하세요.. (최대 30글자)": "Escriba el texto.. (máximo 30 caracteres)",
      "전송": "Enviar",
      "(영어로 입력하시면 더 정확한 답변을 얻습니다)": "(Escriba en inglés para una respuesta más precisa)"
    }
  };

  return localizedTexts[MyApp.currentLanguage]?[textKey] ?? textKey;
}