import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Shared in-memory store for tradesperson requests and jobs.
/// Keeps dashboard, requests, and jobs tabs in sync.
class TradespersonWorkStore {
  TradespersonWorkStore._();

  static final ValueNotifier<int> notifier = ValueNotifier<int>(0);
  static int _mutationToken = 0;
  static String _lastMutation = 'init';
  static String? _lastAcceptedJobId;

  static int get mutationToken => _mutationToken;
  static String get lastMutation => _lastMutation;
  static String? get lastAcceptedJobId => _lastAcceptedJobId;

  /// Returns true when at least one job is currently 'In Progress'.
  static bool get hasJobInProgress =>
      _jobs.any((j) => j['status'] == 'In Progress');

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

  // ── Mutations ──────────────────────────────────────────────────

  static void acceptRequestById(String requestId) {
    final index = _requests.indexWhere((r) => r['id'] == requestId);
    if (index == -1) return;

    final request = _requests.removeAt(index);
    final newJobId = 'BK-${request['id']}';
    _jobs.insert(0, {
      'id': newJobId,
      'homeowner': request['homeowner'],
      'avatar': request['avatar'],
      'service': request['service'],
      'description': request['description'],
      'address': request['address'],
      'date': request['date'],
      'time': request['time'],
      'budget': request['budget'],
      'status': 'Accepted',
      'startedAt': null,
    });
    _lastAcceptedJobId = newJobId;

    _notify('accept_request');
  }

  static void declineRequestById(String requestId) {
    _requests.removeWhere((r) => r['id'] == requestId);
    _lastAcceptedJobId = null;
    _notify('decline_request');
  }

  /// Transitions an Accepted job to In Progress.
  /// Only succeeds when no other job is already In Progress.
  static bool startJobById(String jobId) {
    // Guard: only one In Progress job at a time
    if (hasJobInProgress) return false;

    final index = _jobs.indexWhere((j) => j['id'] == jobId);
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

  static void markJobAsComplete(String jobId) {
    final index = _jobs.indexWhere((j) => j['id'] == jobId);
    if (index == -1) return;

    _jobs[index] = {
      ..._jobs[index],
      'status': 'Completed',
      'completedAt': 'Just now',
    };
    _lastAcceptedJobId = null;
    _notify('complete_job');
  }

  static void _notify(String mutation) {
    _lastMutation = mutation;
    _mutationToken++;
    notifier.value = _mutationToken;
  }
}
