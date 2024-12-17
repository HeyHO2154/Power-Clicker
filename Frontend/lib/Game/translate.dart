import 'dart:convert';
import 'package:http/http.dart' as http;

Future<String> translateText(String text, String sourceLang, String targetLang) async {
  final String apiUrl = 'http://ekaf.kro.kr:5000/translate';

  print("Translating: '$text' from $sourceLang to $targetLang");

  try {
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        "q": text,
        "source": sourceLang,
        "target": targetLang,
        "format": "text",
      }),
    );
    // UTF-8로 응답 본문 디코딩
    final decodedBody = utf8.decode(response.bodyBytes);
    print("허성준 API Response Body: $decodedBody");

    if (response.statusCode == 200) {
      final data = json.decode(decodedBody); // UTF-8로 디코딩된 JSON 문자열 파싱
      return data['translatedText']; // Map에서 translatedText 키에 접근
    } else {
      throw Exception('Failed to translate: ${response.statusCode}');
    }
  } catch (e) {
    print('Error: $e');
    return 'Translation Error';
  }
}

Future<String> detectInputLanguage(String text) async {
  final String apiUrl = 'http://ekaf.kro.kr:5000/translate';

  try {
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        "q": text,
        "source": "auto",
        "target": "en",
        "format": "text",
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      // 감지된 언어 가져오기
      final detectedLanguage = data['detectedLanguage']?['language'];

      return detectedLanguage ?? 'en'; // 감지된 언어가 없으면 'en' 반환
    } else {
      print('Language detection failed: ${response.statusCode}');
      return 'en';
    }
  } catch (e) {
    print('Error detecting language: $e');
    return 'en';
  }
}





