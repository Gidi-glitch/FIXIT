import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum JobStatus { pending, onTheWay, inProgress, completed }

class _JobRequest {
  final String id;
  final String homeownerName;
  final String problemDescription;
  final String location;
  final String dateRequested;

  const _JobRequest({
    required this.id,
    required this.homeownerName,
    required this.problemDescription,
    required this.location,
    required this.dateRequested,
  });
}

class _OngoingJob {
  final String id;
  final String homeownerName;
  final String problemDescription;
  final String location;
  final String dateAccepted;
  final JobStatus status;

  const _OngoingJob({
    required this.id,
    required this.homeownerName,
    required this.problemDescription,
    required this.location,
    required this.dateAccepted,
    required this.status,
  });
}

class _CompletedJob {
  final String id;
  final String homeownerName;
  final String problemDescription;
  final String location;
  final String dateCompleted;
  final double? rating;
  final String? review;

  const _CompletedJob({
    required this.id,
    required this.homeownerName,
    required this.problemDescription,
    required this.location,
    required this.dateCompleted,
    this.rating,
    this.review,
  });
}

class _Tradesperson {
  final String name;
  final String category;
  final double rating;
  final int totalReviews;
  final bool isVerified;

  const _Tradesperson({
    required this.name,
    required this.category,
    required this.rating,
    required this.totalReviews,
    required this.isVerified,
  });
}

// ─────────────────────────────────────────────────────────────────
//  MAIN SHELL — Bottom Navigation with 3 Tabs
// ─────────────────────────────────────────────────────────────────

/// Entry-point widget for the tradesperson side of FIXit.
/// Provides bottom navigation with Home, Jobs, and Profile tabs.
class TradesmanDashboard extends StatefulWidget {
  const TradesmanDashboard({super.key});

  @override
  State<TradesmanDashboard> createState() => _TradesmanDashboardState();
}

class _TradesmanDashboardState extends State<TradesmanDashboard> {
  // ── Color Palette (matches prologin_screen.dart) ──────────────
  static const Color _primaryBlue = Color(0xFF1E3A8A);
  static const Color _textMuted = Color(0xFF6B7280);
  static const Color _cardWhite = Color(0xFFFFFFFF);
  static const Color _borderLight = Color(0xFFE5E7EB);
  static const Color _backgroundGray = Color(0xFFF9FAFB);

  int _currentIndex = 0;

  final List<Widget> _screens = [
    const _DashboardHome(),
    const _PlaceholderTab(title: 'My Jobs', icon: Icons.work_outline_rounded),
    const _PlaceholderTab(title: 'Profile', icon: Icons.person_outline_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundGray,
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: _cardWhite,
          border: const Border(top: BorderSide(color: _borderLight, width: 1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  index: 0,
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                  label: 'Home',
                ),
                _buildNavItem(
                  index: 1,
                  icon: Icons.work_outline_rounded,
                  activeIcon: Icons.work_rounded,
                  label: 'Jobs',
                ),
                _buildNavItem(
                  index: 2,
                  icon: Icons.person_outline_rounded,
                  activeIcon: Icons.person_rounded,
                  label: 'Profile',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final bool isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? _primaryBlue.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              size: 24,
              color: isActive ? _primaryBlue : _textMuted,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? _primaryBlue : _textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  DASHBOARD HOME TAB
// ─────────────────────────────────────────────────────────────────

class _DashboardHome extends StatefulWidget {
  const _DashboardHome();

  @override
  State<_DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<_DashboardHome>
    with SingleTickerProviderStateMixin {
  // ── Color Palette (matches prologin_screen.dart) ──────────────
  static const Color _primaryBlue = Color(0xFF1E3A8A);
  static const Color _accentOrange = Color(0xFFF97316);
  static const Color _backgroundGray = Color(0xFFF9FAFB);
  static const Color _textDark = Color(0xFF111827);
  static const Color _textMuted = Color(0xFF6B7280);
  static const Color _cardWhite = Color(0xFFFFFFFF);
  static const Color _successGreen = Color(0xFF10B981);
  static const Color _borderLight = Color(0xFFE5E7EB);

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  bool _isAvailable = true;

  // ── Mock Tradesperson Data ────────────────────────────────────
  final _Tradesperson _tradesperson = const _Tradesperson(
    name: 'Marcus Johnson',
    category: 'Electrician',
    rating: 4.8,
    totalReviews: 127,
    isVerified: true,
  );

  late List<_JobRequest> _jobRequests;
  late List<_OngoingJob> _ongoingJobs;
  late List<_CompletedJob> _completedJobs;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();

    _jobRequests = [
      const _JobRequest(
        id: '1',
        homeownerName: 'Sarah Williams',
        problemDescription:
            'Faulty wiring in kitchen causing intermittent power outages',
        location: '42 Oak Street, Brighton',
        dateRequested: '4 Mar 2026',
      ),
      const _JobRequest(
        id: '2',
        homeownerName: 'David Chen',
        problemDescription:
            'Install new ceiling fan and light fixture in living room',
        location: '15 Maple Avenue, Sandton',
        dateRequested: '3 Mar 2026',
      ),
    ];

    _ongoingJobs = [
      const _OngoingJob(
        id: '3',
        homeownerName: 'Emily Roberts',
        problemDescription: 'Complete rewiring of upstairs bedroom circuit',
        location: '8 Pine Road, Rosebank',
        dateAccepted: '2 Mar 2026',
        status: JobStatus.inProgress,
      ),
      const _OngoingJob(
        id: '4',
        homeownerName: 'James Mokoena',
        problemDescription: 'Repair outdoor security lighting system',
        location: '23 Birch Lane, Fourways',
        dateAccepted: '1 Mar 2026',
        status: JobStatus.onTheWay,
      ),
    ];

    _completedJobs = [
      const _CompletedJob(
        id: '5',
        homeownerName: 'Aisha Patel',
        problemDescription: 'Installed smart home electrical panel upgrade',
        location: '67 Cedar Drive, Bryanston',
        dateCompleted: '28 Feb 2026',
        rating: 5.0,
        review: 'Excellent work! Very professional and efficient.',
      ),
      const _CompletedJob(
        id: '6',
        homeownerName: 'Thomas Nkosi',
        problemDescription: 'Fixed tripping main breaker and replaced fuse box',
        location: '12 Elm Court, Midrand',
        dateCompleted: '25 Feb 2026',
        rating: 4.5,
      ),
    ];
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  // ── Actions ───────────────────────────────────────────────────

  void _acceptJob(String jobId) {
    final index = _jobRequests.indexWhere((j) => j.id == jobId);
    if (index == -1) return;
    final request = _jobRequests[index];
    setState(() {
      _jobRequests.removeAt(index);
      _ongoingJobs.insert(
        0,
        _OngoingJob(
          id: request.id,
          homeownerName: request.homeownerName,
          problemDescription: request.problemDescription,
          location: request.location,
          dateAccepted: 'Today',
          status: JobStatus.onTheWay,
        ),
      );
    });
  }

  void _declineJob(String jobId) {
    setState(() {
      _jobRequests.removeWhere((j) => j.id == jobId);
    });
  }

  void _markCompleted(String jobId) {
    final index = _ongoingJobs.indexWhere((j) => j.id == jobId);
    if (index == -1) return;
    final job = _ongoingJobs[index];
    setState(() {
      _ongoingJobs.removeAt(index);
      _completedJobs.insert(
        0,
        _CompletedJob(
          id: job.id,
          homeownerName: job.homeownerName,
          problemDescription: job.problemDescription,
          location: job.location,
          dateCompleted: 'Today',
        ),
      );
    });
  }

  void _showReview(_CompletedJob job) {
    if (job.review == null) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: _cardWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: _borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Review from ${job.homeownerName}',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: _textDark,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ...List.generate(5, (i) {
                  return Icon(
                    i < (job.rating ?? 0).floor()
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 20,
                    color: _accentOrange,
                  );
                }),
                const SizedBox(width: 8),
                Text(
                  '${job.rating}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _textDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              job.review!,
              style: const TextStyle(
                fontSize: 15,
                color: _textMuted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: _backgroundGray,
        body: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _buildWelcomeHeader()),
                SliverToBoxAdapter(child: _buildAvailabilityToggle()),
                if (_jobRequests.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: _buildSectionHeader(
                      'New Job Requests',
                      _jobRequests.length,
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) =>
                          _buildJobRequestCard(_jobRequests[index]),
                      childCount: _jobRequests.length,
                    ),
                  ),
                ],
                if (_ongoingJobs.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: _buildSectionHeader(
                      'Ongoing Jobs',
                      _ongoingJobs.length,
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) =>
                          _buildOngoingJobCard(_ongoingJobs[index]),
                      childCount: _ongoingJobs.length,
                    ),
                  ),
                ],
                if (_completedJobs.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: _buildSectionHeader(
                      'Completed Jobs',
                      _completedJobs.length,
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) =>
                          _buildCompletedJobCard(_completedJobs[index]),
                      childCount: _completedJobs.length,
                    ),
                  ),
                ],
                // Bottom padding so content clears the nav bar
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  SECTION WIDGETS
  // ═══════════════════════════════════════════════════════════════

  /// ── 1. Welcome Header ────────────────────────────────────────
  /// Blue card with initials avatar, category pill, star rating,
  /// and verification badge. Matches the ProLoginScreen branding.
  Widget _buildWelcomeHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _primaryBlue,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _primaryBlue.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Initials avatar
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                _tradesperson.name.split(' ').map((n) => n[0]).take(2).join(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Name, category, rating
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back,',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _tradesperson.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    // Category pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _tradesperson.category,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Star rating
                    const Icon(
                      Icons.star_rounded,
                      size: 16,
                      color: _accentOrange,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${_tradesperson.rating}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      ' (${_tradesperson.totalReviews})',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Verification badge
          if (_tradesperson.isVerified)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _successGreen.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.verified_rounded,
                size: 22,
                color: _successGreen,
              ),
            ),
        ],
      ),
    );
  }

  /// ── 2. Availability Toggle ───────────────────────────────────
  /// Card with adaptive switch, status icon, and descriptive text.
  Widget _buildAvailabilityToggle() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: _cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isAvailable
              ? _successGreen.withValues(alpha: 0.3)
              : _borderLight,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _isAvailable
                  ? _successGreen.withValues(alpha: 0.1)
                  : _backgroundGray,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _isAvailable
                  ? Icons.wifi_tethering_rounded
                  : Icons.wifi_tethering_off_rounded,
              size: 20,
              color: _isAvailable ? _successGreen : _textMuted,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Available for Work',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _isAvailable
                      ? 'You are visible to homeowners'
                      : 'You are hidden from new requests',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: _isAvailable ? _successGreen : _textMuted,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: _isAvailable,
            onChanged: (val) => setState(() => _isAvailable = val),
            activeColor: _successGreen,
            activeTrackColor: _successGreen.withValues(alpha: 0.3),
            inactiveThumbColor: _textMuted,
            inactiveTrackColor: _borderLight,
          ),
        ],
      ),
    );
  }

  /// Section header with title and count badge.
  Widget _buildSectionHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: _textDark,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _primaryBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ── 3. New Job Request Card ──────────────────────────────────
  /// Card with homeowner info, description, location, and
  /// Accept / Decline action buttons.
  Widget _buildJobRequestCard(_JobRequest job) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _accentOrange.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: avatar, name, date, NEW badge
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _accentOrange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    job.homeownerName
                        .split(' ')
                        .map((n) => n[0])
                        .take(2)
                        .join(),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _accentOrange,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.homeownerName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      job.dateRequested,
                      style: const TextStyle(fontSize: 12, color: _textMuted),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _accentOrange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'NEW',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _accentOrange,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Description
          Text(
            job.problemDescription,
            style: const TextStyle(
              fontSize: 14,
              color: _textDark,
              fontWeight: FontWeight.w400,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),

          // Location row
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 15,
                color: _textMuted,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  job.location,
                  style: const TextStyle(fontSize: 13, color: _textMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Accept / Decline buttons
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton(
                    onPressed: () => _declineJob(job.id),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _textMuted,
                      side: const BorderSide(color: _borderLight, width: 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Decline',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () => _acceptJob(job.id),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Accept',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// ── 4. Ongoing Job Card ──────────────────────────────────────
  /// Card with animated status badge and "Mark as Completed" button.
  Widget _buildOngoingJobCard(_OngoingJob job) {
    final bool isInProgress = job.status == JobStatus.inProgress;
    final Color statusColor = isInProgress ? _primaryBlue : _accentOrange;
    final String statusLabel = isInProgress ? 'In Progress' : 'On the Way';
    final IconData statusIcon = isInProgress
        ? Icons.engineering_rounded
        : Icons.directions_car_rounded;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with status badge
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(statusIcon, size: 18, color: statusColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.homeownerName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Accepted ${job.dateAccepted}',
                      style: const TextStyle(fontSize: 12, color: _textMuted),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Text(
            job.problemDescription,
            style: const TextStyle(fontSize: 14, color: _textDark, height: 1.4),
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 15,
                color: _textMuted,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  job.location,
                  style: const TextStyle(fontSize: 13, color: _textMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: () => _markCompleted(job.id),
              icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
              label: const Text(
                'Mark as Completed',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _successGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ── 5. Completed Job Card ────────────────────────────────────
  /// Card with completion badge, star rating, and optional
  /// "View Review" bottom-sheet trigger.
  Widget _buildCompletedJobCard(_CompletedJob job) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _successGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  size: 18,
                  color: _successGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.homeownerName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Completed ${job.dateCompleted}',
                      style: const TextStyle(fontSize: 12, color: _textMuted),
                    ),
                  ],
                ),
              ),
              // Completed badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _successGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Completed',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _successGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Text(
            job.problemDescription,
            style: const TextStyle(fontSize: 14, color: _textDark, height: 1.4),
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 15,
                color: _textMuted,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  job.location,
                  style: const TextStyle(fontSize: 13, color: _textMuted),
                ),
              ),
            ],
          ),

          // Rating + View Review
          if (job.rating != null) ...[
            const SizedBox(height: 12),
            const Divider(color: _borderLight, height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                ...List.generate(5, (i) {
                  return Icon(
                    i < job.rating!.floor()
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 18,
                    color: _accentOrange,
                  );
                }),
                const SizedBox(width: 6),
                Text(
                  '${job.rating}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _textDark,
                  ),
                ),
                const Spacer(),
                if (job.review != null)
                  GestureDetector(
                    onTap: () => _showReview(job),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _primaryBlue.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'View Review',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _primaryBlue,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  PLACEHOLDER TAB (Jobs & Profile — coming soon)
// ─────────────────────────────────────────────────────────────────

class _PlaceholderTab extends StatelessWidget {
  final String title;
  final IconData icon;

  const _PlaceholderTab({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFF1E3A8A).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, size: 32, color: const Color(0xFF1E3A8A)),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Coming soon',
              style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
            ),
          ],
        ),
      ),
    );
  }
}
