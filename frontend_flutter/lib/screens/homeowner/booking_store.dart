import 'package:flutter/foundation.dart';

class BookingModel {
  final int id;
  final String referenceId;
  final String tradespersonName;
  final String tradespersonAvatar;
  final String? tradespersonProfileImageUrl;
  final String trade;
  final String specialization;
  final String problemDescription;
  final String address;
  final String date;
  final String time;
  final double offeredBudget;
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
    String? specialization,
    String? problemDescription,
    String? address,
    String? date,
    String? time,
    double? offeredBudget,
    String? status,
    DateTime? createdAt,
    bool? isReviewed,
    double? reviewRating,
    String? reviewComment,
    List<String>? reviewTags,
  }) {
    return BookingModel(
      id: id,
      referenceId: referenceId ?? this.referenceId,
      tradespersonName: tradespersonName ?? this.tradespersonName,
      tradespersonAvatar: tradespersonAvatar ?? this.tradespersonAvatar,
      tradespersonProfileImageUrl:
          tradespersonProfileImageUrl ?? this.tradespersonProfileImageUrl,
      trade: trade ?? this.trade,
      specialization: specialization ?? this.specialization,
      problemDescription: problemDescription ?? this.problemDescription,
      address: address ?? this.address,
      date: date ?? this.date,
      time: time ?? this.time,
      offeredBudget: offeredBudget ?? this.offeredBudget,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      isReviewed: isReviewed ?? this.isReviewed,
      reviewRating: reviewRating ?? this.reviewRating,
      reviewComment: reviewComment ?? this.reviewComment,
      reviewTags: reviewTags ?? this.reviewTags,
    );
  }
}

class BookingIssueReport {
  final String id;
  final int bookingId;
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

  static final List<BookingModel> _bookings = [];
  static final List<BookingIssueReport> _issueReports = [];
  static final ValueNotifier<int> notifier = ValueNotifier<int>(0);

  static List<BookingModel> get all => List.unmodifiable(_bookings);

  static List<BookingIssueReport> get issueReports =>
      List.unmodifiable(_issueReports);

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
    final index = _bookings.indexWhere((b) => b.id == id);
    if (index != -1) {
      _bookings[index] = _bookings[index].copyWith(status: status);
      _notify();
    }
  }

  static void updateBookingDetails(
    int id, {
    String? specialization,
    String? problemDescription,
    String? address,
    String? date,
    String? time,
    double? offeredBudget,
  }) {
    final index = _bookings.indexWhere((b) => b.id == id);
    if (index == -1) {
      return;
    }

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
    int id,
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
    int bookingId, {
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
    updateStatus(bookingId, status);
  }

  static BookingModel? getBookingById(int id) {
    try {
      return _bookings.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }

  static List<BookingModel> get unreviewedCompletedBookings =>
      _bookings.where((b) => b.status == 'Completed' && !b.isReviewed).toList();

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
