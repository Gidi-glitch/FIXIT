import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/api_service.dart';
import 'jobs_screen.dart';
import 'requests_screen.dart';
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
  final ValueNotifier<bool> _onDutyNotifier = ValueNotifier<bool>(true);
<<<<<<< HEAD
  String _displayName = 'Tradesperson';
  String _firstName = 'Tradesperson';
=======
  bool _isUpdatingOnDuty = false;
  String _displayName = 'Tradesperson';
  String _firstName = 'Tradesperson';
  String _trade = 'Tradesperson';
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
  String? _profileImagePath;
  String? _messageHomeownerName;
  String? _messageService;
  String? _messageAvatar;
<<<<<<< HEAD
  String? _messageHomeownerUserId;
  int _messageChatRequestId = 0;
=======
  int _messageChatRequestId = 0;
  double _averageRating = 0;
  int _reviewCount = 0;
  String _verificationStatus = 'pending';
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe

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

<<<<<<< HEAD
  // ── Sample Data ────────────────────────────────────────────────
  final Map<String, dynamic> _stats = {
    'newRequests': 3,
    'activeJobs': 2,
    'completedJobs': 47,
    'rating': 4.9,
  };

=======
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
  List<Map<String, dynamic>> get _incomingRequests =>
      TradespersonWorkStore.dashboardRequests();

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
    _loadProfileData();
<<<<<<< HEAD
    _syncWorkItems();
=======
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
  }

  void _handleOnDutyChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _handleStoreChanged() {
    if (!mounted) return;
    setState(() {});
  }

<<<<<<< HEAD
  Future<void> _syncWorkItems() async {
    await TradespersonWorkStore.syncFromBackend();
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
=======
  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    bool? onDutyFromApi;
    var verificationStatus = _verificationStatus;
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe

    final token = prefs.getString('token')?.trim();
    if (token != null && token.isNotEmpty) {
      try {
        final result = await ApiService.getProfile(token);
        final user =
            (result['user'] as Map?)?.cast<String, dynamic>() ??
            <String, dynamic>{};
<<<<<<< HEAD
=======
        final profile =
            (result['profile'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{};
        onDutyFromApi = _readOnDutyFromProfilePayload(result, user);
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
        final firstNameFromApi = (user['first_name'] ?? '').toString().trim();
        final lastNameFromApi = (user['last_name'] ?? '').toString().trim();
        final fullNameFromApi = '$firstNameFromApi $lastNameFromApi'.trim();
        final profileImageUrl = (user['profile_image_url'] ?? '')
            .toString()
            .trim();
<<<<<<< HEAD
=======
        final tradeFromApi = (user['trade'] ?? profile['trade_category'])
            .toString()
            .trim();
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe

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
<<<<<<< HEAD
        final userId = (user['id'] ?? '').toString().trim();
        if (userId.isNotEmpty) {
          await prefs.setString('user_id', userId);
        }
      } catch (_) {
        // Keep cached profile values if profile refresh fails.
      }
    }

    final firstName = prefs.getString('first_name')?.trim();
    final lastName = prefs.getString('last_name')?.trim();
    final fullNameFromPrefs = prefs.getString('full_name')?.trim();
=======
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
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
    final fullName = fullNameFromPrefs?.isNotEmpty == true
        ? fullNameFromPrefs!
        : '${firstName ?? ''} ${lastName ?? ''}'.trim();

    if (!mounted) return;

    setState(() {
      _firstName = (firstName?.isNotEmpty == true)
          ? firstName!
          : (fullName.isNotEmpty ? fullName.split(' ').first : 'Tradesperson');
      _displayName = fullName.isNotEmpty ? fullName : 'Tradesperson';
<<<<<<< HEAD
      _profileImagePath = prefs.getString('profile_image_url');
    });
=======
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

  Future<void> _setOnDutyStatus(bool value) async {
    if (_isUpdatingOnDuty || _onDutyNotifier.value == value) return;

    final previous = _onDutyNotifier.value;
    setState(() => _isUpdatingOnDuty = true);
    _onDutyNotifier.value = value;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token')?.trim() ?? '';
      if (token.isEmpty) {
        throw Exception('Session expired. Please log in again.');
      }

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
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
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
    _onDutyNotifier.removeListener(_handleOnDutyChanged);
    TradespersonWorkStore.notifier.removeListener(_handleStoreChanged);
    _onDutyNotifier.dispose();
    _fadeController.dispose();
    super.dispose();
  }

<<<<<<< HEAD
  void _openMessagesForHomeowner(
    String name,
    String service,
    String avatar, [
    String? userId,
  ]) {
=======
  void _openMessagesForHomeowner(String name, String service, String avatar) {
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
    setState(() {
      _messageHomeownerName = name.trim();
      _messageService = service.trim();
      _messageAvatar = avatar.trim();
<<<<<<< HEAD
      _messageHomeownerUserId = userId?.trim();
=======
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
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
            const JobsScreen(),
            TradespersonMessagesScreen(
              initialHomeownerName: _messageHomeownerName,
              initialService: _messageService,
              initialAvatar: _messageAvatar,
<<<<<<< HEAD
              initialHomeownerUserId: _messageHomeownerUserId,
=======
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
              autoOpenChat: _messageChatRequestId > 0,
              chatRequestId: _messageChatRequestId,
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
<<<<<<< HEAD
=======
    final verificationColor = _verificationColor(_verificationStatus);
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
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
<<<<<<< HEAD
                        color: _successGreen.withValues(alpha: 0.12),
=======
                        color: verificationColor.withValues(alpha: 0.12),
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
<<<<<<< HEAD
                            Icons.verified_rounded,
                            size: 12,
                            color: _successGreen,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Verified',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: _successGreen,
=======
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
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
<<<<<<< HEAD
                      'Plumber',
=======
                      _trade,
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
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
              onPressed: () {},
              icon: Stack(
                children: [
                  const Icon(
                    Icons.notifications_outlined,
                    color: _textDark,
                    size: 24,
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: _accentOrange,
                        shape: BoxShape.circle,
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
<<<<<<< HEAD
              onChanged: (value) => _onDutyNotifier.value = value,
=======
              onChanged: _isUpdatingOnDuty ? null : _setOnDutyStatus,
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
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
<<<<<<< HEAD
=======
    final ratingLabel = _reviewCount > 0
        ? _averageRating.toStringAsFixed(1)
        : '0.0';
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
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
<<<<<<< HEAD
            '${_stats['rating']}',
=======
            ratingLabel,
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
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
      child: Container(
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
<<<<<<< HEAD
=======
            final urgency = (request['urgency'] ?? '').toString();
            final homeownerProfileImageUrl =
                (request['homeownerProfileImageUrl'] ?? '').toString().trim();
            final urgencyColorRaw = request['urgencyColor'];
            final urgencyColor = urgencyColorRaw is Color
                ? urgencyColorRaw
                : _urgencyColor(urgency);
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
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
<<<<<<< HEAD
                        child: Center(
                          child: Text(
                            request['avatar'] as String,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
=======
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
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
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
<<<<<<< HEAD
                          color: (request['urgencyColor'] as Color).withValues(
                            alpha: 0.12,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          request['urgency'] as String,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: request['urgencyColor'] as Color,
=======
                          color: urgencyColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          urgency,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: urgencyColor,
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
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
<<<<<<< HEAD
                          onPressed: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            final declined =
                                await TradespersonWorkStore.declineRequestById(
                                  request['id'] as String,
                                );
                            if (!mounted) return;
                            if (!declined) {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: const Text(
                                    'Unable to decline request right now.',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  backgroundColor: _errorRed,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  margin: const EdgeInsets.all(16),
                                ),
                              );
                              return;
                            }
                            messenger.showSnackBar(
=======
                          onPressed: () {
                            TradespersonWorkStore.declineRequestById(
                              request['id'] as String,
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
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
                          },
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
<<<<<<< HEAD
                          onPressed: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            final accepted =
                                await TradespersonWorkStore.acceptRequestById(
                                  request['id'] as String,
                                );
                            if (!mounted) return;
                            if (!accepted) {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: const Text(
                                    'Unable to accept request right now.',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  backgroundColor: _errorRed,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  margin: const EdgeInsets.all(16),
                                ),
                              );
                              return;
                            }
                            messenger.showSnackBar(
=======
                          onPressed: () {
                            TradespersonWorkStore.acceptRequestById(
                              request['id'] as String,
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
                              SnackBar(
                                content: Text(
                                  'Request from ${request['homeowner']} accepted!',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
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
                          },
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
<<<<<<< HEAD
=======
    final currentJobProfileImageUrl =
        (currentJob?['homeownerProfileImageUrl'] ?? '').toString().trim();
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe

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
<<<<<<< HEAD
                      child: Center(
                        child: Text(
                          (currentJob['avatar'] ?? 'TP').toString(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
=======
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
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
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
<<<<<<< HEAD
=======
    final customerSatisfaction = _reviewCount > 0
        ? _averageRating.clamp(0.0, 5.0)
        : 0.0;
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
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
<<<<<<< HEAD
                  '4.9/5',
                  0.98,
=======
                  '${customerSatisfaction.toStringAsFixed(1)}/5',
                  customerSatisfaction / 5,
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
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
                child: _buildNavItem(0, Icons.dashboard_rounded, 'Dashboard'),
              ),
              Expanded(
                child: _buildNavItem(1, Icons.inbox_rounded, 'Requests'),
              ),
              Expanded(child: _buildNavItem(2, Icons.handyman_rounded, 'Jobs')),
              Expanded(
                child: _buildNavItem(
                  3,
                  Icons.chat_bubble_outline_rounded,
                  'Messages',
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

  Widget _buildNavItem(int index, IconData icon, String label) {
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
            Icon(icon, color: isActive ? _primaryBlue : _textMuted, size: 24),
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
