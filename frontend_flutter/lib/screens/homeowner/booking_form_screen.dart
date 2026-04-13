import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'booking_store.dart';

class BookingFormScreen extends StatefulWidget {
  final Map<String, dynamic> pro;
  final VoidCallback onBookingConfirmed;

  const BookingFormScreen({
    super.key,
    required this.pro,
    required this.onBookingConfirmed,
  });

  @override
  State<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends State<BookingFormScreen> {
  // ── Color Palette ───────────────────────────────────────────────
  static const Color _primaryBlue = Color(0xFF1E3A8A);
  static const Color _accentOrange = Color(0xFFF97316);
  static const Color _backgroundGray = Color(0xFFF9FAFB);
  static const Color _textDark = Color(0xFF111827);
  static const Color _textMuted = Color(0xFF6B7280);
  static const Color _cardWhite = Color(0xFFFFFFFF);
  static const Color _successGreen = Color(0xFF10B981);
  static const Color _warningYellow = Color(0xFFF59E0B);
  static const Color _errorRed = Color(0xFFEF4444);

  // ── Form State ──────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _budgetController = TextEditingController();
  late final List<String> _serviceOptions;
  final Set<String> _selectedServices = <String>{};

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _serviceOptions = _extractServiceOptions();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _addressController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  // ── Helpers ─────────────────────────────────────────────────────

  List<String> _extractServiceOptions() {
    final raw = <dynamic>[
      if (widget.pro['skills'] is List) ...(widget.pro['skills'] as List),
      if (widget.pro['services'] is List) ...(widget.pro['services'] as List),
      if ((widget.pro['specialization'] ?? '').toString().trim().isNotEmpty)
        widget.pro['specialization'],
    ];

    final seen = <String>{};
    final result = <String>[];

    for (final item in raw) {
      final value = item.toString().trim();
      if (value.isEmpty) continue;

      final normalized = value.toLowerCase();
      if (seen.add(normalized)) {
        result.add(value);
      }
    }

    return result;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final d = DateTime(date.year, date.month, date.day);
    if (d == today) return 'Today';
    if (d == tomorrow) return 'Tomorrow';
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
    return '${months[date.month]} ${date.day}';
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _primaryBlue,
              onPrimary: Colors.white,
              surface: _cardWhite,
              onSurface: _textDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _primaryBlue,
              onPrimary: Colors.white,
              surface: _cardWhite,
              onSurface: _textDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _confirmBooking() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedServices.isEmpty) {
      _showError('Please select at least one service needed.');
      return;
    }
    if (_selectedDate == null) {
      _showError('Please select a preferred date.');
      return;
    }
    if (_selectedTime == null) {
      _showError('Please select a preferred time.');
      return;
    }

    setState(() => _isSubmitting = true);

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    final booking = BookingModel(
      id: 'BK-${DateTime.now().millisecondsSinceEpoch}',
      tradespersonName: widget.pro['name'] as String,
      tradespersonAvatar: widget.pro['avatar'] as String,
      trade: widget.pro['trade'] as String,
      specialization: _selectedServices.join(', '),
      problemDescription: _descriptionController.text.trim(),
      address: _addressController.text.trim(),
      date: _formatDate(_selectedDate!),
      time: _formatTime(_selectedTime!),
      offeredBudget: double.tryParse(_budgetController.text.trim()) ?? 0,
      status: 'Pending',
      createdAt: DateTime.now(),
    );

    BookingStore.add(booking);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    // Pop all the way back to the dashboard root
    Navigator.of(context).popUntil((route) => route.isFirst);

    // Switch dashboard to Bookings tab (index 1)
    widget.onBookingConfirmed();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _errorRed,
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
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTradespersonCard(),
                      const SizedBox(height: 20),
                      _buildSectionLabel(
                        'Service Needed',
                        Icons.build_circle_rounded,
                      ),
                      const SizedBox(height: 6),
                      _buildServiceHint(),
                      const SizedBox(height: 12),
                      _buildServiceSelector(),
                      const SizedBox(height: 24),
                      _buildSectionLabel(
                        'Problem Description',
                        Icons.description_rounded,
                      ),
                      const SizedBox(height: 10),
                      _buildDescriptionField(),
                      const SizedBox(height: 20),
                      _buildSectionLabel(
                        'Service Address',
                        Icons.location_on_rounded,
                      ),
                      const SizedBox(height: 10),
                      _buildAddressField(),
                      const SizedBox(height: 20),
                      _buildSectionLabel(
                        'Preferred Schedule',
                        Icons.calendar_today_rounded,
                      ),
                      const SizedBox(height: 10),
                      _buildDateTimeRow(),
                      const SizedBox(height: 20),
                      _buildSectionLabel(
                        'Offered Budget',
                        Icons.payments_rounded,
                      ),
                      const SizedBox(height: 6),
                      _buildBudgetHint(),
                      const SizedBox(height: 10),
                      _buildBudgetField(),
                      const SizedBox(height: 32),
                      _buildConfirmButton(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  HEADER
  // ═══════════════════════════════════════════════════════════════

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_primaryBlue, Color(0xFF1E40AF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Book a Service',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.4,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Fill in the details for your request',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              // Step indicator
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Step 2 of 2',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  TRADESPERSON CARD (read-only, pre-filled)
  // ═══════════════════════════════════════════════════════════════

  Widget _buildTradespersonCard() {
    final avatarColor = widget.pro['avatarColor'] as Color;
    final isOnDuty = widget.pro['isOnDuty'] as bool;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _primaryBlue.withValues(alpha: 0.1),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _primaryBlue.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [avatarColor, avatarColor.withValues(alpha: 0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: avatarColor.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                widget.pro['avatar'] as String,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.pro['name'] as String,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: _textDark,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _successGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.circle,
                            size: 6,
                            color: isOnDuty ? _successGreen : _textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isOnDuty ? 'On-Duty' : 'Off-Duty',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isOnDuty ? _successGreen : _textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  widget.pro['specialization'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: avatarColor,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: _warningYellow,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.pro['rating']}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _textDark,
                      ),
                    ),
                    Text(
                      ' · ${widget.pro['reviews']} reviews',
                      style: TextStyle(
                        fontSize: 12,
                        color: _textMuted.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(
                      Icons.location_on_outlined,
                      size: 13,
                      color: _textMuted.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      widget.pro['barangay'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        color: _textMuted.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
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

  Widget _buildSectionLabel(String label, IconData icon) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: _primaryBlue.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: _primaryBlue, size: 17),
        ),
        const SizedBox(width: 10),
        Text(
          label,
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
  //  FORM FIELDS
  // ═══════════════════════════════════════════════════════════════

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      maxLines: 4,
      maxLength: 300,
      style: const TextStyle(
        fontSize: 14,
        color: _textDark,
        fontWeight: FontWeight.w500,
        height: 1.5,
      ),
      decoration: _inputDecoration(
        hint:
            'Describe the problem in detail (e.g., leaking pipe under kitchen sink, water pressure is low…)',
      ),
      validator: (val) {
        if (val == null || val.trim().isEmpty) {
          return 'Please describe the problem.';
        }
        if (val.trim().length < 10) {
          return 'Please provide more detail (min. 10 characters).';
        }
        return null;
      },
    );
  }

  Widget _buildServiceHint() {
    return Row(
      children: [
        Icon(
          Icons.touch_app_rounded,
          size: 13,
          color: _textMuted.withValues(alpha: 0.6),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'Select one or more services from ${widget.pro['name'].toString().split(' ').first}.',
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

  Widget _buildServiceSelector() {
    if (_serviceOptions.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: _cardWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
        ),
        child: Text(
          'No services available.',
          style: TextStyle(
            fontSize: 13,
            color: _textMuted.withValues(alpha: 0.7),
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Wrap(
        spacing: 9,
        runSpacing: 9,
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: isSelected
                    ? _primaryBlue
                    : _primaryBlue.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(11),
                border: Border.all(
                  color: isSelected
                      ? _primaryBlue
                      : _primaryBlue.withValues(alpha: 0.2),
                  width: 1.2,
                ),
                boxShadow: [
                  if (isSelected)
                    BoxShadow(
                      color: _primaryBlue.withValues(alpha: 0.25),
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
    );
  }

  Widget _buildAddressField() {
    return TextFormField(
      controller: _addressController,
      style: const TextStyle(
        fontSize: 14,
        color: _textDark,
        fontWeight: FontWeight.w500,
      ),
      decoration: _inputDecoration(
        hint: 'e.g. Blk 4 Lot 12, Dayap, Calauan, Laguna',
        prefixIcon: Icons.home_rounded,
      ),
      validator: (val) {
        if (val == null || val.trim().isEmpty) {
          return 'Please enter your service address.';
        }
        return null;
      },
    );
  }

  Widget _buildDateTimeRow() {
    return Row(
      children: [
        Expanded(child: _buildDatePicker()),
        const SizedBox(width: 12),
        Expanded(child: _buildTimePicker()),
      ],
    );
  }

  Widget _buildDatePicker() {
    final hasValue = _selectedDate != null;
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: _cardWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasValue
                ? _primaryBlue.withValues(alpha: 0.4)
                : const Color(0xFFE5E7EB),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 18,
              color: hasValue
                  ? _primaryBlue
                  : _textMuted.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                hasValue ? _formatDate(_selectedDate!) : 'Date',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: hasValue ? FontWeight.w700 : FontWeight.w400,
                  color: hasValue
                      ? _textDark
                      : _textMuted.withValues(alpha: 0.6),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePicker() {
    final hasValue = _selectedTime != null;
    return GestureDetector(
      onTap: _pickTime,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: _cardWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasValue
                ? _primaryBlue.withValues(alpha: 0.4)
                : const Color(0xFFE5E7EB),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              Icons.access_time_rounded,
              size: 18,
              color: hasValue
                  ? _primaryBlue
                  : _textMuted.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                hasValue ? _formatTime(_selectedTime!) : 'Time',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: hasValue ? FontWeight.w700 : FontWeight.w400,
                  color: hasValue
                      ? _textDark
                      : _textMuted.withValues(alpha: 0.6),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetHint() {
    return Row(
      children: [
        Icon(
          Icons.info_outline_rounded,
          size: 13,
          color: _textMuted.withValues(alpha: 0.6),
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

  Widget _buildBudgetField() {
    return TextFormField(
      controller: _budgetController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
      ],
      style: const TextStyle(
        fontSize: 15,
        color: _textDark,
        fontWeight: FontWeight.w700,
      ),
      decoration: _inputDecoration(
        hint: '0.00',
        prefixIcon: Icons.attach_money_rounded,
      ),
      validator: (val) {
        if (val == null || val.trim().isEmpty) {
          return 'Please enter your offered budget.';
        }
        final amount = double.tryParse(val.trim());
        if (amount == null || amount <= 0) {
          return 'Please enter a valid amount.';
        }
        return null;
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  CONFIRM BUTTON
  // ═══════════════════════════════════════════════════════════════

  Widget _buildConfirmButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _confirmBooking,
        style: ElevatedButton.styleFrom(
          backgroundColor: _accentOrange,
          disabledBackgroundColor: _accentOrange.withValues(alpha: 0.6),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          shadowColor: _accentOrange.withValues(alpha: 0.4),
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_rounded, size: 20),
                  SizedBox(width: 10),
                  Text(
                    'Confirm Booking',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  INPUT DECORATION HELPER
  // ═══════════════════════════════════════════════════════════════

  InputDecoration _inputDecoration({
    required String hint,
    IconData? prefixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: _textMuted.withValues(alpha: 0.55),
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: _textMuted.withValues(alpha: 0.5), size: 20)
          : null,
      filled: true,
      fillColor: _cardWhite,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
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
}
