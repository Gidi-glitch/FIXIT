import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/api_service.dart';
import '../../services/notification_center_service.dart';
import 'jobs_screen.dart';
import 'requests_screen.dart';
import '../../shared/notifications_inbox_screen.dart';
import 'settings/tradesperson_edit_profile_screen.dart';
import 'settings/tradesperson_my_documents_screen.dart';
import 'settings/tradesperson_service_area_screen.dart';
import 'tradesperson_messages_screen.dart';
import 'tradesperson_profile_screen.dart';
import 'tradesperson_work_store.dart';
import 'view_reviews_screen.dart';

/// Tradesperson Dashboard for the Fix It Marketplace Android app.
/// Provides job management, availability toggle, incoming requests,
/// and performance overview for verified tradespeople.
class TradesmanDashboard extends StatefulWidget {
  const TradesmanDashboard({super.key});

  @override
  State<TradesmanDashboard> createState() => _TradesmanDashboardState();
}

class _TradesmanDashboardState extends State<TradesmanDashboard>
    with SingleTickerProviderStateMixin {
  int _currentNavIndex = 0;
  String _jobsInitialFilter = 'All';
  int _jobsFilterRequestToken = 0;
  final ValueNotifier<bool> _onDutyNotifier = ValueNotifier<bool>(true);
  bool _isUpdatingOnDuty = false;
  String _displayName = 'Tradesperson';
  String _firstName = 'Tradesperson';
  String _trade = 'Tradesperson';
  String? _profileImagePath;
  String? _messageHomeownerName;
  String? _messageService;
  String? _messageAvatar;
  int? _messageHomeownerUserId;
  int? _messageBookingId;
  int _messageChatRequestId = 0;
  int _messageUnreadCount = 0;
  double _averageRating = 0;
  int _reviewCount = 0;
  String _verificationStatus = 'pending';
  int _notificationUnreadCount = 0;
  bool _isRefreshingNotificationCount = false;
  Timer? _notificationRefreshTimer;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

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

  List<Map<String, dynamic>> get _incomingRequests =>
      TradespersonWorkStore.dashboardRequests();
  int get _requestNavBadgeCount => TradespersonWorkStore.requests.length;
  int get _jobNavBadgeCount => TradespersonWorkStore.jobs
      .where(
        (job) =>
            job['status'] == 'Accepted' ||
            job['status'] == 'In Progress' ||
            job['status'] == 'Under Review',
      )
      .length;

  Map<String, dynamic>? get _currentJob {
    try {
      return TradespersonWorkStore.jobs.firstWhere(
        (job) => job['status'] == 'In Progress',
      );
    } catch (_) {
      return null;
    }
  }

  final List<Map<String, dynamic>> _quickActions = [
    {'icon': Icons.edit_rounded, 'label': 'Edit Profile'},
    {'icon': Icons.map_rounded, 'label': 'Service Area'},
    {'icon': Icons.star_rounded, 'label': 'Reviews'},
    {'icon': Icons.description_rounded, 'label': 'Documents'},
  ];

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
    _onDutyNotifier.addListener(_handleOnDutyChanged);
    TradespersonWorkStore.notifier.addListener(_handleStoreChanged);
    _loadWorkSnapshot();
    _loadProfileData();
    _refreshNotificationUnreadCount();
    _startNotificationRefresh();
  }

  void _startNotificationRefresh() {
    _notificationRefreshTimer?.cancel();
    _notificationRefreshTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      _refreshNotificationUnreadCount();
      _loadWorkSnapshot();
    });
  }

  Future<void> _refreshNotificationUnreadCount() async {
    if (!mounted || _isRefreshingNotificationCount) return;
    _isRefreshingNotificationCount = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = (prefs.getString('token') ?? '').trim();
      if (token.isEmpty) {
        if (mounted) {
          setState(() => _notificationUnreadCount = 0);
        }
        return;
      }

      final unread = await NotificationCenterService.tradespersonUnreadCount(
        token: token,
      );

      if (!mounted) return;
      setState(() => _notificationUnreadCount = unread);
    } catch (_) {
      // Keep current badge count if refresh fails.
    } finally {
      _isRefreshingNotificationCount = false;
    }
  }

  Future<void> _loadWorkSnapshot() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = (prefs.getString('token') ?? '').trim();
      if (token.isEmpty) {
        return;
      }

      final requestsResponse = await ApiService.getIncomingRequests(
        token: token,
      );
      final requestRows = (requestsResponse['requests'] as List?) ?? const [];
      TradespersonWorkStore.setRequestsFromApi(requestRows);

      final jobsResponse = await ApiService.getTradespersonJobs(token: token);
      final jobRows = (jobsResponse['jobs'] as List?) ?? const [];
      TradespersonWorkStore.setJobsFromApi(jobRows);
    } catch (_) {
      // Keep existing dashboard/store values when background refresh fails.
    }
  }

  void _handleOnDutyChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _handleStoreChanged() {
    if (!mounted) return;
    setState(() {});
    _refreshNotificationUnreadCount();
  }

  Future<void> _openNotificationsInbox() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final prefs = await SharedPreferences.getInstance();
    final token = (prefs.getString('token') ?? '').trim();
    if (token.isEmpty) {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Please log in again to view notifications.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final targetTab = await navigator.push<String>(
      MaterialPageRoute(
        builder: (_) => NotificationsInboxScreen(
          audience: NotificationAudience.tradesperson,
          token: token,
        ),
      ),
    );

    await _refreshNotificationUnreadCount();
    if (!mounted) return;

    switch (targetTab) {
      case 'requests':
        setState(() => _currentNavIndex = 1);
        break;
      case 'jobs':
        setState(() => _currentNavIndex = 2);
        break;
      case 'messages':
        setState(() => _currentNavIndex = 3);
        break;
    }
  }

  Widget _buildNotificationBadge() {
    if (_notificationUnreadCount <= 0) {
      return const SizedBox.shrink();
    }

    final label = _notificationUnreadCount > 99
        ? '99+'
        : _notificationUnreadCount.toString();

    return Positioned(
      right: -2,
      top: -2,
      child: Container(
        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        decoration: const BoxDecoration(
          color: _accentOrange,
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.w800,
            height: 1.1,
          ),
        ),
      ),
    );
  }

  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    bool? onDutyFromApi;
    var verificationStatus = _verificationStatus;

    final token = prefs.getString('token')?.trim();
    if (token != null && token.isNotEmpty) {
      try {
        final result = await ApiService.getProfile(token);
        final user =
            (result['user'] as Map?)?.cast<String, dynamic>() ??
            <String, dynamic>{};
        final profile =
            (result['profile'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{};
        onDutyFromApi = _readOnDutyFromProfilePayload(result, user);
        final firstNameFromApi = (user['first_name'] ?? '').toString().trim();
        final lastNameFromApi = (user['last_name'] ?? '').toString().trim();
        final fullNameFromApi = '$firstNameFromApi $lastNameFromApi'.trim();
        final profileImageUrl = (user['profile_image_url'] ?? '')
            .toString()
            .trim();
        final tradeFromApi = (user['trade'] ?? profile['trade_category'])
            .toString()
            .trim();

        if (firstNameFromApi.isNotEmpty) {
          await prefs.setString('first_name', firstNameFromApi);
        }
        if (lastNameFromApi.isNotEmpty) {
          await prefs.setString('last_name', lastNameFromApi);
        }
        if (fullNameFromApi.isNotEmpty) {
          await prefs.setString('full_name', fullNameFromApi);
        }
        if (profileImageUrl.isNotEmpty) {
          await prefs.setString('profile_image_url', profileImageUrl);
        } else {
          await prefs.remove('profile_image_url');
        }
        if (tradeFromApi.isNotEmpty) {
          await prefs.setString('trade', tradeFromApi);
        } else {
          await prefs.remove('trade');
        }
        if (onDutyFromApi != null) {
          await prefs.setBool('on_duty', onDutyFromApi);
        }

        verificationStatus = _normalizeVerificationStatus(
          profile['verification_status'] ?? user['verification_status'],
        );
      } catch (_) {
        // Keep cached profile values if profile refresh fails.
      }

      await _loadRatingSummary(token);
    }

    final cachedOnDuty = prefs.getBool('on_duty');
    final effectiveOnDuty = onDutyFromApi ?? cachedOnDuty;

    final firstName = prefs.getString('first_name')?.trim();
    final lastName = prefs.getString('last_name')?.trim();
    final fullNameFromPrefs = prefs.getString('full_name')?.trim();
    final tradeFromPrefs = prefs.getString('trade')?.trim();
    final fullName = fullNameFromPrefs?.isNotEmpty == true
        ? fullNameFromPrefs!
        : '${firstName ?? ''} ${lastName ?? ''}'.trim();

    if (!mounted) return;

    setState(() {
      _firstName = (firstName?.isNotEmpty == true)
          ? firstName!
          : (fullName.isNotEmpty ? fullName.split(' ').first : 'Tradesperson');
      _displayName = fullName.isNotEmpty ? fullName : 'Tradesperson';
      _trade = tradeFromPrefs != null && tradeFromPrefs.isNotEmpty
          ? tradeFromPrefs
          : 'Tradesperson';
      _profileImagePath = prefs.getString('profile_image_url');
      _verificationStatus = verificationStatus;
    });
    if (effectiveOnDuty != null) {
      _onDutyNotifier.value = effectiveOnDuty;
    }
  }

  Future<void> _loadRatingSummary(String token) async {
    try {
      final result = await ApiService.getMyTradespersonReviews(
        token: token,
        sort: 'recent',
      );
      final summary =
          (result['summary'] as Map?)?.cast<String, dynamic>() ??
          const <String, dynamic>{};
      final reviews = (result['reviews'] as List?) ?? const [];

      var rating = _asDouble(summary['average_rating']);
      var reviewCount = _asInt(summary['review_count']);

      if (reviewCount <= 0 && reviews.isNotEmpty) {
        var sum = 0.0;
        var count = 0;
        for (final row in reviews.whereType<Map>()) {
          sum += _asDouble(row['rating']);
          count++;
        }
        if (count > 0) {
          rating = sum / count;
          reviewCount = count;
        }
      }

      if (!mounted) return;
      setState(() {
        _averageRating = rating.clamp(0.0, 5.0);
        _reviewCount = reviewCount;
      });
    } catch (_) {
      // Keep default values when metrics endpoint is unavailable.
    }
  }

  bool? _asBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final text = value?.toString().trim().toLowerCase() ?? '';
    if (text == 'true' || text == '1' || text == 'yes') return true;
    if (text == 'false' || text == '0' || text == 'no') return false;
    return null;
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  double _asDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _normalizeVerificationStatus(dynamic value) {
    final raw = value?.toString().trim().toLowerCase() ?? '';
    switch (raw) {
      case 'approved':
      case 'verified':
        return 'approved';
      case 'rejected':
        return 'rejected';
      case 'pending':
      case 'in_review':
      case 'for_review':
      default:
        return 'pending';
    }
  }

  String _verificationLabel(String status) {
    switch (status) {
      case 'approved':
        return 'Verified';
      case 'rejected':
        return 'Rejected';
      default:
        return 'Pending';
    }
  }

  Color _verificationColor(String status) {
    switch (status) {
      case 'approved':
        return _successGreen;
      case 'rejected':
        return _errorRed;
      default:
        return _accentOrange;
    }
  }

  IconData _verificationIcon(String status) {
    switch (status) {
      case 'approved':
        return Icons.verified_rounded;
      case 'rejected':
        return Icons.cancel_rounded;
      default:
        return Icons.schedule_rounded;
    }
  }

  Color _urgencyColor(String urgency) {
    switch (urgency) {
      case 'High':
        return _errorRed;
      case 'Medium':
        return _warningYellow;
      case 'Low':
        return _successGreen;
      default:
        return _textMuted;
    }
  }

  bool? _readOnDutyFromProfilePayload(
    Map<String, dynamic> payload,
    Map<String, dynamic> user,
  ) {
    final direct = _asBool(user['on_duty']);
    if (direct != null) return direct;

    final embeddedUserProfile = user['tradesperson_profile'];
    if (embeddedUserProfile is Map) {
      final profile = embeddedUserProfile.cast<String, dynamic>();
      final fromEmbedded =
          _asBool(profile['on_duty']) ??
          _asBool(profile['is_available']) ??
          _asBool(profile['availability']);
      if (fromEmbedded != null) return fromEmbedded;
    }

    final topProfile = payload['tradesperson_profile'];
    if (topProfile is Map) {
      final profile = topProfile.cast<String, dynamic>();
      return _asBool(profile['on_duty']) ??
          _asBool(profile['is_available']) ??
          _asBool(profile['availability']);
    }

    return null;
  }

  Future<String> _readToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token')?.trim() ?? '';
    if (token.isEmpty) {
      throw Exception('Session expired. Please log in again.');
    }
    return token;
  }

  Future<void> _acceptDashboardRequest(Map<String, dynamic> request) async {
    try {
      final token = await _readToken();
      final requestId = _asInt(request['bookingId']);
      if (requestId <= 0) {
        throw Exception('Invalid request id.');
      }

      final response = await ApiService.acceptRequest(
        token: token,
        requestId: requestId,
      );
      final jobRow = (response['job'] as Map?)?.cast<String, dynamic>();
      TradespersonWorkStore.acceptRequestByApiResult(
        (request['id'] ?? '').toString(),
        jobRow,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Request from ${request['homeowner']} accepted!',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: _successGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      setState(() => _currentNavIndex = 2);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: _errorRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  Future<void> _declineDashboardRequest(Map<String, dynamic> request) async {
    try {
      final token = await _readToken();
      final requestId = _asInt(request['bookingId']);
      if (requestId <= 0) {
        throw Exception('Invalid request id.');
      }

      await ApiService.declineRequest(token: token, requestId: requestId);
      TradespersonWorkStore.declineRequestById(
        (request['id'] ?? '').toString(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Request declined.',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: _textMuted,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: _errorRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  Future<void> _setOnDutyStatus(bool value) async {
    if (_isUpdatingOnDuty || _onDutyNotifier.value == value) return;

    final previous = _onDutyNotifier.value;
    setState(() => _isUpdatingOnDuty = true);
    _onDutyNotifier.value = value;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = await _readToken();

      await ApiService.updateMyOnDutyStatus(token: token, isOnDuty: value);
      await prefs.setBool('on_duty', value);
    } catch (e) {
      _onDutyNotifier.value = previous;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: _errorRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isUpdatingOnDuty = false);
      }
    }
  }

  String get _initials {
    final parts = _displayName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'TP';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

  @override
  void dispose() {
    _notificationRefreshTimer?.cancel();
    _onDutyNotifier.removeListener(_handleOnDutyChanged);
    TradespersonWorkStore.notifier.removeListener(_handleStoreChanged);
    _onDutyNotifier.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _openMessagesForHomeowner(
    String name,
    String service,
    String avatar, {
    int? homeownerUserId,
    int? bookingId,
  }) {
    setState(() {
      _messageHomeownerName = name.trim();
      _messageService = service.trim();
      _messageAvatar = avatar.trim();
      _messageHomeownerUserId = homeownerUserId;
      _messageBookingId = bookingId;
      _messageChatRequestId++;
      _currentNavIndex = 3;
    });
  }

  void _handleQuickActionTap(String label) {
    switch (label) {
      case 'Edit Profile':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const TradespersonEditProfileScreen(),
          ),
        );
        break;
      case 'Service Area':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const TradespersonServiceAreaScreen(),
          ),
        );
        break;
      case 'Documents':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const TradespersonMyDocumentsScreen(),
          ),
        );
        break;
      case 'Reviews':
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const ViewReviewsScreen()));
        break;
      default:
        break;
    }
  }

  void _openCurrentJobDetails() {
    final job = _currentJob;
    if (job == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'No in-progress job to view yet.',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: _textMuted,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    setState(() => _currentNavIndex = 2);
    TradespersonWorkStore.requestOpenJobDetails((job['id'] ?? '').toString());
  }

  void _openJobsTab({String filter = 'All'}) {
    setState(() {
      _jobsInitialFilter = filter;
      _jobsFilterRequestToken++;
      _currentNavIndex = 2;
    });
  }

  void _handleStatCardTap(String label) {
    switch (label) {
      case 'New Requests':
        setState(() => _currentNavIndex = 1);
        break;
      case 'Active Jobs':
        _openJobsTab(filter: 'In Progress');
        break;
      case 'Completed':
        _openJobsTab(filter: 'Completed');
        break;
      case 'Rating':
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const ViewReviewsScreen()));
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: _backgroundGray,
        body: IndexedStack(
          index: _currentNavIndex,
          children: [
            _buildHomeContent(),
            RequestsScreen(
              onNavigateToJobs: () => setState(() => _currentNavIndex = 2),
              onMessageRequested: _openMessagesForHomeowner,
            ),
            JobsScreen(
              initialFilter: _jobsInitialFilter,
              filterRequestToken: _jobsFilterRequestToken,
            ),
            TradespersonMessagesScreen(
              initialHomeownerName: _messageHomeownerName,
              initialService: _messageService,
              initialAvatar: _messageAvatar,
              initialHomeownerUserId: _messageHomeownerUserId,
              initialBookingId: _messageBookingId,
              autoOpenChat: _messageChatRequestId > 0,
              chatRequestId: _messageChatRequestId,
              onUnreadCountChanged: (count) {
                if (!mounted) return;
                setState(() => _messageUnreadCount = count);
              },
            ),
            TradespersonProfileScreen(onDutyNotifier: _onDutyNotifier),
          ],
        ),
        bottomNavigationBar: _buildBottomNavigation(),
      ),
    );
  }

  Widget _buildHomeContent() {
    return SafeArea(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header Section ─────────────────────────────────
              _buildHeader(),

              // ── Availability Card ──────────────────────────────
              _buildAvailabilityCard(),

              // ── Stats Section ──────────────────────────────────
              _buildStatsSection(),

              // ── Incoming Requests ──────────────────────────────
              _buildIncomingRequestsSection(),

              // ── Current Job ────────────────────────────────────
              _buildCurrentJobSection(),

              // ── Performance Overview ───────────────────────────
              _buildPerformanceSection(),

              // ── Quick Actions ──────────────────────────────────
              _buildQuickActionsSection(),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  HEADER
  // ═══════════════════════════════════════════════════════════════

  Widget _buildHeader() {
    final verificationColor = _verificationColor(_verificationStatus);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          // ── Profile Avatar ────────────────────────────────────
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_primaryBlue, Color(0xFF2563EB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: _primaryBlue.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child:
                  _profileImagePath != null &&
                      _profileImagePath!.startsWith('http')
                  ? Image.network(
                      _profileImagePath!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Center(
                        child: Text(
                          _initials,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        _initials,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 14),

          // ── Greeting & Trade ──────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back, $_firstName',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: _textDark,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: verificationColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _verificationIcon(_verificationStatus),
                            size: 12,
                            color: verificationColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _verificationLabel(_verificationStatus),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: verificationColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _trade,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Notification ──────────────────────────────────────
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
              onPressed: _openNotificationsInbox,
              icon: Stack(
                children: [
                  const Icon(
                    Icons.notifications_outlined,
                    color: _textDark,
                    size: 24,
                  ),
                  _buildNotificationBadge(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  AVAILABILITY CARD
  // ═══════════════════════════════════════════════════════════════

  Widget _buildAvailabilityCard() {
    final isOnDuty = _onDutyNotifier.value;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isOnDuty
              ? [_successGreen, const Color(0xFF059669)]
              : [_textMuted, const Color(0xFF4B5563)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isOnDuty ? _successGreen : _textMuted).withValues(
              alpha: 0.35,
            ),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              isOnDuty ? Icons.work_rounded : Icons.work_off_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOnDuty ? 'You\'re On-Duty' : 'You\'re Off-Duty',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isOnDuty
                      ? 'You are visible to nearby homeowners'
                      : 'Toggle on to receive new requests',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 1.2,
            child: Switch(
              value: isOnDuty,
              onChanged: _isUpdatingOnDuty ? null : _setOnDutyStatus,
              activeThumbColor: Colors.white,
              activeTrackColor: Colors.white.withValues(alpha: 0.4),
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: Colors.white.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  STATS SECTION
  // ═══════════════════════════════════════════════════════════════

  Widget _buildStatsSection() {
    final requestCount = TradespersonWorkStore.requests.length;
    final jobs = TradespersonWorkStore.jobs;
    final ratingLabel = _reviewCount > 0
        ? _averageRating.toStringAsFixed(1)
        : '0.0';
    final activeJobs = jobs
        .where(
          (j) =>
              j['status'] == 'In Progress' ||
              j['status'] == 'Accepted' ||
              j['status'] == 'Under Review',
        )
        .length;
    final completedJobs = jobs.where((j) => j['status'] == 'Completed').length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          _buildStatCard(
            'New Requests',
            '$requestCount',
            Icons.inbox_rounded,
            _accentOrange,
          ),
          const SizedBox(width: 10),
          _buildStatCard(
            'Active Jobs',
            '$activeJobs',
            Icons.handyman_rounded,
            _infoBlue,
          ),
          const SizedBox(width: 10),
          _buildStatCard(
            'Completed',
            '$completedJobs',
            Icons.check_circle_rounded,
            _successGreen,
          ),
          const SizedBox(width: 10),
          _buildStatCard(
            'Rating',
            ratingLabel,
            Icons.star_rounded,
            _warningYellow,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleStatCardTap(label),
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
            decoration: BoxDecoration(
              color: _cardWhite,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(height: 10),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: _textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: _textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  INCOMING REQUESTS SECTION
  // ═══════════════════════════════════════════════════════════════

  Widget _buildIncomingRequestsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    'Incoming Requests',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: _textDark,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _accentOrange,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_incomingRequests.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => setState(() => _currentNavIndex = 1),
                style: TextButton.styleFrom(
                  foregroundColor: _primaryBlue,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'See All',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_ios_rounded, size: 12),
                  ],
                ),
              ),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: _incomingRequests.length,
          itemBuilder: (context, index) {
            final request = _incomingRequests[index];
            final urgency = (request['urgency'] ?? '').toString();
            final homeownerProfileImageUrl =
                (request['homeownerProfileImageUrl'] ?? '').toString().trim();
            final urgencyColorRaw = request['urgencyColor'];
            final urgencyColor = urgencyColorRaw is Color
                ? urgencyColorRaw
                : _urgencyColor(urgency);
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _cardWhite,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [_primaryBlue, Color(0xFF3B82F6)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: homeownerProfileImageUrl.isNotEmpty
                              ? Image.network(
                                  homeownerProfileImageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Center(
                                        child: Text(
                                          request['avatar'] as String,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                )
                              : Center(
                                  child: Text(
                                    request['avatar'] as String,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
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
                              request['homeowner'] as String,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: _textDark,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              request['service'] as String,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: _textMuted,
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
                          color: urgencyColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          urgency,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: urgencyColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: _textMuted.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        request['barangay'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _textMuted.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.access_time_rounded,
                        size: 14,
                        color: _textMuted.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        (request['postedAt'] ?? request['time']) as String,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _textMuted.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _declineDashboardRequest(request),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _errorRed,
                            side: BorderSide(
                              color: _errorRed.withValues(alpha: 0.35),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Decline',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            _openMessagesForHomeowner(
                              (request['homeowner'] ?? '').toString(),
                              (request['service'] ?? '').toString(),
                              (request['avatar'] ?? '').toString(),
                              bookingId: _asInt(request['bookingId']),
                            );
                          },
                          icon: const Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 16,
                          ),
                          label: const Text(
                            'Message',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _primaryBlue,
                            side: BorderSide(
                              color: _primaryBlue.withValues(alpha: 0.35),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _acceptDashboardRequest(request),
                          icon: const Icon(Icons.check_rounded, size: 18),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryBlue,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          label: const Text(
                            'Accept',
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
              ),
            );
          },
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  CURRENT JOB SECTION
  // ═══════════════════════════════════════════════════════════════

  Widget _buildCurrentJobSection() {
    final currentJob = _currentJob;
    final currentJobProfileImageUrl =
        (currentJob?['homeownerProfileImageUrl'] ?? '').toString().trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Text(
            'Current Job',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: _textDark,
              letterSpacing: -0.3,
            ),
          ),
        ),
        if (currentJob == null)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _cardWhite,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'No in-progress job right now',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Active jobs will appear here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _textMuted.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _primaryBlue.withValues(alpha: 0.08),
                  _primaryBlue.withValues(alpha: 0.03),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _primaryBlue.withValues(alpha: 0.15),
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_primaryBlue, Color(0xFF3B82F6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: currentJobProfileImageUrl.isNotEmpty
                            ? Image.network(
                                currentJobProfileImageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Center(
                                      child: Text(
                                        (currentJob['avatar'] ?? 'TP')
                                            .toString(),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                              )
                            : Center(
                                child: Text(
                                  (currentJob['avatar'] ?? 'TP').toString(),
                                  style: const TextStyle(
                                    fontSize: 16,
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
                            (currentJob['homeowner'] ?? '').toString(),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: _textDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            (currentJob['service'] ?? '').toString(),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: _textMuted,
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
                        color: _infoBlue.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.circle, color: _infoBlue, size: 6),
                          const SizedBox(width: 4),
                          Text(
                            (currentJob['status'] ?? 'In Progress').toString(),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _infoBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _cardWhite,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        size: 18,
                        color: _primaryBlue,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          (currentJob['address'] ?? '').toString(),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _textDark,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _textMuted.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 12,
                              color: _textMuted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Started ${(currentJob['startedAt'] ?? currentJob['time'] ?? '').toString()}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: _textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _openCurrentJobDetails,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.visibility_rounded, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'View Details',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  PERFORMANCE OVERVIEW
  // ═══════════════════════════════════════════════════════════════

  Widget _buildPerformanceSection() {
    final customerSatisfaction = _reviewCount > 0
        ? _averageRating.clamp(0.0, 5.0)
        : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 28, 20, 16),
          child: Text(
            'Performance Overview',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: _textDark,
              letterSpacing: -0.3,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _cardWhite,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildPerformanceRow(
                  'Response Rate',
                  '98%',
                  0.98,
                  _successGreen,
                ),
                const SizedBox(height: 16),
                _buildPerformanceRow('Completion Rate', '95%', 0.95, _infoBlue),
                const SizedBox(height: 16),
                _buildPerformanceRow(
                  'Customer Satisfaction',
                  '${customerSatisfaction.toStringAsFixed(1)}/5',
                  customerSatisfaction / 5,
                  _warningYellow,
                ),
                const SizedBox(height: 16),
                _buildPerformanceRow(
                  'On-Time Arrival',
                  '92%',
                  0.92,
                  _accentOrange,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceRow(
    String label,
    String value,
    double progress,
    Color color,
  ) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _textMuted,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: color.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  QUICK ACTIONS
  // ═══════════════════════════════════════════════════════════════

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 28, 20, 16),
          child: Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: _textDark,
              letterSpacing: -0.3,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: _quickActions.map((action) {
              final label = action['label'] as String;
              return Expanded(
                child: GestureDetector(
                  onTap: () => _handleQuickActionTap(label),
                  child: Container(
                    margin: EdgeInsets.only(
                      right: action != _quickActions.last ? 10 : 0,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: _cardWhite,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _primaryBlue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            action['icon'] as IconData,
                            color: _primaryBlue,
                            size: 20,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          label,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  BOTTOM NAVIGATION
  // ═══════════════════════════════════════════════════════════════

  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: _cardWhite,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: _buildNavItem(
                  0,
                  Icons.dashboard_rounded,
                  'Dashboard',
                  showNotificationDot: _notificationUnreadCount > 0,
                ),
              ),
              Expanded(
                child: _buildNavItem(
                  1,
                  Icons.inbox_rounded,
                  'Requests',
                  badgeCount: _requestNavBadgeCount,
                ),
              ),
              Expanded(
                child: _buildNavItem(
                  2,
                  Icons.handyman_rounded,
                  'Jobs',
                  badgeCount: _jobNavBadgeCount,
                ),
              ),
              Expanded(
                child: _buildNavItem(
                  3,
                  Icons.chat_bubble_outline_rounded,
                  'Messages',
                  badgeCount: _messageUnreadCount,
                ),
              ),
              Expanded(
                child: _buildNavItem(
                  4,
                  Icons.person_outline_rounded,
                  'Profile',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    String label, {
    int badgeCount = 0,
    bool showNotificationDot = false,
  }) {
    final isActive = _currentNavIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentNavIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? _primaryBlue.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  color: isActive ? _primaryBlue : _textMuted,
                  size: 24,
                ),
                if (showNotificationDot)
                  Positioned(
                    right: -1,
                    top: -1,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _accentOrange,
                        shape: BoxShape.circle,
                        border: Border.all(color: _cardWhite, width: 1.5),
                      ),
                    ),
                  ),
                if (badgeCount > 0)
                  Positioned(
                    right: -10,
                    top: -8,
                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _accentOrange,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _cardWhite, width: 1.5),
                      ),
                      child: Text(
                        badgeCount > 99 ? '99+' : '$badgeCount',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
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
