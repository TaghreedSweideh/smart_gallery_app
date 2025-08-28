import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  final String baseUrl = "https://example.com/api"; // غيّري الرابط

  Future<String?> getUserId() async {
    final response = await http.get(Uri.parse('$baseUrl/get-user-id'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['id'].toString(); // يفترض أن السيرفر يرجع {"id": "12345"}
    } else {
      return null;
    }
  }
}
