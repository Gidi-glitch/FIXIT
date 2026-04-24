import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Notifications Screen for the Fix It Marketplace Homeowner App.
///
/// Grouped toggles for push, booking, messages, and marketing
/// notifications. All preferences are persisted in SharedPreferences.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // ── Color Palette ──────────────────────────────────────────────
  static const Color _primaryBlue = Color(0xFF1E3A8A);
  static const Color _backgroundGray = Color(0xFFF9FAFB);
  static const Color _textDark = Color(0xFF111827);
  static const Color _textMuted = Color(0xFF6B7280);
  static const Color _cardWhite = Color(0xFFFFFFFF);
  static const Color _successGreen = Color(0xFF10B981);
  static const Color _infoBlue = Color(0xFF3B82F6);
  static const Color _purple = Color(0xFF8B5CF6);

  // ── Toggle state ────────────────────────────────────────────────
  // Key → (label, subtitle, icon, color, pref-key)
  bool _pushAll = true;

  // Booking
  bool _notifBookingConfirmed = true;
  bool _notifBookingAccepted = true;
  bool _notifBookingInProgress = true;
  bool _notifBookingCompleted = true;
  bool _notifBookingCancelled = true;

  // Messages
  bool _notifNewMessage = true;
  bool _notifMessagePreview = true;

  // Promotions
  bool _notifPromos = false;
  bool _notifAppUpdates = true;
  bool _notifTips = false;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _pushAll = p.getBool('notif_push_all') ?? true;
      _notifBookingConfirmed = p.getBool('notif_booking_confirmed') ?? true;
      _notifBookingAccepted = p.getBool('notif_booking_accepted') ?? true;
      _notifBookingInProgress = p.getBool('notif_booking_in_progress') ?? true;
      _notifBookingCompleted = p.getBool('notif_booking_completed') ?? true;
      _notifBookingCancelled = p.getBool('notif_booking_cancelled') ?? true;
      _notifNewMessage = p.getBool('notif_new_message') ?? true;
      _notifMessagePreview = p.getBool('notif_message_preview') ?? true;
      _notifPromos = p.getBool('notif_promos') ?? false;
      _notifAppUpdates = p.getBool('notif_app_updates') ?? true;
      _notifTips = p.getBool('notif_tips') ?? false;
      _isLoading = false;
    });
  }

  Future<void> _set(String key, bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(key, value);
  }

  void _toggle(String key, bool value, VoidCallback update) {
    setState(update);
    _set(key, value);
  }

  // Master toggle — flip all sub-toggles
  void _toggleMaster(bool value) {
    setState(() {
      _pushAll = value;
      if (!value) {
        _notifBookingConfirmed = false;
        _notifBookingAccepted = false;
        _notifBookingInProgress = false;
        _notifBookingCompleted = false;
        _notifBookingCancelled = false;
        _notifNewMessage = false;
        _notifMessagePreview = false;
        _notifPromos = false;
        _notifAppUpdates = false;
        _notifTips = false;
      } else {
        _notifBookingConfirmed = true;
        _notifBookingAccepted = true;
        _notifBookingInProgress = true;
        _notifBookingCompleted = true;
        _notifBookingCancelled = true;
        _notifNewMessage = true;
        _notifMessagePreview = true;
        _notifAppUpdates = true;
      }
    });
    _set('notif_push_all', value);
    _set('notif_booking_confirmed', _notifBookingConfirmed);
    _set('notif_booking_accepted', _notifBookingAccepted);
    _set('notif_booking_in_progress', _notifBookingInProgress);
    _set('notif_booking_completed', _notifBookingCompleted);
    _set('notif_booking_cancelled', _notifBookingCancelled);
    _set('notif_new_message', _notifNewMessage);
    _set('notif_message_preview', _notifMessagePreview);
    _set('notif_app_updates', _notifAppUpdates);
  }

  // ═══════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: _backgroundGray,
        body: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                      children: [
                        _buildMasterToggle(),
                        const SizedBox(height: 20),
                        _buildGroup(
                          icon: Icons.calendar_today_rounded,
                          color: _primaryBlue,
                          title: 'Booking Updates',
                          subtitle:
                              'Stay informed about your service bookings.',
                          items: [
                            _NotifItem(
                              label: 'Booking Confirmed',
                              subtitle: 'When your booking request is sent.',
                              value: _notifBookingConfirmed,
                              onChanged: (v) => _toggle(
                                'notif_booking_confirmed',
                                v,
                                () => _notifBookingConfirmed = v,
                              ),
                            ),
                            _NotifItem(
                              label: 'Booking Accepted',
                              subtitle:
                                  'When a tradesperson accepts your request.',
                              value: _notifBookingAccepted,
                              onChanged: (v) => _toggle(
                                'notif_booking_accepted',
                                v,
                                () => _notifBookingAccepted = v,
                              ),
                            ),
                            _NotifItem(
                              label: 'Job In Progress',
                              subtitle: 'When the tradesperson starts working.',
                              value: _notifBookingInProgress,
                              onChanged: (v) => _toggle(
                                'notif_booking_in_progress',
                                v,
                                () => _notifBookingInProgress = v,
                              ),
                            ),
                            _NotifItem(
                              label: 'Job Completed',
                              subtitle:
                                  'When the tradesperson marks job as done.',
                              value: _notifBookingCompleted,
                              onChanged: (v) => _toggle(
                                'notif_booking_completed',
                                v,
                                () => _notifBookingCompleted = v,
                              ),
                            ),
                            _NotifItem(
                              label: 'Booking Cancelled',
                              subtitle:
                                  'When a booking is cancelled by either party.',
                              value: _notifBookingCancelled,
                              onChanged: (v) => _toggle(
                                'notif_booking_cancelled',
                                v,
                                () => _notifBookingCancelled = v,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildGroup(
                          icon: Icons.chat_bubble_outline_rounded,
                          color: _infoBlue,
                          title: 'Messages',
                          subtitle: 'Control how you\'re notified for chats.',
                          items: [
                            _NotifItem(
                              label: 'New Message',
                              subtitle:
                                  'When a tradesperson sends you a message.',
                              value: _notifNewMessage,
                              onChanged: (v) => _toggle(
                                'notif_new_message',
                                v,
                                () => _notifNewMessage = v,
                              ),
                            ),
                            _NotifItem(
                              label: 'Message Preview',
                              subtitle:
                                  'Show message content in the notification.',
                              value: _notifMessagePreview,
                              onChanged: (v) => _toggle(
                                'notif_message_preview',
                                v,
                                () => _notifMessagePreview = v,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildGroup(
                          icon: Icons.campaign_rounded,
                          color: _purple,
                          title: 'Promotions & Updates',
                          subtitle: 'News, tips, and app improvements.',
                          items: [
                            _NotifItem(
                              label: 'App Updates',
                              subtitle:
                                  'New features and improvements to Fix It.',
                              value: _notifAppUpdates,
                              onChanged: (v) => _toggle(
                                'notif_app_updates',
                                v,
                                () => _notifAppUpdates = v,
                              ),
                            ),
                            _NotifItem(
                              label: 'Promotions',
                              subtitle:
                                  'Special offers and seasonal discounts.',
                              value: _notifPromos,
                              onChanged: (v) => _toggle(
                                'notif_promos',
                                v,
                                () => _notifPromos = v,
                              ),
                            ),
                            _NotifItem(
                              label: 'Tips & Tricks',
                              subtitle:
                                  'Home maintenance tips from our community.',
                              value: _notifTips,
                              onChanged: (v) => _toggle(
                                'notif_tips',
                                v,
                                () => _notifTips = v,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildFooterNote(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_primaryBlue, Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 20, 20),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notifications',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.4,
                      ),
                    ),
                    Text(
                      'Manage your notification preferences',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xB3FFFFFF),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Master toggle ────────────────────────────────────────────────

  Widget _buildMasterToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: _pushAll ? _primaryBlue.withValues(alpha: 0.06) : _cardWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _pushAll
              ? _primaryBlue.withValues(alpha: 0.25)
              : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: _pushAll
                  ? _primaryBlue.withValues(alpha: 0.12)
                  : _textMuted.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              _pushAll
                  ? Icons.notifications_active_rounded
                  : Icons.notifications_off_outlined,
              color: _pushAll ? _primaryBlue : _textMuted,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Push Notifications',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _textDark,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _pushAll
                      ? 'All notifications are enabled.'
                      : 'All notifications are turned off.',
                  style: TextStyle(
                    fontSize: 12,
                    color: _textMuted.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: _pushAll,
            onChanged: _toggleMaster,
            activeThumbColor: _primaryBlue,
          ),
        ],
      ),
    );
  }

  // ── Group card ───────────────────────────────────────────────────

  Widget _buildGroup({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required List<_NotifItem> items,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _cardWhite,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Group header ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: _textDark,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: _textMuted.withValues(alpha: 0.75),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 1,
            color: Colors.grey.shade100,
            margin: const EdgeInsets.symmetric(horizontal: 16),
          ),

          // ── Toggle rows ────────────────────────────────────────
          ...items.asMap().entries.map((e) {
            final isLast = e.key == items.length - 1;
            final item = e.value;
            return Column(
              children: [
                _buildToggleRow(item, disabled: !_pushAll),
                if (!isLast)
                  Container(
                    height: 1,
                    color: Colors.grey.shade100,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildToggleRow(_NotifItem item, {bool disabled = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: disabled
                        ? _textDark.withValues(alpha: 0.35)
                        : _textDark,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: _textMuted.withValues(alpha: disabled ? 0.4 : 0.75),
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch.adaptive(
            value: disabled ? false : item.value,
            onChanged: disabled ? null : item.onChanged,
            activeThumbColor: _successGreen,
          ),
        ],
      ),
    );
  }

  Widget _buildFooterNote() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.info_outline_rounded,
          size: 14,
          color: _textMuted.withValues(alpha: 0.5),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'You can also manage notification permissions from your '
            'device Settings → Apps → Fix It Marketplace.',
            style: TextStyle(
              fontSize: 12,
              color: _textMuted.withValues(alpha: 0.65),
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Data class ─────────────────────────────────────────────────────
class _NotifItem {
  final String label;
  final String subtitle;
  final bool value;
  final void Function(bool) onChanged;

  const _NotifItem({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });
}
