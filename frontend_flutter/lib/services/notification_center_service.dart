import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';

class NotificationCenterService {
  NotificationCenterService._();

  static const String _homeownerSeenKey = 'homeowner_notification_seen_ids_v1';
  static const String _tradespersonSeenKey =
      'tradesperson_notification_seen_ids_v1';

  static Future<List<Map<String, dynamic>>> loadHomeownerNotifications({
    required String token,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final notifications = await _buildHomeownerEvents(
      token: token,
      prefs: prefs,
    );
    final seen = _readSeenSet(prefs, _homeownerSeenKey);

    for (final item in notifications) {
      final id = (item['id'] ?? '').toString();
      item['isRead'] = seen.contains(id);
    }

    return notifications;
  }

  static Future<List<Map<String, dynamic>>> loadTradespersonNotifications({
    required String token,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final notifications = await _buildTradespersonEvents(
      token: token,
      prefs: prefs,
    );
    final seen = _readSeenSet(prefs, _tradespersonSeenKey);

    for (final item in notifications) {
      final id = (item['id'] ?? '').toString();
      item['isRead'] = seen.contains(id);
    }

    return notifications;
  }

  static Future<int> homeownerUnreadCount({required String token}) async {
    final notifications = await loadHomeownerNotifications(token: token);
    return notifications.where((n) => n['isRead'] != true).length;
  }

  static Future<int> tradespersonUnreadCount({required String token}) async {
    final notifications = await loadTradespersonNotifications(token: token);
    return notifications.where((n) => n['isRead'] != true).length;
  }

  static Future<void> markHomeownerNotificationRead(
    String notificationID,
  ) async {
    if (notificationID.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final seen = _readSeenSet(prefs, _homeownerSeenKey);
    seen.add(notificationID.trim());
    await _writeSeenSet(prefs, _homeownerSeenKey, seen);
  }

  static Future<void> markTradespersonNotificationRead(
    String notificationID,
  ) async {
    if (notificationID.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final seen = _readSeenSet(prefs, _tradespersonSeenKey);
    seen.add(notificationID.trim());
    await _writeSeenSet(prefs, _tradespersonSeenKey, seen);
  }

  static Future<void> markAllHomeownerNotificationsRead({
    required String token,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final seen = _readSeenSet(prefs, _homeownerSeenKey);
    final notifications = await _buildHomeownerEvents(
      token: token,
      prefs: prefs,
    );
    for (final item in notifications) {
      final id = (item['id'] ?? '').toString();
      if (id.isNotEmpty) {
        seen.add(id);
      }
    }
    await _writeSeenSet(prefs, _homeownerSeenKey, seen);
  }

  static Future<void> markAllTradespersonNotificationsRead({
    required String token,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final seen = _readSeenSet(prefs, _tradespersonSeenKey);
    final notifications = await _buildTradespersonEvents(
      token: token,
      prefs: prefs,
    );
    for (final item in notifications) {
      final id = (item['id'] ?? '').toString();
      if (id.isNotEmpty) {
        seen.add(id);
      }
    }
    await _writeSeenSet(prefs, _tradespersonSeenKey, seen);
  }

  static Future<List<Map<String, dynamic>>> _buildHomeownerEvents({
    required String token,
    required SharedPreferences prefs,
  }) async {
    final pushAll = prefs.getBool('notif_push_all') ?? true;
    if (!pushAll || token.trim().isEmpty) {
      return <Map<String, dynamic>>[];
    }

    final notifications = <Map<String, dynamic>>[];
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    // Fetch server-side notifications (booking expiration, etc.)
    try {
      final response = await ApiService.getNotifications(token: token);
      final rows = (response['notifications'] as List?) ?? const [];
      for (final raw in rows.whereType<Map>()) {
        final row = raw.cast<String, dynamic>();
        final id = _asInt(row['id']);
        final title = _text(row['title']);
        final message = _text(row['message']);
        final type = _text(row['type']);
        final createdAt = _text(row['created_at']);

        String kind = 'notification';
        String targetTab = 'home';

        if (type == 'booking_expired') {
          kind = 'booking_expired';
          targetTab = 'bookings';
        }

        final timestampMs = _parseIsoTimeToMs(createdAt) ?? (nowMs - 1000);

        notifications.add(_buildEvent(
          id: 'server_home_$id',
          title: title,
          body: message,
          kind: kind,
          targetTab: targetTab,
          sortOrder: timestampMs,
          timeLabel: _relativeTimeLabel(timestampMs),
        ));
      }
    } catch (_) {
      // Keep local notification sources available even if server fetch fails.
    }

    final includeMessages = prefs.getBool('notif_new_message') ?? true;
    final includeMessagePreview =
        prefs.getBool('notif_message_preview') ?? true;

    final includeBookingConfirmed =
        prefs.getBool('notif_booking_confirmed') ?? true;
    final includeBookingAccepted =
        prefs.getBool('notif_booking_accepted') ?? true;
    final includeBookingInProgress =
        prefs.getBool('notif_booking_in_progress') ?? true;
    final includeBookingCompleted =
        prefs.getBool('notif_booking_completed') ?? true;
    final includeBookingCancelled =
        prefs.getBool('notif_booking_cancelled') ?? true;

    if (includeMessages) {
      try {
        final response = await ApiService.getConversations(token: token);
        final rows = (response['conversations'] as List?) ?? const [];

        var index = 0;
        for (final raw in rows.whereType<Map>()) {
          final row = raw.cast<String, dynamic>();
          final unreadCount = _asInt(row['unreadCount'] ?? row['unread_count']);
          if (unreadCount <= 0) {
            continue;
          }

          final conversationID = _asInt(row['id']);
          final contactName = _text(row['name'], fallback: 'Tradesperson');
          final preview = _text(row['lastMessage'] ?? row['last_message']);
          final safePreview = preview == 'Start your conversation'
              ? ''
              : preview;

          final notificationID =
              'home_msg_${conversationID}_${unreadCount}_${_eventFragment(safePreview.isNotEmpty ? safePreview : contactName)}';

          final body = includeMessagePreview && safePreview.isNotEmpty
              ? safePreview
              : unreadCount == 1
              ? '1 unread message from $contactName'
              : '$unreadCount unread messages from $contactName';

          notifications.add(
            _buildEvent(
              id: notificationID,
              title: 'New message',
              body: body,
              kind: 'message',
              targetTab: 'messages',
              sortOrder: nowMs - index,
              timeLabel: _text(row['time'], fallback: 'New'),
            ),
          );
          index++;
        }
      } catch (_) {
        // Keep other notification sources available even if chat load fails.
      }
    }

    final hasBookingToggle =
        includeBookingConfirmed ||
        includeBookingAccepted ||
        includeBookingInProgress ||
        includeBookingCompleted ||
        includeBookingCancelled;

    if (hasBookingToggle) {
      try {
        final response = await ApiService.getHomeownerBookings(token: token);
        final rows = (response['bookings'] as List?) ?? const [];

        var index = 0;
        for (final raw in rows.whereType<Map>()) {
          final row = raw.cast<String, dynamic>();
          final bookingID = _asInt(row['id']);
          if (bookingID <= 0) {
            continue;
          }

          final normalizedStatus = _text(row['status']).toLowerCase().trim();
          String? title;
          String? kind;
          var enabled = false;

          switch (normalizedStatus) {
            case 'pending':
              enabled = includeBookingConfirmed;
              title = 'Booking confirmed';
              kind = 'booking_confirmed';
              break;
            case 'accepted':
              enabled = includeBookingAccepted;
              title = 'Booking accepted';
              kind = 'booking_accepted';
              break;
            case 'in progress':
              enabled = includeBookingInProgress;
              title = 'Job started';
              kind = 'booking_in_progress';
              break;
            case 'completed':
              enabled = includeBookingCompleted;
              title = 'Job completed';
              kind = 'booking_completed';
              break;
            case 'cancelled':
              enabled = includeBookingCancelled;
              title = 'Booking cancelled';
              kind = 'booking_cancelled';
              break;
          }

          if (!enabled || title == null || kind == null) {
            continue;
          }

          final tradespersonName = _text(
            row['tradesperson_name'],
            fallback: 'your tradesperson',
          );
          final service = _text(
            row['specialization'] ?? row['trade'] ?? row['trade_category'],
          );

          final timestampMs =
              _parseIsoTimeToMs(row['updated_at']) ??
              _parseIsoTimeToMs(row['created_at']) ??
              (nowMs - 3600000 - index);

          final body = service.isNotEmpty
              ? '$service with $tradespersonName'
              : 'Update from $tradespersonName';

          notifications.add(
            _buildEvent(
              id: 'home_booking_${bookingID}_${normalizedStatus.replaceAll(' ', '_')}',
              title: title,
              body: body,
              kind: kind,
              targetTab: 'bookings',
              sortOrder: timestampMs,
              timeLabel: _relativeTimeLabel(timestampMs),
            ),
          );
          index++;
        }
      } catch (_) {
        // Keep other notification sources available even if bookings fail.
      }
    }

    notifications.sort(
      (a, b) => _asInt(b['sortOrder']).compareTo(_asInt(a['sortOrder'])),
    );

    return notifications;
  }

  static Future<List<Map<String, dynamic>>> _buildTradespersonEvents({
    required String token,
    required SharedPreferences prefs,
  }) async {
    final pushAll = prefs.getBool('tp_notif_push_all') ?? true;
    if (!pushAll || token.trim().isEmpty) {
      return <Map<String, dynamic>>[];
    }

    final notifications = <Map<String, dynamic>>[];
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    // Fetch server-side notifications (booking expiration, etc.)
    try {
      final response = await ApiService.getNotifications(token: token);
      final rows = (response['notifications'] as List?) ?? const [];
      for (final raw in rows.whereType<Map>()) {
        final row = raw.cast<String, dynamic>();
        final id = _asInt(row['id']);
        final title = _text(row['title']);
        final message = _text(row['message']);
        final type = _text(row['type']);
        final createdAt = _text(row['created_at']);

        String kind = 'notification';
        String targetTab = 'home';

        if (type == 'booking_expired') {
          kind = 'booking_expired';
          targetTab = 'requests';
        }

        final timestampMs = _parseIsoTimeToMs(createdAt) ?? (nowMs - 1000);

        notifications.add(_buildEvent(
          id: 'server_tp_$id',
          title: title,
          body: message,
          kind: kind,
          targetTab: targetTab,
          sortOrder: timestampMs,
          timeLabel: _relativeTimeLabel(timestampMs),
        ));
      }
    } catch (_) {
      // Keep local notification sources available even if server fetch fails.
    }

    final includeNewRequest = prefs.getBool('tp_notif_new_request') ?? true;
    final includeHighUrgency = prefs.getBool('tp_notif_high_urgency') ?? true;
    final includeJobAccepted = prefs.getBool('tp_notif_job_accepted') ?? true;
    final includeJobStarted = prefs.getBool('tp_notif_job_started') ?? true;
    final includeJobCompleted = prefs.getBool('tp_notif_job_completed') ?? true;
    final includeJobCancelled = prefs.getBool('tp_notif_job_cancelled') ?? true;
    final includeMessages = prefs.getBool('tp_notif_new_message') ?? true;
    final includeMessagePreview =
        prefs.getBool('tp_notif_message_preview') ?? true;

    if (includeMessages) {
      try {
        final response = await ApiService.getConversations(token: token);
        final rows = (response['conversations'] as List?) ?? const [];

        var index = 0;
        for (final raw in rows.whereType<Map>()) {
          final row = raw.cast<String, dynamic>();
          final unreadCount = _asInt(row['unreadCount'] ?? row['unread_count']);
          if (unreadCount <= 0) {
            continue;
          }

          final conversationID = _asInt(row['id']);
          final contactName = _text(row['name'], fallback: 'Homeowner');
          final preview = _text(row['lastMessage'] ?? row['last_message']);
          final safePreview = preview == 'Start your conversation'
              ? ''
              : preview;

          final notificationID =
              'tp_msg_${conversationID}_${unreadCount}_${_eventFragment(safePreview.isNotEmpty ? safePreview : contactName)}';

          final body = includeMessagePreview && safePreview.isNotEmpty
              ? safePreview
              : unreadCount == 1
              ? '1 unread message from $contactName'
              : '$unreadCount unread messages from $contactName';

          notifications.add(
            _buildEvent(
              id: notificationID,
              title: 'New message',
              body: body,
              kind: 'message',
              targetTab: 'messages',
              sortOrder: nowMs - index,
              timeLabel: _text(row['time'], fallback: 'New'),
            ),
          );
          index++;
        }
      } catch (_) {
        // Keep other notification sources available even if chat load fails.
      }
    }

    if (includeNewRequest || includeHighUrgency) {
      try {
        final response = await ApiService.getIncomingRequests(token: token);
        final rows = (response['requests'] as List?) ?? const [];

        var index = 0;
        for (final raw in rows.whereType<Map>()) {
          final row = raw.cast<String, dynamic>();
          final bookingID = _asInt(row['booking_id'] ?? row['id']);
          if (bookingID <= 0) {
            continue;
          }

          final homeownerName = _text(
            row['homeowner_name'],
            fallback: 'Homeowner',
          );
          final service = _text(
            row['service'] ?? row['specialization'] ?? row['trade'],
          );
          final urgency = _text(row['urgency']).toLowerCase();
          final timestampMs =
              _parseIsoTimeToMs(row['posted_at']) ??
              _parseIsoTimeToMs(row['created_at']) ??
              (nowMs - 1800000 - index);

          if (includeNewRequest) {
            notifications.add(
              _buildEvent(
                id: 'tp_request_$bookingID',
                title: 'New service request',
                body: service.isNotEmpty
                    ? '$homeownerName requested $service'
                    : '$homeownerName sent a new request',
                kind: 'request',
                targetTab: 'requests',
                sortOrder: timestampMs,
                timeLabel: _relativeTimeLabel(timestampMs),
              ),
            );
          }

          if (includeHighUrgency && urgency == 'high') {
            notifications.add(
              _buildEvent(
                id: 'tp_request_high_$bookingID',
                title: 'High-urgency request',
                body: service.isNotEmpty
                    ? '$homeownerName marked $service as high urgency'
                    : '$homeownerName marked this request as high urgency',
                kind: 'high_urgency',
                targetTab: 'requests',
                sortOrder: timestampMs + 1,
                timeLabel: _relativeTimeLabel(timestampMs),
              ),
            );
          }

          index++;
        }
      } catch (_) {
        // Keep other notification sources available even if requests fail.
      }
    }

    final hasJobStatusToggle =
        includeJobAccepted ||
        includeJobStarted ||
        includeJobCompleted ||
        includeJobCancelled;

    if (hasJobStatusToggle) {
      try {
        final response = await ApiService.getTradespersonJobs(token: token);
        final rows = (response['jobs'] as List?) ?? const [];

        var index = 0;
        for (final raw in rows.whereType<Map>()) {
          final row = raw.cast<String, dynamic>();
          final bookingID = _asInt(row['booking_id'] ?? row['id']);
          if (bookingID <= 0) {
            continue;
          }

          final status = _text(row['status']).toLowerCase().trim();
          String? title;
          String? kind;
          var enabled = false;

          switch (status) {
            case 'accepted':
              enabled = includeJobAccepted;
              title = 'Job accepted';
              kind = 'job_accepted';
              break;
            case 'in progress':
              enabled = includeJobStarted;
              title = 'Job in progress';
              kind = 'job_started';
              break;
            case 'completed':
              enabled = includeJobCompleted;
              title = 'Job completed';
              kind = 'job_completed';
              break;
            case 'cancelled':
              enabled = includeJobCancelled;
              title = 'Job cancelled';
              kind = 'job_cancelled';
              break;
          }

          if (!enabled || title == null || kind == null) {
            continue;
          }

          final homeownerName = _text(
            row['homeowner_name'],
            fallback: 'Homeowner',
          );
          final service = _text(
            row['service'] ?? row['specialization'] ?? row['trade'],
          );
          final timestampMs =
              _parseIsoTimeToMs(row['updated_at']) ??
              _parseIsoTimeToMs(row['created_at']) ??
              (nowMs - 5400000 - index);

          notifications.add(
            _buildEvent(
              id: 'tp_job_${bookingID}_${status.replaceAll(' ', '_')}',
              title: title,
              body: service.isNotEmpty
                  ? '$service for $homeownerName'
                  : 'Update for $homeownerName',
              kind: kind,
              targetTab: 'jobs',
              sortOrder: timestampMs,
              timeLabel: _relativeTimeLabel(timestampMs),
            ),
          );
          index++;
        }
      } catch (_) {
        // Keep other notification sources available even if jobs fail.
      }
    }

    notifications.sort(
      (a, b) => _asInt(b['sortOrder']).compareTo(_asInt(a['sortOrder'])),
    );

    return notifications;
  }

  static Map<String, dynamic> _buildEvent({
    required String id,
    required String title,
    required String body,
    required String kind,
    required String targetTab,
    required int sortOrder,
    required String timeLabel,
  }) {
    return {
      'id': id,
      'title': title,
      'body': body,
      'kind': kind,
      'targetTab': targetTab,
      'sortOrder': sortOrder,
      'timeLabel': timeLabel,
    };
  }

  static Set<String> _readSeenSet(SharedPreferences prefs, String key) {
    final list = prefs.getStringList(key) ?? const <String>[];
    return list.map((e) => e.trim()).where((e) => e.isNotEmpty).toSet();
  }

  static Future<void> _writeSeenSet(
    SharedPreferences prefs,
    String key,
    Set<String> seen,
  ) async {
    final items = seen.toList(growable: false);
    await prefs.setStringList(key, items);
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _text(dynamic value, {String fallback = ''}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  static int? _parseIsoTimeToMs(dynamic raw) {
    final value = raw?.toString().trim() ?? '';
    if (value.isEmpty) {
      return null;
    }

    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      return null;
    }

    return parsed.toLocal().millisecondsSinceEpoch;
  }

  static String _eventFragment(String value) {
    final normalized = value.toLowerCase().replaceAll(RegExp(r'\s+'), '_');
    if (normalized.isEmpty) {
      return 'event';
    }
    return normalized.length <= 40 ? normalized : normalized.substring(0, 40);
  }

  static String _relativeTimeLabel(int timestampMs) {
    final now = DateTime.now();
    final then = DateTime.fromMillisecondsSinceEpoch(timestampMs);
    final delta = now.difference(then);

    if (delta.inMinutes < 1) return 'Just now';
    if (delta.inMinutes < 60) return '${delta.inMinutes}m ago';
    if (delta.inHours < 24) return '${delta.inHours}h ago';
    if (delta.inDays < 7) return '${delta.inDays}d ago';
    return '${then.month}/${then.day}/${then.year}';
  }
}
