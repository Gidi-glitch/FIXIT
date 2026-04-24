import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'booking_store.dart';

/// Enhanced Edit Request bottom sheet for Pending bookings.
///
/// Features:
///  • Animated scale-in header (matching ReportProblemSheet style)
///  • Booking context identity pill
///  • Grouped sections: Service Details / Location / Schedule / Budget
///  • Real date & time pickers (showDatePicker / showTimePicker)
///  • Per-field green border + check icon when valid
///  • Character counter on description
///  • Animated completion progress banner
///  • Gradient Save button with loading state
///
/// Usage — replace the `_showEditRequestModal` body with:
/// ```dart
/// Future<void> _showEditRequestModal() async {
///   await showModalBottomSheet<void>(
///     context: context,
///     isScrollControlled: true,
///     useSafeArea: true,
///     backgroundColor: Colors.transparent,
///     builder: (_) => EditRequestSheet(
///       booking: _currentBooking,
///       onSaved: () {
///         final latest = BookingStore.getBookingById(_currentBooking.id);
///         if (latest != null && mounted) setState(() => _currentBooking = latest);
///         ScaffoldMessenger.of(context).showSnackBar(SnackBar(
///           content: const Row(children: [
///             Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
///             SizedBox(width: 10),
///             Expanded(child: Text('Booking request updated.', style: TextStyle(fontWeight: FontWeight.w600))),
///           ]),
///           backgroundColor: const Color(0xFF10B981),
///           behavior: SnackBarBehavior.floating,
///           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
///           margin: const EdgeInsets.all(16),
///         ));
///       },
///     ),
///   );
/// }
/// ```
class EditRequestSheet extends StatefulWidget {
  const EditRequestSheet({
    super.key,
    required this.booking,
    required this.onSaved,
  });

  final BookingModel booking;

  /// Called after `BookingStore.updateBookingDetails` succeeds and the
  /// sheet is popped. Use this to refresh the parent's local state and
  /// show a success SnackBar.
  final Future<void> Function() onSaved;

  @override
  State<EditRequestSheet> createState() => _EditRequestSheetState();
}

class _EditRequestSheetState extends State<EditRequestSheet>
    with SingleTickerProviderStateMixin {
  // ── Color Palette (matches BookingDetailsScreen) ───────────────
  static const Color _primaryBlue = Color(0xFF1E3A8A);
  static const Color _infoBlue = Color(0xFF3B82F6);
  static const Color _accentOrange = Color(0xFFF97316);
  static const Color _backgroundGray = Color(0xFFF9FAFB);
  static const Color _textDark = Color(0xFF111827);
  static const Color _textMuted = Color(0xFF6B7280);
  static const Color _cardWhite = Color(0xFFFFFFFF);
  static const Color _successGreen = Color(0xFF10B981);
  static const Color _warningYellow = Color(0xFFF59E0B);
  static const Color _borderGray = Color(0xFFE5E7EB);

  // ── Animation ──────────────────────────────────────────────────
  late final AnimationController _headerAnimCtrl;
  late final Animation<double> _headerScale;

  // ── Controllers ────────────────────────────────────────────────
  late final TextEditingController _descriptionCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _budgetCtrl;

  // ── Services / skills state ───────────────────────────────────
  late final List<String> _serviceOptions;
  final Set<String> _selectedServices = <String>{};

  // ── Schedule state ─────────────────────────────────────────────
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;

  bool _isSaving = false;

  // ── Lifecycle ──────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    // Header entrance animation
    _headerAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _headerScale = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _headerAnimCtrl, curve: Curves.easeOutBack),
    );
    _headerAnimCtrl.forward();

    // Build selectable services from booking + tradesperson profile skills
    _serviceOptions = _extractServiceOptions();

    final existing = widget.booking.specialization
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty);
    _selectedServices.addAll(existing);

    // Ensure previous selections are still available as chips.
    for (final service in existing) {
      if (!_serviceOptions.contains(service)) {
        _serviceOptions.insert(0, service);
      }
    }

    if (_selectedServices.isEmpty && _serviceOptions.isNotEmpty) {
      _selectedServices.add(_serviceOptions.first);
    }

    _descriptionCtrl = TextEditingController(
      text: widget.booking.problemDescription,
    );
    _addressCtrl = TextEditingController(text: widget.booking.address);
    _budgetCtrl = TextEditingController(
      text: widget.booking.offeredBudget.toStringAsFixed(0),
    );

    // Parse existing date/time strings → typed values
    _selectedDate = _parseDate(widget.booking.date);
    _selectedTime = _parseTime(widget.booking.time);

    // Drive UI refresh on every keystroke
    for (final c in [_descriptionCtrl, _addressCtrl, _budgetCtrl]) {
      c.addListener(_refresh);
    }
  }

  List<String> _extractServiceOptions() {
    final trade = widget.booking.trade.trim();

    final fromCurrent = widget.booking.specialization
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final raw = <String>[if (trade.isNotEmpty) trade, ...fromCurrent];

    final seen = <String>{};
    final deduped = <String>[];
    for (final value in raw) {
      final key = value.toLowerCase();
      if (seen.add(key)) {
        deduped.add(value);
      }
    }

    if (deduped.isEmpty && trade.isNotEmpty) {
      return [trade];
    }

    return deduped;
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _headerAnimCtrl.dispose();
    for (final c in [_descriptionCtrl, _addressCtrl, _budgetCtrl]) {
      c.removeListener(_refresh);
      c.dispose();
    }
    super.dispose();
  }

  // ── Date / Time helpers ────────────────────────────────────────

  DateTime _parseDate(String s) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (s.toLowerCase().trim()) {
      case 'today':
        return today;
      case 'tomorrow':
        return today.add(const Duration(days: 1));
      default:
        try {
          const months = {
            'jan': 1,
            'feb': 2,
            'mar': 3,
            'apr': 4,
            'may': 5,
            'jun': 6,
            'jul': 7,
            'aug': 8,
            'sep': 9,
            'oct': 10,
            'nov': 11,
            'dec': 12,
          };
          final parts = s.trim().split(' ');
          if (parts.length == 2) {
            final m = months[parts[0].toLowerCase()];
            final d = int.tryParse(parts[1]);
            if (m != null && d != null) {
              return DateTime(now.year, m, d);
            }
          }
        } catch (_) {}
        return today;
    }
  }

  TimeOfDay _parseTime(String s) {
    try {
      final parts = s.trim().split(' ');
      if (parts.length == 2) {
        final tp = parts[0].split(':');
        int h = int.parse(tp[0]);
        final m = int.parse(tp[1]);
        if (parts[1].toUpperCase() == 'PM' && h != 12) h += 12;
        if (parts[1].toUpperCase() == 'AM' && h == 12) h = 0;
        return TimeOfDay(hour: h, minute: m);
      }
    } catch (_) {}
    return TimeOfDay.now();
  }

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final date = DateTime(d.year, d.month, d.day);
    if (date == today) return 'Today';
    if (date == tomorrow) return 'Tomorrow';
    const months = [
      '',
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
    return '${months[d.month]} ${d.day}';
  }

  String _formatTime(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final p = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $p';
  }

  // ── Pickers ────────────────────────────────────────────────────

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isBefore(now) ? now : _selectedDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _primaryBlue,
            onPrimary: Colors.white,
            surface: _cardWhite,
            onSurface: _textDark,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _primaryBlue,
            onPrimary: Colors.white,
            surface: _cardWhite,
            onSurface: _textDark,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  // ── Validation ─────────────────────────────────────────────────

  bool get _serviceValid => _selectedServices.isNotEmpty;
  bool get _descriptionValid => _descriptionCtrl.text.trim().isNotEmpty;
  bool get _addressValid => _addressCtrl.text.trim().isNotEmpty;
  bool get _budgetValid {
    final v = double.tryParse(_budgetCtrl.text.trim());
    return v != null && v > 0;
  }

  // Date + time always have defaults so they count as 2 of the 6
  int get _completedCount =>
      (_serviceValid ? 1 : 0) +
      (_descriptionValid ? 1 : 0) +
      (_addressValid ? 1 : 0) +
      1 + // date always set
      1 + // time always set
      (_budgetValid ? 1 : 0);

  bool get _canSave =>
      _serviceValid && _descriptionValid && _addressValid && _budgetValid;

  // ── Save ────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!_canSave) return;
    setState(() => _isSaving = true);

    // Slight delay for polish / allow animation to show
    await Future.delayed(const Duration(milliseconds: 320));

    final budget =
        double.tryParse(_budgetCtrl.text.trim()) ??
        widget.booking.offeredBudget;

    BookingStore.updateBookingDetails(
      widget.booking.id,
      specialization: _selectedServices.join(', '),
      problemDescription: _descriptionCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      date: _formatDate(_selectedDate),
      time: _formatTime(_selectedTime),
      offeredBudget: budget,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);
    Navigator.pop(context);
    await widget.onSaved();
  }

  // ═══════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: const BoxDecoration(
          color: _backgroundGray,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, bottomInset + 24),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Drag handle ─────────────────────────────────
                  _buildDragHandle(),
                  const SizedBox(height: 16),

                  // ── Animated header banner ───────────────────────
                  _buildHeader(),
                  const SizedBox(height: 16),

                  // ── Booking context pill ─────────────────────────
                  _buildContextPill(),
                  const SizedBox(height: 22),

                  // ── Service Details ──────────────────────────────
                  _sectionLabel(
                    'Service Details',
                    Icons.handyman_rounded,
                    _primaryBlue,
                  ),
                  const SizedBox(height: 12),
                  _buildServiceField(),
                  const SizedBox(height: 10),
                  _buildDescriptionField(),
                  const SizedBox(height: 22),

                  // ── Location ─────────────────────────────────────
                  _sectionLabel(
                    'Location',
                    Icons.location_on_outlined,
                    const Color(0xFFEC4899),
                  ),
                  const SizedBox(height: 12),
                  _buildAddressField(),
                  const SizedBox(height: 22),

                  // ── Schedule ─────────────────────────────────────
                  _sectionLabel(
                    'Schedule',
                    Icons.calendar_today_rounded,
                    _infoBlue,
                  ),
                  const SizedBox(height: 12),
                  _buildScheduleRow(),
                  const SizedBox(height: 22),

                  // ── Budget ───────────────────────────────────────
                  _sectionLabel(
                    'Offered Budget',
                    Icons.payments_outlined,
                    _successGreen,
                  ),
                  const SizedBox(height: 12),
                  _buildBudgetField(),
                  const SizedBox(height: 8),
                  _buildBudgetHint(),
                  const SizedBox(height: 22),

                  // ── Completion banner ────────────────────────────
                  _buildCompletionBanner(),
                  const SizedBox(height: 20),

                  // ── Action buttons ───────────────────────────────
                  _buildButtons(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  DRAG HANDLE
  // ═══════════════════════════════════════════════════════════════

  Widget _buildDragHandle() => Center(
    child: Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(99),
      ),
    ),
  );

  // ═══════════════════════════════════════════════════════════════
  //  ANIMATED HEADER
  // ═══════════════════════════════════════════════════════════════

  Widget _buildHeader() {
    return ScaleTransition(
      scale: _headerScale,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(18, 18, 14, 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_primaryBlue, _infoBlue],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _primaryBlue.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon box
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.edit_note_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),

            // Title + subtitle
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Edit Request',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Update details before the request is accepted',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),

            // Close button
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  BOOKING CONTEXT PILL
  // ═══════════════════════════════════════════════════════════════

  Widget _buildContextPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderGray),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_primaryBlue, _infoBlue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                widget.booking.tradespersonAvatar,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Name + meta
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.booking.tradespersonName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${widget.booking.trade} · ${widget.booking.id}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: _textMuted.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),

          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _warningYellow.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _warningYellow.withValues(alpha: 0.35)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.access_time_rounded,
                  size: 12,
                  color: _warningYellow,
                ),
                SizedBox(width: 4),
                Text(
                  'Pending',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _warningYellow,
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
  //  SECTION LABEL
  // ═══════════════════════════════════════════════════════════════

  Widget _sectionLabel(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 9),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: _textDark,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  SERVICE FIELD
  // ═══════════════════════════════════════════════════════════════

  Widget _buildServiceField() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: _cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _serviceValid
              ? _successGreen.withValues(alpha: 0.4)
              : _borderGray,
          width: _serviceValid ? 1.8 : 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Select one or more services',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _textMuted.withValues(alpha: 0.85),
                  ),
                ),
              ),
              if (_selectedServices.isNotEmpty)
                TextButton.icon(
                  onPressed: () => setState(_selectedServices.clear),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: _textMuted,
                  ),
                  icon: const Icon(Icons.close_rounded, size: 16),
                  label: const Text(
                    'Clear',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _serviceOptions.map((service) {
              final isSelected = _selectedServices.contains(service);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedServices.remove(service);
                    } else {
                      _selectedServices.add(service);
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _primaryBlue
                        : _primaryBlue.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(
                      color: isSelected
                          ? _primaryBlue
                          : _primaryBlue.withValues(alpha: 0.22),
                      width: 1.2,
                    ),
                    boxShadow: [
                      if (isSelected)
                        BoxShadow(
                          color: _primaryBlue.withValues(alpha: 0.22),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelected) ...[
                        const Icon(
                          Icons.check_rounded,
                          size: 13,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 5),
                      ],
                      Text(
                        service,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? Colors.white : _primaryBlue,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                _serviceValid
                    ? Icons.check_circle_rounded
                    : Icons.info_outline_rounded,
                size: 14,
                color: _serviceValid ? _successGreen : _textMuted,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _serviceValid
                      ? '${_selectedServices.length} selected. Tap a chip to remove it.'
                      : 'Choose services based on this tradesperson\'s skills.',
                  style: TextStyle(
                    fontSize: 12,
                    color: (_serviceValid ? _successGreen : _textMuted)
                        .withValues(alpha: 0.85),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  DESCRIPTION FIELD
  // ═══════════════════════════════════════════════════════════════

  Widget _buildDescriptionField() {
    return TextField(
      controller: _descriptionCtrl,
      maxLines: 4,
      maxLength: 300,
      keyboardType: TextInputType.multiline,
      style: const TextStyle(
        fontSize: 14,
        color: _textDark,
        fontWeight: FontWeight.w500,
        height: 1.5,
      ),
      decoration: InputDecoration(
        hintText:
            'Briefly explain the issue — include any details that might help...',
        hintStyle: TextStyle(
          color: _textMuted.withValues(alpha: 0.5),
          fontSize: 13,
          height: 1.45,
        ),
        labelText: 'Problem Description',
        labelStyle: TextStyle(
          color: _textMuted.withValues(alpha: 0.8),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        alignLabelWithHint: true,
        prefixIcon: Padding(
          padding: const EdgeInsets.only(bottom: 52),
          child: Icon(
            Icons.description_outlined,
            size: 20,
            color: _textMuted.withValues(alpha: 0.6),
          ),
        ),
        counterStyle: TextStyle(
          fontSize: 11,
          color: _textMuted.withValues(alpha: 0.6),
        ),
        suffixIcon: _descriptionCtrl.text.trim().isNotEmpty
            ? Padding(
                padding: const EdgeInsets.only(bottom: 52, right: 4),
                child: Icon(
                  _descriptionValid
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 18,
                  color: _descriptionValid
                      ? _successGreen
                      : _textMuted.withValues(alpha: 0.3),
                ),
              )
            : null,
        filled: true,
        fillColor: _cardWhite,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _borderGray, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: _descriptionValid
                ? _successGreen.withValues(alpha: 0.4)
                : _borderGray,
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _primaryBlue, width: 2),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  ADDRESS FIELD
  // ═══════════════════════════════════════════════════════════════

  Widget _buildAddressField() {
    return _styledField(
      controller: _addressCtrl,
      label: 'Service Address',
      hint: 'Enter the complete service address',
      icon: Icons.location_on_outlined,
      isValid: _addressValid,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  SCHEDULE ROW
  // ═══════════════════════════════════════════════════════════════

  Widget _buildScheduleRow() {
    return Row(
      children: [
        Expanded(
          child: _buildPickerTile(
            topLabel: 'Date',
            value: _formatDate(_selectedDate),
            icon: Icons.calendar_today_rounded,
            color: _infoBlue,
            onTap: _pickDate,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildPickerTile(
            topLabel: 'Time',
            value: _formatTime(_selectedTime),
            icon: Icons.access_time_rounded,
            color: _accentOrange,
            onTap: _pickTime,
          ),
        ),
      ],
    );
  }

  Widget _buildPickerTile({
    required String topLabel,
    required String value,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        decoration: BoxDecoration(
          color: _cardWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.35), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top label row
            Row(
              children: [
                Icon(icon, size: 13, color: color),
                const SizedBox(width: 5),
                Text(
                  topLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Value row
            Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: _textDark,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.expand_more_rounded,
                  size: 18,
                  color: _textMuted.withValues(alpha: 0.45),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  BUDGET FIELD
  // ═══════════════════════════════════════════════════════════════

  Widget _buildBudgetField() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // ₱ prefix chip
        SizedBox(
          height: 54,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: _successGreen.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                bottomLeft: Radius.circular(14),
              ),
              border: Border(
                top: BorderSide(
                  color: _successGreen.withValues(alpha: 0.35),
                  width: 1.5,
                ),
                bottom: BorderSide(
                  color: _successGreen.withValues(alpha: 0.35),
                  width: 1.5,
                ),
                left: BorderSide(
                  color: _successGreen.withValues(alpha: 0.35),
                  width: 1.5,
                ),
              ),
            ),
            child: Center(
              child: Text(
                '₱',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: _successGreen.withValues(alpha: 0.9),
                ),
              ),
            ),
          ),
        ),

        // Amount input
        Expanded(
          child: SizedBox(
            height: 54,
            child: TextField(
              controller: _budgetCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: _textDark,
              ),
              decoration: InputDecoration(
                hintText: '0',
                hintStyle: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _textMuted.withValues(alpha: 0.3),
                ),
                suffixIcon: _budgetCtrl.text.trim().isNotEmpty
                    ? Icon(
                        _budgetValid
                            ? Icons.check_circle_rounded
                            : Icons.warning_amber_rounded,
                        size: 20,
                        color: _budgetValid
                            ? _successGreen
                            : _textMuted.withValues(alpha: 0.4),
                      )
                    : null,
                filled: true,
                fillColor: _cardWhite,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(14),
                    bottomRight: Radius.circular(14),
                  ),
                  borderSide: BorderSide(
                    color: _successGreen.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(14),
                    bottomRight: Radius.circular(14),
                  ),
                  borderSide: BorderSide(
                    color: _budgetValid
                        ? _successGreen.withValues(alpha: 0.4)
                        : _borderGray,
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(14),
                    bottomRight: Radius.circular(14),
                  ),
                  borderSide: const BorderSide(color: _primaryBlue, width: 2),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetHint() {
    return Row(
      children: [
        Icon(
          Icons.info_outline_rounded,
          size: 13,
          color: _textMuted.withValues(alpha: 0.55),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'This is your proposed budget. The tradesperson may accept or negotiate.',
            style: TextStyle(
              fontSize: 12,
              color: _textMuted.withValues(alpha: 0.75),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  COMPLETION BANNER
  // ═══════════════════════════════════════════════════════════════

  Widget _buildCompletionBanner() {
    const totalFields = 6;
    final completed = _completedCount;
    final fraction = completed / totalFields;
    final isAllDone = _canSave;
    final color = isAllDone ? _successGreen : _warningYellow;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isAllDone
                    ? Icons.check_circle_rounded
                    : Icons.info_outline_rounded,
                size: 16,
                color: color,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isAllDone
                      ? 'All set! You can save your changes now.'
                      : 'Fill in all fields to save changes.',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isAllDone ? _successGreen : _textDark,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$completed / $totalFields',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 5,
              backgroundColor: color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  ACTION BUTTONS
  // ═══════════════════════════════════════════════════════════════

  Widget _buildButtons() {
    return Row(
      children: [
        // Discard
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: _textMuted,
              side: BorderSide(color: _textMuted.withValues(alpha: 0.3)),
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Discard',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Save Changes — gradient when active
        Expanded(
          flex: 2,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: _canSave
                  ? const LinearGradient(
                      colors: [_primaryBlue, _infoBlue],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: _canSave ? null : _textMuted.withValues(alpha: 0.14),
              boxShadow: _canSave
                  ? [
                      BoxShadow(
                        color: _primaryBlue.withValues(alpha: 0.3),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ]
                  : [],
            ),
            child: ElevatedButton(
              onPressed: (_canSave && !_isSaving) ? _save : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                disabledBackgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                disabledForegroundColor: _textMuted.withValues(alpha: 0.5),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _isSaving
                    ? const SizedBox(
                        key: ValueKey('loading'),
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Row(
                        key: ValueKey('label'),
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.save_rounded, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Save Changes',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  SHARED STYLED FIELD HELPER
  // ═══════════════════════════════════════════════════════════════

  Widget _styledField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isValid,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(
        fontSize: 14,
        color: _textDark,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(
          color: _textMuted.withValues(alpha: 0.8),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: TextStyle(
          color: _textMuted.withValues(alpha: 0.5),
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: Icon(
          icon,
          size: 20,
          color: _textMuted.withValues(alpha: 0.6),
        ),
        suffixIcon: controller.text.trim().isNotEmpty
            ? Icon(
                isValid
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 19,
                color: isValid
                    ? _successGreen
                    : _textMuted.withValues(alpha: 0.3),
              )
            : null,
        filled: true,
        fillColor: _cardWhite,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _borderGray, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isValid ? _successGreen.withValues(alpha: 0.4) : _borderGray,
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _primaryBlue, width: 2),
        ),
      ),
    );
  }
}
