import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String apiUrl =
      'https://api.spaceflightnewsapi.net/v4/articles/?limit=20';

  static Future<List<dynamic>> fetchNews() async {
    final response = await http.get(Uri.parse(apiUrl));
    if (response.statusCode == 200) {
      return json.decode(response.body)['results'];
    } else {
      throw Exception('Gagal memuat berita');
    }
  }
}
