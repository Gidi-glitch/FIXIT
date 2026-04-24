import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/api_service.dart';
import 'tradesperson_chat_screen.dart';
import 'tradesperson_work_store.dart';

/// Job Details Screen for the Fix It Marketplace Tradesperson App.
///
/// Shows the full detail of a single job, including homeowner info,
/// service description, schedule, budget, address, and a live timeline.
///
/// Action buttons adapt to the job's current status:
///   • Accepted  → "Start Job" (blocked if another job is In Progress)
///   • In Progress → "Mark as Complete"
///   • Completed / Cancelled → read-only summary
///
/// Navigates back with [true] when a mutation occurs so [JobsScreen]
/// can refresh its list.
class JobDetailsScreen extends StatefulWidget {
  const JobDetailsScreen({super.key, required this.jobId});

  final String jobId;

  @override
  State<JobDetailsScreen> createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends State<JobDetailsScreen> {
  // ── Color Palette ──────────────────────────────────────────────
  static const Color _primaryBlue = Color(0xFF1E3A8A);
  static const Color _accentOrange = Color(0xFFF97316);
  static const Color _backgroundGray = Color(0xFFF9FAFB);
  static const Color _textDark = Color(0xFF111827);
  static const Color _textMuted = Color(0xFF6B7280);
  static const Color _cardWhite = Color(0xFFFFFFFF);
  static const Color _successGreen = Color(0xFF10B981);
  static const Color _warningYellow = Color(0xFFF59E0B);
  static const Color _errorRed = Color(0xFFEF4444);
  static const Color _infoBlue = Color(0xFF3B82F6);

  bool _didMutate = false;

  @override
  void initState() {
    super.initState();
    TradespersonWorkStore.notifier.addListener(_handleStoreChanged);
    _refreshJobDetails();
  }

  @override
  void dispose() {
    TradespersonWorkStore.notifier.removeListener(_handleStoreChanged);
    super.dispose();
  }

  void _handleStoreChanged() {
    if (mounted) setState(() {});
  }

  // ── Live job lookup ─────────────────────────────────────────────

  Map<String, dynamic>? get _job {
    try {
      return TradespersonWorkStore.jobs.firstWhere(
        (j) => j['id'] == widget.jobId,
      );
    } catch (_) {
      return null;
    }
  }

  Future<String> _readToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token')?.trim() ?? '';
    if (token.isEmpty) {
      throw Exception('Session expired. Please log in again.');
    }
    return token;
  }

  int _bookingIdFromAny(String idOrRef) {
    final direct = int.tryParse(idOrRef);
    if (direct != null && direct > 0) return direct;

    final digits = RegExp(
      r'\d+',
    ).allMatches(idOrRef).map((m) => m.group(0)).join();
    return int.tryParse(digits) ?? 0;
  }

  Future<void> _refreshJobDetails() async {
    try {
      final token = await _readToken();
      final bookingId = _bookingIdFromAny(widget.jobId);
      if (bookingId <= 0) return;

      final response = await ApiService.getTradespersonJobById(
        token: token,
        jobId: bookingId,
      );

      final jobRow = (response['job'] as Map?)?.cast<String, dynamic>();
      if (jobRow == null) return;
      TradespersonWorkStore.upsertJobFromApi(
        jobRow,
        mutation: 'job_details_sync',
      );
    } catch (_) {
      // Job details screen can still render from cached store data.
    }
  }

  // ── Status helpers ──────────────────────────────────────────────

  IconData _statusIcon(String status) => switch (status) {
    'In Progress' => Icons.handyman_rounded,
    'Accepted' => Icons.check_circle_outline_rounded,
    'Completed' => Icons.task_alt_rounded,
    'Cancelled' => Icons.cancel_outlined,
    _ => Icons.circle_outlined,
  };

  // ── Start Job ───────────────────────────────────────────────────

  void _startJob(Map<String, dynamic> job) async {
    // Show info tooltip if blocked
    if (TradespersonWorkStore.hasJobInProgress) {
      _showBlockedSnack();
      return;
    }

    final confirmed = await _showStartJobDialog(job);
    if (confirmed != true) return;

    try {
      final token = await _readToken();
      final bookingId =
          (job['bookingId'] as int?) ?? _bookingIdFromAny(widget.jobId);
      if (bookingId <= 0) {
        throw Exception('Invalid job id.');
      }

      final response = await ApiService.startJob(
        token: token,
        jobId: bookingId,
      );
      final jobRow = (response['job'] as Map?)?.cast<String, dynamic>();
      final success = TradespersonWorkStore.startJobByApiResult(
        widget.jobId,
        jobRow,
      );

      if (!mounted) return;
      if (success) {
        _didMutate = true;
        _showSnack(
          'Job started! Get to work, ${job['homeowner'].toString().split(' ').first}\'s place awaits.',
          _infoBlue,
          icon: Icons.handyman_rounded,
        );
      } else {
        _showBlockedSnack();
      }
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().replaceFirst('Exception: ', '');
      if (message.toLowerCase().contains('in progress')) {
        _showBlockedSnack();
        return;
      }
      _showSnack(message, _errorRed, icon: Icons.error_outline_rounded);
    }
  }

  Future<bool?> _showStartJobDialog(Map<String, dynamic> job) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
          decoration: BoxDecoration(
            color: _cardWhite,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.14),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_accentOrange, Color(0xFFFB923C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Start Job?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _textDark,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You are about to start "${job['service']}". '
                'This will mark the job as In Progress and notify ${job['homeowner']}.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _textMuted.withValues(alpha: 0.9),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(
                          color: _textMuted.withValues(alpha: 0.3),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Not Yet',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: _textMuted,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accentOrange,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Start Now',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Mark as Complete ────────────────────────────────────────────

  void _markAsComplete(Map<String, dynamic> job) async {
    final confirmed = await _showCompleteDialog(job);
    if (confirmed != true) return;

    try {
      final token = await _readToken();
      final bookingId =
          (job['bookingId'] as int?) ?? _bookingIdFromAny(widget.jobId);
      if (bookingId <= 0) {
        throw Exception('Invalid job id.');
      }

      final response = await ApiService.completeJob(
        token: token,
        jobId: bookingId,
      );
      final jobRow = (response['job'] as Map?)?.cast<String, dynamic>();
      TradespersonWorkStore.completeJobByApiResult(widget.jobId, jobRow);
      if (!mounted) return;

      _didMutate = true;
      _showSnack(
        'Job complete! ${job['homeowner']} has been notified.',
        _successGreen,
        icon: Icons.task_alt_rounded,
      );
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().replaceFirst('Exception: ', '');
      _showSnack(message, _errorRed, icon: Icons.error_outline_rounded);
    }
  }

  Future<bool?> _showCompleteDialog(Map<String, dynamic> job) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
          decoration: BoxDecoration(
            color: _cardWhite,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.14),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_successGreen, Color(0xFF34D399)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.task_alt_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Mark as Complete?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _textDark,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Confirm that you have finished the job for ${job['homeowner']}. '
                'The homeowner will be notified to settle your payment.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _textMuted.withValues(alpha: 0.9),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(
                          color: _textMuted.withValues(alpha: 0.3),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: _textMuted,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _successGreen,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Confirm',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Message homeowner ───────────────────────────────────────────

  void _messageHomeowner(Map<String, dynamic> job) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TradespersonChatScreen(
          conversation: {
            'id': widget.jobId,
            'name': job['homeowner'] as String,
            'avatar': job['avatar'] as String,
            'trade': job['service'] as String,
            'isOnline': true,
          },
        ),
      ),
    );
  }

  // ── Snackbars ───────────────────────────────────────────────────

  void _showSnack(String msg, Color color, {required IconData icon}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                msg,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showBlockedSnack() {
    _showSnack(
      'Finish your current In Progress job before starting another.',
      _warningYellow,
      icon: Icons.warning_amber_rounded,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final job = _job;

    if (job == null) {
      return Scaffold(
        backgroundColor: _backgroundGray,
        appBar: AppBar(
          backgroundColor: _primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'Job Details',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        body: const Center(
          child: Text(
            'Job not found.',
            style: TextStyle(fontSize: 16, color: _textMuted),
          ),
        ),
      );
    }

    final status = job['status'] as String;
    final isAccepted = status == 'Accepted';
    final isInProgress = status == 'In Progress';
    final isCompleted = status == 'Completed';
    final isCancelled = status == 'Cancelled';
    final isActive = isAccepted || isInProgress;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop && _didMutate) {
          // Parent (JobsScreen) listens to the store — nothing extra needed.
        }
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
        ),
        child: Scaffold(
          backgroundColor: _backgroundGray,
          body: Column(
            children: [
              _buildHeader(job),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                  children: [
                    // ── Status banner ──────────────────────────────
                    _buildStatusBanner(status),
                    const SizedBox(height: 16),

                    // ── Homeowner card ─────────────────────────────
                    _buildHomeownerCard(job, isActive),
                    const SizedBox(height: 16),

                    // ── Service details ────────────────────────────
                    _buildServiceCard(job),
                    const SizedBox(height: 16),

                    // ── Schedule & Budget ──────────────────────────
                    _buildScheduleCard(job),
                    const SizedBox(height: 16),

                    // ── Address card ───────────────────────────────
                    _buildAddressCard(job),
                    const SizedBox(height: 16),

                    // ── Job Timeline ───────────────────────────────
                    _buildTimeline(job, status),

                    // ── Rating (Completed only) ────────────────────
                    if (isCompleted && job['rating'] != null) ...[
                      const SizedBox(height: 16),
                      _buildRatingCard(job),
                    ],

                    const SizedBox(height: 16),

                    // ── Action buttons ─────────────────────────────
                    if (isAccepted) _buildStartJobButton(job),
                    if (isInProgress) _buildCompleteButton(job),
                    if (isCancelled) _buildCancelledNote(),
                  ],
                ),
              ),
            ],
          ),

          // ── Floating message button (active jobs) ──────────────
          floatingActionButton: isActive
              ? FloatingActionButton.extended(
                  onPressed: () => _messageHomeowner(job),
                  backgroundColor: _primaryBlue,
                  elevation: 4,
                  icon: const Icon(
                    Icons.chat_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  label: const Text(
                    'Message',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                )
              : null,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  HEADER
  // ═══════════════════════════════════════════════════════════════

  Widget _buildHeader(Map<String, dynamic> job) {
    final status = job['status'] as String;
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
                onPressed: () => Navigator.pop(context, _didMutate),
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job['service'] as String,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.jobId,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.65),
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
              // Status badge in header
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_statusIcon(status), size: 13, color: Colors.white),
                    const SizedBox(width: 5),
                    Text(
                      status,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
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

  // ═══════════════════════════════════════════════════════════════
  //  STATUS BANNER
  // ═══════════════════════════════════════════════════════════════

  Widget _buildStatusBanner(String status) {
    final (color, bgColor, icon, message) = switch (status) {
      'In Progress' => (
        _infoBlue,
        _infoBlue.withValues(alpha: 0.08),
        Icons.handyman_rounded,
        'This job is currently in progress.',
      ),
      'Accepted' => (
        _successGreen,
        _successGreen.withValues(alpha: 0.07),
        Icons.check_circle_outline_rounded,
        TradespersonWorkStore.hasJobInProgress
            ? 'Finish your current job before starting this one.'
            : 'Ready to start. Tap "Start Job" when you arrive.',
      ),
      'Completed' => (
        _successGreen,
        _successGreen.withValues(alpha: 0.07),
        Icons.task_alt_rounded,
        'This job has been completed successfully.',
      ),
      'Cancelled' => (
        _errorRed,
        _errorRed.withValues(alpha: 0.06),
        Icons.cancel_outlined,
        'This job has been cancelled.',
      ),
      _ => (
        _textMuted,
        _textMuted.withValues(alpha: 0.06),
        Icons.info_outline_rounded,
        '',
      ),
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color.withValues(alpha: 0.9),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  HOMEOWNER CARD
  // ═══════════════════════════════════════════════════════════════

  Widget _buildHomeownerCard(Map<String, dynamic> job, bool isActive) {
    return _card(
      child: Row(
        children: [
          // Avatar
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_primaryBlue, Color(0xFF3B82F6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                job['avatar'] as String,
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
                Text(
                  job['homeowner'] as String,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Homeowner',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _textMuted.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          // Message shortcut (active jobs only)
          if (isActive)
            Material(
              color: _primaryBlue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () => _messageHomeowner(job),
                borderRadius: BorderRadius.circular(12),
                child: const Padding(
                  padding: EdgeInsets.all(10),
                  child: Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: _primaryBlue,
                    size: 20,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  SERVICE CARD
  // ═══════════════════════════════════════════════════════════════

  Widget _buildServiceCard(Map<String, dynamic> job) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardSectionHeader(Icons.handyman_rounded, _primaryBlue, 'Service'),
          const SizedBox(height: 14),
          Text(
            job['service'] as String,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: _textDark,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            job['description'] as String,
            style: TextStyle(
              fontSize: 13,
              color: _textMuted.withValues(alpha: 0.85),
              height: 1.55,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  SCHEDULE & BUDGET CARD
  // ═══════════════════════════════════════════════════════════════

  Widget _buildScheduleCard(Map<String, dynamic> job) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardSectionHeader(
            Icons.calendar_today_rounded,
            _accentOrange,
            'Schedule & Budget',
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _infoTile(
                  icon: Icons.calendar_today_rounded,
                  label: 'Date',
                  value: job['date'] as String,
                  color: _primaryBlue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _infoTile(
                  icon: Icons.access_time_rounded,
                  label: 'Time',
                  value: job['time'] as String,
                  color: _accentOrange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _infoTile(
                  icon: Icons.payments_outlined,
                  label: 'Budget',
                  value: '₱${(job['budget'] as double).toStringAsFixed(0)}',
                  color: _successGreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  ADDRESS CARD
  // ═══════════════════════════════════════════════════════════════

  Widget _buildAddressCard(Map<String, dynamic> job) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardSectionHeader(
            Icons.location_on_outlined,
            _errorRed,
            'Service Address',
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _errorRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: _errorRed,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      job['address'] as String,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _textDark,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Calauan, Laguna',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _textMuted.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  TIMELINE
  // ═══════════════════════════════════════════════════════════════

  Widget _buildTimeline(Map<String, dynamic> job, String status) {
    final isInProgress = status == 'In Progress';
    final isCompleted = status == 'Completed';
    final isCancelled = status == 'Cancelled';

    final steps = [
      _TimelineStep(
        icon: Icons.check_circle_outline_rounded,
        label: 'Accepted',
        sublabel: 'Booking confirmed',
        isDone: true, // always reached if we have a job
        color: _successGreen,
      ),
      _TimelineStep(
        icon: Icons.play_arrow_rounded,
        label: 'Started',
        sublabel: job['startedAt'] != null
            ? 'Started at ${job['startedAt']}'
            : 'Tap "Start Job" to begin',
        isDone: isInProgress || isCompleted,
        isActive: isInProgress,
        color: _accentOrange,
      ),
      _TimelineStep(
        icon: Icons.task_alt_rounded,
        label: 'Completed',
        sublabel: job['completedAt'] != null
            ? job['completedAt'] as String
            : 'Pending completion',
        isDone: isCompleted,
        color: _successGreen,
      ),
    ];

    // For cancelled, show a different timeline
    if (isCancelled) {
      return _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _cardSectionHeader(
              Icons.timeline_rounded,
              _textMuted,
              'Job Timeline',
            ),
            const SizedBox(height: 14),
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
                    Icons.cancel_outlined,
                    color: _errorRed,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Cancelled',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _errorRed,
                        ),
                      ),
                      Text(
                        'This job was cancelled.',
                        style: TextStyle(
                          fontSize: 12,
                          color: _textMuted.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardSectionHeader(
            Icons.timeline_rounded,
            _primaryBlue,
            'Job Timeline',
          ),
          const SizedBox(height: 16),
          ...steps.asMap().entries.map((e) {
            final isLast = e.key == steps.length - 1;
            final step = e.value;
            return _buildTimelineRow(step, isLast: isLast);
          }),
        ],
      ),
    );
  }

  Widget _buildTimelineRow(_TimelineStep step, {required bool isLast}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Dot + connector ──────────────────────────────────────
        Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: step.isDone
                    ? step.color.withValues(alpha: 0.15)
                    : step.isActive
                    ? step.color.withValues(alpha: 0.12)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(11),
                border: step.isActive
                    ? Border.all(
                        color: step.color.withValues(alpha: 0.4),
                        width: 1.5,
                      )
                    : null,
              ),
              child: Icon(
                step.icon,
                size: 18,
                color: step.isDone
                    ? step.color
                    : step.isActive
                    ? step.color
                    : Colors.grey.shade400,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 32,
                margin: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: step.isDone
                      ? step.color.withValues(alpha: 0.3)
                      : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
          ],
        ),
        const SizedBox(width: 14),
        // ── Text ──────────────────────────────────────────────────
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: 6, bottom: isLast ? 0 : 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: step.isDone
                        ? _textDark
                        : step.isActive
                        ? _textDark
                        : _textMuted.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  step.sublabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: step.isDone
                        ? _textMuted.withValues(alpha: 0.75)
                        : step.isActive
                        ? step.color.withValues(alpha: 0.8)
                        : _textMuted.withValues(alpha: 0.4),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  RATING CARD
  // ═══════════════════════════════════════════════════════════════

  Widget _buildRatingCard(Map<String, dynamic> job) {
    final rating = (job['rating'] as num).toDouble();
    final stars = rating.round();

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardSectionHeader(
            Icons.star_rounded,
            _accentOrange,
            'Homeowner Rating',
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              ...List.generate(5, (i) {
                return Icon(
                  i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: 28,
                  color: i < stars ? _accentOrange : Colors.grey.shade300,
                );
              }),
              const SizedBox(width: 12),
              Text(
                rating.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: _accentOrange,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '/ 5.0',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _textMuted.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          if (job['completedAt'] != null) ...[
            const SizedBox(height: 8),
            Text(
              'Completed: ${job['completedAt']}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _successGreen.withValues(alpha: 0.8),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  ACTION BUTTONS
  // ═══════════════════════════════════════════════════════════════

  Widget _buildStartJobButton(Map<String, dynamic> job) {
    final isBlocked = TradespersonWorkStore.hasJobInProgress;

    return Column(
      children: [
        // Blocked info banner
        if (isBlocked) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _warningYellow.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _warningYellow.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: _warningYellow.withValues(alpha: 0.9),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'You have a job In Progress. Complete it first before starting another.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _warningYellow.withValues(alpha: 0.9),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: isBlocked ? null : () => _startJob(job),
            icon: const Icon(Icons.play_arrow_rounded, size: 22),
            label: const Text(
              'Start Job',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _accentOrange,
              disabledBackgroundColor: _textMuted.withValues(alpha: 0.15),
              foregroundColor: Colors.white,
              disabledForegroundColor: _textMuted.withValues(alpha: 0.5),
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 17),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompleteButton(Map<String, dynamic> job) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _markAsComplete(job),
        icon: const Icon(Icons.task_alt_rounded, size: 22),
        label: const Text(
          'Mark as Complete',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _successGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 17),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildCancelledNote() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _errorRed.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _errorRed.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cancel_outlined, color: _errorRed, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'This job was cancelled and is no longer active.',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _errorRed.withValues(alpha: 0.85),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  SHARED HELPERS
  // ═══════════════════════════════════════════════════════════════

  Widget _card({required Widget child}) => Container(
    padding: const EdgeInsets.all(16),
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
    child: child,
  );

  Widget _cardSectionHeader(IconData icon, Color color, String title) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 9),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: _textDark,
            letterSpacing: -0.1,
          ),
        ),
      ],
    );
  }

  Widget _infoTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: color,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: _textMuted.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Timeline step data class ───────────────────────────────────────
class _TimelineStep {
  final IconData icon;
  final String label;
  final String sublabel;
  final bool isDone;
  final bool isActive;
  final Color color;

  const _TimelineStep({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.isDone,
    this.isActive = false,
    required this.color,
  });
}
