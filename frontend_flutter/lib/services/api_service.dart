import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';

class ApiService {
  // Change this to your backend URL
  /*static const String baseUrl =
      "http://10.0.2.2:8080";*/ // Use 10.0.2.2 for Android emulator

  static const String _emulatorUrl = "http://10.0.2.2:8080";
<<<<<<< HEAD
  static const String _physicalUrl = "http://192.168.1.10:8080";
=======
  static const String _physicalUrl = "http://192.168.1.13:8080";
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe

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

  static Future<Map<String, dynamic>> updateProfile({
    required String token,
    required Map<String, dynamic> data,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/profile/me'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": 'Bearer $token',
      },
      body: jsonEncode(data),
    );

    return _decodeResponse(response);
  }

<<<<<<< HEAD
=======
  static Future<Map<String, dynamic>> getMyAddresses({
    required String token,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/profile/addresses'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": 'Bearer $token',
      },
    );

    return _decodeResponse(response);
  }

  static Future<Map<String, dynamic>> createMyAddress({
    required String token,
    required Map<String, dynamic> data,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/profile/addresses'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": 'Bearer $token',
      },
      body: jsonEncode(data),
    );

    return _decodeResponse(response);
  }

  static Future<Map<String, dynamic>> updateMyAddress({
    required String token,
    required int addressId,
    required Map<String, dynamic> data,
  }) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/api/profile/addresses/$addressId'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": 'Bearer $token',
      },
      body: jsonEncode(data),
    );

    return _decodeResponse(response);
  }

  static Future<Map<String, dynamic>> deleteMyAddress({
    required String token,
    required int addressId,
  }) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/profile/addresses/$addressId'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": 'Bearer $token',
      },
    );

    return _decodeResponse(response);
  }

  static Future<Map<String, dynamic>> setPrimaryMyAddress({
    required String token,
    required int addressId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/profile/addresses/$addressId/primary'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": 'Bearer $token',
      },
      body: jsonEncode(<String, dynamic>{}),
    );

    return _decodeResponse(response);
  }

>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
  static Future<Map<String, dynamic>> changePassword({
    required String token,
    required String currentPassword,
    required String newPassword,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/change-password'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": 'Bearer $token',
      },
      body: jsonEncode({
        'current_password': currentPassword,
        'new_password': newPassword,
      }),
    );

    return _decodeResponse(response);
  }

<<<<<<< HEAD
  static Future<Map<String, dynamic>> getTradespeople(
    String token, {
    String? search,
    String? category,
    bool onDutyOnly = false,
  }) async {
    final query = <String, String>{};
    if (search != null && search.trim().isNotEmpty) {
      query['search'] = search.trim();
    }
    if (category != null && category.trim().isNotEmpty) {
      query['category'] = category.trim();
    }
    if (onDutyOnly) {
      query['on_duty'] = 'true';
=======
  static Future<Map<String, dynamic>> getTradespeople({
    required String token,
    String? search,
    String? category,
    bool? onDuty,
  }) async {
    final params = <String, String>{};
    if (search != null && search.trim().isNotEmpty) {
      params['search'] = search.trim();
    }
    if (category != null && category.trim().isNotEmpty) {
      params['category'] = category.trim();
    }
    if (onDuty != null) {
      params['on_duty'] = onDuty.toString();
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
    }

    final uri = Uri.parse(
      '$baseUrl/api/tradespeople',
<<<<<<< HEAD
    ).replace(queryParameters: query.isEmpty ? null : query);

    final response = await http.get(uri, headers: _authorizedHeaders(token));

    return _decodeResponse(response);
  }

  static Future<Map<String, dynamic>> getBookings(
    String token, {
    String? status,
  }) async {
    final query = <String, String>{};
    if (status != null && status.trim().isNotEmpty) {
      query['status'] = status.trim();
    }

    final uri = Uri.parse(
      '$baseUrl/api/bookings',
    ).replace(queryParameters: query.isEmpty ? null : query);

    final response = await http.get(uri, headers: _authorizedHeaders(token));
=======
    ).replace(queryParameters: params.isEmpty ? null : params);

    final response = await http.get(
      uri,
      headers: {
        "Content-Type": "application/json",
        "Authorization": 'Bearer $token',
      },
    );
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe

    return _decodeResponse(response);
  }

  static Future<Map<String, dynamic>> createBooking({
    required String token,
<<<<<<< HEAD
    required int tradespersonUserId,
    required String trade,
    required String specialization,
    required String problemDescription,
    required String address,
    required String date,
    required String time,
    required double offeredBudget,
    String urgency = 'Medium',
    String barangay = '',
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/bookings'),
      headers: _authorizedHeaders(token),
      body: jsonEncode({
        'tradesperson_user_id': tradespersonUserId,
        'trade': trade,
        'specialization': specialization,
        'problem_description': problemDescription,
        'address': address,
        'barangay': barangay,
        'date': date,
        'time': time,
        'offered_budget': offeredBudget,
        'urgency': urgency,
      }),
=======
    required Map<String, dynamic> data,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/bookings'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": 'Bearer $token',
      },
      body: jsonEncode(data),
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
    );

    return _decodeResponse(response);
  }

<<<<<<< HEAD
  static Future<Map<String, dynamic>> updateBookingStatus({
    required String token,
    required int bookingId,
    required String status,
  }) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/api/bookings/$bookingId/status'),
      headers: _authorizedHeaders(token),
      body: jsonEncode({'status': status}),
=======
  static Future<Map<String, dynamic>> getHomeownerBookings({
    required String token,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/bookings/homeowner'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": 'Bearer $token',
      },
    );

    return _decodeResponse(response);
  }

  static Future<Map<String, dynamic>> getBookingById({
    required String token,
    required int bookingId,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/bookings/$bookingId'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": 'Bearer $token',
      },
    );

    return _decodeResponse(response);
  }

  static Future<Map<String, dynamic>> updateBooking({
    required String token,
    required int bookingId,
    required Map<String, dynamic> data,
  }) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/api/bookings/$bookingId'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": 'Bearer $token',
      },
      body: jsonEncode(data),
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
    );

    return _decodeResponse(response);
  }

<<<<<<< HEAD
  static Future<Map<String, dynamic>> getConversations(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/conversations'),
      headers: _authorizedHeaders(token),
    );

    return _decodeResponse(response);
  }

  static Future<Map<String, dynamic>> ensureConversation({
    required String token,
    required String counterpartUserId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/conversations'),
      headers: _authorizedHeaders(token),
      body: jsonEncode({
        'counterpart_user_id': int.tryParse(counterpartUserId) ?? 0,
      }),
=======
  static Future<Map<String, dynamic>> cancelBooking({
    required String token,
    required int bookingId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/bookings/$bookingId/cancel'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": 'Bearer $token',
      },
      body: jsonEncode(<String, dynamic>{}),
    );

    return _decodeResponse(response);
  }

  static Future<Map<String, dynamic>> submitBookingReview({
    required String token,
    required int bookingId,
    required double rating,
    String comment = '',
    List<String> tags = const [],
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/bookings/$bookingId/review'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": 'Bearer $token',
      },
      body: jsonEncode({'rating': rating, 'comment': comment, 'tags': tags}),
    );

    return _decodeResponse(response);
  }

  static Future<Map<String, dynamic>> reportBookingIssue({
    required String token,
    required int bookingId,
    required String category,
    required String details,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/bookings/$bookingId/issues'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": 'Bearer $token',
      },
      body: jsonEncode({'category': category, 'details': details}),
    );

    return _decodeResponse(response);
  }

  static Future<Map<String, dynamic>> updateMyOnDutyStatus({
    required String token,
    required bool isOnDuty,
  }) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/api/tradespeople/me/on-duty'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": 'Bearer $token',
      },
      body: jsonEncode({'is_on_duty': isOnDuty}),
    );

    return _decodeResponse(response);
  }

  static Future<Map<String, dynamic>> getIncomingRequests({
    required String token,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/requests/incoming'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": 'Bearer $token',
      },
    );

    return _decodeResponse(response);
  }

  static Future<Map<String, dynamic>> acceptRequest({
    required String token,
    required int requestId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/requests/$requestId/accept'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": 'Bearer $token',
      },
      body: jsonEncode(<String, dynamic>{}),
    );

    return _decodeResponse(response);
  }

  static Future<Map<String, dynamic>> declineRequest({
    required String token,
    required int requestId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/requests/$requestId/decline'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": 'Bearer $token',
      },
      body: jsonEncode(<String, dynamic>{}),
    );

    return _decodeResponse(response);
  }

  static Future<Map<String, dynamic>> getTradespersonJobs({
    required String token,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/jobs/tradesperson'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": 'Bearer $token',
      },
    );

    return _decodeResponse(response);
  }

  static Future<Map<String, dynamic>> getTradespersonJobById({
    required String token,
    required int jobId,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/jobs/$jobId'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": 'Bearer $token',
      },
    );

    return _decodeResponse(response);
  }

  static Future<Map<String, dynamic>> startJob({
    required String token,
    required int jobId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/jobs/$jobId/start'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": 'Bearer $token',
      },
      body: jsonEncode(<String, dynamic>{}),
    );

    return _decodeResponse(response);
  }

  static Future<Map<String, dynamic>> completeJob({
    required String token,
    required int jobId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/jobs/$jobId/complete'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": 'Bearer $token',
      },
      body: jsonEncode(<String, dynamic>{}),
    );

    return _decodeResponse(response);
  }

  static Future<Map<String, dynamic>> getMyTradespersonReviews({
    required String token,
    int? rating,
    String? sort,
    String? tag,
  }) async {
    final params = <String, String>{};
    if (rating != null && rating >= 1 && rating <= 5) {
      params['rating'] = rating.toString();
    }
    if (sort != null && sort.trim().isNotEmpty) {
      params['sort'] = sort.trim();
    }
    if (tag != null && tag.trim().isNotEmpty) {
      params['tag'] = tag.trim();
    }

    final uri = Uri.parse(
      '$baseUrl/api/reviews/tradesperson/me',
    ).replace(queryParameters: params.isEmpty ? null : params);

    final response = await http.get(
      uri,
      headers: {
        "Content-Type": "application/json",
        "Authorization": 'Bearer $token',
      },
    );

    return _decodeResponse(response);
  }

  static Future<Map<String, dynamic>> getMyVerificationDocuments({
    required String token,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/tradespeople/me/documents'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": 'Bearer $token',
      },
    );

    return _decodeResponse(response);
  }

  static Future<Map<String, dynamic>> replaceMyVerificationDocument({
    required String token,
    required int documentId,
    required File file,
  }) async {
    final request =
        http.MultipartRequest(
            'POST',
            Uri.parse(
              '$baseUrl/api/tradespeople/me/documents/$documentId/replace',
            ),
          )
          ..headers['Authorization'] = 'Bearer $token'
          ..files.add(await http.MultipartFile.fromPath('document', file.path));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    return _decodeResponse(response);
  }

  static Future<Map<String, dynamic>> getMyServiceArea({
    required String token,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/tradespeople/me/service-area'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": 'Bearer $token',
      },
    );

    return _decodeResponse(response);
  }

  static Future<Map<String, dynamic>> saveMyServiceArea({
    required String token,
    required List<String> barangays,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/tradespeople/me/service-area'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": 'Bearer $token',
      },
      body: jsonEncode({'barangays': barangays}),
    );

    return _decodeResponse(response);
  }

  static Future<Map<String, dynamic>> getMyTradeSkills({
    required String token,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/tradespeople/me/trade-skills'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": 'Bearer $token',
      },
    );

    return _decodeResponse(response);
  }

  static Future<Map<String, dynamic>> saveMyTradeSkills({
    required String token,
    required Map<String, dynamic> data,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/tradespeople/me/trade-skills'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": 'Bearer $token',
      },
      body: jsonEncode(data),
    );

    return _decodeResponse(response);
  }

  static Future<Map<String, dynamic>> getConversations({
    required String token,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/conversations'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
    );

    return _decodeResponse(response);
  }

  static Future<Map<String, dynamic>> getConversationMessages({
    required String token,
<<<<<<< HEAD
    required String conversationId,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/conversations/$conversationId/messages'),
      headers: _authorizedHeaders(token),
=======
    required int conversationId,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/conversations/$conversationId/messages'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
    );

    return _decodeResponse(response);
  }

  static Future<Map<String, dynamic>> sendConversationMessage({
    required String token,
<<<<<<< HEAD
    required String conversationId,
=======
    required int conversationId,
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
    required String text,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/conversations/$conversationId/messages'),
<<<<<<< HEAD
      headers: _authorizedHeaders(token),
=======
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
      body: jsonEncode({'text': text}),
    );

    return _decodeResponse(response);
  }

<<<<<<< HEAD
  static Future<Map<String, dynamic>> deleteConversation({
    required String token,
    required String conversationId,
  }) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/conversations/$conversationId'),
      headers: _authorizedHeaders(token),
=======
  static Future<Map<String, dynamic>> sendConversationAttachment({
    required String token,
    required int conversationId,
    required String filePath,
    String? filename,
  }) async {
    final request =
        http.MultipartRequest(
            'POST',
            Uri.parse('$baseUrl/api/conversations/$conversationId/attachments'),
          )
          ..headers['Authorization'] = 'Bearer $token'
          ..files.add(
            await http.MultipartFile.fromPath(
              'attachment',
              filePath,
              filename: filename,
            ),
          );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    return _decodeResponse(response);
  }

  static Future<Map<String, dynamic>> deleteConversation({
    required String token,
    required int conversationId,
  }) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/conversations/$conversationId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
    );

    return _decodeResponse(response);
  }

<<<<<<< HEAD
  static Map<String, String> _authorizedHeaders(String token) => {
    "Content-Type": "application/json",
    "Authorization": 'Bearer $token',
  };

  static Map<String, dynamic> _decodeResponse(http.Response response) {
    final responseBody = response.body.isNotEmpty
        ? jsonDecode(response.body) as Map<String, dynamic>
        : <String, dynamic>{};
=======
  static Future<Map<String, dynamic>> archiveConversation({
    required String token,
    required int conversationId,
    required bool archived,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/conversations/$conversationId/archive'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'archived': archived}),
    );

    return _decodeResponse(response);
  }

  static Future<Map<String, dynamic>> muteConversation({
    required String token,
    required int conversationId,
    required bool muted,
    int durationHours = 24 * 30,
  }) async {
    final payload = <String, dynamic>{'muted': muted};
    if (muted && durationHours > 0) {
      payload['durationHours'] = durationHours;
    }

    final response = await http.post(
      Uri.parse('$baseUrl/api/conversations/$conversationId/mute'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(payload),
    );

    return _decodeResponse(response);
  }

  static Future<Map<String, dynamic>> markConversationRead({
    required String token,
    required int conversationId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/conversations/$conversationId/read'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(<String, dynamic>{}),
    );

    return _decodeResponse(response);
  }

  static Map<String, dynamic> _decodeResponse(http.Response response) {
    Map<String, dynamic> responseBody = <String, dynamic>{};
    final raw = response.body;

    if (raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          responseBody = decoded;
        } else {
          responseBody = <String, dynamic>{'data': decoded};
        }
      } catch (_) {
        responseBody = <String, dynamic>{'message': raw};
      }
    }
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return responseBody;
    }

    throw HttpException(
<<<<<<< HEAD
      responseBody['message']?.toString() ?? 'Request failed',
=======
      responseBody['message']?.toString() ??
          'Request failed (${response.statusCode})',
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
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
