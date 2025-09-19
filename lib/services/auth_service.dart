import 'package:http/http.dart' as http;

class AuthService {
  static Future<bool> login(String email, String password) async {
    final response = await http.post(
      Uri.parse("https://yourapi.com/login"),
      body: {"email": email, "password": password},
    );
    return response.statusCode == 200;
  }
}
