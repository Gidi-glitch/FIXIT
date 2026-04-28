import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/api_service.dart';
import 'booking_store.dart';
import 'review_screen.dart';
import 'edit_request_sheet.dart';

/// Booking Details Screen for the Fix It Marketplace Homeowner App.
/// Shows detailed information about a single booking with a status stepper
/// and dynamic action buttons based on booking status.
class BookingDetailsScreen extends StatefulWidget {
  final BookingModel booking;

  const BookingDetailsScreen({super.key, required this.booking});

  @override
  State<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class ReportProblemSheet extends StatefulWidget {
  final BookingModel booking;
  final Function(String category, String details) onSubmit;

  const ReportProblemSheet({
    super.key,
    required this.booking,
    required this.onSubmit,
  });

  @override
  State<ReportProblemSheet> createState() => _ReportProblemSheetState();
}

class _ReportProblemSheetState extends State<ReportProblemSheet>
    with TickerProviderStateMixin {
  String? selectedCategory;
  final detailsController = TextEditingController();
  final otherController = TextEditingController();
  late AnimationController _headerAnimController;
  late Animation<double> _headerScale;

  final categories =
      const <({String label, IconData icon, String description})>[
        (
          label: 'Work not completed',
          icon: Icons.fact_check_outlined,
          description: 'Task incomplete',
        ),
        (
          label: 'Poor quality',
          icon: Icons.thumb_down_alt_outlined,
          description: 'Quality issue',
        ),
        (
          label: 'Overcharged',
          icon: Icons.price_change_outlined,
          description: 'Pricing issue',
        ),
        (
          label: 'Did not show up',
          icon: Icons.event_busy_outlined,
          description: 'No-show',
        ),
        (
          label: 'Other',
          icon: Icons.more_horiz_rounded,
          description: 'Other issues',
        ),
      ];

  static const Color _primaryBlue = Color(0xFFB91C1C);
  static const Color _accentBlue = Color(0xFFEF4444);
  static const Color _errorRed = Color(0xFFEF4444);
  static const Color _textDark = Color(0xFF111827);
  static const Color _textMuted = Color(0xFF6B7280);
  static const Color _sheetBg = Color(0xFFFAFAFA);
  static const Color _successGreen = Color(0xFF10B981);
  static const Color _warningOrange = Color(0xFFF59E0B);

  bool get _isOther => selectedCategory == 'Other';
  bool get _isDetailsValid => detailsController.text.trim().length >= 10;
  bool get _isOtherValid => !_isOther || otherController.text.trim().isNotEmpty;
  bool get _canSubmit =>
      selectedCategory != null && _isDetailsValid && _isOtherValid;

  @override
  void initState() {
    super.initState();
    _headerAnimController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _headerScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _headerAnimController, curve: Curves.easeOutBack),
    );
    _headerAnimController.forward();
    detailsController.addListener(_refresh);
    otherController.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _headerAnimController.dispose();
    detailsController.removeListener(_refresh);
    otherController.removeListener(_refresh);
    detailsController.dispose();
    otherController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_canSubmit) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please complete all required fields'),
          backgroundColor: _errorRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    final details = detailsController.text.trim();
    final other = otherController.text.trim();

    final combined = _isOther ? 'Other: $other\n$details' : details;
    widget.onSubmit(selectedCategory!, combined);
    Navigator.pop(context);
  }

  InputDecoration _fieldDecoration({
    required String label,
    String? hint,
    Widget? suffix,
    bool isValid = false,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: _textMuted,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: isValid ? _successGreen : Colors.grey.shade200,
          width: isValid ? 1.5 : 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _accentBlue, width: 2),
      ),
      floatingLabelBehavior: FloatingLabelBehavior.auto,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: _sheetBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 12, 20, bottomInset + 20),
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Drag Handle ──────────────────────────────────
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),

                const SizedBox(height: 20),

                // ── Animated Header ──────────────────────────────
                ScaleTransition(
                  scale: _headerScale,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: const LinearGradient(
                        colors: [_primaryBlue, _accentBlue],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _primaryBlue.withValues(alpha: 0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.report_problem_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Report a Problem',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Help us improve by sharing your feedback',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // ── Category Section ─────────────────────────────
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What\'s the issue?',
                      style: TextStyle(
                        color: _textDark,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Select the category that best describes your issue',
                      style: TextStyle(
                        color: _textMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: categories.map((category) {
                        final isSelected = selectedCategory == category.label;

                        return GestureDetector(
                          onTap: () {
                            setState(() => selectedCategory = category.label);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? _accentBlue
                                    : Colors.grey.shade200,
                                width: isSelected ? 2 : 1.5,
                              ),
                              color: isSelected
                                  ? _accentBlue.withValues(alpha: 0.08)
                                  : Colors.white,
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: _accentBlue.withValues(
                                          alpha: 0.15,
                                        ),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : [],
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  category.icon,
                                  size: 22,
                                  color: isSelected ? _accentBlue : _textMuted,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  category.label,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: isSelected ? _accentBlue : _textDark,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                    fontSize: 12,
                                    height: 1.2,
                                  ),
                                  maxLines: 2,
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ── Details Section ─────────────────────────────
                if (_isOther) ...[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Issue Type',
                        style: TextStyle(
                          color: _textDark,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: otherController,
                        textInputAction: TextInputAction.next,
                        maxLength: 50,
                        decoration: _fieldDecoration(
                          label: 'Describe the issue type',
                          hint: 'e.g., Missing materials, Wrong service...',
                          isValid: otherController.text.trim().isNotEmpty,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ],

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Tell us what happened',
                          style: TextStyle(
                            color: _textDark,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '${detailsController.text.length}/400',
                          style: TextStyle(
                            color: _textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: detailsController,
                      minLines: 5,
                      maxLines: 7,
                      maxLength: 400,
                      decoration: _fieldDecoration(
                        label: 'Detailed description',
                        hint:
                            'Provide as much detail as possible. Include dates, times, and specific information...',
                        isValid: _isDetailsValid,
                        suffix: detailsController.text.trim().isEmpty
                            ? null
                            : Padding(
                                padding: const EdgeInsets.only(
                                  right: 12,
                                  bottom: 12,
                                ),
                                child: Icon(
                                  _isDetailsValid
                                      ? Icons.check_circle_rounded
                                      : Icons.info_outline_rounded,
                                  color: _isDetailsValid
                                      ? _successGreen
                                      : _warningOrange,
                                  size: 22,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _isDetailsValid
                                ? _successGreen.withValues(alpha: 0.1)
                                : _warningOrange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _isDetailsValid
                                ? '✓ Minimum requirement met'
                                : '↳ Minimum 10 characters',
                            style: TextStyle(
                              color: _isDetailsValid
                                  ? _successGreen
                                  : _warningOrange,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ── Submit Button ────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _canSubmit ? _submit : null,
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      disabledBackgroundColor: Colors.grey.shade200,
                      disabledForegroundColor: Colors.grey.shade400,
                      backgroundColor: _errorRed,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Submit Report',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // ── Helper Text ──────────────────────────────────
                Center(
                  child: Text(
                    'Our support team will review your report within 24 hours',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BookingDetailsScreenState extends State<BookingDetailsScreen>
    with SingleTickerProviderStateMixin {
  late BookingModel _currentBooking;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  bool _isShowingReview = false;
  bool _isShowingReportModal = false;
  bool _isActionLoading = false;

  // ── Color Palette ──────────────────────────────────────────────
  static const Color _primaryBlue = Color(0xFF1E3A8A);
  static const Color _accentOrange = Color(0xFFF97316);
  static const Color _backgroundGray = Color(0xFFF9FAFB);
  static const Color _textDark = Color(0xFF111827);
  static const Color _textMuted = Color(0xFF6B7280);
  static const Color _cardWhite = Color(0xFFFFFFFF);
  static const Color _successGreen = Color(0xFF10B981);
  static const Color _warningYellow = Color(0xFFF59E0B);
  static const Color _infoBlue = Color(0xFF3B82F6);
  static const Color _errorRed = Color(0xFFEF4444);

  @override
  void initState() {
    super.initState();
    _currentBooking =
        BookingStore.getBookingById(widget.booking.id) ?? widget.booking;
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
    _slideController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reloadBookingFromServer();
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  // Status progression: Pending → Accepted → In Progress → Completed
  List<String> get _statusSteps => [
    'Pending',
    'Accepted',
    'In Progress',
    'Completed',
  ];

  int get _currentStepIndex => _statusSteps.indexOf(_currentBooking.status);
  bool get _requiresCompletionConfirmation =>
      _currentBooking.status == 'Completed' && !_currentBooking.isReviewed;
  bool get _hasCancellationReason =>
      _currentBooking.cancellationReason.trim().isNotEmpty;

  Future<void> _showReviewOverlay() async {
    if (_isShowingReview || _isShowingReportModal || !mounted) return;

    _isShowingReview = true;

    try {
      await showModalBottomSheet(
        context: context,
        isDismissible: false,
        enableDrag: false,
        isScrollControlled: true,
        builder: (_) => ReviewScreen(booking: _currentBooking),
      );
    } finally {
      _isShowingReview = false;
    }

    if (!mounted) return;

    final latest = BookingStore.getBookingById(_currentBooking.id);
    if (latest != null) {
      setState(() => _currentBooking = latest);
    }
  }

  Future<String> _readToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token')?.trim();
    if (token == null || token.isEmpty) {
      throw Exception('Session expired. Please log in again.');
    }
    return token;
  }

  Future<void> _reloadBookingFromServer() async {
    try {
      final token = await _readToken();
      final response = await ApiService.getBookingById(
        token: token,
        bookingId: _currentBooking.id,
      );
      final bookingRaw = response['booking'];
      if (bookingRaw is! Map<String, dynamic>) {
        return;
      }

      BookingStore.upsertFromApi(bookingRaw);
      final latest = BookingStore.getBookingById(_currentBooking.id);
      if (!mounted || latest == null) {
        return;
      }
      setState(() => _currentBooking = latest);
    } catch (_) {
      // Keep existing UI state if reload fails.
    }
  }

  Future<void> _cancelBooking() async {
    if (_isActionLoading) return;

    setState(() => _isActionLoading = true);
    try {
      final token = await _readToken();
      final response = await ApiService.cancelBooking(
        token: token,
        bookingId: _currentBooking.id,
      );

      final bookingRaw = response['booking'];
      if (bookingRaw is Map<String, dynamic>) {
        BookingStore.upsertFromApi(bookingRaw);
      }

      if (!mounted) return;
      setState(() => _isActionLoading = false);
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isActionLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _submitIssue(String category, String details) async {
    try {
      final token = await _readToken();
      await ApiService.reportBookingIssue(
        token: token,
        bookingId: _currentBooking.id,
        category: category,
        details: details,
      );

      await _reloadBookingFromServer();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Issue submitted. Admin will review your report shortly.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _handleConfirmCompletion() async {
    if (_isShowingReportModal || _isShowingReview) return;

    final latest = BookingStore.getBookingById(_currentBooking.id);
    if (latest != null) {
      setState(() => _currentBooking = latest);
    }

    if (_currentBooking.status != 'Completed') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This booking is no longer marked as completed.'),
        ),
      );
      return;
    }

    await _showReviewOverlay();
  }

  Future<void> _showReportProblemModal() async {
    try {
      _isShowingReportModal = true;

      await showModalBottomSheet<void>(
        context: context,
        isDismissible: true,
        enableDrag: true,
        isScrollControlled: true,
        showDragHandle: true,
        backgroundColor: Colors.transparent,
        builder: (_) => ReportProblemSheet(
          booking: _currentBooking,
          onSubmit: (category, details) {
            _submitIssue(category, details);
          },
        ),
      );
    } finally {
      _isShowingReportModal = false;
    }
  }

  Future<void> _showEditRequestModal() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      useSafeArea: false,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.94,
      ),
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.94,
        child: EditRequestSheet(
          booking: _currentBooking,
          onSaved: () async {
            // Refresh local state from the store
            final latest = BookingStore.getBookingById(_currentBooking.id);
            if (latest != null && mounted) {
              setState(() => _currentBooking = latest);
            }

            final refreshCandidate =
                BookingStore.getBookingById(_currentBooking.id) ??
                _currentBooking;

            try {
              final token = await _readToken();
              final response = await ApiService.updateBooking(
                token: token,
                bookingId: refreshCandidate.id,
                data: {
                  'specialization': refreshCandidate.specialization,
                  'problem_description': refreshCandidate.problemDescription,
                  'address': refreshCandidate.address,
                  'date': refreshCandidate.date,
                  'time': refreshCandidate.time,
                  'offered_budget': refreshCandidate.offeredBudget,
                },
              );

              final bookingRaw = response['booking'];
              if (bookingRaw is Map<String, dynamic>) {
                BookingStore.upsertFromApi(bookingRaw);
                final serverLatest = BookingStore.getBookingById(
                  refreshCandidate.id,
                );
                if (serverLatest != null && mounted) {
                  setState(() => _currentBooking = serverLatest);
                }
              }

              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Row(
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Booking request updated successfully.',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: _successGreen,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: const EdgeInsets.all(16),
                  duration: const Duration(seconds: 2),
                ),
              );
            } catch (e) {
              await _reloadBookingFromServer();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(e.toString().replaceFirst('Exception: ', '')),
                ),
              );
            }
          },
        ),
      ),
    );
  }

  Future<bool> _showCompletionWarningDialog() async {
    final shouldLeave =
        await showDialog<bool>(
          context: context,
          barrierColor: Colors.black.withValues(alpha: 0.4),
          builder: (context) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 0,
              backgroundColor: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 40,
                      offset: const Offset(0, 20),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Header with Icon ──────────────────────────────
                    Padding(
                      padding: const EdgeInsets.only(top: 28, bottom: 16),
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: _warningYellow.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.info_outline_rounded,
                          color: _warningYellow,
                          size: 32,
                        ),
                      ),
                    ),

                    // ── Title ─────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'Complete Your Review',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: _textDark,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ── Content ───────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'Help us improve by sharing your feedback about this service. Your review is important!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: _textMuted,
                          height: 1.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ── Action Buttons ────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          // ── Primary Button ────────────────────────────
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(context, false),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _primaryBlue,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Text(
                                'Leave a Review',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // ── Secondary Button ──────────────────────────
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _textDark,
                                side: BorderSide(
                                  color: _textMuted.withValues(alpha: 0.2),
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Text(
                                'Skip for Now',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: _textDark,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        ) ??
        false;

    return shouldLeave;
  }

  Future<void> _handleBackAttempt() async {
    if (!_requiresCompletionConfirmation) {
      if (mounted) Navigator.pop(context);
      return;
    }

    final shouldLeave = await _showCompletionWarningDialog();
    if (shouldLeave && mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: PopScope(
        canPop:
            !_requiresCompletionConfirmation ||
            _isShowingReportModal ||
            _isShowingReview,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop && !_isShowingReportModal) {
            _handleBackAttempt();
          }
        },
        child: Scaffold(
          backgroundColor: _backgroundGray,
          appBar: _buildAppBar(),
          body: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // ── Status Stepper ────────────────────────────────
                  _buildStatusStepper(),

                  // ── Cancellation Notice ───────────────────────────
                  _buildCancellationNoticeCard(),

                  // ── Tradesperson Card ─────────────────────────────
                  _buildTradespersonCard(),

                  // ── Job Details ───────────────────────────────────
                  _buildJobDetailsCard(),

                  // ── Scheduled Date & Time ─────────────────────────
                  _buildDateTimeCard(),

                  // ── Address Card ──────────────────────────────────
                  _buildAddressCard(),

                  // ── Budget Card ───────────────────────────────────
                  _buildBudgetCard(),

                  // ── Action Buttons ────────────────────────────────
                  _buildActionButtons(),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  APP BAR
  // ═══════════════════════════════════════════════════════════════

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      automaticallyImplyLeading: false,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: _handleBackAttempt,
      ),
      iconTheme: const IconThemeData(color: _textDark),
      title: const Text(
        'Booking Details',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: _textDark,
        ),
      ),
      centerTitle: false,
      systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  STATUS STEPPER
  // ═══════════════════════════════════════════════════════════════

  Widget _buildStatusStepper() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Booking Progress',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _textMuted,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: List.generate(_statusSteps.length, (index) {
              final isCompleted = index <= _currentStepIndex;
              final isActive = index == _currentStepIndex;

              return Expanded(
                child: Column(
                  children: [
                    // Step circle
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isCompleted ? _successGreen : _cardWhite,
                        border: Border.all(
                          color: isCompleted
                              ? _successGreen
                              : _textMuted.withValues(alpha: 0.3),
                          width: 2,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: isCompleted
                            ? const Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 18,
                              )
                            : Text(
                                '${index + 1}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: isActive ? _primaryBlue : _textMuted,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Label
                    Text(
                      _statusSteps[index],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isCompleted ? _successGreen : _textMuted,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildCancellationNoticeCard() {
    if (_currentBooking.status != 'Cancelled') {
      return const SizedBox.shrink();
    }

    final reason = _currentBooking.cancellationReason.trim();
    final hasReason = reason.isNotEmpty;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _errorRed.withValues(alpha: 0.08),
        border: Border.all(color: _errorRed.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _errorRed.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.report_off_rounded,
                  color: _errorRed,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasReason ? 'Report Cancelled' : 'Booking Cancelled',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: _textDark,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      hasReason
                          ? 'Admin cancelled your report, so this booking was cancelled.'
                          : 'This booking has been cancelled.',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _textMuted,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (reason.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _errorRed.withValues(alpha: 0.18)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Reason',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: _errorRed,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    reason,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _textDark,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  TRADESPERSON CARD
  // ═══════════════════════════════════════════════════════════════

  Widget _buildTradespersonCard() {
    final tradespersonProfileImageUrl =
        (_currentBooking.tradespersonProfileImageUrl ?? '').trim();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardWhite,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_primaryBlue, _infoBlue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: tradespersonProfileImageUrl.isNotEmpty
                  ? Image.network(
                      tradespersonProfileImageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Center(
                        child: Text(
                          _currentBooking.tradespersonAvatar,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        _currentBooking.tradespersonAvatar,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentBooking.tradespersonName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _currentBooking.trade,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _textMuted,
                  ),
                ),
                const SizedBox(height: 6),
                // Rating (mock)
                Row(
                  children: [
                    Icon(Icons.star_rounded, size: 14, color: _warningYellow),
                    const SizedBox(width: 4),
                    const Text(
                      '4.9 (142 reviews)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Verification badge
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _successGreen.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.verified_rounded,
              size: 18,
              color: _successGreen,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  JOB DETAILS CARD
  // ═══════════════════════════════════════════════════════════════

  Widget _buildJobDetailsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardWhite,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Job Details',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _textDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _currentBooking.specialization,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _textMuted.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: Colors.grey.shade100),
          const SizedBox(height: 12),
          Text(
            _currentBooking.problemDescription,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _textDark,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  DATE & TIME CARD
  // ═══════════════════════════════════════════════════════════════

  Widget _buildDateTimeCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardWhite,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: _infoBlue.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.access_time_rounded,
              color: _infoBlue,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Scheduled',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_currentBooking.date} at ${_currentBooking.time}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  ADDRESS CARD
  // ═══════════════════════════════════════════════════════════════

  Widget _buildAddressCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardWhite,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: _primaryBlue.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.location_on_rounded,
              color: _primaryBlue,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Service Address',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _currentBooking.address,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _textDark,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  BUDGET CARD
  // ═══════════════════════════════════════════════════════════════

  Widget _buildBudgetCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardWhite,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: _successGreen.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.attach_money_rounded,
              color: _successGreen,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Offered Budget',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '₱${_currentBooking.offeredBudget.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: _successGreen,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  ACTION BUTTONS
  // ═══════════════════════════════════════════════════════════════

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          if (_currentBooking.status == 'Pending') ...[
            // Cancel & Edit for Pending
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isActionLoading ? null : _cancelBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _errorRed,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Cancel Booking',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _showEditRequestModal,
                style: OutlinedButton.styleFrom(
                  foregroundColor: _primaryBlue,
                  side: const BorderSide(color: _primaryBlue, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Edit Request',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ] else if (_currentBooking.status == 'Accepted' ||
              _currentBooking.status == 'In Progress') ...[
            // Message + secondary action (Cancel for Accepted, Call for In Progress)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isActionLoading
                        ? null
                        : () {
                            Navigator.pop(context, {
                              'openMessage': true,
                              'tradespersonName':
                                  _currentBooking.tradespersonName,
                              'trade': _currentBooking.trade,
                              'avatar': _currentBooking.tradespersonAvatar,
                            });
                          },
                    icon: const Icon(Icons.message_rounded, size: 18),
                    label: const Text('Message'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _currentBooking.status == 'Accepted'
                      ? OutlinedButton.icon(
                          onPressed: _isActionLoading ? null : _cancelBooking,
                          icon: const Icon(Icons.cancel_rounded, size: 18),
                          label: const Text('Cancel Booking'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _errorRed,
                            side: const BorderSide(
                              color: _errorRed,
                              width: 1.5,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        )
                      : OutlinedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Calling tradesperson...'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          icon: const Icon(Icons.call_rounded, size: 18),
                          label: const Text('Call'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _primaryBlue,
                            side: const BorderSide(
                              color: _primaryBlue,
                              width: 1.5,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ] else if (_currentBooking.status == 'Completed') ...[
            // For Completed - require user decision flow.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
              decoration: BoxDecoration(
                color: _successGreen.withValues(alpha: 0.1),
                border: Border.all(color: _successGreen, width: 1.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: _successGreen,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _currentBooking.isReviewed
                          ? 'Service completed and reviewed'
                          : 'Service Completed',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _successGreen,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (!_currentBooking.isReviewed) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _handleConfirmCompletion,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accentOrange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Confirm Completion',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _showReportProblemModal,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _errorRed,
                        side: const BorderSide(color: _errorRed, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Report a Problem',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ] else if (_currentBooking.status == 'Cancelled') ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
              decoration: BoxDecoration(
                color: _errorRed.withValues(alpha: 0.08),
                border: Border.all(color: _errorRed.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.cancel_outlined, color: _errorRed, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _hasCancellationReason
                          ? 'This booking was cancelled after admin cancelled your report.'
                          : 'This booking has been cancelled.',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _textDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _textMuted,
                  side: BorderSide(
                    color: _textMuted.withValues(alpha: 0.35),
                    width: 1.3,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Back to Bookings',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ] else if (_currentBooking.status == 'Under Review' ||
              _currentBooking.status == 'Disputed') ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
              decoration: BoxDecoration(
                color: _warningYellow.withValues(alpha: 0.12),
                border: Border.all(color: _warningYellow, width: 1.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.support_agent_rounded,
                    color: _warningYellow,
                    size: 22,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Issue reported. This booking is now under admin review.',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _textDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _textMuted,
                  side: BorderSide(
                    color: _textMuted.withValues(alpha: 0.35),
                    width: 1.3,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Back to Bookings',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
