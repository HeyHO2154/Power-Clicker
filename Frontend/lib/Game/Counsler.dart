import 'package:flutter/material.dart';
import 'solama_service.dart';

class Counsler extends StatefulWidget {
  @override
  _CounslerState createState() => _CounslerState();
}

class _CounslerState extends State<Counsler> {
  final TextEditingController _controller = TextEditingController();
  String _responseMessage = '';
  bool _isLoading = false;

  void _sendMessage() {
    final userMessage = _controller.text.trim();
    if (userMessage.isNotEmpty) {
      setState(() {
        _responseMessage = '';
        _isLoading = true;
      });

      SolamaService.streamResponse(
        prompt: userMessage,
        onContentReceived: (content) {
          setState(() {
            _responseMessage += content;
          });
        },
        onComplete: () {
          setState(() {
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  'Counsler',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
              ),
              padding: const EdgeInsets.all(16.0),
              child: Column( // 세로 정렬로 변경
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 10.0),
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _responseMessage.isNotEmpty
                          ? _responseMessage
                          : 'Counsler: 대화 내용을 여기에 표시합니다.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black,
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
                          decoration: InputDecoration(
                            hintText: '메시지를 입력하세요...',
                            hintStyle: TextStyle(color: Colors.grey[400]),
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
                        onPressed: _isLoading ? null : _sendMessage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amberAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 12.0,
                          ),
                        ),
                        child: Text(
                          _isLoading ? '응답 대기 중...' : '확인',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.black,
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
    );
  }
}
