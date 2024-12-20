import 'dart:convert';
import 'package:http/http.dart' as http;

class SolamaService {
  List<Map<String, String>> messages;

  final String apiUrl = 'http://ekaf.kro.kr:11434/v1/chat/completions';

  // 생성자를 통해 초기 메시지를 설정할 수 있도록 변경
  SolamaService({String role = "You are helpful AI. Please respond with fewer than 20 characters."})
      : messages = [
    {"role": "system", "content": role}
  ];

  Future<void> streamResponse({
    required String prompt,
    required Function(String content) onContentReceived,
    required Function() onComplete,
    required Function(String error) onError,
  }) async {
    try {
      messages.add({"role": "user", "content": prompt});

      String assistantResponse = '';

      final request = http.Request('POST', Uri.parse(apiUrl))
        ..headers['Content-Type'] = 'application/json; charset=utf-8'
        ..body = json.encode({
          "model": "llama3.2:1b",
          "messages": messages,
          "stream": true
        });

      print(messages);
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
                messages.add({"role": "assistant", "content": assistantResponse.trim()});
                if (messages.length > 5) {
                  messages.removeAt(1);
                  messages.removeAt(2);
                }
                onComplete();
                return;
              }

              final decodedLine = json.decode(jsonString);
              final content = decodedLine['choices']?[0]?['delta']?['content'] ?? '';
              assistantResponse += content;
              onContentReceived(content);
            }
          } catch (e) {
            onError('[Error processing response]');
          }
        }, onDone: onComplete, onError: (error) {
          onError('[Error streaming response]');
        });
      } else {
        onError('[Server error]');
      }
    } catch (e) {
      onError('[AI server unavailable]');
    }
  }
}
