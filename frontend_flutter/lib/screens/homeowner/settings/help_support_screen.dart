import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Help & Support Screen for the Fix It Marketplace Homeowner App.
///
/// Sections:
///   • Quick Help (contact cards)
///   • FAQ accordion
///   • Report a Problem
///   • App Info
class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
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
  static const Color _infoBlue = Color(0xFF3B82F6);
  static const Color _purple = Color(0xFF8B5CF6);

  // ── FAQ state ──────────────────────────────────────────────────
  int? _expandedFaqIndex;

  // ── Report form ────────────────────────────────────────────────
  final _reportFormKey = GlobalKey<FormState>();
  final _reportController = TextEditingController();
  String _reportCategory = 'Booking Issue';
  bool _isSubmittingReport = false;

  static const List<String> _reportCategories = [
    'Booking Issue',
    'Tradesperson Behavior',
    'Payment Problem',
    'App Bug / Error',
    'Account Issue',
    'Other',
  ];

  static const List<Map<String, String>> _faqs = [
    {
      'q': 'How do I book a tradesperson?',
      'a':
          'Go to the Home tab, browse the available tradespeople, and tap '
          '"Book Now" on any verified professional. Fill in your problem '
          'description, address, schedule, and your offered budget — then '
          'confirm the booking.',
    },
    {
      'q': 'How does payment work?',
      'a':
          'Fix It Marketplace uses a cash-based payment system. Once the '
          'tradesperson marks the job as complete, you settle the agreed '
          'amount with them directly in cash. Digital payment options are '
          'coming in a future update.',
    },
    {
      'q': 'Can I cancel a booking?',
      'a':
          'Yes. Open the booking from your Bookings tab and tap "Cancel '
          'Booking." You can cancel a booking while it is still in Pending '
          'or Accepted status. Cancellations are not allowed once the job '
          'is In Progress.',
    },
    {
      'q': 'How are tradespeople verified?',
      'a':
          'Every tradesperson on Fix It Marketplace goes through a community '
          'vetting process that requires a valid government-issued ID and '
          'a trade license or certification. Accounts are reviewed by our '
          'team before the Verified badge is granted.',
    },
    {
      'q': 'What if I\'m not satisfied with the work?',
      'a':
          'After a job is completed you can leave a rating and review. If '
          'you have a serious concern, tap "Report an Issue" on the booking '
          'details page to open a dispute. Our support team will review '
          'and follow up within 24 hours.',
    },
    {
      'q': 'How do I change my service address?',
      'a':
          'Go to Profile → My Addresses. You can edit your current address '
          'or add new ones. All addresses must be within Calauan, Laguna. '
          'Your primary address is pre-filled when you create a booking.',
    },
    {
      'q': 'Why can\'t I message a tradesperson?',
      'a':
          'The in-app chat becomes available once a tradesperson has accepted '
          'your booking. Before that point, messaging is not yet enabled '
          'for that conversation.',
    },
    {
      'q': 'Is my personal information secure?',
      'a':
          'Yes. All personal data is encrypted in transit and at rest. '
          'We do not sell or share your information with third parties '
          'without your explicit consent. See Privacy & Security in your '
          'profile settings for more controls.',
    },
  ];

  @override
  void dispose() {
    _reportController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (!_reportFormKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _isSubmittingReport = true);
    await Future.delayed(const Duration(milliseconds: 900));
    _reportController.clear();
    setState(() {
      _isSubmittingReport = false;
      _reportCategory = 'Booking Issue';
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Report submitted. We\'ll respond within 24 hours.',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: _successGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
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
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                children: [
                  _buildQuickHelp(),
                  const SizedBox(height: 24),
                  _buildFaqSection(),
                  const SizedBox(height: 24),
                  _buildReportSection(),
                  const SizedBox(height: 24),
                  _buildAppInfo(),
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
                      'Help & Support',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.4,
                      ),
                    ),
                    Text(
                      'We\'re here to help you',
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

  // ── Quick help cards ─────────────────────────────────────────────

  Widget _buildQuickHelp() {
    final options = [
      (
        Icons.chat_rounded,
        'Live Chat',
        'Chat with support',
        _primaryBlue,
        const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      (
        Icons.email_rounded,
        'Email Us',
        'support@fixitph.com',
        _accentOrange,
        const LinearGradient(
          colors: [Color(0xFFF97316), Color(0xFFFB923C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      (
        Icons.phone_rounded,
        'Call Us',
        '+63 917 123 4567',
        _successGreen,
        const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF34D399)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Contact Support'),
        const SizedBox(height: 12),
        Row(
          children: options.map((o) {
            final (icon, title, sub, color, grad) = o;
            final isLast = o == options.last;
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(right: isLast ? 0 : 10),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {},
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _cardWhite,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              gradient: grad,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Icon(icon, color: Colors.white, size: 22),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: _textDark,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            sub,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: _textMuted.withValues(alpha: 0.75),
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── FAQ section ──────────────────────────────────────────────────

  Widget _buildFaqSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Frequently Asked Questions'),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: _cardWhite,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: _faqs.asMap().entries.map((e) {
              final index = e.key;
              final faq = e.value;
              final isExpanded = _expandedFaqIndex == index;
              final isLast = index == _faqs.length - 1;

              return Column(
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => setState(
                        () => _expandedFaqIndex = isExpanded ? null : index,
                      ),
                      borderRadius: index == 0
                          ? const BorderRadius.only(
                              topLeft: Radius.circular(18),
                              topRight: Radius.circular(18),
                            )
                          : isLast && !isExpanded
                          ? const BorderRadius.only(
                              bottomLeft: Radius.circular(18),
                              bottomRight: Radius.circular(18),
                            )
                          : BorderRadius.zero,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: isExpanded
                                    ? _primaryBlue.withValues(alpha: 0.1)
                                    : _backgroundGray,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                isExpanded
                                    ? Icons.remove_rounded
                                    : Icons.add_rounded,
                                color: isExpanded ? _primaryBlue : _textMuted,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                faq['q']!,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: isExpanded ? _primaryBlue : _textDark,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  AnimatedCrossFade(
                    firstChild: const SizedBox(width: double.infinity),
                    secondChild: Container(
                      padding: const EdgeInsets.fromLTRB(56, 0, 16, 16),
                      child: Text(
                        faq['a']!,
                        style: TextStyle(
                          fontSize: 13,
                          color: _textMuted.withValues(alpha: 0.85),
                          height: 1.55,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    crossFadeState: isExpanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 220),
                  ),
                  if (!isLast)
                    Container(
                      height: 1,
                      color: Colors.grey.shade100,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ── Report a problem ─────────────────────────────────────────────

  Widget _buildReportSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Report a Problem'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _cardWhite,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Form(
            key: _reportFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _errorRed.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.flag_outlined,
                        color: _errorRed,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Report an Issue',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: _textDark,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Category ───────────────────────────────────────
                _fieldLabel('Category'),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _reportCategory,
                  items: _reportCategories
                      .map(
                        (c) => DropdownMenuItem(
                          value: c,
                          child: Text(
                            c,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _textDark,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _reportCategory = v ?? _reportCategory),
                  dropdownColor: _cardWhite,
                  isExpanded: true,
                  decoration: _inputDec(
                    'Select category',
                    Icons.category_outlined,
                  ),
                ),
                const SizedBox(height: 14),

                // ── Details ────────────────────────────────────────
                _fieldLabel('Describe the Problem'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _reportController,
                  maxLines: 5,
                  maxLength: 500,
                  style: const TextStyle(
                    fontSize: 14,
                    color: _textDark,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                  decoration:
                      _inputDec(
                        'Please describe the issue in as much detail as possible...',
                        Icons.description_outlined,
                      ).copyWith(
                        alignLabelWithHint: true,
                        counterStyle: TextStyle(
                          fontSize: 11,
                          color: _textMuted.withValues(alpha: 0.6),
                        ),
                      ),
                  validator: (v) => (v == null || v.trim().length < 20)
                      ? 'Please provide at least 20 characters of detail.'
                      : null,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSubmittingReport ? null : _submitReport,
                    icon: _isSubmittingReport
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Icon(Icons.send_rounded, size: 18),
                    label: Text(
                      _isSubmittingReport ? 'Submitting...' : 'Submit Report',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── App info ─────────────────────────────────────────────────────

  Widget _buildAppInfo() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _cardWhite,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // App logo row
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.home_repair_service_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Fix It Marketplace',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: _textDark,
                    ),
                  ),
                  Text(
                    'Homeowner App',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _textMuted.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: Colors.grey.shade100),
          const SizedBox(height: 14),
          _infoRow('Version', '1.0.0 (Build 1)'),
          _infoRow('Platform', 'Android'),
          _infoRow('Region', 'Calauan, Laguna, Philippines'),
          _infoRow('Support Hours', 'Mon – Sat, 8AM – 6PM'),
          const SizedBox(height: 14),
          Container(height: 1, color: Colors.grey.shade100),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _linkButton('Terms of Service', () {}),
              Container(
                width: 1,
                height: 14,
                color: Colors.grey.shade300,
                margin: const EdgeInsets.symmetric(horizontal: 12),
              ),
              _linkButton('Privacy Policy', () {}),
              Container(
                width: 1,
                height: 14,
                color: Colors.grey.shade300,
                margin: const EdgeInsets.symmetric(horizontal: 12),
              ),
              _linkButton('Licenses', () {}),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _textMuted.withValues(alpha: 0.75),
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _linkButton(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _primaryBlue.withValues(alpha: 0.8),
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────

  Widget _sectionLabel(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w800,
      color: _textMuted,
      letterSpacing: 0.5,
    ),
  );

  Widget _fieldLabel(String text) => Text(
    text,
    style: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: _textDark.withValues(alpha: 0.75),
    ),
  );

  InputDecoration _inputDec(String hint, IconData icon) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(
      color: _textMuted.withValues(alpha: 0.5),
      fontSize: 14,
      fontWeight: FontWeight.w400,
    ),
    prefixIcon: Icon(icon, color: _textMuted.withValues(alpha: 0.5), size: 20),
    filled: true,
    fillColor: _backgroundGray,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: _borderGray, width: 1.5),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: _borderGray, width: 1.5),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: _primaryBlue, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: _errorRed, width: 1.5),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: _errorRed, width: 2),
    ),
    errorStyle: const TextStyle(
      fontSize: 12,
      color: _errorRed,
      fontWeight: FontWeight.w500,
    ),
  );
}
