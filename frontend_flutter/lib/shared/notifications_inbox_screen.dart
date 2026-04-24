import 'package:flutter/material.dart';

import '../services/notification_center_service.dart';

enum NotificationAudience { homeowner, tradesperson }

class NotificationsInboxScreen extends StatefulWidget {
  final NotificationAudience audience;
  final String token;

  const NotificationsInboxScreen({
    super.key,
    required this.audience,
    required this.token,
  });

  @override
  State<NotificationsInboxScreen> createState() =>
      _NotificationsInboxScreenState();
}

class _NotificationsInboxScreenState extends State<NotificationsInboxScreen> {
  static const Color _primaryBlue = Color(0xFF1E3A8A);
  static const Color _backgroundGray = Color(0xFFF9FAFB);
  static const Color _textDark = Color(0xFF111827);
  static const Color _textMuted = Color(0xFF6B7280);
  static const Color _cardWhite = Color(0xFFFFFFFF);
  static const Color _accentOrange = Color(0xFFF97316);
  static const Color _successGreen = Color(0xFF10B981);
  static const Color _warningYellow = Color(0xFFF59E0B);
  static const Color _errorRed = Color(0xFFEF4444);

  List<Map<String, dynamic>> _notifications = <Map<String, dynamic>>[];
  bool _isLoading = true;
  bool _isMarkingAllRead = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final notifications = switch (widget.audience) {
        NotificationAudience.homeowner =>
          await NotificationCenterService.loadHomeownerNotifications(
            token: widget.token,
          ),
        NotificationAudience.tradesperson =>
          await NotificationCenterService.loadTradespersonNotifications(
            token: widget.token,
          ),
      };

      if (!mounted) return;
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _markAllAsRead() async {
    if (_isMarkingAllRead) return;

    setState(() => _isMarkingAllRead = true);
    try {
      switch (widget.audience) {
        case NotificationAudience.homeowner:
          await NotificationCenterService.markAllHomeownerNotificationsRead(
            token: widget.token,
          );
        case NotificationAudience.tradesperson:
          await NotificationCenterService.markAllTradespersonNotificationsRead(
            token: widget.token,
          );
      }

      if (!mounted) return;
      await _loadNotifications();
    } finally {
      if (mounted) {
        setState(() => _isMarkingAllRead = false);
      }
    }
  }

  Future<void> _handleTap(Map<String, dynamic> item) async {
    final id = (item['id'] ?? '').toString();
    if (id.isEmpty) return;

    switch (widget.audience) {
      case NotificationAudience.homeowner:
        await NotificationCenterService.markHomeownerNotificationRead(id);
      case NotificationAudience.tradesperson:
        await NotificationCenterService.markTradespersonNotificationRead(id);
    }

    if (!mounted) return;
    final targetTab = (item['targetTab'] ?? '').toString().trim();
    Navigator.pop(context, targetTab.isNotEmpty ? targetTab : null);
  }

  int get _unreadCount {
    return _notifications.where((n) => n['isRead'] != true).length;
  }

  String get _subtitle {
    if (widget.audience == NotificationAudience.homeowner) {
      return 'Booking and message updates';
    }
    return 'Request, job, and message updates';
  }

  IconData _iconFor(String kind) {
    switch (kind) {
      case 'message':
        return Icons.chat_bubble_outline_rounded;
      case 'booking_confirmed':
      case 'request':
        return Icons.inbox_rounded;
      case 'booking_accepted':
      case 'job_accepted':
        return Icons.check_circle_outline_rounded;
      case 'booking_in_progress':
      case 'job_started':
        return Icons.handyman_rounded;
      case 'booking_completed':
      case 'job_completed':
        return Icons.task_alt_rounded;
      case 'booking_cancelled':
      case 'job_cancelled':
        return Icons.cancel_outlined;
      case 'booking_expired':
        return Icons.access_time_rounded;
      case 'high_urgency':
        return Icons.priority_high_rounded;
      default:
        return Icons.notifications_none_rounded;
    }
  }

  Color _iconColor(String kind) {
    switch (kind) {
      case 'message':
        return _primaryBlue;
      case 'booking_accepted':
      case 'job_accepted':
      case 'booking_completed':
      case 'job_completed':
        return _successGreen;
      case 'booking_in_progress':
      case 'job_started':
      case 'booking_confirmed':
      case 'request':
        return _accentOrange;
      case 'booking_cancelled':
      case 'job_cancelled':
      case 'booking_expired':
      case 'high_urgency':
        return _errorRed;
      default:
        return _warningYellow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundGray,
      appBar: AppBar(
        backgroundColor: _primaryBlue,
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          TextButton(
            onPressed: (_unreadCount > 0 && !_isMarkingAllRead)
                ? _markAllAsRead
                : null,
            child: _isMarkingAllRead
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'Read all',
                    style: TextStyle(
                      color: _unreadCount > 0
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.5),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: _primaryBlue,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Text(
              '$_unreadCount unread • $_subtitle',
              style: const TextStyle(
                color: Color(0xCCFFFFFF),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: _errorRed,
                size: 34,
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: _textDark, fontSize: 14),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadNotifications,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryBlue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_notifications.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadNotifications,
        child: ListView(
          children: const [
            SizedBox(height: 120),
            Icon(Icons.notifications_none_rounded, size: 40, color: _textMuted),
            SizedBox(height: 10),
            Center(
              child: Text(
                'No notifications yet',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _textDark,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: _notifications.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = _notifications[index];
          final title = (item['title'] ?? '').toString();
          final body = (item['body'] ?? '').toString();
          final kind = (item['kind'] ?? '').toString();
          final timeLabel = (item['timeLabel'] ?? '').toString();
          final isRead = item['isRead'] == true;

          return Material(
            color: _cardWhite,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _handleTap(item),
              child: Container(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: _iconColor(kind).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _iconFor(kind),
                        color: _iconColor(kind),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isRead
                                  ? FontWeight.w600
                                  : FontWeight.w800,
                              color: _textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            body,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.4,
                              color: _textMuted.withValues(
                                alpha: isRead ? 0.75 : 0.9,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            timeLabel,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _textMuted.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isRead)
                      Container(
                        width: 9,
                        height: 9,
                        margin: const EdgeInsets.only(top: 3),
                        decoration: const BoxDecoration(
                          color: _accentOrange,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
