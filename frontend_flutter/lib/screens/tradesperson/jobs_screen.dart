import 'dart:math' as math;

import 'package:flutter/material.dart';
<<<<<<< HEAD

=======
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/api_service.dart';
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
import 'tradesperson_work_store.dart';
import 'job_details_screen.dart';

/// Jobs Screen for the Fix It Marketplace Tradesperson App.
///
/// • Cards are tappable and push [JobDetailsScreen].
/// • Accepted jobs show a "Start Job" button.
///   → Disabled (with inline warning) when another job is In Progress.
/// • In-Progress jobs show "Mark as Complete".
class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen>
    with AutomaticKeepAliveClientMixin {
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

  bool _isSyncingAcceptedJob = false;
<<<<<<< HEAD
=======
  bool _isLoading = true;
  String? _errorMessage;
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
  int _handledMutationToken = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _handledMutationToken = TradespersonWorkStore.mutationToken;
    TradespersonWorkStore.notifier.addListener(_handleStoreChanged);
<<<<<<< HEAD
    _refreshFromBackend();
=======
    _refreshJobs();
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
  }

  @override
  void dispose() {
    TradespersonWorkStore.notifier.removeListener(_handleStoreChanged);
    super.dispose();
  }

  Future<void> _handleStoreChanged() async {
    if (!mounted) return;

    if (TradespersonWorkStore.lastMutation == 'open_job_details') {
      final pendingJobId = TradespersonWorkStore.consumePendingOpenJobId();
      if (pendingJobId != null) {
        Map<String, dynamic>? job;
        try {
          job = _jobs.firstWhere((j) => j['id'] == pendingJobId);
        } catch (_) {
          job = null;
        }
        if (job != null && mounted) {
          await _openJobDetails(job);
        }
      }
      if (mounted) setState(() {});
      return;
    }

    final token = TradespersonWorkStore.mutationToken;
    if (token == _handledMutationToken) {
      setState(() {});
      return;
    }

    _handledMutationToken = token;
    if (TradespersonWorkStore.lastMutation == 'accept_request') {
      setState(() {
        _activeFilter = 'All';
        _isSyncingAcceptedJob = true;
      });
      await Future.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      setState(() => _isSyncingAcceptedJob = false);
      return;
    }

    setState(() {});
  }

<<<<<<< HEAD
  Future<void> _refreshFromBackend() async {
    await TradespersonWorkStore.syncFromBackend();
    if (!mounted) return;
    setState(() {});
  }

=======
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
  String _activeFilter = 'All';
  final List<String> _filters = [
    'All',
    'In Progress',
    'Accepted',
    'Completed',
    'Cancelled',
  ];

  List<Map<String, dynamic>> get _jobs => TradespersonWorkStore.jobs;

<<<<<<< HEAD
=======
  Future<String> _readToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token')?.trim() ?? '';
    if (token.isEmpty) {
      throw Exception('Session expired. Please log in again.');
    }
    return token;
  }

  Future<void> _refreshJobs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await _readToken();
      final response = await ApiService.getTradespersonJobs(token: token);
      final rows = (response['jobs'] as List?) ?? const [];
      TradespersonWorkStore.setJobsFromApi(rows);

      if (!mounted) return;
      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
  // ── Status helpers ─────────────────────────────────────────────
  Color _statusColor(String status) => switch (status) {
    'In Progress' => _infoBlue,
    'Accepted' => _successGreen,
    'Completed' => _successGreen,
    'Cancelled' => _errorRed,
    'Under Review' => _warningYellow,
    _ => _textMuted,
  };

  IconData _statusIcon(String status) => switch (status) {
    'In Progress' => Icons.handyman_rounded,
    'Accepted' => Icons.check_circle_outline_rounded,
    'Completed' => Icons.task_alt_rounded,
    'Cancelled' => Icons.cancel_outlined,
    _ => Icons.circle_outlined,
  };

  List<Map<String, dynamic>> get _filtered {
    if (_activeFilter == 'All') return List.from(_jobs);
    return _jobs.where((j) => j['status'] == _activeFilter).toList();
  }

  // ── Navigate to Job Details ─────────────────────────────────────
  Future<void> _openJobDetails(Map<String, dynamic> job) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => JobDetailsScreen(jobId: job['id'] as String),
      ),
    );
    if (mounted) setState(() {});
  }

  // ── Start Job (inline from card) ────────────────────────────────
  void _startJob(Map<String, dynamic> job) async {
    if (TradespersonWorkStore.hasJobInProgress) {
      _showBlockedSnack();
      return;
    }

    final confirmed = await _showStartJobDialog(job);
    if (confirmed != true || !mounted) return;

<<<<<<< HEAD
    final success = await TradespersonWorkStore.startJobById(
      job['id'] as String,
    );
    if (!mounted) return;

    if (success) {
      _showSnack(
        'Job started! Head to ${job['homeowner'].toString().split(' ').first}\'s place.',
        _infoBlue,
        icon: Icons.handyman_rounded,
      );
    } else {
      _showBlockedSnack();
=======
    try {
      final token = await _readToken();
      final bookingId = (job['bookingId'] as int?) ?? 0;
      if (bookingId <= 0) {
        throw Exception('Invalid job id.');
      }

      final response = await ApiService.startJob(
        token: token,
        jobId: bookingId,
      );
      final jobRow = (response['job'] as Map?)?.cast<String, dynamic>();
      final success = TradespersonWorkStore.startJobByApiResult(
        (job['id'] ?? '').toString(),
        jobRow,
      );

      if (!mounted) return;
      if (success) {
        _showSnack(
          'Job started! Head to ${job['homeowner'].toString().split(' ').first}\'s place.',
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
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
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
                '${job['homeowner']} will be notified.',
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

  // ── Mark as Complete (inline from card) ─────────────────────────
  void _markAsComplete(Map<String, dynamic> job) {
    showDialog<bool>(
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
    ).then((confirmed) async {
      if (confirmed == true) {
<<<<<<< HEAD
        final completed = await TradespersonWorkStore.markJobAsComplete(
          job['id'] as String,
        );
        if (!completed || !mounted) {
          if (mounted) {
            _showSnack(
              'Unable to complete this job right now.',
              _errorRed,
              icon: Icons.error_outline_rounded,
            );
          }
          return;
        }
        _showSnack(
          'Job marked as complete. Homeowner has been notified.',
          _successGreen,
          icon: Icons.task_alt_rounded,
        );
=======
        try {
          final token = await _readToken();
          final bookingId = (job['bookingId'] as int?) ?? 0;
          if (bookingId <= 0) {
            throw Exception('Invalid job id.');
          }

          final response = await ApiService.completeJob(
            token: token,
            jobId: bookingId,
          );
          final jobRow = (response['job'] as Map?)?.cast<String, dynamic>();
          TradespersonWorkStore.completeJobByApiResult(
            (job['id'] ?? '').toString(),
            jobRow,
          );

          if (!mounted) return;
          _showSnack(
            'Job marked as complete. Homeowner has been notified.',
            _successGreen,
            icon: Icons.task_alt_rounded,
          );
        } catch (e) {
          if (!mounted) return;
          final message = e.toString().replaceFirst('Exception: ', '');
          _showSnack(message, _errorRed, icon: Icons.error_outline_rounded);
        }
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
      }
    });
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

  void _showBlockedSnack() => _showSnack(
    'Finish your current In Progress job before starting another.',
    _warningYellow,
    icon: Icons.warning_amber_rounded,
  );

  // ═══════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final jobs = _filtered;

    return Scaffold(
      backgroundColor: _backgroundGray,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAppBar(),
            _buildFilterTabs(),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: _isSyncingAcceptedJob
                    ? _buildJobsSyncState()
<<<<<<< HEAD
=======
                    : _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage != null
                    ? _buildErrorState()
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
                    : jobs.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        key: const ValueKey('jobs-list'),
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                        itemCount: jobs.length,
                        itemBuilder: (context, index) {
                          return TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: Duration(
                              milliseconds: 300 + (index * 50),
                            ),
                            curve: Curves.easeOut,
                            builder: (context, val, child) => Opacity(
                              opacity: val,
                              child: Transform.translate(
                                offset: Offset(0, 16 * (1 - val)),
                                child: child,
                              ),
                            ),
                            child: _buildJobCard(jobs[index]),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobsSyncState() {
    return Center(
      key: const ValueKey('jobs-syncing'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 850),
            builder: (context, value, child) =>
                Transform.rotate(angle: value * 2 * math.pi, child: child),
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: _primaryBlue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.refresh_rounded,
                size: 36,
                color: _primaryBlue,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Syncing jobs...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: _textDark,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Preparing your newly accepted request',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: _textMuted.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

<<<<<<< HEAD
=======
  Widget _buildErrorState() {
    return Center(
      key: const ValueKey('jobs-error'),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 54,
              color: _textMuted.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 14),
            const Text(
              'Failed to load jobs',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Please try again.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: _textMuted.withValues(alpha: 0.85),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: _refreshJobs,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Retry',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
  // ═══════════════════════════════════════════════════════════════
  //  APP BAR
  // ═══════════════════════════════════════════════════════════════

  Widget _buildAppBar() {
    final activeCount = _jobs
        .where((j) => j['status'] == 'In Progress' || j['status'] == 'Accepted')
        .length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'My Jobs',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: _textDark,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${_jobs.length} total · $activeCount active',
                  style: TextStyle(
                    fontSize: 13,
                    color: _textMuted.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: _cardWhite,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
<<<<<<< HEAD
              onPressed: () => _refreshFromBackend(),
=======
              onPressed: _refreshJobs,
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
              icon: const Icon(
                Icons.refresh_rounded,
                color: _textDark,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  FILTER TABS
  // ═══════════════════════════════════════════════════════════════

  Widget _buildFilterTabs() {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = _activeFilter == filter;
          final count = filter == 'All'
              ? _jobs.length
              : _jobs.where((j) => j['status'] == filter).length;

          return GestureDetector(
            onTap: () => setState(() => _activeFilter = filter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? _primaryBlue : _cardWhite,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? _primaryBlue : Colors.grey.shade200,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: _primaryBlue.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    filter,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : _textMuted,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.25)
                          : _primaryBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : _primaryBlue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  JOB CARD  (tappable → JobDetailsScreen)
  // ═══════════════════════════════════════════════════════════════

  Widget _buildJobCard(Map<String, dynamic> job) {
    final status = job['status'] as String;
    final statusColor = _statusColor(status);
<<<<<<< HEAD
=======
    final homeownerProfileImageUrl = (job['homeownerProfileImageUrl'] ?? '')
        .toString()
        .trim();
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
    final isCompleted = status == 'Completed';
    final isCancelled = status == 'Cancelled';
    final isInProgress = status == 'In Progress';
    final isAccepted = status == 'Accepted';
    final isDimmed = isCompleted || isCancelled;
    final isStartBlocked = isAccepted && TradespersonWorkStore.hasJobInProgress;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _cardWhite,
        borderRadius: BorderRadius.circular(20),
        border: isInProgress
            ? Border.all(color: _infoBlue.withValues(alpha: 0.3), width: 1.5)
            : isAccepted && !isStartBlocked
            ? Border.all(
                color: _accentOrange.withValues(alpha: 0.25),
                width: 1.2,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDimmed ? 0.03 : 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => _openJobDetails(job),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header Row ─────────────────────────────────────
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDimmed
                              ? [
                                  _textMuted.withValues(alpha: 0.4),
                                  _textMuted.withValues(alpha: 0.25),
                                ]
                              : [_primaryBlue, const Color(0xFF3B82F6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
<<<<<<< HEAD
                      child: Center(
                        child: Text(
                          job['avatar'] as String,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
=======
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: homeownerProfileImageUrl.isNotEmpty
                            ? Image.network(
                                homeownerProfileImageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Center(
                                      child: Text(
                                        job['avatar'] as String,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                              )
                            : Center(
                                child: Text(
                                  job['avatar'] as String,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            job['homeowner'] as String,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isDimmed
                                  ? _textMuted.withValues(alpha: 0.6)
                                  : _textDark,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            job['id'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _textMuted.withValues(alpha: 0.6),
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _statusIcon(status),
                            size: 12,
                            color: statusColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            status,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),
                Container(
                  height: 1,
                  color: isDimmed
                      ? Colors.grey.shade100.withValues(alpha: 0.5)
                      : Colors.grey.shade100,
                ),
                const SizedBox(height: 12),

                // ── Service Name ──────────────────────────────────
                Text(
                  job['service'] as String,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: isDimmed
                        ? _textMuted.withValues(alpha: 0.6)
                        : _textDark,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 6),

                // ── Description (preview) ─────────────────────────
                Text(
                  job['description'] as String,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDimmed
                        ? _textMuted.withValues(alpha: 0.45)
                        : _textMuted.withValues(alpha: 0.85),
                    height: 1.45,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 12),
                Container(
                  height: 1,
                  color: isDimmed
                      ? Colors.grey.shade100.withValues(alpha: 0.5)
                      : Colors.grey.shade100,
                ),
                const SizedBox(height: 12),

                // ── Details Row ───────────────────────────────────
                Row(
                  children: [
                    _buildDetailItem(
                      Icons.calendar_today_rounded,
                      job['date'] as String,
                      isDimmed: isDimmed,
                    ),
                    const SizedBox(width: 14),
                    _buildDetailItem(
                      Icons.access_time_rounded,
                      job['time'] as String,
                      isDimmed: isDimmed,
                    ),
                    const SizedBox(width: 14),
                    _buildDetailItem(
                      Icons.payments_outlined,
                      '₱${(job['budget'] as double).toStringAsFixed(0)}',
                      isDimmed: isDimmed,
                      highlight: !isDimmed,
                    ),
                    const Spacer(),
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: _primaryBlue.withValues(
                          alpha: isDimmed ? 0.04 : 0.08,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: _primaryBlue.withValues(
                          alpha: isDimmed ? 0.35 : 1.0,
                        ),
                        size: 13,
                      ),
                    ),
                  ],
                ),

                // ── Address ───────────────────────────────────────
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: _textMuted.withValues(alpha: isDimmed ? 0.3 : 0.6),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        job['address'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          color: _textMuted.withValues(
                            alpha: isDimmed ? 0.4 : 0.75,
                          ),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                // ── Completed info / rating ────────────────────────
                if (isCompleted && job['completedAt'] != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        Icons.task_alt_rounded,
                        size: 14,
                        color: _successGreen.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Completed: ${job['completedAt']}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _successGreen.withValues(alpha: 0.8),
                        ),
                      ),
                      if (job['rating'] != null) ...[
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: _accentOrange,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${job['rating']}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _accentOrange,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],

                // ── Mark as Complete (In Progress) ─────────────────
                if (isInProgress) ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _markAsComplete(job),
                      icon: const Icon(Icons.task_alt_rounded, size: 18),
                      label: const Text(
                        'Mark as Complete',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _successGreen,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],

                // ── Start Job (Accepted) ────────────────────────────
                if (isAccepted) ...[
                  const SizedBox(height: 14),
                  if (isStartBlocked) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _warningYellow.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _warningYellow.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 14,
                            color: _warningYellow.withValues(alpha: 0.9),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Complete your current In Progress job first.',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _warningYellow.withValues(alpha: 0.9),
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isStartBlocked ? null : () => _startJob(job),
                      icon: const Icon(Icons.play_arrow_rounded, size: 20),
                      label: const Text(
                        'Start Job',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accentOrange,
                        disabledBackgroundColor: _textMuted.withValues(
                          alpha: 0.12,
                        ),
                        foregroundColor: Colors.white,
                        disabledForegroundColor: _textMuted.withValues(
                          alpha: 0.4,
                        ),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(
    IconData icon,
    String text, {
    bool isDimmed = false,
    bool highlight = false,
  }) {
    final color = highlight
        ? _successGreen
        : _textMuted.withValues(alpha: isDimmed ? 0.3 : 0.6);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 5),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: highlight
                ? _successGreen
                : _textMuted.withValues(alpha: isDimmed ? 0.4 : 0.9),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  EMPTY STATE
  // ═══════════════════════════════════════════════════════════════

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _primaryBlue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.handyman_rounded,
                size: 38,
                color: _primaryBlue.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _activeFilter == 'All' ? 'No Jobs Yet' : 'No $_activeFilter Jobs',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _textDark,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _activeFilter == 'All'
                  ? 'Accepted requests will appear here as active jobs.'
                  : 'You have no ${_activeFilter.toLowerCase()} jobs at the moment.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: _textMuted.withValues(alpha: 0.7),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
