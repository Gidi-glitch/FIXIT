import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Notifications Screen for the Fix It Marketplace Tradesperson App.
///
/// Grouped toggles for push, job requests, job updates,
/// payments, messages, and marketing — all with SharedPreferences.
class TradespersonNotificationsScreen extends StatefulWidget {
  const TradespersonNotificationsScreen({super.key});

  @override
  State<TradespersonNotificationsScreen> createState() =>
      _TradespersonNotificationsScreenState();
}

class _TradespersonNotificationsScreenState
    extends State<TradespersonNotificationsScreen> {
  // ── Color Palette ──────────────────────────────────────────────
  static const Color _primaryBlue = Color(0xFF1E3A8A);
  static const Color _backgroundGray = Color(0xFFF9FAFB);
  static const Color _textDark = Color(0xFF111827);
  static const Color _textMuted = Color(0xFF6B7280);
  static const Color _cardWhite = Color(0xFFFFFFFF);
  static const Color _successGreen = Color(0xFF10B981);
  static const Color _infoBlue = Color(0xFF3B82F6);
  static const Color _purple = Color(0xFF8B5CF6);
  static const Color _errorRed = Color(0xFFEF4444);

  // ── Toggle state ────────────────────────────────────────────────
  bool _pushAll = true;

  // Job requests
  bool _notifNewRequest = true;
  bool _notifHighUrgency = true;

  // Job updates
  bool _notifJobAccepted = true;
  bool _notifJobStarted = true;
  bool _notifJobCompleted = true;
  bool _notifJobCancelled = true;

  // Payments
  bool _notifPaymentReceived = true;
  bool _notifPaymentReminder = true;

  // Messages
  bool _notifNewMessage = true;
  bool _notifMessagePreview = true;

  // Other
  bool _notifAppUpdates = true;
  bool _notifPromos = false;
  bool _notifTips = false;

  bool _isLoading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _pushAll = p.getBool('tp_notif_push_all') ?? true;
      _notifNewRequest = p.getBool('tp_notif_new_request') ?? true;
      _notifHighUrgency = p.getBool('tp_notif_high_urgency') ?? true;
      _notifJobAccepted = p.getBool('tp_notif_job_accepted') ?? true;
      _notifJobStarted = p.getBool('tp_notif_job_started') ?? true;
      _notifJobCompleted = p.getBool('tp_notif_job_completed') ?? true;
      _notifJobCancelled = p.getBool('tp_notif_job_cancelled') ?? true;
      _notifPaymentReceived = p.getBool('tp_notif_payment_received') ?? true;
      _notifPaymentReminder = p.getBool('tp_notif_payment_reminder') ?? true;
      _notifNewMessage = p.getBool('tp_notif_new_message') ?? true;
      _notifMessagePreview = p.getBool('tp_notif_message_preview') ?? true;
      _notifAppUpdates = p.getBool('tp_notif_app_updates') ?? true;
      _notifPromos = p.getBool('tp_notif_promos') ?? false;
      _notifTips = p.getBool('tp_notif_tips') ?? false;
      _isLoading = false;
    });
  }

  Future<void> _set(String key, bool v) async { final p = await SharedPreferences.getInstance(); await p.setBool(key, v); }

  void _toggle(String key, bool v, VoidCallback update) { setState(update); _set(key, v); }

  void _toggleMaster(bool v) {
    setState(() {
      _pushAll = v;
      if (!v) {
        _notifNewRequest = _notifHighUrgency = _notifJobAccepted = _notifJobStarted = _notifJobCompleted = _notifJobCancelled = _notifPaymentReceived = _notifPaymentReminder = _notifNewMessage = _notifMessagePreview = _notifAppUpdates = _notifPromos = _notifTips = false;
      } else {
        _notifNewRequest = _notifHighUrgency = _notifJobAccepted = _notifJobStarted = _notifJobCompleted = _notifJobCancelled = _notifPaymentReceived = _notifPaymentReminder = _notifNewMessage = _notifMessagePreview = _notifAppUpdates = true;
      }
    });
    for (final e in {
      'tp_notif_push_all': v, 'tp_notif_new_request': _notifNewRequest, 'tp_notif_high_urgency': _notifHighUrgency,
      'tp_notif_job_accepted': _notifJobAccepted, 'tp_notif_job_started': _notifJobStarted, 'tp_notif_job_completed': _notifJobCompleted, 'tp_notif_job_cancelled': _notifJobCancelled,
      'tp_notif_payment_received': _notifPaymentReceived, 'tp_notif_payment_reminder': _notifPaymentReminder,
      'tp_notif_new_message': _notifNewMessage, 'tp_notif_message_preview': _notifMessagePreview, 'tp_notif_app_updates': _notifAppUpdates,
    }.entries) { _set(e.key, e.value); }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: _backgroundGray,
        body: Column(children: [
          _buildHeader(),
          Expanded(child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(physics: const BouncingScrollPhysics(), padding: const EdgeInsets.fromLTRB(20, 24, 20, 40), children: [
                _buildMasterToggle(),
                const SizedBox(height: 20),
                _buildGroup(
                  icon: Icons.inbox_rounded, color: _errorRed, title: 'New Requests',
                  subtitle: 'Alerts when homeowners request your service.',
                  items: [
                    _NotifItem('New Job Request', 'When a homeowner sends a new request.', _notifNewRequest, (v) => _toggle('tp_notif_new_request', v, () => _notifNewRequest = v)),
                    _NotifItem('High Urgency Alert', 'Extra alert for high-urgency requests.', _notifHighUrgency, (v) => _toggle('tp_notif_high_urgency', v, () => _notifHighUrgency = v)),
                  ],
                ),
                const SizedBox(height: 16),
                _buildGroup(
                  icon: Icons.handyman_rounded, color: _primaryBlue, title: 'Job Updates',
                  subtitle: 'Status changes across your active jobs.',
                  items: [
                    _NotifItem('Job Accepted Confirmed', 'When your acceptance is confirmed.', _notifJobAccepted, (v) => _toggle('tp_notif_job_accepted', v, () => _notifJobAccepted = v)),
                    _NotifItem('Job Started', 'When a job transitions to In Progress.', _notifJobStarted, (v) => _toggle('tp_notif_job_started', v, () => _notifJobStarted = v)),
                    _NotifItem('Job Completed', 'When a job is marked as complete.', _notifJobCompleted, (v) => _toggle('tp_notif_job_completed', v, () => _notifJobCompleted = v)),
                    _NotifItem('Job Cancelled', 'When a homeowner cancels a booking.', _notifJobCancelled, (v) => _toggle('tp_notif_job_cancelled', v, () => _notifJobCancelled = v)),
                  ],
                ),
                const SizedBox(height: 16),
                _buildGroup(
                  icon: Icons.payments_outlined, color: _successGreen, title: 'Payments',
                  subtitle: 'Alerts related to your earnings.',
                  items: [
                    _NotifItem('Payment Received', 'When a homeowner releases your payment.', _notifPaymentReceived, (v) => _toggle('tp_notif_payment_received', v, () => _notifPaymentReceived = v)),
                    _NotifItem('Payment Reminder', 'Remind the homeowner to settle payment.', _notifPaymentReminder, (v) => _toggle('tp_notif_payment_reminder', v, () => _notifPaymentReminder = v)),
                  ],
                ),
                const SizedBox(height: 16),
                _buildGroup(
                  icon: Icons.chat_bubble_outline_rounded, color: _infoBlue, title: 'Messages',
                  subtitle: 'Chat notifications with homeowners.',
                  items: [
                    _NotifItem('New Message', 'When a homeowner sends you a message.', _notifNewMessage, (v) => _toggle('tp_notif_new_message', v, () => _notifNewMessage = v)),
                    _NotifItem('Message Preview', 'Show message content in notification.', _notifMessagePreview, (v) => _toggle('tp_notif_message_preview', v, () => _notifMessagePreview = v)),
                  ],
                ),
                const SizedBox(height: 16),
                _buildGroup(
                  icon: Icons.campaign_rounded, color: _purple, title: 'Promotions & Updates',
                  subtitle: 'App news, tips, and improvements.',
                  items: [
                    _NotifItem('App Updates', 'New features and Fix It improvements.', _notifAppUpdates, (v) => _toggle('tp_notif_app_updates', v, () => _notifAppUpdates = v)),
                    _NotifItem('Promotions', 'Seasonal offers and platform events.', _notifPromos, (v) => _toggle('tp_notif_promos', v, () => _notifPromos = v)),
                    _NotifItem('Tips for Tradespeople', 'Pro tips on better service delivery.', _notifTips, (v) => _toggle('tp_notif_tips', v, () => _notifTips = v)),
                  ],
                ),
                const SizedBox(height: 20),
                _buildFootnote(),
              ]),
          ),
        ]),
      ),
    );
  }

  Widget _buildHeader() => Container(
    decoration: const BoxDecoration(gradient: LinearGradient(colors: [_primaryBlue, Color(0xFF2563EB)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
    child: SafeArea(bottom: false, child: Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 20),
      child: Row(children: [
        IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20)),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Notifications', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.4)),
          Text('Manage your notification preferences', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xB3FFFFFF))),
        ])),
      ]),
    )),
  );

  Widget _buildMasterToggle() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
    decoration: BoxDecoration(
      color: _pushAll ? _primaryBlue.withValues(alpha: 0.06) : _cardWhite,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _pushAll ? _primaryBlue.withValues(alpha: 0.25) : Colors.grey.shade200),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
    ),
    child: Row(children: [
      Container(width: 46, height: 46, decoration: BoxDecoration(color: _pushAll ? _primaryBlue.withValues(alpha: 0.12) : _textMuted.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(14)),
        child: Icon(_pushAll ? Icons.notifications_active_rounded : Icons.notifications_off_outlined, color: _pushAll ? _primaryBlue : _textMuted, size: 24)),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Push Notifications', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _textDark)),
        const SizedBox(height: 3),
        Text(_pushAll ? 'All notifications are enabled.' : 'All notifications are turned off.',
          style: TextStyle(fontSize: 12, color: _textMuted.withValues(alpha: 0.8), fontWeight: FontWeight.w500)),
      ])),
      Switch.adaptive(value: _pushAll, onChanged: _toggleMaster, activeColor: _primaryBlue),
    ]),
  );

  Widget _buildGroup({required IconData icon, required Color color, required String title, required String subtitle, required List<_NotifItem> items}) {
    return Container(
      decoration: BoxDecoration(color: _cardWhite, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 12), child: Row(children: [
          Container(width: 36, height: 36, decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 18)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _textDark)),
            Text(subtitle, style: TextStyle(fontSize: 11, color: _textMuted.withValues(alpha: 0.75), fontWeight: FontWeight.w500)),
          ])),
        ])),
        Container(height: 1, color: Colors.grey.shade100, margin: const EdgeInsets.symmetric(horizontal: 16)),
        ...items.asMap().entries.map((e) {
          final isLast = e.key == items.length - 1;
          final item = e.value;
          return Column(children: [
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(item.label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _pushAll ? _textDark : _textDark.withValues(alpha: 0.35))),
                const SizedBox(height: 3),
                Text(item.subtitle, style: TextStyle(fontSize: 12, color: _textMuted.withValues(alpha: _pushAll ? 0.75 : 0.4), fontWeight: FontWeight.w500, height: 1.35)),
              ])),
              const SizedBox(width: 12),
              Switch.adaptive(value: _pushAll ? item.value : false, onChanged: _pushAll ? item.onChanged : null, activeColor: _successGreen),
            ])),
            if (!isLast) Container(height: 1, color: Colors.grey.shade100, margin: const EdgeInsets.symmetric(horizontal: 16)),
          ]);
        }),
      ]),
    );
  }

  Widget _buildFootnote() => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Icon(Icons.info_outline_rounded, size: 14, color: _textMuted.withValues(alpha: 0.5)), const SizedBox(width: 8),
    Expanded(child: Text('You can also manage notification permissions from your device Settings → Apps → Fix It Marketplace.', style: TextStyle(fontSize: 12, color: _textMuted.withValues(alpha: 0.65), height: 1.5))),
  ]);
}

class _NotifItem {
  final String label, subtitle;
  final bool value;
  final void Function(bool) onChanged;
  const _NotifItem(this.label, this.subtitle, this.value, this.onChanged);
}