import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Change this to your backend URL
  static const String baseUrl =
      "http://10.0.2.2:8080"; // Use 10.0.2.2 for Android emulator

  // REGISTER
  static Future<Map<String, dynamic>> registerUser({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/register"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "name": name,
        "email": email,
        "password": password,
        "role": role,
      }),
    );

    return jsonDecode(response.body);
  }

  // LOGIN
  static Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "password": password}),
    );

    return jsonDecode(response.body);
  }

  // GET PROFILE (Protected)
  static Future<Map<String, dynamic>> getProfile(String token) async {
    final response = await http.get(
      Uri.parse("$baseUrl/api/profile"),
      headers: {"Content-Type": "application/json", "Authorization": token},
    );

    return jsonDecode(response.body);
  }
}
