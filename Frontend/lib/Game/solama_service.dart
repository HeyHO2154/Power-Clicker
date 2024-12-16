import 'dart:convert';
import 'package:http/http.dart' as http;

class SolamaService {
  static const String apiUrl = 'http://ekaf.kro.kr:11434/v1/chat/completions';

  // 스트리밍 응답 처리 함수
  static Future<void> streamResponse({
    required String prompt,
    required Function(String content) onContentReceived,
    required Function() onComplete,
    required Function(String error) onError,
  }) async {
    try {
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
        streamedResponse.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .listen((line) {
          try {
            if (line.trim().isNotEmpty && line.startsWith('data:')) {
              final jsonString = line.substring(5).trim();

              if (jsonString == '[DONE]') {
                onComplete();
                return;
              }

              final decodedLine = json.decode(jsonString);
              final content = decodedLine['choices']?[0]?['delta']?['content'] ?? '';
              onContentReceived(content);
            }
          } catch (e) {
            onError('JSON 디코딩 오류: $e\n받은 데이터: $line');
          }
        }, onDone: onComplete, onError: (error) {
          onError('오류 발생: $error');
        });
      } else {
        onError('스트리밍 요청 실패: ${streamedResponse.statusCode}');
      }
    } catch (e) {
      onError('오류 발생: $e');
    }
  }
}
