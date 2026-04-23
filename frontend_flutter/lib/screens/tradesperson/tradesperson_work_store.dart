import 'package:flutter/material.dart';
<<<<<<< HEAD
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/api_service.dart';
=======
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe

/// Shared in-memory store for tradesperson requests and jobs.
/// Keeps dashboard, requests, and jobs tabs in sync.
class TradespersonWorkStore {
  TradespersonWorkStore._();

  static final ValueNotifier<int> notifier = ValueNotifier<int>(0);
  static int _mutationToken = 0;
  static String _lastMutation = 'init';
  static String? _lastAcceptedJobId;
  static String? _pendingOpenJobId;
<<<<<<< HEAD
  static bool _isSyncing = false;
  static final Set<String> _backendRequestIds = <String>{};
  static final Set<String> _backendJobIds = <String>{};
=======
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe

  static int get mutationToken => _mutationToken;
  static String get lastMutation => _lastMutation;
  static String? get lastAcceptedJobId => _lastAcceptedJobId;
  static String? get pendingOpenJobId => _pendingOpenJobId;
<<<<<<< HEAD
  static bool get isSyncing => _isSyncing;
=======
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe

  /// Returns true when at least one job is currently 'In Progress'.
  static bool get hasJobInProgress =>
      _jobs.any((j) => j['status'] == 'In Progress');

<<<<<<< HEAD
  static final List<Map<String, dynamic>> _requests = [
    {
      'id': 'REQ-001',
      'homeowner': 'Gideon Alcantara',
      'avatar': 'GA',
      'service': 'Pipe Leak Repair',
      'description':
          'There is a major pipe leak under the kitchen sink. Water is dripping constantly and causing damage to the cabinet.',
      'barangay': 'Dayap',
      'address': 'Blk 4 Lot 12, Dayap, Calauan',
      'urgency': 'High',
      'urgencyColor': const Color(0xFFEF4444),
      'budget': 500.0,
      'date': 'Today',
      'time': '2:00 PM',
      'postedAt': '15 mins ago',
      'isNew': true,
    },
    {
      'id': 'REQ-002',
      'homeowner': 'Maria Clara',
      'avatar': 'MC',
      'service': 'Faucet Installation',
      'description':
          'Need a new kitchen faucet installed. I already have the replacement unit ready, just need someone to do the installation.',
      'barangay': 'Hanggan',
      'address': 'Blk 2 Lot 5, Hanggan, Calauan',
      'urgency': 'Medium',
      'urgencyColor': const Color(0xFFF59E0B),
      'budget': 350.0,
      'date': 'Tomorrow',
      'time': '10:00 AM',
      'postedAt': '32 mins ago',
      'isNew': true,
    },
    {
      'id': 'REQ-003',
      'homeowner': 'Jose Rizal',
      'avatar': 'JR',
      'service': 'Drain Cleaning',
      'description':
          'Bathroom drain is slow and partially clogged. It has been getting worse over the past week.',
      'barangay': 'Imok',
      'address': 'Blk 7 Lot 3, Imok, Calauan',
      'urgency': 'Low',
      'urgencyColor': const Color(0xFF10B981),
      'budget': 250.0,
      'date': 'Mar 28',
      'time': '9:00 AM',
      'postedAt': '1 hour ago',
      'isNew': false,
    },
    {
      'id': 'REQ-004',
      'homeowner': 'Lucia Reyes',
      'avatar': 'LR',
      'service': 'Water Heater Check',
      'description':
          'My water heater is making a loud banging noise every time it heats up. Concerned it might be a serious issue.',
      'barangay': 'Balayhangin',
      'address': 'Blk 1 Lot 8, Balayhangin, Calauan',
      'urgency': 'High',
      'urgencyColor': const Color(0xFFEF4444),
      'budget': 700.0,
      'date': 'Today',
      'time': '4:30 PM',
      'postedAt': '2 hours ago',
      'isNew': false,
    },
    {
      'id': 'REQ-005',
      'homeowner': 'Carlos Mendoza',
      'avatar': 'CM',
      'service': 'Toilet Repair',
      'description':
          'Toilet keeps running after flushing. The flapper or fill valve may need replacement.',
      'barangay': 'Dayap',
      'address': 'Blk 9 Lot 2, Dayap, Calauan',
      'urgency': 'Medium',
      'urgencyColor': const Color(0xFFF59E0B),
      'budget': 300.0,
      'date': 'Mar 29',
      'time': '11:00 AM',
      'postedAt': '3 hours ago',
      'isNew': false,
    },
  ];

  static final List<Map<String, dynamic>> _jobs = [
    {
      'id': 'BK-001',
      'homeowner': 'Ana Santos',
      'avatar': 'AS',
      'service': 'Water Heater Repair',
      'description':
          'Water heater making banging noise. Suspected faulty heating element or mineral buildup.',
      'address': 'Blk 1 Lot 8, Balayhangin, Calauan',
      'date': 'Today',
      'time': '10:30 AM',
      'budget': 700.0,
      'status': 'In Progress',
      'startedAt': '10:30 AM',
    },
    {
      'id': 'BK-002',
      'homeowner': 'Roberto Cruz',
      'avatar': 'RC',
      'service': 'Bathroom Pipe Installation',
      'description':
          'Full replacement of old galvanized pipes in the bathroom with PVC piping.',
      'address': 'Blk 3 Lot 6, Hanggan, Calauan',
      'date': 'Tomorrow',
      'time': '8:00 AM',
      'budget': 1500.0,
      'status': 'Accepted',
      'startedAt': null,
    },
    {
      'id': 'BK-003',
      'homeowner': 'Elena Bautista',
      'avatar': 'EB',
      'service': 'Kitchen Sink Leak Fix',
      'description':
          'P-trap under the kitchen sink was corroded and leaking. Replaced and sealed.',
      'address': 'Blk 9 Lot 1, Dayap, Calauan',
      'date': 'Mar 22',
      'time': '2:00 PM',
      'budget': 450.0,
      'status': 'Completed',
      'startedAt': null,
      'completedAt': 'Mar 22 · 4:15 PM',
      'rating': 5.0,
    },
    {
      'id': 'BK-004',
      'homeowner': 'Fernando Lopez',
      'avatar': 'FL',
      'service': 'Faucet Replacement',
      'description': 'Replaced two leaking faucets in the master bathroom.',
      'address': 'Blk 6 Lot 4, Imok, Calauan',
      'date': 'Mar 18',
      'time': '11:00 AM',
      'budget': 300.0,
      'status': 'Completed',
      'startedAt': null,
      'completedAt': 'Mar 18 · 1:00 PM',
      'rating': 4.5,
    },
    {
      'id': 'BK-005',
      'homeowner': 'Carina Dela Rosa',
      'avatar': 'CD',
      'service': 'Drain Cleaning',
      'description': 'Unclogged main bathroom drain using hydro-jetting.',
      'address': 'Blk 2 Lot 11, Dayap, Calauan',
      'date': 'Mar 15',
      'time': '3:00 PM',
      'budget': 280.0,
      'status': 'Cancelled',
      'startedAt': null,
    },
  ];
=======
  static final List<Map<String, dynamic>> _requests = [];
  static final List<Map<String, dynamic>> _jobs = [];
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe

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

<<<<<<< HEAD
  static Future<void> syncFromBackend() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token')?.trim();
      if (token == null || token.isEmpty) return;

      final result = await ApiService.getBookings(token);
      final rows = (result['bookings'] as List? ?? const <dynamic>[])
          .whereType<Map>()
          .map((row) => row.cast<String, dynamic>())
          .toList();

      _mergeBackendBookings(rows);
      _notify('sync_backend');
    } catch (_) {
      // Keep current in-memory data when sync fails.
    } finally {
      _isSyncing = false;
    }
=======
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
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
  }

  // ── Mutations ──────────────────────────────────────────────────

<<<<<<< HEAD
  static Future<bool> acceptRequestById(String requestId) async {
    final index = _requests.indexWhere((r) => r['id'] == requestId);
    if (index == -1) return false;

    final request = _requests.removeAt(index);
    final remoteBookingId = _backendBookingIdFromItem(request);
    if (remoteBookingId != null) {
      final updated = await _updateRemoteStatus(
        bookingId: remoteBookingId,
        status: 'Accepted',
      );
      if (!updated) {
        _requests.insert(index, request);
        return false;
      }
    }

    final newJobId = remoteBookingId != null
        ? 'DB-$remoteBookingId'
        : 'BK-${request['id']}';
    _jobs.insert(0, {
      'id': newJobId,
      ...(remoteBookingId == null
          ? <String, dynamic>{}
          : <String, dynamic>{'backendBookingId': remoteBookingId}),
      'homeowner': request['homeowner'],
      'avatar': request['avatar'],
=======
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
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
      'service': request['service'],
      'description': request['description'],
      'address': request['address'],
      'date': request['date'],
      'time': request['time'],
      'budget': request['budget'],
      'status': 'Accepted',
      'startedAt': null,
<<<<<<< HEAD
=======
      'completedAt': null,
      'rating': null,
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
    });
    _lastAcceptedJobId = newJobId;

    _notify('accept_request');
<<<<<<< HEAD
    return true;
  }

  static Future<bool> declineRequestById(String requestId) async {
    final index = _requests.indexWhere((r) => r['id'] == requestId);
    if (index == -1) return false;

    final request = _requests[index];
    final remoteBookingId = _backendBookingIdFromItem(request);
    if (remoteBookingId != null) {
      final updated = await _updateRemoteStatus(
        bookingId: remoteBookingId,
        status: 'Cancelled',
      );
      if (!updated) return false;
    }

    _requests.removeAt(index);
    _lastAcceptedJobId = null;
    _notify('decline_request');
    return true;
=======
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
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
  }

  /// Transitions an Accepted job to In Progress.
  /// Only succeeds when no other job is already In Progress.
<<<<<<< HEAD
  static Future<bool> startJobById(String jobId) async {
    // Guard: only one In Progress job at a time
    if (hasJobInProgress) return false;

    final index = _jobs.indexWhere((j) => j['id'] == jobId);
    if (index == -1) return false;
    if (_jobs[index]['status'] != 'Accepted') return false;

    final remoteBookingId = _backendBookingIdFromItem(_jobs[index]);
    if (remoteBookingId != null) {
      final updated = await _updateRemoteStatus(
        bookingId: remoteBookingId,
        status: 'In Progress',
      );
      if (!updated) return false;
    }

=======
  static bool startJobById(String jobId) {
    // Guard: only one In Progress job at a time
    if (hasJobInProgress) return false;

    final index = _findJobIndexByAnyId(jobId);
    if (index == -1) return false;
    if (_jobs[index]['status'] != 'Accepted') return false;

>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
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

<<<<<<< HEAD
  static Future<bool> markJobAsComplete(String jobId) async {
    final index = _jobs.indexWhere((j) => j['id'] == jobId);
    if (index == -1) return false;

    final remoteBookingId = _backendBookingIdFromItem(_jobs[index]);
    if (remoteBookingId != null) {
      final updated = await _updateRemoteStatus(
        bookingId: remoteBookingId,
        status: 'Completed',
      );
      if (!updated) return false;
    }

=======
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

>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
    _jobs[index] = {
      ..._jobs[index],
      'status': 'Completed',
      'completedAt': 'Just now',
    };
    _lastAcceptedJobId = null;
    _notify('complete_job');
<<<<<<< HEAD
    return true;
=======
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
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
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

<<<<<<< HEAD
  static void _mergeBackendBookings(List<Map<String, dynamic>> rows) {
    _requests.removeWhere(
      (request) => _backendRequestIds.contains(request['id']),
    );
    _jobs.removeWhere((job) => _backendJobIds.contains(job['id']));
    _backendRequestIds.clear();
    _backendJobIds.clear();

    final mapped = rows.map(_mapBackendBooking).toList()
      ..sort(
        (a, b) =>
            (b['createdAt'] as DateTime).compareTo(a['createdAt'] as DateTime),
      );

    for (final booking in mapped) {
      if (booking['status'] == 'Pending') {
        final request = _toRequestMap(booking);
        _backendRequestIds.add(request['id'] as String);
        _requests.insert(0, request);
      } else {
        final job = _toJobMap(booking);
        _backendJobIds.add(job['id'] as String);
        _jobs.insert(0, job);
      }
    }
  }

  static Map<String, dynamic> _mapBackendBooking(Map<String, dynamic> row) {
    final id = _parseInt(row['id']) ?? 0;
    final createdAt = _parseDateTime(row['created_at']) ?? DateTime.now();
    final status = _normalizeStatus((row['status'] ?? '').toString());
    final urgency = _normalizeUrgency((row['urgency'] ?? '').toString());
    final homeownerName = (row['homeowner_name'] ?? 'Homeowner').toString();

    return {
      'id': 'DB-$id',
      'backendBookingId': id,
      'homeowner': homeownerName,
      'avatar': ((row['homeowner_avatar'] ?? '').toString().trim().isNotEmpty)
          ? (row['homeowner_avatar'] ?? '').toString().trim().toUpperCase()
          : _buildAvatar(homeownerName),
      'service': (row['service'] ?? row['specialization'] ?? 'Service')
          .toString()
          .trim(),
      'description': (row['description'] ?? row['problem_description'] ?? '')
          .toString()
          .trim(),
      'barangay': (row['barangay'] ?? '').toString().trim(),
      'address': (row['address'] ?? '').toString().trim(),
      'urgency': urgency,
      'budget': _parseDouble(row['budget'] ?? row['offered_budget']) ?? 0,
      'date': (row['date'] ?? '').toString().trim(),
      'time': (row['time'] ?? '').toString().trim(),
      'postedAt': (row['posted_at'] ?? '').toString().trim(),
      'isNew': row['is_new'] == true,
      'status': status,
      'createdAt': createdAt,
      'startedAt': _displayDateTime(row['started_at']),
      'completedAt': _displayDateTime(row['completed_at']),
    };
  }

  static Map<String, dynamic> _toRequestMap(Map<String, dynamic> booking) {
    final urgency = (booking['urgency'] ?? 'Medium').toString();
    return {
      'id': booking['id'],
      'backendBookingId': booking['backendBookingId'],
      'homeowner': booking['homeowner'],
      'avatar': booking['avatar'],
      'service': booking['service'],
      'description': booking['description'],
      'barangay': booking['barangay'],
      'address': booking['address'],
      'urgency': urgency,
      'urgencyColor': _urgencyColor(urgency),
      'budget': booking['budget'],
      'date': booking['date'],
      'time': booking['time'],
      'postedAt': booking['postedAt'],
      'isNew': booking['isNew'],
      'createdAt': booking['createdAt'],
    };
  }

  static Map<String, dynamic> _toJobMap(Map<String, dynamic> booking) {
    return {
      'id': booking['id'],
      'backendBookingId': booking['backendBookingId'],
      'homeowner': booking['homeowner'],
      'avatar': booking['avatar'],
      'service': booking['service'],
      'description': booking['description'],
      'address': booking['address'],
      'date': booking['date'],
      'time': booking['time'],
      'budget': booking['budget'],
      'status': booking['status'],
      'startedAt': booking['startedAt'],
      'completedAt': booking['completedAt'],
      'createdAt': booking['createdAt'],
    };
  }

  static Future<bool> _updateRemoteStatus({
    required int bookingId,
    required String status,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token')?.trim();
      if (token == null || token.isEmpty) return false;
      await ApiService.updateBookingStatus(
        token: token,
        bookingId: bookingId,
        status: status,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  static int? _backendBookingIdFromItem(Map<String, dynamic> item) {
    return _parseInt(item['backendBookingId']);
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

  static String _displayDateTime(dynamic value) {
    final parsed = _parseDateTime(value);
    if (parsed == null) return '';
    final minute = parsed.minute.toString().padLeft(2, '0');
    final hour12 = parsed.hour == 0
        ? 12
        : parsed.hour > 12
        ? parsed.hour - 12
        : parsed.hour;
    final period = parsed.hour >= 12 ? 'PM' : 'AM';
    return '$hour12:$minute $period';
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

  static String _normalizeUrgency(String urgency) {
    switch (urgency.trim().toLowerCase()) {
      case 'high':
        return 'High';
      case 'low':
        return 'Low';
      default:
        return 'Medium';
    }
  }

  static Color _urgencyColor(String urgency) {
    switch (urgency) {
      case 'High':
        return const Color(0xFFEF4444);
      case 'Low':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFFF59E0B);
    }
  }

  static String _buildAvatar(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'HO';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }
=======
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
      'startedAt': startedAtRaw.isNotEmpty
          ? startedAtRaw
          : (status == 'In Progress' ? 'Ongoing' : null),
      'completedAt': completedAtRaw.isNotEmpty
          ? completedAtRaw
          : (status == 'Completed' ? 'Completed' : null),
      'rating': row['rating'] == null ? null : _asDouble(row['rating']),
    };
  }
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
}
