import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';

class ApiService {
  // Change this to your backend URL
  /*static const String baseUrl =
      "http://10.0.2.2:8080";*/ // Use 10.0.2.2 for Android emulator

  static const String _emulatorUrl = "http://10.0.2.2:8080";
  static const String _physicalUrl = "http://192.168.1.15:8080";

  static String baseUrl = _emulatorUrl; // safe default

  static Future<void> initialize() async {
    if (Platform.isAndroid) {
      final info = await DeviceInfoPlugin().androidInfo;
      baseUrl = info.isPhysicalDevice ? _physicalUrl : _emulatorUrl;
    } else {
      baseUrl = _physicalUrl;
    }
  }

  // LOGIN
  static Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "password": password}),
    );

    return _decodeResponse(response);
  }

  // HOMEOWNER REGISTER
  static Future<Map<String, dynamic>> registerHomeowner({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String barangay,
    required String password,
    required String idType,
    required File idDocument,
  }) async {
    final request =
        http.MultipartRequest(
            'POST',
            Uri.parse('$baseUrl/api/auth/homeowners/register'),
          )
          ..fields['first_name'] = firstName
          ..fields['last_name'] = lastName
          ..fields['email'] = email
          ..fields['phone'] = phone
          ..fields['barangay'] = barangay
          ..fields['password'] = password
          ..fields['id_type'] = idType
          ..files.add(
            await http.MultipartFile.fromPath('id_document', idDocument.path),
          );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    return _decodeResponse(response);
  }

  // TRADESPERSON REGISTER
  static Future<Map<String, dynamic>> registerTradesperson({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
    required String tradeCategory,
    required int yearsExperience,
    required String serviceBarangay,
    required String bio,
    required String governmentIdType,
    required File governmentIdDocument,
    required String licenseType,
    required File licenseDocument,
  }) async {
    final request =
        http.MultipartRequest(
            'POST',
            Uri.parse('$baseUrl/api/auth/tradespeople/register'),
          )
          ..fields['first_name'] = firstName
          ..fields['last_name'] = lastName
          ..fields['email'] = email
          ..fields['phone'] = phone
          ..fields['password'] = password
          ..fields['trade_category'] = tradeCategory
          ..fields['years_experience'] = yearsExperience.toString()
          ..fields['service_barangay'] = serviceBarangay
          ..fields['bio'] = bio
          ..fields['government_id_type'] = governmentIdType
          ..fields['license_type'] = licenseType
          ..files.add(
            await http.MultipartFile.fromPath(
              'government_id_document',
              governmentIdDocument.path,
            ),
          )
          ..files.add(
            await http.MultipartFile.fromPath(
              'license_document',
              licenseDocument.path,
            ),
          );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    return _decodeResponse(response);
  }

  // GET PROFILE (Protected)
  static Future<Map<String, dynamic>> getProfile(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/profile/me'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": 'Bearer $token',
      },
    );

    return _decodeResponse(response);
  }

  static Future<Map<String, dynamic>> uploadProfileImage({
    required String token,
    required File image,
  }) async {
    final request =
        http.MultipartRequest('POST', Uri.parse('$baseUrl/api/profile/photo'))
          ..headers['Authorization'] = 'Bearer $token'
          ..files.add(
            await http.MultipartFile.fromPath('profile_image', image.path),
          );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return _decodeResponse(response);
  }

  static Map<String, dynamic> _decodeResponse(http.Response response) {
    final responseBody = response.body.isNotEmpty
        ? jsonDecode(response.body) as Map<String, dynamic>
        : <String, dynamic>{};

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return responseBody;
    }

    throw HttpException(
      responseBody['message']?.toString() ?? 'Request failed',
    );
  }

  static Future<void> forgotPassword({required String email}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/forgot-password'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email}),
    );
    _decodeResponse(response);
  }

  static Future<void> verifyResetCode({
    required String email,
    required String otp,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/verify-reset-code'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "otp": otp}),
    );
    _decodeResponse(response);
  }

  static Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/reset-password'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
        "otp": otp,
        "new_password": newPassword,
      }),
    );
    _decodeResponse(response);
  }
}
