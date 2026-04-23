import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Help & Support Screen for the Fix It Marketplace Tradesperson App.
class TradespersonHelpSupportScreen extends StatefulWidget {
  const TradespersonHelpSupportScreen({super.key});

  @override
  State<TradespersonHelpSupportScreen> createState() =>
      _TradespersonHelpSupportScreenState();
}

class _TradespersonHelpSupportScreenState
    extends State<TradespersonHelpSupportScreen> {
  // ── Color Palette ──────────────────────────────────────────────
  static const Color _primaryBlue = Color(0xFF1E3A8A);
  static const Color _accentOrange = Color(0xFFF97316);
  static const Color _backgroundGray = Color(0xFFF9FAFB);
  static const Color _textDark = Color(0xFF111827);
  static const Color _textMuted = Color(0xFF6B7280);
  static const Color _cardWhite = Color(0xFFFFFFFF);
  static const Color _successGreen = Color(0xFF10B981);
  static const Color _errorRed = Color(0xFFEF4444);
  static const Color _borderGray = Color(0xFFE5E7EB);

  int? _expandedFaqIndex;
  final _reportFormKey = GlobalKey<FormState>();
  final _reportCtrl = TextEditingController();
  String _reportCategory = 'Booking Dispute';
  bool _isSubmitting = false;

  static const List<String> _reportCategories = [
    'Booking Dispute', 'Payment Issue', 'Homeowner Behavior',
    'App Bug / Error', 'Account Issue', 'Verification Problem', 'Other',
  ];

  static const List<Map<String, String>> _faqs = [
    {'q': 'How do I accept or decline a request?', 'a': 'Go to the Requests tab. Each card shows Accept and Decline buttons. Accepted requests move to your Jobs tab automatically. You can also view request details before deciding.'},
    {'q': 'Can I have more than one active job?', 'a': 'You can have multiple Accepted jobs, but only one job can be In Progress at a time. You must mark the current job as Complete before starting another.'},
    {'q': 'How do I start a job?', 'a': 'Open the Jobs tab and tap the "Start Job" button on any Accepted job, or open the job details and tap Start Job there. The homeowner will be notified when you begin.'},
    {'q': 'How do I mark a job as complete?', 'a': 'From the Jobs tab or Job Details screen, tap "Mark as Complete." The homeowner is notified to settle your payment in cash directly after confirmation.'},
    {'q': 'How does payment work for tradespeople?', 'a': 'Fix It Marketplace uses a cash-based system. After you mark a job as complete, the homeowner settles the agreed amount with you directly in cash. No digital payment is currently processed through the app.'},
    {'q': 'How do I toggle my On Duty status?', 'a': 'Use the On Duty switch on your Dashboard or Profile screen. When Off Duty, your profile is hidden from homeowners and you will not receive new requests.'},
    {'q': 'How do I manage my service area?', 'a': 'Go to Profile → Service Area. Select the barangays in Calauan, Laguna where you are willing to work. Homeowners from those barangays will be able to find and book you.'},
    {'q': 'What documents do I need to stay verified?', 'a': 'You need a valid government-issued ID and a trade license or TESDA NC certificate. Documents are reviewed by the Fix It team. Expired documents must be re-uploaded to maintain your Verified badge.'},
    {'q': 'How are ratings and reviews calculated?', 'a': 'After each completed job, the homeowner can leave a star rating and comment. Your average rating is calculated from all received reviews and is visible on your public profile.'},
    {'q': 'What happens if a homeowner reports an issue?', 'a': 'An issue report moves the booking to Under Review status. The Fix It support team investigates within 24–48 hours. You may be contacted for your side of the situation.'},
  ];

  @override
  void dispose() { _reportCtrl.dispose(); super.dispose(); }

  Future<void> _submitReport() async {
    if (!_reportFormKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(milliseconds: 900));
    _reportCtrl.clear();
    setState(() { _isSubmitting = false; _reportCategory = 'Booking Dispute'; });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Row(children: [Icon(Icons.check_circle_rounded, color: Colors.white, size: 18), SizedBox(width: 10), Expanded(child: Text('Report submitted. We\'ll respond within 24 hours.', style: TextStyle(fontWeight: FontWeight.w600)))]),
      backgroundColor: _successGreen, behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), margin: const EdgeInsets.all(16),
    ));
  }

  // ═══════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: _backgroundGray,
        body: Column(children: [
          _buildHeader(),
          Expanded(child: ListView(physics: const BouncingScrollPhysics(), padding: const EdgeInsets.fromLTRB(20, 24, 20, 40), children: [
            _buildContactCards(),
            const SizedBox(height: 24),
            _buildFaqSection(),
            const SizedBox(height: 24),
            _buildReportSection(),
            const SizedBox(height: 24),
            _buildAppInfo(),
          ])),
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
          Text('Help & Support', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.4)),
          Text('We\'re here to help you succeed', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xB3FFFFFF))),
        ])),
      ]),
    )),
  );

  Widget _buildContactCards() {
    final options = [
      (Icons.chat_rounded, 'Live Chat', 'Chat with support', _primaryBlue, const LinearGradient(colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
      (Icons.email_rounded, 'Email Us', 'support@fixitph.com', _accentOrange, const LinearGradient(colors: [Color(0xFFF97316), Color(0xFFFB923C)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
      (Icons.phone_rounded, 'Call Us', '+63 917 123 4567', _successGreen, const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF34D399)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _secLabel('Contact Support'),
      const SizedBox(height: 12),
      Row(children: options.map((o) {
        final (icon, title, sub, color, grad) = o;
        final isLast = o == options.last;
        return Expanded(child: Container(
          margin: EdgeInsets.only(right: isLast ? 0 : 10),
          child: Material(color: Colors.transparent, child: InkWell(onTap: () {}, borderRadius: BorderRadius.circular(16), child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: _cardWhite, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4))]),
            child: Column(children: [
              Container(width: 46, height: 46, decoration: BoxDecoration(gradient: grad, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))]), child: Icon(icon, color: Colors.white, size: 22)),
              const SizedBox(height: 10),
              Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _textDark), textAlign: TextAlign.center),
              const SizedBox(height: 3),
              Text(sub, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: _textMuted.withValues(alpha: 0.75)), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
            ]),
          ))),
        ));
      }).toList()),
    ]);
  }

  Widget _buildFaqSection() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _secLabel('Frequently Asked Questions'),
    const SizedBox(height: 12),
    Container(
      decoration: BoxDecoration(color: _cardWhite, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 14, offset: const Offset(0, 4))]),
      child: Column(children: _faqs.asMap().entries.map((e) {
        final idx = e.key;
        final faq = e.value;
        final isExpanded = _expandedFaqIndex == idx;
        final isLast = idx == _faqs.length - 1;
        return Column(children: [
          Material(color: Colors.transparent, child: InkWell(
            onTap: () => setState(() => _expandedFaqIndex = isExpanded ? null : idx),
            borderRadius: idx == 0 ? const BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18)) : (isLast && !isExpanded ? const BorderRadius.only(bottomLeft: Radius.circular(18), bottomRight: Radius.circular(18)) : BorderRadius.zero),
            child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), child: Row(children: [
              AnimatedContainer(duration: const Duration(milliseconds: 180), width: 28, height: 28,
                decoration: BoxDecoration(color: isExpanded ? _primaryBlue.withValues(alpha: 0.1) : _backgroundGray, borderRadius: BorderRadius.circular(8)),
                child: Icon(isExpanded ? Icons.remove_rounded : Icons.add_rounded, color: isExpanded ? _primaryBlue : _textMuted, size: 16)),
              const SizedBox(width: 12),
              Expanded(child: Text(faq['q']!, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: isExpanded ? _primaryBlue : _textDark, height: 1.35))),
            ])),
          )),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Container(padding: const EdgeInsets.fromLTRB(56, 0, 16, 16), child: Text(faq['a']!, style: TextStyle(fontSize: 13, color: _textMuted.withValues(alpha: 0.85), height: 1.55, fontWeight: FontWeight.w500))),
            crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 220),
          ),
          if (!isLast) Container(height: 1, color: Colors.grey.shade100, margin: const EdgeInsets.symmetric(horizontal: 16)),
        ]);
      }).toList()),
    ),
  ]);

  Widget _buildReportSection() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _secLabel('Report a Problem'),
    const SizedBox(height: 12),
    Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: _cardWhite, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 14, offset: const Offset(0, 4))]),
      child: Form(key: _reportFormKey, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 36, height: 36, decoration: BoxDecoration(color: _errorRed.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.flag_outlined, color: _errorRed, size: 18)),
          const SizedBox(width: 10),
          const Text('Report an Issue', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _textDark, letterSpacing: -0.2)),
        ]),
        const SizedBox(height: 16),
        _fieldLabel('Category'), const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _reportCategory, onChanged: (v) => setState(() => _reportCategory = v!),
          dropdownColor: _cardWhite, isExpanded: true,
          decoration: _inputDec('Select category', Icons.category_outlined),
          items: _reportCategories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _textDark)))).toList(),
        ),
        const SizedBox(height: 14),
        _fieldLabel('Describe the Problem'), const SizedBox(height: 8),
        TextFormField(
          controller: _reportCtrl, maxLines: 5, maxLength: 500,
          style: const TextStyle(fontSize: 14, color: _textDark, fontWeight: FontWeight.w500, height: 1.5),
          decoration: _inputDec('Describe the issue in as much detail as possible...', Icons.description_outlined).copyWith(
            alignLabelWithHint: true, counterStyle: TextStyle(fontSize: 11, color: _textMuted.withValues(alpha: 0.6))),
          validator: (v) => (v == null || v.trim().length < 20) ? 'Please provide at least 20 characters of detail.' : null,
        ),
        const SizedBox(height: 16),
        SizedBox(width: double.infinity, child: ElevatedButton.icon(
          onPressed: _isSubmitting ? null : _submitReport,
          icon: _isSubmitting ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)) : const Icon(Icons.send_rounded, size: 18),
          label: Text(_isSubmitting ? 'Submitting...' : 'Submit Report'),
          style: ElevatedButton.styleFrom(backgroundColor: _primaryBlue, foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        )),
      ])),
    ),
  ]);

  Widget _buildAppInfo() => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(color: _cardWhite, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 14, offset: const Offset(0, 4))]),
    child: Column(children: [
      Row(children: [
        Container(width: 48, height: 48, decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(14)),
          child: const Icon(Icons.home_repair_service_rounded, color: Colors.white, size: 24)),
        const SizedBox(width: 14),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Fix It Marketplace', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _textDark)),
          Text('Tradesperson App', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: _textMuted.withValues(alpha: 0.8))),
        ]),
      ]),
      const SizedBox(height: 16),
      Container(height: 1, color: Colors.grey.shade100),
      const SizedBox(height: 14),
      ...[('Version', '1.0.0 (Build 1)'), ('Platform', 'Android'), ('Region', 'Calauan, Laguna, Philippines'), ('Support Hours', 'Mon – Sat, 8AM – 6PM')].map(
        (e) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [
          Text(e.$1, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _textMuted.withValues(alpha: 0.75))),
          const Spacer(),
          Text(e.$2, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _textDark)),
        ])),
      ),
      const SizedBox(height: 14),
      Container(height: 1, color: Colors.grey.shade100),
      const SizedBox(height: 14),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        _linkBtn('Terms of Service'),
        Container(width: 1, height: 14, color: Colors.grey.shade300, margin: const EdgeInsets.symmetric(horizontal: 12)),
        _linkBtn('Privacy Policy'),
        Container(width: 1, height: 14, color: Colors.grey.shade300, margin: const EdgeInsets.symmetric(horizontal: 12)),
        _linkBtn('Licenses'),
      ]),
    ]),
  );

  Widget _linkBtn(String label) => GestureDetector(onTap: () {}, child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _primaryBlue.withValues(alpha: 0.8))));
  Widget _secLabel(String text) => Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _textMuted, letterSpacing: 0.5));
  Widget _fieldLabel(String text) => Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _textDark.withValues(alpha: 0.75)));

  InputDecoration _inputDec(String hint, IconData icon) => InputDecoration(
    hintText: hint, hintStyle: TextStyle(color: _textMuted.withValues(alpha: 0.5), fontSize: 14, fontWeight: FontWeight.w400),
    prefixIcon: Icon(icon, color: _textMuted.withValues(alpha: 0.5), size: 20),
    filled: true, fillColor: _backgroundGray, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _borderGray, width: 1.5)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _borderGray, width: 1.5)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _primaryBlue, width: 2)),
    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _errorRed, width: 1.5)),
    focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _errorRed, width: 2)),
    errorStyle: const TextStyle(fontSize: 12, color: _errorRed, fontWeight: FontWeight.w500),
  );
}