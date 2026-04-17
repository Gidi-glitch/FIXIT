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
  final String trade;
  final String specialization;
  final String problemDescription;
  final String address;
  final String date;
  final String time;
  final double offeredBudget;
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

  BookingModel copyWith({
    String? specialization,
    String? problemDescription,
    String? address,
    String? date,
    String? time,
    double? offeredBudget,
    String? status,
    bool? isReviewed,
    double? reviewRating,
    String? reviewComment,
    List<String>? reviewTags,
  }) {
    return BookingModel(
      id: id,
      tradespersonName: tradespersonName,
      tradespersonAvatar: tradespersonAvatar,
      trade: trade,
      specialization: specialization ?? this.specialization,
      problemDescription: problemDescription ?? this.problemDescription,
      address: address ?? this.address,
      date: date ?? this.date,
      time: time ?? this.time,
      offeredBudget: offeredBudget ?? this.offeredBudget,
      status: status ?? this.status,
      createdAt: createdAt,
      isReviewed: isReviewed ?? this.isReviewed,
      reviewRating: reviewRating ?? this.reviewRating,
      reviewComment: reviewComment ?? this.reviewComment,
      reviewTags: reviewTags ?? this.reviewTags,
    );
  }
}

class BookingIssueReport {
  final String id;
  final String bookingId;
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

  static List<BookingIssueReport> get issueReports =>
      List.unmodifiable(_issueReports);

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
    final index = _bookings.indexWhere((b) => b.id == id);
    if (index != -1) {
      _bookings[index] = _bookings[index].copyWith(status: status);
      _notify();
    }
  }

  static void updateBookingDetails(
    String id, {
    String? specialization,
    String? problemDescription,
    String? address,
    String? date,
    String? time,
    double? offeredBudget,
  }) {
    final index = _bookings.indexWhere((b) => b.id == id);
    if (index == -1) return;

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
    String id,
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
    String bookingId, {
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

    // In-memory handoff to admin queue for now.
    updateStatus(bookingId, status);
  }

  static BookingModel? getBookingById(String id) {
    try {
      return _bookings.firstWhere((b) => b.id == id);
    } catch (e) {
      return null;
    }
  }

  static List<BookingModel> get unreviewedCompletedBookings =>
      _bookings.where((b) => b.status == 'Completed' && !b.isReviewed).toList();

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
