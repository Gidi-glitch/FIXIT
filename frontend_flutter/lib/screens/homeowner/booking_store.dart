<<<<<<< HEAD
/// Simple static store that acts as the shared in-memory booking list.
/// BookingFormScreen writes here; BookingsScreen reads from here.
/// Replace with a proper state-management solution (Riverpod/Provider)
/// once you wire up the Go backend.
library;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/api_service.dart';

class BookingModel {
  final String id;
  final String tradespersonName;
  final String tradespersonAvatar;
=======
import 'package:flutter/foundation.dart';

class BookingModel {
  final int id;
  final String referenceId;
  final String tradespersonName;
  final String tradespersonAvatar;
  final String? tradespersonProfileImageUrl;
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
  final String trade;
  final String specialization;
  final String problemDescription;
  final String address;
  final String date;
  final String time;
  final double offeredBudget;
<<<<<<< HEAD
  final String
  status; // 'Pending' | 'Accepted' | 'In Progress' | 'Completed' | 'Under Review' | 'Disputed' | 'Cancelled'
  final DateTime createdAt;
  final bool isReviewed; // New field for review tracking
  final double? reviewRating; // Rating given by homeowner
  final String? reviewComment; // Comment given by homeowner
  final List<String> reviewTags; // Quick feedback tags

  const BookingModel({
    required this.id,
    required this.tradespersonName,
    required this.tradespersonAvatar,
=======
  final String status;
  final DateTime createdAt;
  final bool isReviewed;
  final double? reviewRating;
  final String? reviewComment;
  final List<String> reviewTags;

  const BookingModel({
    required this.id,
    required this.referenceId,
    required this.tradespersonName,
    required this.tradespersonAvatar,
    this.tradespersonProfileImageUrl,
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
    required this.trade,
    required this.specialization,
    required this.problemDescription,
    required this.address,
    required this.date,
    required this.time,
    required this.offeredBudget,
    required this.status,
    required this.createdAt,
    this.isReviewed = false,
    this.reviewRating,
    this.reviewComment,
    this.reviewTags = const [],
  });

<<<<<<< HEAD
  BookingModel copyWith({
=======
  factory BookingModel.fromApi(Map<String, dynamic> json) {
    final id = _asInt(json['id']);
    final referenceId = _asString(json['reference_id']).isNotEmpty
        ? _asString(json['reference_id'])
        : 'BK-${id.toString().padLeft(6, '0')}';

    final tagsRaw = json['review_tags'];
    final tags = <String>[];
    if (tagsRaw is List) {
      for (final item in tagsRaw) {
        final value = item.toString().trim();
        if (value.isNotEmpty) {
          tags.add(value);
        }
      }
    }

    return BookingModel(
      id: id,
      referenceId: referenceId,
      tradespersonName: _asString(json['tradesperson_name']),
      tradespersonAvatar: _asString(json['tradesperson_avatar']).isNotEmpty
          ? _asString(json['tradesperson_avatar'])
          : 'TP',
      tradespersonProfileImageUrl: _asNullableString(
        json['tradesperson_profile_image_url'],
      ),
      trade: _asString(json['trade']).isNotEmpty
          ? _asString(json['trade'])
          : _asString(json['trade_category']),
      specialization: _asString(json['specialization']),
      problemDescription: _asString(json['problem_description']).isNotEmpty
          ? _asString(json['problem_description'])
          : _asString(json['problemDescription']),
      address: _asString(json['address']),
      date: _asString(json['date']),
      time: _asString(json['time']),
      offeredBudget: _asDouble(json['offered_budget']) > 0
          ? _asDouble(json['offered_budget'])
          : _asDouble(json['offeredBudget']),
      status: _asString(json['status']).isNotEmpty
          ? _asString(json['status'])
          : 'Pending',
      createdAt: _asDateTime(json['created_at']) ?? DateTime.now(),
      isReviewed: _asBool(json['is_reviewed']) || _asBool(json['isReviewed']),
      reviewRating: _asNullableDouble(json['review_rating']),
      reviewComment: _asNullableString(json['review_comment']),
      reviewTags: tags,
    );
  }

  BookingModel copyWith({
    String? referenceId,
    String? tradespersonName,
    String? tradespersonAvatar,
    String? tradespersonProfileImageUrl,
    String? trade,
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
    String? specialization,
    String? problemDescription,
    String? address,
    String? date,
    String? time,
    double? offeredBudget,
    String? status,
<<<<<<< HEAD
=======
    DateTime? createdAt,
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
    bool? isReviewed,
    double? reviewRating,
    String? reviewComment,
    List<String>? reviewTags,
  }) {
    return BookingModel(
      id: id,
<<<<<<< HEAD
      tradespersonName: tradespersonName,
      tradespersonAvatar: tradespersonAvatar,
      trade: trade,
=======
      referenceId: referenceId ?? this.referenceId,
      tradespersonName: tradespersonName ?? this.tradespersonName,
      tradespersonAvatar: tradespersonAvatar ?? this.tradespersonAvatar,
      tradespersonProfileImageUrl:
          tradespersonProfileImageUrl ?? this.tradespersonProfileImageUrl,
      trade: trade ?? this.trade,
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
      specialization: specialization ?? this.specialization,
      problemDescription: problemDescription ?? this.problemDescription,
      address: address ?? this.address,
      date: date ?? this.date,
      time: time ?? this.time,
      offeredBudget: offeredBudget ?? this.offeredBudget,
      status: status ?? this.status,
<<<<<<< HEAD
      createdAt: createdAt,
=======
      createdAt: createdAt ?? this.createdAt,
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
      isReviewed: isReviewed ?? this.isReviewed,
      reviewRating: reviewRating ?? this.reviewRating,
      reviewComment: reviewComment ?? this.reviewComment,
      reviewTags: reviewTags ?? this.reviewTags,
    );
  }
}

class BookingIssueReport {
  final String id;
<<<<<<< HEAD
  final String bookingId;
=======
  final int bookingId;
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
  final String category;
  final String details;
  final DateTime createdAt;
  final String status;

  const BookingIssueReport({
    required this.id,
    required this.bookingId,
    required this.category,
    required this.details,
    required this.createdAt,
    this.status = 'Open',
  });
}

class BookingStore {
  BookingStore._();

<<<<<<< HEAD
  static final ValueNotifier<int> notifier = ValueNotifier<int>(0);
  static int _mutationToken = 0;
  static bool _isSyncing = false;
  static final Set<String> _backendIds = <String>{};

  static final List<BookingModel> _bookings = [
    // Pre-loaded sample data (mirrors dashboard mock data)
    BookingModel(
      id: 'BK-001',
      tradespersonName: 'Juan Dela Cruz',
      tradespersonAvatar: 'JD',
      trade: 'Plumbing',
      specialization: 'Pipe Repair & Installation',
      problemDescription: 'Pipe leak under the kitchen sink.',
      address: 'Blk 4 Lot 12, Dayap, Calauan',
      date: 'Today',
      time: '2:00 PM',
      offeredBudget: 500,
      status: 'In Progress',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    BookingModel(
      id: 'BK-002',
      tradespersonName: 'Maria Santos',
      tradespersonAvatar: 'MS',
      trade: 'Electrical',
      specialization: 'Wiring & Panel Upgrades',
      problemDescription: 'Electrical wiring check for the living room.',
      address: 'Blk 2 Lot 5, Hanggan, Calauan',
      date: 'Tomorrow',
      time: '9:00 AM',
      offeredBudget: 800,
      status: 'Accepted',
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    BookingModel(
      id: 'BK-003',
      tradespersonName: 'Pedro Reyes',
      tradespersonAvatar: 'PR',
      trade: 'HVAC',
      specialization: 'AC Maintenance & Repair',
      problemDescription: 'AC unit not cooling properly.',
      address: 'Blk 7 Lot 3, Imok, Calauan',
      date: 'Mar 25',
      time: '10:00 AM',
      offeredBudget: 1200,
      status: 'Pending',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    BookingModel(
      id: 'BK-004',
      tradespersonName: 'Antonio Lim',
      tradespersonAvatar: 'AL',
      trade: 'Carpentry',
      specialization: 'Cabinet Repair & Installation',
      problemDescription: 'Kitchen cabinet hinge replacement and alignment.',
      address: 'Blk 5 Lot 9, Dayap, Calauan',
      date: 'Mar 20',
      time: '1:30 PM',
      offeredBudget: 650,
      status: 'Completed',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
  ];

  static List<BookingModel> get all => List.unmodifiable(_bookings);
  static int get mutationToken => _mutationToken;
  static final List<BookingIssueReport> _issueReports = [];
=======
  static final List<BookingModel> _bookings = [];
  static final List<BookingIssueReport> _issueReports = [];
  static final ValueNotifier<int> notifier = ValueNotifier<int>(0);

  static List<BookingModel> get all => List.unmodifiable(_bookings);
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe

  static List<BookingIssueReport> get issueReports =>
      List.unmodifiable(_issueReports);

<<<<<<< HEAD
  static void add(BookingModel booking) {
    _bookings.insert(0, booking);
    _notify();
  }

  static void upsertBackendBooking(BookingModel booking) {
    final index = _bookings.indexWhere((b) => b.id == booking.id);
    if (index == -1) {
      _bookings.insert(0, booking);
    } else {
      _bookings[index] = booking;
    }
    _backendIds.add(booking.id);
    _notify();
  }

  static void replaceBackendBookings(List<BookingModel> bookings) {
    _bookings.removeWhere((booking) => _backendIds.contains(booking.id));
    _backendIds
      ..clear()
      ..addAll(bookings.map((booking) => booking.id));
    _bookings.insertAll(0, bookings);
    _notify();
  }

  static Future<void> syncFromBackend() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token')?.trim();
      if (token == null || token.isEmpty) return;

      final result = await ApiService.getBookings(token);
      final rows =
          (result['bookings'] as List? ?? const <dynamic>[])
              .whereType<Map>()
              .map((row) => fromBackendRow(row.cast<String, dynamic>()))
              .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      replaceBackendBookings(rows);
    } catch (_) {
      // Keep current in-memory data when sync fails.
    } finally {
      _isSyncing = false;
    }
  }

  static void updateStatus(String id, String status) {
=======
  static void setAllFromApi(List<dynamic> rows) {
    _bookings
      ..clear()
      ..addAll(
        rows
            .whereType<Map>()
            .map((row) => BookingModel.fromApi(row.cast<String, dynamic>())),
      );
    _sortByCreatedAt();
    _notify();
  }

  static void upsertFromApi(Map<String, dynamic> row) {
    final booking = BookingModel.fromApi(row);
    replaceBooking(booking);
  }

  static void add(BookingModel booking) {
    replaceBooking(booking);
  }

  static void replaceBooking(BookingModel booking) {
    final index = _bookings.indexWhere((b) => b.id == booking.id);
    if (index >= 0) {
      _bookings[index] = booking;
    } else {
      _bookings.add(booking);
    }
    _sortByCreatedAt();
    _notify();
  }

  static void updateStatus(int id, String status) {
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
    final index = _bookings.indexWhere((b) => b.id == id);
    if (index != -1) {
      _bookings[index] = _bookings[index].copyWith(status: status);
      _notify();
    }
  }

  static void updateBookingDetails(
<<<<<<< HEAD
    String id, {
=======
    int id, {
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
    String? specialization,
    String? problemDescription,
    String? address,
    String? date,
    String? time,
    double? offeredBudget,
  }) {
    final index = _bookings.indexWhere((b) => b.id == id);
<<<<<<< HEAD
    if (index == -1) return;
=======
    if (index == -1) {
      return;
    }
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe

    _bookings[index] = _bookings[index].copyWith(
      specialization: specialization,
      problemDescription: problemDescription,
      address: address,
      date: date,
      time: time,
      offeredBudget: offeredBudget,
    );
    _notify();
  }

  static void submitReview(
<<<<<<< HEAD
    String id,
=======
    int id,
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
    double rating,
    String comment,
    List<String> tags,
  ) {
    final index = _bookings.indexWhere((b) => b.id == id);
    if (index != -1) {
      _bookings[index] = _bookings[index].copyWith(
        isReviewed: true,
        reviewRating: rating,
        reviewComment: comment.isNotEmpty ? comment : null,
        reviewTags: tags,
      );
      _notify();
    }
  }

  static void submitIssue(
<<<<<<< HEAD
    String bookingId, {
=======
    int bookingId, {
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
    required String category,
    required String details,
    String status = 'Under Review',
  }) {
    final report = BookingIssueReport(
      id: 'ISSUE-${DateTime.now().millisecondsSinceEpoch}',
      bookingId: bookingId,
      category: category,
      details: details,
      createdAt: DateTime.now(),
    );
    _issueReports.insert(0, report);
<<<<<<< HEAD

    // In-memory handoff to admin queue for now.
    updateStatus(bookingId, status);
  }

  static BookingModel? getBookingById(String id) {
    try {
      return _bookings.firstWhere((b) => b.id == id);
    } catch (e) {
=======
    updateStatus(bookingId, status);
  }

  static BookingModel? getBookingById(int id) {
    try {
      return _bookings.firstWhere((b) => b.id == id);
    } catch (_) {
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
      return null;
    }
  }

  static List<BookingModel> get unreviewedCompletedBookings =>
      _bookings.where((b) => b.status == 'Completed' && !b.isReviewed).toList();

<<<<<<< HEAD
  static BookingModel fromBackendRow(Map<String, dynamic> row) {
    final id = _parseInt(row['id']) ?? 0;
    final createdAt = _parseDateTime(row['created_at']) ?? DateTime.now();
    final tradespersonName = (row['tradesperson_name'] ?? 'Tradesperson')
        .toString()
        .trim();
    final avatar = (row['tradesperson_avatar'] ?? '')
        .toString()
        .trim()
        .toUpperCase();
    final trade = (row['trade'] ?? 'Service').toString().trim();

    return BookingModel(
      id: 'DB-$id',
      tradespersonName: tradespersonName.isEmpty
          ? 'Tradesperson'
          : tradespersonName,
      tradespersonAvatar: avatar.isEmpty
          ? _buildAvatar(tradespersonName)
          : avatar,
      trade: trade.isEmpty ? 'Service' : trade,
      specialization: (row['specialization'] ?? row['service'] ?? trade)
          .toString()
          .trim(),
      problemDescription:
          (row['problem_description'] ?? row['description'] ?? '')
              .toString()
              .trim(),
      address: (row['address'] ?? '').toString().trim(),
      date: (row['date'] ?? '').toString().trim(),
      time: (row['time'] ?? '').toString().trim(),
      offeredBudget: _parseDouble(row['offered_budget'] ?? row['budget']) ?? 0,
      status: _normalizeStatus((row['status'] ?? '').toString()),
      createdAt: createdAt,
    );
  }

  static int? backendIdFromStoreId(String id) {
    if (!id.startsWith('DB-')) return null;
    return int.tryParse(id.substring(3));
  }

  static void _notify() {
    _mutationToken++;
    notifier.value = _mutationToken;
  }

  static int? _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static double? _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  static DateTime? _parseDateTime(dynamic value) {
    final text = (value ?? '').toString().trim();
    if (text.isEmpty) return null;
    return DateTime.tryParse(text)?.toLocal();
  }

  static String _normalizeStatus(String status) {
    switch (status.trim().toLowerCase()) {
      case 'accepted':
        return 'Accepted';
      case 'in progress':
      case 'in_progress':
      case 'in-progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'under review':
      case 'under_review':
      case 'under-review':
        return 'Under Review';
      case 'disputed':
        return 'Disputed';
      case 'cancelled':
      case 'canceled':
        return 'Cancelled';
      default:
        return 'Pending';
    }
  }

  static String _buildAvatar(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'TP';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }
}
=======
  static void clear() {
    _bookings.clear();
    _issueReports.clear();
    _notify();
  }

  static void _sortByCreatedAt() {
    _bookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  static void _notify() {
    notifier.value++;
  }
}

int _asInt(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is double) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value.trim()) ?? 0;
  }
  return 0;
}

double _asDouble(dynamic value) {
  if (value is double) {
    return value;
  }
  if (value is int) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value.trim()) ?? 0;
  }
  return 0;
}

double? _asNullableDouble(dynamic value) {
  final parsed = _asDouble(value);
  if (parsed == 0 && value != 0 && value != 0.0 && value != '0') {
    return null;
  }
  return parsed;
}

String _asString(dynamic value) {
  return value?.toString().trim() ?? '';
}

String? _asNullableString(dynamic value) {
  final str = _asString(value);
  return str.isEmpty ? null : str;
}

bool _asBool(dynamic value) {
  if (value is bool) {
    return value;
  }
  if (value is num) {
    return value != 0;
  }
  if (value is String) {
    final lower = value.trim().toLowerCase();
    return lower == '1' || lower == 'true' || lower == 'yes';
  }
  return false;
}

DateTime? _asDateTime(dynamic value) {
  if (value is DateTime) {
    return value;
  }
  if (value is String && value.trim().isNotEmpty) {
    return DateTime.tryParse(value.trim())?.toLocal();
  }
  return null;
}
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
