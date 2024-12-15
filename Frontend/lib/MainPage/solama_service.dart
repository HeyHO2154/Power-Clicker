import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/main.dart'; // MyApp.url 사용을 위한 임포트

class ChatPage extends StatefulWidget {
  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  String _responseMessage = '';

  // API 호출과 응답 파싱 모두 여기서 처리
  Future<String> _generateScenario(String prompt) async {
    final String apiUrl = 'http://ekaf.kro.kr:11434/v1/chat/completions';
    //final String apiUrl = 'http://10.0.2.2:11434/v1/chat/completions';

    try {
      // HTTP POST 요청
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
        },
        body: json.encode({
          "model": "llama3.2:1b",
          "messages": [
            {
              "role": "user",
              "content": prompt+"라는 말에 대해 중세 상인처럼 대답해줘",
            }
          ]
        }),
      );

      // 응답 파싱
      if (response.statusCode == 200) {
        final responseData = json.decode(utf8.decode(response.bodyBytes));
        return responseData['choices']?[0]?['message']?['content'] ?? '응답이 비어있습니다.';
      } else {
        throw Exception('API 요청 실패: ${response.statusCode}\n응답 본문: ${utf8.decode(response.bodyBytes)}');
      }
    } catch (e) {
      print('Ollama API 호출 오류: $e');
      return '오류 발생: $e';
    }
  }

  // 메시지 전송
  void _sendMessage() async {
    final userMessage = _controller.text.trim(); // 사용자 입력 메시지 가져오기
    if (userMessage.isNotEmpty) {
      setState(() {
        _responseMessage = '응답을 기다리는 중...'; // 로딩 메시지 표시
      });

      try {
        // API 호출 및 응답 처리
        final response = await _generateScenario(userMessage);
        setState(() {
          _responseMessage = response; // 받은 응답을 화면에 표시
        });
      } catch (e) {
        setState(() {
          _responseMessage = '오류 발생: $e'; // 오류 처리
        });
      }

      _controller.clear(); // 입력 필드 초기화
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sollama Chat'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: '메시지를 입력하세요',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _sendMessage,
              child: Text('확인'),
            ),
            SizedBox(height: 16.0),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  _responseMessage,
                  style: TextStyle(fontSize: 16.0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
