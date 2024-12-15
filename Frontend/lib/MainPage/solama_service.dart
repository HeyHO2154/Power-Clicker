import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ChatPage extends StatefulWidget {
  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  String _responseMessage = '';
  bool _isLoading = false;

  // 스트리밍 응답 처리 함수
  Future<void> _streamResponse(String prompt) async {
    final String apiUrl = 'http://ekaf.kro.kr:11434/v1/chat/completions';

    setState(() {
      _responseMessage = '';
      _isLoading = true;
    });

    try {
      // HTTP POST 요청 (스트리밍 요청)
      final request = http.Request('POST', Uri.parse(apiUrl))
        ..headers['Content-Type'] = 'application/json; charset=utf-8'
        ..body = json.encode({
          "model": "llama3.2:1b",
          "messages": [
            {"role": "user", "content": prompt}
          ],
          "stream": true // 스트리밍 활성화
        });

      final streamedResponse = await request.send();

      if (streamedResponse.statusCode == 200) {
        // 스트림에서 데이터를 한 줄씩 읽음
        streamedResponse.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .listen((line) {
          try {
            if (line.trim().isNotEmpty) {
              if (line.startsWith('data:')) {
                // 'data:' 접두사 제거
                final jsonString = line.substring(5).trim();

                // [DONE] 처리
                if (jsonString == '[DONE]') {
                  print('스트리밍 완료');
                  return;
                }

                // JSON 디코딩
                final decodedLine = json.decode(jsonString);
                final content = decodedLine['choices']?[0]?['delta']?['content'] ?? '';

                // 화면 업데이트
                setState(() {
                  _responseMessage += content;
                });
              }
            }
          } catch (e) {
            print('JSON 디코딩 오류: $e\n받은 데이터: $line');
          }
        }, onDone: () {
          setState(() {
            _isLoading = false;
          });
          print('스트리밍 완료');
        }, onError: (error) {
          setState(() {
            _responseMessage = '오류 발생: $error';
            _isLoading = false;
          });
        });


      } else {
        throw Exception(
            '스트리밍 요청 실패: ${streamedResponse.statusCode}\n응답 본문: ${await streamedResponse.stream.bytesToString()}');
      }
    } catch (e) {
      setState(() {
        _responseMessage = '오류 발생: $e';
        _isLoading = false;
      });
    }
  }

  // 메시지 전송
  void _sendMessage() {
    final userMessage = _controller.text.trim();
    if (userMessage.isNotEmpty) {
      _streamResponse(userMessage); // 스트리밍 응답 호출
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sollama Chat (Streaming)'),
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
              onPressed: _isLoading ? null : _sendMessage,
              child: Text(_isLoading ? '응답 대기 중...' : '확인'),
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
