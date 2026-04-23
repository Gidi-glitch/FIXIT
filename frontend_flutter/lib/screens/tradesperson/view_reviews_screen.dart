import 'package:flutter/material.dart';
<<<<<<< HEAD

class ViewReviewsScreen extends StatelessWidget {
  const ViewReviewsScreen({super.key});

  static const Color _backgroundGray = Color(0xFFF9FAFB);
  static const Color _textDark = Color(0xFF111827);
  static const Color _textMuted = Color(0xFF6B7280);
  static const Color _accentOrange = Color(0xFFF97316);

  @override
  Widget build(BuildContext context) {
    final reviews = const [
      ('Maria Santos', 'Fast response and clean work.', 5),
      ('Rico Mendoza', 'Solved the leak quickly.', 5),
      ('Ana Villanueva', 'Good service, arrived on time.', 4),
    ];

    return Scaffold(
      backgroundColor: _backgroundGray,
      appBar: AppBar(
        title: const Text('Customer Reviews'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: reviews.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final (name, comment, stars) = reviews[index];
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _textDark,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: List.generate(
                    stars,
                    (_) =>
                        const Icon(Icons.star_rounded, size: 16, color: _accentOrange),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  comment,
                  style: const TextStyle(
                    color: _textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        },
=======
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/api_service.dart';

/// View Reviews Screen for the Fix It Marketplace Tradesperson App.
///
/// Shows all homeowner ratings & feedback the tradesperson has received,
/// sorted by most recent by default. Includes:
///   • Summary header — average rating, total count, star distribution bars
///   • Star-rating filter chips (All / 5★ – 1★)
///   • Sort picker  (Most Recent · Highest · Lowest)
///   • Tag filter chips (Punctual, Clean, Expert …)
///   • Animated review cards with avatar, stars, tags, comment, service info
///   • Empty state when no reviews match the active filters
class ViewReviewsScreen extends StatefulWidget {
  const ViewReviewsScreen({super.key});

  @override
  State<ViewReviewsScreen> createState() => _ViewReviewsScreenState();
}

// ── Review data model ──────────────────────────────────────────────
class _ReviewEntry {
  final String id;
  final String homeownerName;
  final String homeownerAvatar;
  final String? homeownerProfileImageUrl;
  final double rating;
  final String? comment;
  final List<String> tags;
  final String service;
  final String barangay;
  final DateTime date;

  const _ReviewEntry({
    required this.id,
    required this.homeownerName,
    required this.homeownerAvatar,
    this.homeownerProfileImageUrl,
    required this.rating,
    this.comment,
    required this.tags,
    required this.service,
    required this.barangay,
    required this.date,
  });
}

// ─────────────────────────────────────────────────────────────────
class _ViewReviewsScreenState extends State<ViewReviewsScreen> {
  // ── Color Palette (matches dashboard / review_screen) ──────────
  static const Color _primaryBlue = Color(0xFF1E3A8A);
  static const Color _accentOrange = Color(0xFFF97316);
  static const Color _backgroundGray = Color(0xFFF9FAFB);
  static const Color _textDark = Color(0xFF111827);
  static const Color _textMuted = Color(0xFF6B7280);
  static const Color _cardWhite = Color(0xFFFFFFFF);
  static const Color _successGreen = Color(0xFF10B981);
  static const Color _warningYellow = Color(0xFFF59E0B);
  static const Color _errorRed = Color(0xFFEF4444);
  static const Color _borderGray = Color(0xFFE5E7EB);

  // ── All possible tags (mirrors ReviewScreen._quickTags) ─────────
  static const List<String> _allTags = [
    'Punctual',
    'Clean',
    'Expert',
    'Friendly',
    'Professional',
    'Quick',
  ];

  // ── Filter & sort state ─────────────────────────────────────────
  int? _starFilter; // null = All, 1-5 = specific star
  String _sort = 'Recent'; // 'Recent' | 'Highest' | 'Lowest'
  String? _tagFilter; // null = no tag filter
  bool _isLoading = true;
  String? _errorMessage;

  // ── Sample review data ──────────────────────────────────────────
  // In production, replace with: TradespersonWorkStore.reviews or API call.
  static final List<_ReviewEntry> _allReviews = [
    _ReviewEntry(
      id: 'R-001',
      homeownerName: 'Gideon Alcantara',
      homeownerAvatar: 'GA',
      rating: 5,
      comment:
          'Juan was incredible — arrived on time, explained everything clearly, and fixed the leak faster than expected. Highly recommend!',
      tags: ['Punctual', 'Expert', 'Professional'],
      service: 'Pipe Leak Repair',
      barangay: 'Dayap',
      date: DateTime.now().subtract(const Duration(days: 2)),
    ),
    _ReviewEntry(
      id: 'R-002',
      homeownerName: 'Maria Clara',
      homeownerAvatar: 'MC',
      rating: 5,
      comment:
          'Very clean work. He even cleaned up after himself. The faucet is perfect now.',
      tags: ['Clean', 'Friendly', 'Quick'],
      service: 'Faucet Installation',
      barangay: 'Hanggan',
      date: DateTime.now().subtract(const Duration(days: 5)),
    ),
    _ReviewEntry(
      id: 'R-003',
      homeownerName: 'Elena Bautista',
      homeownerAvatar: 'EB',
      rating: 5,
      comment: 'Top-notch plumber. Fixed my sink leak in under an hour!',
      tags: ['Expert', 'Quick', 'Professional'],
      service: 'Kitchen Sink Leak Fix',
      barangay: 'Dayap',
      date: DateTime.now().subtract(const Duration(days: 12)),
    ),
    _ReviewEntry(
      id: 'R-004',
      homeownerName: 'Fernando Lopez',
      homeownerAvatar: 'FL',
      rating: 4,
      comment:
          'Good job overall. A little late but the quality of work was solid.',
      tags: ['Clean', 'Professional'],
      service: 'Faucet Replacement',
      barangay: 'Imok',
      date: DateTime.now().subtract(const Duration(days: 18)),
    ),
    _ReviewEntry(
      id: 'R-005',
      homeownerName: 'Lucia Reyes',
      homeownerAvatar: 'LR',
      rating: 5,
      comment: 'Outstanding service! Very professional and friendly.',
      tags: ['Punctual', 'Friendly', 'Expert'],
      service: 'Water Heater Repair',
      barangay: 'Balayhangin',
      date: DateTime.now().subtract(const Duration(days: 25)),
    ),
    _ReviewEntry(
      id: 'R-006',
      homeownerName: 'Carlos Mendoza',
      homeownerAvatar: 'CM',
      rating: 4,
      comment: null,
      tags: ['Punctual', 'Quick'],
      service: 'Toilet Repair',
      barangay: 'Dayap',
      date: DateTime.now().subtract(const Duration(days: 31)),
    ),
    _ReviewEntry(
      id: 'R-007',
      homeownerName: 'Ana Santos',
      homeownerAvatar: 'AS',
      rating: 3,
      comment:
          'Decent work but took longer than expected. Still happy with the result.',
      tags: ['Clean'],
      service: 'Drain Cleaning',
      barangay: 'Laguna',
      date: DateTime.now().subtract(const Duration(days: 38)),
    ),
    _ReviewEntry(
      id: 'R-008',
      homeownerName: 'Roberto Cruz',
      homeownerAvatar: 'RC',
      rating: 5,
      comment:
          'Juan replaced all our bathroom pipes perfectly. No leaks, no mess. Will book again!',
      tags: ['Expert', 'Clean', 'Professional'],
      service: 'Bathroom Pipe Installation',
      barangay: 'Hanggan',
      date: DateTime.now().subtract(const Duration(days: 44)),
    ),
    _ReviewEntry(
      id: 'R-009',
      homeownerName: 'Rosa Dela Cruz',
      homeownerAvatar: 'RD',
      rating: 4,
      comment: 'Polite and professional. Work was done well.',
      tags: ['Friendly', 'Professional'],
      service: 'Pipe Repair',
      barangay: 'Sucol',
      date: DateTime.now().subtract(const Duration(days: 52)),
    ),
    _ReviewEntry(
      id: 'R-010',
      homeownerName: 'Jose Garcia',
      homeownerAvatar: 'JG',
      rating: 2,
      comment:
          'Finished the job but left without checking if there were any remaining issues. Had to call again.',
      tags: [],
      service: 'Pipe Installation',
      barangay: 'Turbina',
      date: DateTime.now().subtract(const Duration(days: 60)),
    ),
    _ReviewEntry(
      id: 'R-011',
      homeownerName: 'Natividad Soriano',
      homeownerAvatar: 'NS',
      rating: 5,
      comment: 'Very fast and reliable. Solved our clogged drain in no time!',
      tags: ['Quick', 'Expert', 'Punctual'],
      service: 'Drain Cleaning',
      barangay: 'Imok',
      date: DateTime.now().subtract(const Duration(days: 68)),
    ),
    _ReviewEntry(
      id: 'R-012',
      homeownerName: 'Patrick Villanueva',
      homeownerAvatar: 'PV',
      rating: 3,
      comment: 'Okay service. Nothing exceptional but got the job done.',
      tags: ['Clean'],
      service: 'Faucet Repair',
      barangay: 'Pansol',
      date: DateTime.now().subtract(const Duration(days: 75)),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<String> _readToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token')?.trim() ?? '';
    if (token.isEmpty) {
      throw Exception('Session expired. Please log in again.');
    }
    return token;
  }

  String _toApiSort(String value) {
    switch (value) {
      case 'Highest':
        return 'highest';
      case 'Lowest':
        return 'lowest';
      default:
        return 'recent';
    }
  }

  Future<void> _loadReviews() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await _readToken();
      final response = await ApiService.getMyTradespersonReviews(
        token: token,
        sort: _toApiSort(_sort),
      );

      final rows = (response['reviews'] as List?) ?? const [];
      final loaded = rows.whereType<Map>().map((raw) {
        final row = raw.cast<String, dynamic>();
        final tags = ((row['tags'] as List?) ?? const [])
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList();

        final ratingRaw = row['rating'];
        final rating = ratingRaw is num
            ? ratingRaw.toDouble()
            : double.tryParse(ratingRaw.toString()) ?? 0;

        final createdAt =
            DateTime.tryParse((row['created_at'] ?? '').toString()) ??
            DateTime.now();

        final homeownerName = (row['homeowner_name'] ?? 'Homeowner').toString();
        final avatar = (row['homeowner_avatar'] ?? '').toString().trim();

        return _ReviewEntry(
          id: (row['id'] ?? '').toString(),
          homeownerName: homeownerName,
          homeownerAvatar: avatar.isEmpty ? 'HO' : avatar,
          homeownerProfileImageUrl: (row['homeowner_profile_image_url'] ?? '')
              .toString()
              .trim(),
          rating: rating,
          comment: (row['comment'] ?? '').toString().trim().isEmpty
              ? null
              : (row['comment'] ?? '').toString().trim(),
          tags: tags,
          service: (row['service'] ?? row['trade'] ?? 'Service').toString(),
          barangay: (row['barangay'] ?? '').toString(),
          date: createdAt,
        );
      }).toList();

      if (!mounted) return;
      setState(() {
        _allReviews
          ..clear()
          ..addAll(loaded);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  // ── Derived data ────────────────────────────────────────────────

  List<_ReviewEntry> get _filtered {
    var list = List<_ReviewEntry>.from(_allReviews);

    // Star filter
    if (_starFilter != null) {
      list = list.where((r) => r.rating.round() == _starFilter).toList();
    }

    // Tag filter
    if (_tagFilter != null) {
      list = list.where((r) => r.tags.contains(_tagFilter)).toList();
    }

    // Sort
    switch (_sort) {
      case 'Highest':
        list.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'Lowest':
        list.sort((a, b) => a.rating.compareTo(b.rating));
        break;
      default: // 'Recent'
        list.sort((a, b) => b.date.compareTo(a.date));
    }

    return list;
  }

  double get _avgRating {
    if (_allReviews.isEmpty) return 0;
    return _allReviews.fold(0.0, (s, r) => s + r.rating) / _allReviews.length;
  }

  int _countForStar(int star) =>
      _allReviews.where((r) => r.rating.round() == star).length;

  // ── Helpers ─────────────────────────────────────────────────────

  String _ratingLabel(double r) {
    if (r >= 4.8) return 'Excellent';
    if (r >= 4.0) return 'Very Good';
    if (r >= 3.0) return 'Good';
    if (r >= 2.0) return 'Fair';
    return 'Poor';
  }

  Color _ratingColor(double r) {
    if (r >= 4.5) return _successGreen;
    if (r >= 3.5) return _warningYellow;
    return _errorRed;
  }

  String _timeAgo(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    if (diff.inDays < 30) {
      return '${(diff.inDays / 7).floor()} week${(diff.inDays / 7).floor() > 1 ? 's' : ''} ago';
    }
    if (diff.inDays < 365) {
      return '${(diff.inDays / 30).floor()} month${(diff.inDays / 30).floor() > 1 ? 's' : ''} ago';
    }
    return '${(diff.inDays / 365).floor()} year${(diff.inDays / 365).floor() > 1 ? 's' : ''} ago';
  }

  // ═══════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: _backgroundGray,
        appBar: AppBar(
          title: const Text('My Reviews'),
          backgroundColor: _primaryBlue,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: _errorRed,
                  size: 40,
                ),
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _textMuted.withValues(alpha: 0.85)),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _loadReviews,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryBlue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final reviews = _filtered;

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
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // ── Summary card ──────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: _buildSummaryCard(),
                    ),
                  ),

                  // ── Filters ───────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: _buildFiltersSection(),
                    ),
                  ),

                  // ── Result count ──────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                      child: Row(
                        children: [
                          Text(
                            '${reviews.length} review${reviews.length != 1 ? 's' : ''}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _textMuted.withValues(alpha: 0.75),
                            ),
                          ),
                          if (_starFilter != null ||
                              _tagFilter != null ||
                              _sort != 'Recent') ...[
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => setState(() {
                                _starFilter = null;
                                _tagFilter = null;
                                _sort = 'Recent';
                              }),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _primaryBlue.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.close_rounded,
                                      size: 13,
                                      color: _primaryBlue,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Clear filters',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
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
                    ),
                  ),

                  // ── Review list or empty state ─────────────────────
                  reviews.isEmpty
                      ? SliverFillRemaining(
                          hasScrollBody: false,
                          child: _buildEmptyState(),
                        )
                      : SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              return TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0.0, end: 1.0),
                                duration: Duration(
                                  milliseconds: 280 + (index * 40),
                                ),
                                curve: Curves.easeOut,
                                builder: (_, val, child) => Opacity(
                                  opacity: val,
                                  child: Transform.translate(
                                    offset: Offset(0, 18 * (1 - val)),
                                    child: child,
                                  ),
                                ),
                                child: _buildReviewCard(reviews[index]),
                              );
                            }, childCount: reviews.length),
                          ),
                        ),
                ],
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'My Reviews',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.4,
                      ),
                    ),
                    Text(
                      '${_allReviews.length} total · avg ${_avgRating.toStringAsFixed(1)} ★',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              // Sort button
              _buildSortButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSortButton() {
    final sortIcon = switch (_sort) {
      'Highest' => Icons.arrow_upward_rounded,
      'Lowest' => Icons.arrow_downward_rounded,
      _ => Icons.schedule_rounded,
    };

    return GestureDetector(
      onTap: _showSortSheet,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(sortIcon, size: 15, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              _sort,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.expand_more_rounded,
              size: 16,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  void _showSortSheet() {
    final options = [
      ('Recent', Icons.schedule_rounded, 'Most recent first'),
      ('Highest', Icons.arrow_upward_rounded, 'Highest rated first'),
      ('Lowest', Icons.arrow_downward_rounded, 'Lowest rated first'),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        decoration: BoxDecoration(
          color: _cardWhite,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 30,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    'Sort Reviews',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: _textDark,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ...options.map((o) {
              final (label, icon, subtitle) = o;
              final isSelected = _sort == label;
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    setState(() => _sort = label);
                    Navigator.pop(context);
                    _loadReviews();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? _primaryBlue.withValues(alpha: 0.1)
                                : _backgroundGray,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            icon,
                            color: isSelected ? _primaryBlue : _textMuted,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                label,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected ? _primaryBlue : _textDark,
                                ),
                              ),
                              Text(
                                subtitle,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _textMuted.withValues(alpha: 0.7),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check_rounded,
                            color: _primaryBlue,
                            size: 20,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  SUMMARY CARD
  // ═══════════════════════════════════════════════════════════════

  Widget _buildSummaryCard() {
    final avg = _avgRating;
    final total = _allReviews.length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Average score ──────────────────────────────────────
          Column(
            children: [
              Text(
                avg.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 52,
                  fontWeight: FontWeight.w900,
                  color: _ratingColor(avg),
                  height: 1,
                  letterSpacing: -2,
                ),
              ),
              const SizedBox(height: 6),
              _buildStarRow(avg, size: 16),
              const SizedBox(height: 6),
              Text(
                _ratingLabel(avg),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _ratingColor(avg),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$total review${total != 1 ? 's' : ''}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: _textMuted.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),

          const SizedBox(width: 24),
          Container(width: 1, height: 130, color: _borderGray),
          const SizedBox(width: 20),

          // ── Star distribution bars ─────────────────────────────
          Expanded(
            child: Column(
              children: List.generate(5, (i) {
                final star = 5 - i;
                final count = _countForStar(star);
                final fraction = total == 0 ? 0.0 : count / total;
                final isFiltered = _starFilter == star;

                return GestureDetector(
                  onTap: () => setState(() {
                    _starFilter = isFiltered ? null : star;
                  }),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        // Star label
                        SizedBox(
                          width: 14,
                          child: Text(
                            '$star',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isFiltered ? _primaryBlue : _textMuted,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.star_rounded,
                          size: 12,
                          color: isFiltered
                              ? _primaryBlue
                              : _warningYellow.withValues(alpha: 0.8),
                        ),
                        const SizedBox(width: 8),
                        // Bar
                        Expanded(
                          child: Stack(
                            children: [
                              Container(
                                height: 8,
                                decoration: BoxDecoration(
                                  color: _backgroundGray,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              FractionallySizedBox(
                                widthFactor: fraction,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 400),
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: isFiltered
                                        ? _primaryBlue
                                        : star >= 4
                                        ? _successGreen
                                        : star == 3
                                        ? _warningYellow
                                        : _errorRed,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Count
                        SizedBox(
                          width: 20,
                          child: Text(
                            '$count',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _textMuted.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  FILTERS SECTION
  // ═══════════════════════════════════════════════════════════════

  Widget _buildFiltersSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardWhite,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Filter by star ─────────────────────────────────────
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: _warningYellow.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.star_rounded,
                  color: _warningYellow,
                  size: 15,
                ),
              ),
              const SizedBox(width: 9),
              const Text(
                'Filter by Rating',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: _textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _filterChip(
                  label: 'All',
                  isSelected: _starFilter == null,
                  onTap: () => setState(() => _starFilter = null),
                  count: _allReviews.length,
                ),
                ...List.generate(5, (i) {
                  final star = 5 - i;
                  return _filterChip(
                    label: '$star ★',
                    isSelected: _starFilter == star,
                    onTap: () => setState(
                      () => _starFilter = _starFilter == star ? null : star,
                    ),
                    count: _countForStar(star),
                    starColor: star >= 4
                        ? _successGreen
                        : star == 3
                        ? _warningYellow
                        : _errorRed,
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 16),
          Container(height: 1, color: _borderGray),
          const SizedBox(height: 16),

          // ── Filter by tag ──────────────────────────────────────
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: _primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.label_outline_rounded,
                  color: _primaryBlue,
                  size: 15,
                ),
              ),
              const SizedBox(width: 9),
              const Text(
                'Filter by Feedback Tag',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: _textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _tagChip(
                'All tags',
                _tagFilter == null,
                () => setState(() => _tagFilter = null),
              ),
              ..._allTags.map((tag) {
                final tagCount = _allReviews
                    .where((r) => r.tags.contains(tag))
                    .length;
                return _tagChip(
                  '$tag ($tagCount)',
                  _tagFilter == tag,
                  () => setState(
                    () => _tagFilter = _tagFilter == tag ? null : tag,
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required int count,
    Color? starColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _primaryBlue : _backgroundGray,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? _primaryBlue : _borderGray,
            width: isSelected ? 1.5 : 1,
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
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : (starColor ?? _textDark),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
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
                  fontWeight: FontWeight.w800,
                  color: isSelected ? Colors.white : _primaryBlue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tagChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? _primaryBlue : _cardWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? _primaryBlue
                : _textMuted.withValues(alpha: 0.25),
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : _textDark,
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  REVIEW CARD
  // ═══════════════════════════════════════════════════════════════

  Widget _buildReviewCard(_ReviewEntry review) {
    final starInt = review.rating.round();
    final ratingColor = _ratingColor(review.rating);
    final homeownerProfileImageUrl = (review.homeownerProfileImageUrl ?? '')
        .trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _cardWhite,
        borderRadius: BorderRadius.circular(20),
        border: starInt == 5
            ? Border.all(
                color: _successGreen.withValues(alpha: 0.25),
                width: 1.2,
              )
            : starInt <= 2
            ? Border.all(color: _errorRed.withValues(alpha: 0.2), width: 1.2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ─────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                Container(
                  width: 48,
                  height: 48,
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
                    child: homeownerProfileImageUrl.isNotEmpty
                        ? Image.network(
                            homeownerProfileImageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Center(
                                  child: Text(
                                    review.homeownerAvatar,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                          )
                        : Center(
                            child: Text(
                              review.homeownerAvatar,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),

                // Name + star row
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.homeownerName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: _textDark,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          _buildStarRow(review.rating, size: 15),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: ratingColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              review.rating.toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: ratingColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Time badge
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _timeAgo(review.date),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _textMuted.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),
            Container(height: 1, color: Colors.grey.shade100),
            const SizedBox(height: 12),

            // ── Service info ─────────────────────────────────────
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: _accentOrange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.handyman_rounded,
                    color: _accentOrange,
                    size: 14,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    review.service,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _textDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 12,
                      color: _textMuted.withValues(alpha: 0.55),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      review.barangay,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _textMuted.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // ── Comment ───────────────────────────────────────────
            if (review.comment != null && review.comment!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: _backgroundGray,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _borderGray),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.format_quote_rounded,
                      size: 16,
                      color: _primaryBlue.withValues(alpha: 0.45),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        review.comment!,
                        style: TextStyle(
                          fontSize: 13,
                          color: _textDark.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ── Tags ──────────────────────────────────────────────
            if (review.tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: review.tags.map((tag) {
                  final isActiveFilter = _tagFilter == tag;
                  return GestureDetector(
                    onTap: () => setState(
                      () => _tagFilter = isActiveFilter ? null : tag,
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: isActiveFilter
                            ? _primaryBlue
                            : _primaryBlue.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isActiveFilter
                              ? _primaryBlue
                              : _primaryBlue.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isActiveFilter ? Colors.white : _primaryBlue,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],

            // ── No comment placeholder ─────────────────────────────
            if (review.comment == null && review.tags.isEmpty) ...[
              const SizedBox(height: 10),
              Text(
                'No written feedback provided.',
                style: TextStyle(
                  fontSize: 12,
                  color: _textMuted.withValues(alpha: 0.5),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  STAR ROW HELPER
  // ═══════════════════════════════════════════════════════════════

  Widget _buildStarRow(double rating, {double size = 14}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final full = i < rating.floor();
        final half = !full && (i < rating);
        return Icon(
          full
              ? Icons.star_rounded
              : half
              ? Icons.star_half_rounded
              : Icons.star_outline_rounded,
          size: size,
          color: full || half
              ? _warningYellow
              : _textMuted.withValues(alpha: 0.3),
        );
      }),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  EMPTY STATE
  // ═══════════════════════════════════════════════════════════════

  Widget _buildEmptyState() {
    final hasFilter =
        _starFilter != null || _tagFilter != null || _sort != 'Recent';

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
                hasFilter
                    ? Icons.filter_list_off_rounded
                    : Icons.star_outline_rounded,
                size: 38,
                color: _primaryBlue.withValues(alpha: 0.45),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              hasFilter ? 'No Matching Reviews' : 'No Reviews Yet',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _textDark,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasFilter
                  ? 'Try adjusting your filters to see more reviews.'
                  : 'Reviews from homeowners will appear here after completed jobs.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: _textMuted.withValues(alpha: 0.7),
                height: 1.5,
              ),
            ),
            if (hasFilter) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => setState(() {
                  _starFilter = null;
                  _tagFilter = null;
                  _sort = 'Recent';
                }),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Clear All Filters'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
      ),
    );
  }
}
