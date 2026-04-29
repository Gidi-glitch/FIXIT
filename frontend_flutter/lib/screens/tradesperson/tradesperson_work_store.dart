import 'package:flutter/material.dart';

/// Shared in-memory store for tradesperson requests and jobs.
/// Keeps dashboard, requests, and jobs tabs in sync.
class TradespersonWorkStore {
  TradespersonWorkStore._();

  static final ValueNotifier<int> notifier = ValueNotifier<int>(0);
  static int _mutationToken = 0;
  static String _lastMutation = 'init';
  static String? _lastAcceptedJobId;
  static String? _pendingOpenJobId;

  static int get mutationToken => _mutationToken;
  static String get lastMutation => _lastMutation;
  static String? get lastAcceptedJobId => _lastAcceptedJobId;
  static String? get pendingOpenJobId => _pendingOpenJobId;

  /// Returns true when at least one job is currently 'In Progress'.
  static bool get hasJobInProgress =>
      _jobs.any((j) => j['status'] == 'In Progress');

  static final List<Map<String, dynamic>> _requests = [];
  static final List<Map<String, dynamic>> _jobs = [];

  // ── Public getters ─────────────────────────────────────────────

  static List<Map<String, dynamic>> get requests =>
      List.unmodifiable(_requests.map((r) => Map<String, dynamic>.from(r)));

  static List<Map<String, dynamic>> get jobs =>
      List.unmodifiable(_jobs.map((j) => Map<String, dynamic>.from(j)));

  static List<Map<String, dynamic>> dashboardRequests({int limit = 3}) {
    return _requests
        .take(limit)
        .map((r) => Map<String, dynamic>.from(r))
        .toList(growable: false);
  }

  // ── API cache hydration ───────────────────────────────────────

  static void setRequestsFromApi(List<dynamic> rows) {
    _requests
      ..clear()
      ..addAll(
        rows
            .whereType<Map>()
            .map((raw) {
              final mapped = _mapRequest(raw.cast<String, dynamic>());
              return mapped;
            })
            .where((row) => row.isNotEmpty),
      );

    _notify('set_requests');
  }

  static void setJobsFromApi(List<dynamic> rows) {
    _jobs
      ..clear()
      ..addAll(
        rows
            .whereType<Map>()
            .map((raw) {
              final mapped = _mapJob(raw.cast<String, dynamic>());
              return mapped;
            })
            .where((row) => row.isNotEmpty),
      );

    _notify('set_jobs');
  }

  static void upsertJobFromApi(
    Map<String, dynamic> row, {
    String mutation = 'upsert_job',
  }) {
    final mapped = _mapJob(row);
    if (mapped.isEmpty) return;

    final bookingId = mapped['bookingId'] as int;
    final index = _jobs.indexWhere((j) => j['bookingId'] == bookingId);
    if (index == -1) {
      _jobs.insert(0, mapped);
    } else {
      _jobs[index] = {..._jobs[index], ...mapped};
    }

    _lastAcceptedJobId = (mapped['id'] ?? '').toString();
    _notify(mutation);
  }

  // ── Mutations ──────────────────────────────────────────────────

  static void acceptRequestById(String requestId) {
    final index = _findRequestIndexByAnyId(requestId);
    if (index == -1) return;

    final request = _requests.removeAt(index);
    final newJobId = _jobReference(request['bookingId'] as int);
    _jobs.insert(0, {
      'id': newJobId,
      'bookingId': request['bookingId'],
      'homeowner': request['homeowner'],
      'avatar': request['avatar'],
      'homeownerProfileImageUrl': request['homeownerProfileImageUrl'],
      'service': request['service'],
      'description': request['description'],
      'address': request['address'],
      'date': request['date'],
      'time': request['time'],
      'budget': request['budget'],
      'status': 'Accepted',
      'startedAt': null,
      'completedAt': null,
      'rating': null,
    });
    _lastAcceptedJobId = newJobId;

    _notify('accept_request');
  }

  static void acceptRequestByApiResult(
    String requestId,
    Map<String, dynamic>? jobRow,
  ) {
    final index = _findRequestIndexByAnyId(requestId);
    if (index != -1) {
      _requests.removeAt(index);
    }

    if (jobRow != null) {
      upsertJobFromApi(jobRow, mutation: 'accept_request');
      return;
    }

    _notify('accept_request');
  }

  static void declineRequestById(String requestId) {
    final index = _findRequestIndexByAnyId(requestId);
    if (index != -1) {
      _requests.removeAt(index);
    }
    _lastAcceptedJobId = null;
    _notify('decline_request');
  }

  /// Transitions an Accepted job to In Progress.
  /// Only succeeds when no other job is already In Progress.
  static bool startJobById(String jobId) {
    // Guard: only one In Progress job at a time
    if (hasJobInProgress) return false;

    final index = _findJobIndexByAnyId(jobId);
    if (index == -1) return false;
    if (_jobs[index]['status'] != 'Accepted') return false;

    final now = TimeOfDay.now();
    final hour = now.hourOfPeriod == 0 ? 12 : now.hourOfPeriod;
    final minute = now.minute.toString().padLeft(2, '0');
    final period = now.period == DayPeriod.am ? 'AM' : 'PM';
    final timeLabel = '$hour:$minute $period';

    _jobs[index] = {
      ..._jobs[index],
      'status': 'In Progress',
      'startedAt': timeLabel,
    };
    _lastAcceptedJobId = null;
    _notify('start_job');
    return true;
  }

  static bool startJobByApiResult(String jobId, Map<String, dynamic>? jobRow) {
    if (jobRow != null) {
      upsertJobFromApi(jobRow, mutation: 'start_job');
      return true;
    }

    return startJobById(jobId);
  }

  static void markJobAsComplete(String jobId) {
    final index = _findJobIndexByAnyId(jobId);
    if (index == -1) return;

    _jobs[index] = {
      ..._jobs[index],
      'status': 'Completed',
      'completedAt': 'Just now',
    };
    _lastAcceptedJobId = null;
    _notify('complete_job');
  }

  static void completeJobByApiResult(
    String jobId,
    Map<String, dynamic>? jobRow,
  ) {
    if (jobRow != null) {
      upsertJobFromApi(jobRow, mutation: 'complete_job');
      _lastAcceptedJobId = null;
      return;
    }

    markJobAsComplete(jobId);
  }

  static void requestOpenJobDetails(String jobId) {
    _pendingOpenJobId = jobId;
    _notify('open_job_details');
  }

  static String? consumePendingOpenJobId() {
    final id = _pendingOpenJobId;
    _pendingOpenJobId = null;
    return id;
  }

  static void _notify(String mutation) {
    _lastMutation = mutation;
    _mutationToken++;
    notifier.value = _mutationToken;
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _asDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int _bookingIdFromAny(String idOrRef) {
    final direct = int.tryParse(idOrRef);
    if (direct != null && direct > 0) return direct;

    final digits = RegExp(
      r'\d+',
    ).allMatches(idOrRef).map((m) => m.group(0)).join();
    return int.tryParse(digits) ?? 0;
  }

  static String _requestReference(int bookingId) =>
      'REQ-${bookingId.toString().padLeft(6, '0')}';

  static String _jobReference(int bookingId) =>
      'BK-${bookingId.toString().padLeft(6, '0')}';

  static String _urgencyFromBudget(double budget) {
    if (budget >= 1000) return 'High';
    if (budget >= 500) return 'Medium';
    return 'Low';
  }

  static String _avatarFromName(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'HO';
    if (parts.length == 1) {
      final word = parts.first;
      if (word.length >= 2) return word.substring(0, 2).toUpperCase();
      return word.substring(0, 1).toUpperCase();
    }
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

  static int _findRequestIndexByAnyId(String requestId) {
    final requestedBookingId = _bookingIdFromAny(requestId);
    return _requests.indexWhere((r) {
      final bookingId = _asInt(r['bookingId']);
      if (requestedBookingId > 0 && bookingId == requestedBookingId) {
        return true;
      }
      return (r['id'] ?? '').toString() == requestId;
    });
  }

  static int _findJobIndexByAnyId(String jobId) {
    final requestedBookingId = _bookingIdFromAny(jobId);
    return _jobs.indexWhere((j) {
      final bookingId = _asInt(j['bookingId']);
      if (requestedBookingId > 0 && bookingId == requestedBookingId) {
        return true;
      }
      return (j['id'] ?? '').toString() == jobId;
    });
  }

  static Map<String, dynamic> _mapRequest(Map<String, dynamic> row) {
    final bookingId = _asInt(row['booking_id'] ?? row['id']);
    if (bookingId <= 0) return {};

    final homeowner = (row['homeowner_name'] ?? '').toString().trim();
    final budget = _asDouble(row['budget'] ?? row['offered_budget']);
    final urgency = (row['urgency'] ?? '').toString().trim();
    final service = (row['service'] ?? row['specialization'] ?? row['trade'])
        .toString()
        .trim();

    return {
      'id': (row['reference_id'] ?? _requestReference(bookingId)).toString(),
      'bookingId': bookingId,
      'homeowner': homeowner.isEmpty ? 'Homeowner' : homeowner,
      'avatar': (row['homeowner_avatar'] ?? _avatarFromName(homeowner))
          .toString(),
      'homeownerProfileImageUrl': (row['homeowner_profile_image_url'] ?? '')
          .toString()
          .trim(),
      'service': service,
      'description': (row['problem_description'] ?? '').toString(),
      'barangay': (row['barangay'] ?? '').toString(),
      'address': (row['address'] ?? '').toString(),
      'urgency': urgency.isEmpty ? _urgencyFromBudget(budget) : urgency,
      'budget': budget,
      'date': (row['date'] ?? '').toString(),
      'time': (row['time'] ?? '').toString(),
      'postedAt': (row['posted_at'] ?? '').toString(),
      'isNew': row['is_new'] == true,
      'status': (row['status'] ?? 'Pending').toString(),
    };
  }

  static Map<String, dynamic> _mapJob(Map<String, dynamic> row) {
    final bookingId = _asInt(row['booking_id'] ?? row['id']);
    if (bookingId <= 0) return {};

    final homeowner = (row['homeowner_name'] ?? '').toString().trim();
    final budget = _asDouble(row['budget'] ?? row['offered_budget']);
    final status = (row['status'] ?? '').toString().trim();
    final service = (row['service'] ?? row['specialization'] ?? row['trade'])
        .toString()
        .trim();

    final startedAtRaw = (row['started_at'] ?? '').toString();
    final completedAtRaw = (row['completed_at'] ?? '').toString();
    final cancelledAtRaw = (row['cancelled_at'] ?? '').toString();
    final startedAtLabel = _formatApiDateTime(startedAtRaw);
    final completedAtLabel = _formatApiDateTime(completedAtRaw);
    final cancelledAtLabel = _formatApiDateTime(cancelledAtRaw);

    return {
      'id': (row['reference_id'] ?? _jobReference(bookingId)).toString(),
      'bookingId': bookingId,
      'homeowner': homeowner.isEmpty ? 'Homeowner' : homeowner,
      'avatar': (row['homeowner_avatar'] ?? _avatarFromName(homeowner))
          .toString(),
      'homeownerProfileImageUrl': (row['homeowner_profile_image_url'] ?? '')
          .toString()
          .trim(),
      'service': service,
      'description': (row['problem_description'] ?? '').toString(),
      'address': (row['address'] ?? '').toString(),
      'date': (row['date'] ?? '').toString(),
      'time': (row['time'] ?? '').toString(),
      'budget': budget,
      'status': status,
      'startedAt': startedAtLabel.isNotEmpty
          ? startedAtLabel
          : (status == 'In Progress' ? 'Ongoing' : null),
      'completedAt': completedAtLabel.isNotEmpty
          ? completedAtLabel
          : (status == 'Completed' ? 'Completed' : null),
      'cancelledAt': cancelledAtLabel.isNotEmpty ? cancelledAtLabel : null,
      'rating': row['rating'] == null ? null : _asDouble(row['rating']),
    };
  }

  static String _formatApiDateTime(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';

    final parsed = DateTime.tryParse(trimmed);
    if (parsed == null) return trimmed;

    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final local = parsed.toLocal();
    final month = months[local.month - 1];
    final day = local.day;
    final year = local.year;
    final hour12 = local.hour == 0
        ? 12
        : (local.hour > 12 ? local.hour - 12 : local.hour);
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';
    return '$month $day, $year · $hour12:$minute $period';
  }
}
