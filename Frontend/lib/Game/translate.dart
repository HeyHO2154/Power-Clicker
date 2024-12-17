import 'dart:convert';
import 'package:http/http.dart' as http;

Future<String> translateText(String text, String sourceLang, String targetLang) async {
  final String apiUrl = 'http://ekaf.kro.kr:5000/translate';

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

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['translatedText'];
    } else {
      throw Exception('Failed to translate: ${response.statusCode}');
    }
  } catch (e) {
    print('Error: $e');
    return 'Translation Error';
  }
}
