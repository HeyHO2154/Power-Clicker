import 'dart:convert';
import 'package:http/http.dart' as http;

class SolamaService {
  static const String apiUrl = 'http://ekaf.kro.kr:11434/v1/chat/completions';

  // 대화 히스토리 저장 - 최초 메시지
  static List<Map<String, String>> messages = [
    {"role": "system", "content": "You are helpful assistant."}
  ];

  // 스트리밍 응답 처리 함수
  static Future<void> streamResponse({
    required String prompt,
    required Function(String content) onContentReceived,
    required Function() onComplete,
    required Function(String error) onError,
  }) async {
    try {
      // 사용자의 메시지를 히스토리에 추가
      messages.add({"role": "user", "content": "$prompt (Please respond with fewer than 20 characters)"});

      // 스트리밍 데이터를 임시로 저장할 변수
      String assistantResponse = '';

      final request = http.Request('POST', Uri.parse(apiUrl))
        ..headers['Content-Type'] = 'application/json; charset=utf-8'
        ..body = json.encode({
          "model": "llama3.2:1b",
          //"messages": messages, // 히스토리를 포함한 요청
          //일단 임시로 1문장씩 오가는걸로 하자. 라즈베리파이가 버거워함
          "messages": [
            {"role": "user", "content": "$prompt (Please respond with fewer than 20 characters)"}
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
                // 스트리밍 완료 후 AI 응답을 하나의 메시지로 저장
                messages.add({"role": "assistant", "content": assistantResponse.trim()});
                // 오래된 메시지 정리 (최대 10개 메시지 유지)
                if (messages.length > 5) {
                  messages.removeAt(1); // 최초 메시지를 제외하고 첫 번째 메시지 삭제
                }
                print("대화");
                print(messages);
                onComplete();
                return;
              }

              final decodedLine = json.decode(jsonString);
              final content = decodedLine['choices']?[0]?['delta']?['content'] ?? '';

              // 스트리밍 데이터를 합침
              assistantResponse += content;

              onContentReceived(content);
            }
          } catch (e) {
            onError('[ She went to toilet for a while.. come back later ]');
          }
        }, onDone: onComplete, onError: (error) {
          onError('[ She went to toilet for a while.. come back later ]');
        });
      } else {
        onError('[ She went to toilet for a while.. come back later ]');
      }
    } catch (e) {
      onError('[ She went to toilet for a while.. ] \n (AI server is currently unavailable)');
    }
  }
}
