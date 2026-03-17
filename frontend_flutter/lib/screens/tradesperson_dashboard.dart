import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_fixit_application/screens/login_screen.dart';

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

class _CommunityPost {
  final String authorName;
  final String message;
  final String postedAt;
  final String location;
  final String? photoLabel;
  final List<_PostComment> comments;

  _CommunityPost({
    required this.authorName,
    required this.message,
    required this.postedAt,
    required this.location,
    this.photoLabel,
    List<_PostComment>? comments,
  }) : comments = comments ?? <_PostComment>[];
}

class _PostComment {
  final String authorName;
  final String text;
  final String timeLabel;

  const _PostComment({
    required this.authorName,
    required this.text,
    required this.timeLabel,
  });
}

class _ServiceOfferPost {
  final String tradesmanName;
  final String skill;
  final String message;
  final String postedAt;
  final String? photoLabel;

  const _ServiceOfferPost({
    required this.tradesmanName,
    required this.skill,
    required this.message,
    required this.postedAt,
    this.photoLabel,
  });
}

class _MessageThread {
  final String homeownerName;
  final String lastMessage;
  final String timeLabel;
  final int unreadCount;

  const _MessageThread({
    required this.homeownerName,
    required this.lastMessage,
    required this.timeLabel,
    this.unreadCount = 0,
  });
}

// ─────────────────────────────────────────────────────────────────
//  MAIN SHELL — Bottom Navigation with 4 Tabs
// ─────────────────────────────────────────────────────────────────

/// Entry-point widget for the tradesperson side of FIXit.
/// Provides bottom navigation with Home, Jobs, Messages, and Profile tabs.
class TradesmanDashboard extends StatefulWidget {
  const TradesmanDashboard({super.key});

  @override
  State<TradesmanDashboard> createState() => _TradesmanDashboardState();
}

class _TradesmanDashboardState extends State<TradesmanDashboard> {
  // ── Color Palette (matches prologin_screen.dart) ──────────────
  static const Color _primaryBlue = Color.fromARGB(255, 255, 167, 59);
  static const Color _textMuted = Color(0xFF6B7280);
  static const Color _cardWhite = Color(0xFFFFFFFF);
  static const Color _borderLight = Color(0xFFE5E7EB);
  static const Color _backgroundGray = Color(0xFFF9FAFB);
  static const String _proName = 'Prince Aeroll';
  static const String _proEmail = 'princeaeroll@fixit.com';
  static const String _proSpecialty = 'Electrician';
  static const String _proStatus = 'Verified Pro';
  static const List<String> _proAchievements = [
    'Top Rated Electrician 2025',
    '200+ Completed Repairs',
  ];
  static const List<String> _proRecentWorks = [
    'Main panel rewiring for 2-storey residence',
    'Smart breaker and load balancing setup',
  ];
  static const List<String> _proCertificates = [
    'TESDA NC II - Electrical Installation',
  ];

  int _currentIndex = 0;

  List<Widget> get _screens => [
    const _DashboardHome(),
    const _DashboardHome(showJobsOnly: true),
    const _MessagesTab(),
    _ProfileTab(
      onSignOut: _handleSignOut,
      name: _proName,
      email: _proEmail,
      specialty: _proSpecialty,
      status: _proStatus,
      achievements: _proAchievements,
      recentWorks: _proRecentWorks,
      initialCertificates: _proCertificates,
    ),
  ];

  void _handleSignOut() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const UserLoginScreen()),
      (route) => false,
    );
  }

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
                  icon: Icons.chat_bubble_outline_rounded,
                  activeIcon: Icons.chat_bubble_rounded,
                  label: 'Messages',
                ),
                _buildNavItem(
                  index: 3,
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
  final bool showJobsOnly;

  const _DashboardHome({this.showJobsOnly = false});

  @override
  State<_DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<_DashboardHome>
    with SingleTickerProviderStateMixin {
  // ── Color Palette (matches prologin_screen.dart) ──────────────
  static const Color _primaryBlue = Color(0xFFF97316);
  static const Color _accentOrange = Color(0xFFF97316);
  static const Color _backgroundGray = Color(0xFFF9FAFB);
  static const Color _textDark = Color(0xFF111827);
  static const Color _textMuted = Color(0xFF6B7280);
  static const Color _cardWhite = Color(0xFFFFFFFF);
  static const Color _successGreen = Color(0xFF10B981);
  static const Color _borderLight = Color(0xFFE5E7EB);

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  final TextEditingController _postController = TextEditingController();
  String? _attachedPhotoLabel;

  bool _isAvailable = true;

  // ── Mock Tradesperson Data ────────────────────────────────────
  final _Tradesperson _tradesperson = const _Tradesperson(
    name: 'Prince Aeroll',
    category: 'Electrician',
    rating: 4.8,
    totalReviews: 127,
    isVerified: true,
  );

  late List<_JobRequest> _jobRequests;
  late List<_OngoingJob> _ongoingJobs;
  late List<_CompletedJob> _completedJobs;
  late List<_CommunityPost> _communityPosts;
  late List<_ServiceOfferPost> _serviceOfferPosts;

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
        homeownerName: 'Shawn Vita',
        problemDescription:
            'Tripping circuit breaker when using multiple appliances',
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

    _serviceOfferPosts = [
      const _ServiceOfferPost(
        tradesmanName: 'Prince Aeroll',
        skill: 'Electrician',
        message: 'Available today for electrical repairs around San Pablo.',
        postedAt: 'Just now',
      ),
      const _ServiceOfferPost(
        tradesmanName: 'Marco Santos',
        skill: 'Plumber',
        message: 'Offering same-day leak repairs and pipe replacements.',
        postedAt: '14m ago',
      ),
      const _ServiceOfferPost(
        tradesmanName: 'Rico De Leon',
        skill: 'Aircon Technician',
        message: 'Available for cleaning, maintenance, and troubleshooting.',
        postedAt: '31m ago',
        photoLabel: 'Service portfolio photo',
      ),
    ];

    _communityPosts = [
      _CommunityPost(
        authorName: 'Sarah Williams',
        message: 'Need urgent help with kitchen wiring. Power keeps cutting.',
        postedAt: '8m ago',
        location: '42 Oak Street, Brighton',
        comments: [
          const _PostComment(
            authorName: 'Prince Aeroll',
            text: 'I can inspect this today. What time are you available?',
            timeLabel: '2m ago',
          ),
        ],
      ),
      _CommunityPost(
        authorName: 'Aisha Patel',
        message:
            'Looking for plumber to fix low water pressure in 2 bathrooms.',
        postedAt: '22m ago',
        location: '67 Cedar Drive, Bryanston',
      ),
      _CommunityPost(
        authorName: 'James Mokoena',
        message: 'Need appliance tech for a washing machine not spinning.',
        postedAt: '45m ago',
        location: '23 Birch Lane, Fourways',
        photoLabel: 'Attached issue photo',
      ),
    ];
  }

  @override
  void dispose() {
    _postController.dispose();
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

  void _submitAvailabilityPost() {
    final text = _postController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _serviceOfferPosts.insert(
        0,
        _ServiceOfferPost(
          tradesmanName: _tradesperson.name,
          skill: _tradesperson.category,
          message: text,
          postedAt: 'Just now',
          photoLabel: _attachedPhotoLabel,
        ),
      );
    });
    _postController.clear();
    _attachedPhotoLabel = null;
    FocusScope.of(context).unfocus();
  }

  void _commentOnPost(_CommunityPost post) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Add Comment'),
          content: TextField(
            controller: controller,
            maxLines: 3,
            minLines: 1,
            decoration: const InputDecoration(
              hintText: 'Write your reply to the homeowner...',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final text = controller.text.trim();
                if (text.isEmpty) return;
                setState(() {
                  post.comments.add(
                    _PostComment(
                      authorName: _tradesperson.name,
                      text: text,
                      timeLabel: 'Just now',
                    ),
                  );
                });
                Navigator.pop(context);
              },
              child: const Text('Comment'),
            ),
          ],
        );
      },
    );
  }

  void _showPhotoSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _cardWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: const Text('Take Photo'),
                  onTap: () {
                    Navigator.pop(context);
                    setState(
                      () => _attachedPhotoLabel = 'Camera photo attached',
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Choose from Gallery'),
                  onTap: () {
                    Navigator.pop(context);
                    setState(
                      () => _attachedPhotoLabel = 'Gallery photo attached',
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
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
                if (!widget.showJobsOnly) ...[
                  SliverToBoxAdapter(child: _buildWelcomeHeader()),
                  SliverToBoxAdapter(child: _buildAvailabilityToggle()),
                  SliverToBoxAdapter(child: _buildAvailabilityComposer()),
                ],
                if (!widget.showJobsOnly && _serviceOfferPosts.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: _buildSectionHeader(
                      'Tradesman Service Offers',
                      _serviceOfferPosts.length,
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) =>
                          _buildServiceOfferCard(_serviceOfferPosts[index]),
                      childCount: _serviceOfferPosts.length,
                    ),
                  ),
                ],
                if (!widget.showJobsOnly && _communityPosts.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: _buildSectionHeader(
                      'Homeowner Requests',
                      _communityPosts.length,
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) =>
                          _buildCommunityPostCard(_communityPosts[index]),
                      childCount: _communityPosts.length,
                    ),
                  ),
                ],
                if (widget.showJobsOnly && _jobRequests.isNotEmpty) ...[
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
                if (widget.showJobsOnly && _ongoingJobs.isNotEmpty) ...[
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
                if (widget.showJobsOnly && _completedJobs.isNotEmpty) ...[
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

  Widget _buildAvailabilityComposer() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Post Availability',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _textDark,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _postController,
            maxLines: 3,
            minLines: 2,
            decoration: InputDecoration(
              hintText:
                  'Post that you are looking for homeowners who need help.',
              hintStyle: const TextStyle(fontSize: 13, color: _textMuted),
              filled: true,
              fillColor: _backgroundGray,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _showPhotoSourceSheet,
                icon: const Icon(Icons.add_a_photo_outlined, size: 16),
                label: const Text('Add Photo'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _primaryBlue,
                  side: const BorderSide(color: _borderLight),
                ),
              ),
              if (_attachedPhotoLabel != null) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _primaryBlue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.image_outlined,
                          size: 14,
                          color: _primaryBlue,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _attachedPhotoLabel!,
                            style: const TextStyle(
                              fontSize: 11,
                              color: _primaryBlue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () =>
                              setState(() => _attachedPhotoLabel = null),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 14,
                            color: _primaryBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: _submitAvailabilityPost,
              icon: const Icon(Icons.campaign_rounded, size: 16),
              label: const Text('Post Offer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryBlue,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityPostCard(_CommunityPost post) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  post.authorName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _textDark,
                  ),
                ),
              ),
              Text(
                post.postedAt,
                style: const TextStyle(fontSize: 11, color: _textMuted),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Homeowner Request',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _accentOrange,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            post.message,
            style: const TextStyle(
              fontSize: 13,
              color: _textDark,
              height: 1.35,
            ),
          ),
          if (post.photoLabel != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.image_outlined, size: 14, color: _textMuted),
                const SizedBox(width: 6),
                Text(
                  post.photoLabel!,
                  style: const TextStyle(
                    fontSize: 11,
                    color: _textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 14,
                color: _textMuted,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  post.location,
                  style: const TextStyle(fontSize: 11, color: _textMuted),
                ),
              ),
              TextButton.icon(
                onPressed: () => _commentOnPost(post),
                icon: const Icon(Icons.mode_comment_outlined, size: 16),
                label: const Text('Comment'),
                style: TextButton.styleFrom(
                  foregroundColor: _primaryBlue,
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (post.comments.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Divider(height: 1, color: _borderLight),
            const SizedBox(height: 8),
            ...post.comments.map(
              (comment) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.subdirectory_arrow_right,
                      size: 14,
                      color: _textMuted,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 12,
                            color: _textDark,
                          ),
                          children: [
                            TextSpan(
                              text: '${comment.authorName}: ',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            TextSpan(text: comment.text),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      comment.timeLabel,
                      style: const TextStyle(fontSize: 10, color: _textMuted),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildServiceOfferCard(_ServiceOfferPost post) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  post.tradesmanName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _textDark,
                  ),
                ),
              ),
              Text(
                post.postedAt,
                style: const TextStyle(fontSize: 11, color: _textMuted),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            post.skill,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _primaryBlue,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            post.message,
            style: const TextStyle(
              fontSize: 13,
              color: _textDark,
              height: 1.35,
            ),
          ),
          if (post.photoLabel != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.image_outlined, size: 14, color: _textMuted),
                const SizedBox(width: 6),
                Text(
                  post.photoLabel!,
                  style: const TextStyle(
                    fontSize: 11,
                    color: _textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
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


class _MessagesTab extends StatelessWidget {
  const _MessagesTab();

  static const List<_MessageThread> _threads = [
    _MessageThread(
      homeownerName: 'Sarah Williams',
      lastMessage: 'Can you come by tomorrow at 9 AM?',
      timeLabel: '2m',
      unreadCount: 2,
    ),
    _MessageThread(
      homeownerName: 'James Mokoena',
      lastMessage: 'Thanks, the lights are working now.',
      timeLabel: '18m',
    ),
    _MessageThread(
      homeownerName: 'Aisha Patel',
      lastMessage: 'I uploaded a photo of the breaker panel.',
      timeLabel: '1h',
      unreadCount: 1,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Messages',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                itemCount: _threads.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final thread = _threads[index];
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: const Color(
                            0xFF1E3A8A,
                          ).withValues(alpha: 0.1),
                          child: Text(
                            thread.homeownerName
                                .split(' ')
                                .map((n) => n[0])
                                .take(2)
                                .join(),
                            style: const TextStyle(
                              color: Color(0xFF1E3A8A),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                thread.homeownerName,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF111827),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                thread.lastMessage,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              thread.timeLabel,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                            if (thread.unreadCount > 0) ...[
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF97316),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${thread.unreadCount}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileTab extends StatefulWidget {
  final VoidCallback onSignOut;
  final String name;
  final String email;
  final String specialty;
  final String status;
  final List<String> achievements;
  final List<String> recentWorks;
  final List<String> initialCertificates;

  const _ProfileTab({
    required this.onSignOut,
    required this.name,
    required this.email,
    required this.specialty,
    required this.status,
    required this.achievements,
    required this.recentWorks,
    required this.initialCertificates,
  });

  @override
  State<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<_ProfileTab> {
  late String _name;
  late String _email;
  late String _specialty;
  late String _status;
  late final List<String> _certificates = List<String>.from(
    widget.initialCertificates,
  );

  @override
  void initState() {
    super.initState();
    _name = widget.name;
    _email = widget.email;
    _specialty = widget.specialty;
    _status = widget.status;
  }

  void _editProfile() {
    final nameController = TextEditingController(text: _name);
    final emailController = TextEditingController(text: _email);
    final specialtyController = TextEditingController(text: _specialty);
    final statusController = TextEditingController(text: _status);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 14,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1D5DB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Edit Profile',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: specialtyController,
                decoration: InputDecoration(
                  labelText: 'Specialty',
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: statusController,
                decoration: InputDecoration(
                  labelText: 'Status',
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    final email = emailController.text.trim();
                    final specialty = specialtyController.text.trim();
                    final status = statusController.text.trim();
                    if (name.isEmpty ||
                        email.isEmpty ||
                        specialty.isEmpty ||
                        status.isEmpty) {
                      return;
                    }
                    setState(() {
                      _name = name;
                      _email = email;
                      _specialty = specialty;
                      _status = status;
                    });
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Save Changes'),
                ),
              ),
            ],
          ),
        );
      },
    ).whenComplete(() {
      nameController.dispose();
      emailController.dispose();
      specialtyController.dispose();
      statusController.dispose();
    });
  }

  void _uploadCertificate() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: const Text('Take Certificate Photo'),
                  onTap: () {
                    setState(
                      () => _certificates.insert(0, 'Camera certificate photo'),
                    );
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Choose Certificate from Gallery'),
                  onTap: () {
                    setState(
                      () =>
                          _certificates.insert(0, 'Gallery certificate photo'),
                    );
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A8A).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  size: 32,
                  color: Color(0xFF1E3A8A),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Profile',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _name,
                style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 4),
              const Text(
                'Tradesperson Account',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E3A8A),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _editProfile,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit Profile'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1E3A8A),
                    side: const BorderSide(color: Color(0xFFBFDBFE)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  children: [
                    _buildContextRow(
                      icon: Icons.mail_outline_rounded,
                      label: 'Email',
                      value: _email,
                    ),
                    const SizedBox(height: 10),
                    _buildContextRow(
                      icon: Icons.handyman_outlined,
                      label: 'Specialty',
                      value: _specialty,
                    ),
                    const SizedBox(height: 10),
                    _buildContextRow(
                      icon: Icons.verified_outlined,
                      label: 'Status',
                      value: _status,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _buildListCard(
                title: 'Achievements',
                items: widget.achievements,
                icon: Icons.workspace_premium_outlined,
              ),
              const SizedBox(height: 12),
              _buildListCard(
                title: 'Recent Works',
                items: widget.recentWorks,
                icon: Icons.construction_outlined,
              ),
              const SizedBox(height: 12),
              _buildCertificateCard(
                action: OutlinedButton.icon(
                  onPressed: _uploadCertificate,
                  icon: const Icon(Icons.add_a_photo_outlined, size: 16),
                  label: const Text('Attach Certificate'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1E3A8A),
                    side: const BorderSide(color: Color(0xFFBFDBFE)),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: widget.onSignOut,
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Sign Out'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFB91C1C),
                    side: const BorderSide(color: Color(0xFFFCA5A5)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCertificateCard({Widget? action}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.badge_outlined,
                size: 16,
                color: Color(0xFF1E3A8A),
              ),
              const SizedBox(width: 6),
              const Text(
                'Certificates',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E3A8A),
                ),
              ),
              const Spacer(),
              action ?? const SizedBox.shrink(),
            ],
          ),
          const SizedBox(height: 10),
          ..._certificates.map(
            (item) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDBEAFE),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.image_outlined,
                      size: 18,
                      color: Color(0xFF1E3A8A),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF111827),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListCard({
    required String title,
    required List<String> items,
    required IconData icon,
    Widget? action,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: const Color(0xFF1E3A8A)),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E3A8A),
                ),
              ),
              const Spacer(),
              action ?? const SizedBox.shrink(),
            ],
          ),
          const SizedBox(height: 8),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(fontSize: 13)),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContextRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF6B7280)),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF6B7280),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF111827),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
