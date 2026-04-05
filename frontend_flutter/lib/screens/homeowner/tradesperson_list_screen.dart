import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'booking_form_screen.dart';

class TradespersonListScreen extends StatefulWidget {
  final String? serviceCategory;
  final bool onDutyOnly;
  final String? initialTradespersonName;
  final VoidCallback onBookingConfirmed;
  final void Function(String tradespersonName, String trade, String avatar)
  onMessageRequested;

  const TradespersonListScreen({
    super.key,
    this.serviceCategory,
    this.onDutyOnly = false,
    this.initialTradespersonName,
    required this.onMessageRequested,
    required this.onBookingConfirmed,
  });

  @override
  State<TradespersonListScreen> createState() => _TradespersonListScreenState();
}

class _TradespersonListScreenState extends State<TradespersonListScreen>
    with SingleTickerProviderStateMixin {
  // ── Color Palette (matches HomeownerDashboard) ──────────────────
  static const Color _primaryBlue = Color(0xFF1E3A8A);
  static const Color _accentOrange = Color(0xFFF97316);
  static const Color _backgroundGray = Color(0xFFF9FAFB);
  static const Color _textDark = Color(0xFF111827);
  static const Color _textMuted = Color(0xFF6B7280);
  static const Color _cardWhite = Color(0xFFFFFFFF);
  static const Color _successGreen = Color(0xFF10B981);
  static const Color _warningYellow = Color(0xFFF59E0B);

  late String? _selectedCategory;
  String _sortBy = 'Rating';
  bool _onDutyOnly = false;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  late AnimationController _listAnimController;

  // ── Category Definitions ────────────────────────────────────────
  final List<Map<String, dynamic>> _categories = [
    {'name': 'All', 'icon': Icons.grid_view_rounded, 'color': _primaryBlue},
    {
      'name': 'Plumbing',
      'icon': Icons.plumbing_rounded,
      'color': Color(0xFF3B82F6),
    },
    {
      'name': 'Electrical',
      'icon': Icons.electrical_services_rounded,
      'color': Color(0xFFF59E0B),
    },
    {'name': 'HVAC', 'icon': Icons.ac_unit_rounded, 'color': Color(0xFF06B6D4)},
    {
      'name': 'Carpentry',
      'icon': Icons.carpenter_rounded,
      'color': Color(0xFF8B5CF6),
    },
    {
      'name': 'Appliance',
      'icon': Icons.kitchen_rounded,
      'color': Color(0xFFEC4899),
    },
  ];

  // ── Sample Tradesperson Data ────────────────────────────────────
  final List<Map<String, dynamic>> _allPros = [
    {
      'id': '1',
      'name': 'Juan Dela Cruz',
      'trade': 'Plumbing',
      'specialization': 'Pipe Repair & Installation',
      'rating': 4.9,
      'reviews': 87,
      'barangay': 'Dayap',
      'isOnDuty': true,
      'avatar': 'JD',
      'avatarColor': Color(0xFF3B82F6),
      'experience': '8 years',
      'completedJobs': 214,
      'responseTime': '~10 mins',
      'bio':
          'Certified master plumber specializing in emergency pipe repairs and residential installations. Fast, clean, and reliable.',
      'skills': [
        'Pipe Repair',
        'Leak Detection',
        'Drain Cleaning',
        'Water Heater',
      ],
    },
    {
      'id': '2',
      'name': 'Maria Santos',
      'trade': 'Electrical',
      'specialization': 'Wiring & Panel Upgrades',
      'rating': 4.8,
      'reviews': 64,
      'barangay': 'Hanggan',
      'isOnDuty': true,
      'avatar': 'MS',
      'avatarColor': Color(0xFFF59E0B),
      'experience': '6 years',
      'completedJobs': 159,
      'responseTime': '~15 mins',
      'bio':
          'Licensed electrician with expertise in residential rewiring, panel upgrades, and emergency electrical diagnostics.',
      'skills': ['Rewiring', 'Panel Upgrade', 'Outlet Install', 'Safety Audit'],
    },
    {
      'id': '3',
      'name': 'Pedro Reyes',
      'trade': 'HVAC',
      'specialization': 'AC Maintenance & Repair',
      'rating': 4.7,
      'reviews': 41,
      'barangay': 'Imok',
      'isOnDuty': true,
      'avatar': 'PR',
      'avatarColor': Color(0xFF06B6D4),
      'experience': '5 years',
      'completedJobs': 98,
      'responseTime': '~20 mins',
      'bio':
          'HVAC technician focused on air conditioning maintenance, freon recharging, and full unit replacements for homes.',
      'skills': [
        'AC Cleaning',
        'Freon Recharge',
        'Duct Repair',
        'Installation',
      ],
    },
    {
      'id': '4',
      'name': 'Ramon Flores',
      'trade': 'Carpentry',
      'specialization': 'Furniture & Structural Repair',
      'rating': 4.6,
      'reviews': 52,
      'barangay': 'Dayap',
      'isOnDuty': false,
      'avatar': 'RF',
      'avatarColor': Color(0xFF8B5CF6),
      'experience': '10 years',
      'completedJobs': 301,
      'responseTime': '~30 mins',
      'bio':
          'Skilled carpenter offering furniture repair, cabinet making, and door/window frame fixes for residential properties.',
      'skills': ['Cabinet Making', 'Door Repair', 'Flooring', 'Furniture Fix'],
    },
    {
      'id': '5',
      'name': 'Liza Cruz',
      'trade': 'Appliance',
      'specialization': 'Kitchen Appliance Repair',
      'rating': 4.5,
      'reviews': 33,
      'barangay': 'Bangyas',
      'isOnDuty': true,
      'avatar': 'LC',
      'avatarColor': Color(0xFFEC4899),
      'experience': '4 years',
      'completedJobs': 77,
      'responseTime': '~25 mins',
      'bio':
          'Appliance repair technician experienced in refrigerators, washing machines, microwaves, and kitchen equipment.',
      'skills': ['Refrigerator', 'Washing Machine', 'Microwave', 'Oven Repair'],
    },
    {
      'id': '6',
      'name': 'Carlo Mendoza',
      'trade': 'Plumbing',
      'specialization': 'Emergency Leak & Sewage',
      'rating': 4.4,
      'reviews': 29,
      'barangay': 'Lamot',
      'isOnDuty': false,
      'avatar': 'CM',
      'avatarColor': Color(0xFF3B82F6),
      'experience': '3 years',
      'completedJobs': 55,
      'responseTime': '~35 mins',
      'bio':
          'Plumber specializing in emergency leak response and sewage line clearing for residential and light commercial units.',
      'skills': [
        'Leak Repair',
        'Sewage Clearing',
        'Toilet Fix',
        'Pipe Fitting',
      ],
    },
    {
      'id': '7',
      'name': 'Noel Bautista',
      'trade': 'Electrical',
      'specialization': 'CCTV & Smart Home Wiring',
      'rating': 4.9,
      'reviews': 71,
      'barangay': 'Hanggan',
      'isOnDuty': false,
      'avatar': 'NB',
      'avatarColor': Color(0xFFF59E0B),
      'experience': '7 years',
      'completedJobs': 188,
      'responseTime': '~20 mins',
      'bio':
          'Electrician specializing in smart home wiring, CCTV installation, and structured network cabling for modern homes.',
      'skills': ['CCTV Install', 'Smart Wiring', 'Intercom', 'Circuit Breaker'],
    },
  ];

  List<Map<String, dynamic>> get _filteredPros {
    return _allPros.where((pro) {
      final matchCategory =
          _selectedCategory == null ||
          _selectedCategory == 'All' ||
          pro['trade'] == _selectedCategory;
      final matchOnDuty = !_onDutyOnly || pro['isOnDuty'] == true;
      final matchSearch =
          _searchQuery.isEmpty ||
          (pro['name'] as String).toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          (pro['trade'] as String).toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          (pro['barangay'] as String).toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );
      return matchCategory && matchOnDuty && matchSearch;
    }).toList()..sort((a, b) {
      if (_sortBy == 'Rating') {
        return (b['rating'] as double).compareTo(a['rating'] as double);
      } else if (_sortBy == 'Reviews') {
        return (b['reviews'] as int).compareTo(a['reviews'] as int);
      } else {
        return (a['name'] as String).compareTo(b['name'] as String);
      }
    });
  }

  Color _categoryColor(String? category) {
    final match = _categories.firstWhere(
      (c) => c['name'] == category,
      orElse: () => _categories[0],
    );
    return match['color'] as Color;
  }

  @override
  void initState() {
    super.initState();
    _selectedCategory =
        (widget.serviceCategory != null && widget.serviceCategory!.isNotEmpty)
        ? widget.serviceCategory
        : 'All';

    if (widget.onDutyOnly) _onDutyOnly = true;

    _listAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openInitialTradespersonProfile();
    });
  }

  void _openInitialTradespersonProfile() {
    final requestedName = widget.initialTradespersonName?.trim();
    if (requestedName == null || requestedName.isEmpty || !mounted) {
      return;
    }

    final normalizedRequested = requestedName.toLowerCase();
    final match = _allPros.where((pro) {
      final name = (pro['name'] ?? '').toString().trim().toLowerCase();
      return name == normalizedRequested;
    });

    if (match.isEmpty) {
      return;
    }

    final pro = match.first;
    setState(() {
      _selectedCategory = (pro['trade'] ?? '').toString();
      _searchQuery = '';
      _searchController.clear();
    });

    _showTradespersonSheet(pro);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _listAnimController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: _backgroundGray,
        body: Column(
          children: [
            _buildHeader(context),
            _buildSearchBar(),
            _buildCategoryChips(),
            _buildFilterRow(),
            Expanded(child: _buildProList()),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  HEADER
  // ═══════════════════════════════════════════════════════════════

  Widget _buildHeader(BuildContext context) {
    final activeColor = _categoryColor(_selectedCategory);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primaryBlue, activeColor.withValues(alpha: 0.85)],
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
              // Back button
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedCategory == 'All'
                          ? 'Find Professionals'
                          : '$_selectedCategory Pros',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_filteredPros.length} available in your area',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.75),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // On-duty toggle pill
              GestureDetector(
                onTap: () => setState(() => _onDutyOnly = !_onDutyOnly),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _onDutyOnly
                        ? _successGreen
                        : Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _onDutyOnly
                          ? _successGreen
                          : Colors.white.withValues(alpha: 0.35),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.circle,
                        size: 7,
                        color: _onDutyOnly
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.8),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'On-Duty',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _onDutyOnly
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
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
  //  SEARCH BAR
  // ═══════════════════════════════════════════════════════════════

  Widget _buildSearchBar() {
    return Container(
      color: _primaryBlue,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (val) => setState(() => _searchQuery = val),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: _textDark,
          ),
          decoration: InputDecoration(
            hintText: 'Search by name, trade, or barangay…',
            hintStyle: TextStyle(
              color: _textMuted.withValues(alpha: 0.7),
              fontSize: 14,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: _textMuted.withValues(alpha: 0.6),
              size: 22,
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                    child: Icon(
                      Icons.close_rounded,
                      color: _textMuted.withValues(alpha: 0.6),
                      size: 20,
                    ),
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  CATEGORY CHIPS
  // ═══════════════════════════════════════════════════════════════

  Widget _buildCategoryChips() {
    return Container(
      color: _cardWhite,
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: SizedBox(
        height: 40,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _categories.length,
          itemBuilder: (context, index) {
            final cat = _categories[index];
            final isSelected = _selectedCategory == cat['name'];
            final catColor = cat['color'] as Color;
            return GestureDetector(
              onTap: () {
                setState(() => _selectedCategory = cat['name'] as String);
                _listAnimController
                  ..reset()
                  ..forward();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? catColor
                      : catColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? catColor
                        : catColor.withValues(alpha: 0.25),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      cat['icon'] as IconData,
                      size: 15,
                      color: isSelected ? Colors.white : catColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      cat['name'] as String,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : catColor,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  FILTER ROW
  // ═══════════════════════════════════════════════════════════════

  Widget _buildFilterRow() {
    final pros = _filteredPros;
    return Container(
      color: _backgroundGray,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
      child: Row(
        children: [
          Text(
            '${pros.length} Tradesperson${pros.length == 1 ? '' : 's'}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: _textDark,
              letterSpacing: -0.2,
            ),
          ),
          const Spacer(),
          const Text(
            'Sort:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: _textMuted,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _showSortSheet,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _primaryBlue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _primaryBlue.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Text(
                    _sortBy,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _primaryBlue,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: _primaryBlue,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: _cardWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: _textMuted.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Sort By',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: _textDark,
              ),
            ),
            const SizedBox(height: 16),
            for (final opt in ['Rating', 'Reviews', 'Name'])
              GestureDetector(
                onTap: () {
                  setState(() => _sortBy = opt);
                  Navigator.pop(context);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: _sortBy == opt
                        ? _primaryBlue.withValues(alpha: 0.08)
                        : _backgroundGray,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _sortBy == opt
                          ? _primaryBlue.withValues(alpha: 0.3)
                          : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        opt == 'Rating'
                            ? Icons.star_rounded
                            : opt == 'Reviews'
                            ? Icons.rate_review_rounded
                            : Icons.sort_by_alpha_rounded,
                        color: _sortBy == opt ? _primaryBlue : _textMuted,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        opt,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _sortBy == opt ? _primaryBlue : _textDark,
                        ),
                      ),
                      const Spacer(),
                      if (_sortBy == opt)
                        const Icon(
                          Icons.check_circle_rounded,
                          color: _primaryBlue,
                          size: 20,
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  PRO LIST
  // ═══════════════════════════════════════════════════════════════

  Widget _buildProList() {
    final pros = _filteredPros;
    if (pros.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _primaryBlue.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 36,
                color: _primaryBlue.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No tradespeople found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _textDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Try adjusting your filters or search.',
              style: TextStyle(
                fontSize: 13,
                color: _textMuted.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: pros.length,
      itemBuilder: (context, index) {
        final pro = pros[index];
        final delay = index * 60;
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 400 + delay),
          curve: Curves.easeOut,
          builder: (context, val, child) {
            return Opacity(
              opacity: val,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - val)),
                child: child,
              ),
            );
          },
          child: _buildProCard(pro),
        );
      },
    );
  }

  Widget _buildProCard(Map<String, dynamic> pro) {
    final avatarColor = pro['avatarColor'] as Color;
    final isOnDuty = pro['isOnDuty'] as bool;
    final rating = pro['rating'] as double;

    return GestureDetector(
      onTap: () => _showTradespersonSheet(pro),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: _cardWhite,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  // ── Avatar ───────────────────────────────────────
                  Stack(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              avatarColor,
                              avatarColor.withValues(alpha: 0.7),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
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
                            pro['avatar'] as String,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: isOnDuty
                                ? _successGreen
                                : _textMuted.withValues(alpha: 0.4),
                            shape: BoxShape.circle,
                            border: Border.all(color: _cardWhite, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 14),

                  // ── Info ─────────────────────────────────────────
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                pro['name'] as String,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: _textDark,
                                  letterSpacing: -0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // On-Duty badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isOnDuty
                                    ? _successGreen.withValues(alpha: 0.12)
                                    : _textMuted.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.circle,
                                    size: 6,
                                    color: isOnDuty
                                        ? _successGreen
                                        : _textMuted.withValues(alpha: 0.5),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isOnDuty ? 'On-Duty' : 'Off-Duty',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: isOnDuty
                                          ? _successGreen
                                          : _textMuted.withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          pro['specialization'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: avatarColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 13,
                              color: _textMuted.withValues(alpha: 0.7),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              pro['barangay'] as String,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: _textMuted.withValues(alpha: 0.8),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Icon(
                              Icons.star_rounded,
                              size: 14,
                              color: _warningYellow,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '$rating',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _textDark,
                              ),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '(${pro['reviews']})',
                              style: TextStyle(
                                fontSize: 11,
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
              const SizedBox(height: 14),

              // ── Stats Row ─────────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 4,
                ),
                decoration: BoxDecoration(
                  color: _backgroundGray,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatChip(
                      Icons.work_history_rounded,
                      pro['experience'] as String,
                      'Experience',
                    ),
                    _buildStatDivider(),
                    _buildStatChip(
                      Icons.task_alt_rounded,
                      '${pro['completedJobs']} jobs',
                      'Completed',
                    ),
                    _buildStatDivider(),
                    _buildStatChip(
                      Icons.timer_outlined,
                      pro['responseTime'] as String,
                      'Response',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ── View Profile CTA ──────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _showTradespersonSheet(pro),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _primaryBlue,
                        side: BorderSide(
                          color: _primaryBlue.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'View Profile',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isOnDuty
                          ? () =>
                                _showTradespersonSheet(pro, scrollToBook: true)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accentOrange,
                        disabledBackgroundColor: _textMuted.withValues(
                          alpha: 0.15,
                        ),
                        foregroundColor: Colors.white,
                        disabledForegroundColor: _textMuted.withValues(
                          alpha: 0.5,
                        ),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isOnDuty
                                ? Icons.calendar_today_rounded
                                : Icons.schedule_rounded,
                            size: 15,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isOnDuty ? 'Book Now' : 'Unavailable',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
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

  Widget _buildStatChip(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, size: 16, color: _primaryBlue.withValues(alpha: 0.7)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: _textDark,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: _textMuted.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 36,
      color: _textMuted.withValues(alpha: 0.15),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  TRADESPERSON BOTTOM SHEET
  // ═══════════════════════════════════════════════════════════════

  void _showTradespersonSheet(
    Map<String, dynamic> pro, {
    bool scrollToBook = false,
  }) {
    final avatarColor = pro['avatarColor'] as Color;
    final isOnDuty = pro['isOnDuty'] as bool;
    final skills = pro['skills'] as List<String>;
    final scrollController = DraggableScrollableController();
    bool autoScrolledToBook = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.72,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          controller: scrollController,
          builder: (context, sheetScrollController) {
            if (scrollToBook && !autoScrolledToBook) {
              autoScrolledToBook = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!sheetScrollController.hasClients) {
                  return;
                }
                sheetScrollController.animateTo(
                  sheetScrollController.position.maxScrollExtent,
                  duration: const Duration(milliseconds: 380),
                  curve: Curves.easeOutCubic,
                );
              });
            }

            return Container(
              decoration: const BoxDecoration(
                color: _cardWhite,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  // ── Handle ─────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.only(top: 14, bottom: 4),
                    child: Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: _textMuted.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      controller: sheetScrollController,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(24, 10, 24, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Profile Header ──────────────────────
                          Row(
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      avatarColor,
                                      avatarColor.withValues(alpha: 0.7),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(22),
                                  boxShadow: [
                                    BoxShadow(
                                      color: avatarColor.withValues(
                                        alpha: 0.35,
                                      ),
                                      blurRadius: 14,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    pro['avatar'] as String,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      pro['name'] as String,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        color: _textDark,
                                        letterSpacing: -0.4,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      pro['specialization'] as String,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: avatarColor,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isOnDuty
                                                ? _successGreen.withValues(
                                                    alpha: 0.12,
                                                  )
                                                : _textMuted.withValues(
                                                    alpha: 0.08,
                                                  ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.circle,
                                                size: 7,
                                                color: isOnDuty
                                                    ? _successGreen
                                                    : _textMuted.withValues(
                                                        alpha: 0.5,
                                                      ),
                                              ),
                                              const SizedBox(width: 5),
                                              Text(
                                                isOnDuty
                                                    ? 'On-Duty'
                                                    : 'Off-Duty',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                  color: isOnDuty
                                                      ? _successGreen
                                                      : _textMuted.withValues(
                                                          alpha: 0.6,
                                                        ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(
                                          Icons.location_on_outlined,
                                          size: 13,
                                          color: _textMuted.withValues(
                                            alpha: 0.7,
                                          ),
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          pro['barangay'] as String,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: _textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // ── Stats Row ───────────────────────────
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: _backgroundGray,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildSheetStat(
                                  '${pro['rating']}',
                                  'Rating',
                                  Icons.star_rounded,
                                  _warningYellow,
                                ),
                                _buildStatDivider(),
                                _buildSheetStat(
                                  '${pro['reviews']}',
                                  'Reviews',
                                  Icons.rate_review_rounded,
                                  _primaryBlue,
                                ),
                                _buildStatDivider(),
                                _buildSheetStat(
                                  '${pro['completedJobs']}',
                                  'Jobs Done',
                                  Icons.task_alt_rounded,
                                  _successGreen,
                                ),
                                _buildStatDivider(),
                                _buildSheetStat(
                                  pro['responseTime'] as String,
                                  'Response',
                                  Icons.timer_outlined,
                                  _accentOrange,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 22),

                          // ── About ───────────────────────────────
                          const Text(
                            'About',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: _textDark,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            pro['bio'] as String,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: _textMuted,
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 22),

                          // ── Skills ──────────────────────────────
                          const Text(
                            'Skills & Services',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: _textDark,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: skills
                                .map(
                                  (skill) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: avatarColor.withValues(
                                        alpha: 0.08,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: avatarColor.withValues(
                                          alpha: 0.25,
                                        ),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      skill,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: avatarColor,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                          const SizedBox(height: 22),

                          // ── Recent Reviews ──────────────────────
                          const Text(
                            'Recent Reviews',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: _textDark,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildReviewCard(
                            'Excellent work! Very fast and professional.',
                            'Ana Reyes',
                            5,
                            '2 days ago',
                          ),
                          const SizedBox(height: 10),
                          _buildReviewCard(
                            'Fixed our issue quickly. Highly recommend!',
                            'Bong Lim',
                            4,
                            '1 week ago',
                          ),
                          const SizedBox(height: 28),

                          // ── Book Now Button ─────────────────────
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: isOnDuty
                                  ? () {
                                      Navigator.pop(context);
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => BookingFormScreen(
                                            pro: pro,
                                            onBookingConfirmed:
                                                widget.onBookingConfirmed,
                                          ),
                                        ),
                                      );
                                    }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _accentOrange,
                                disabledBackgroundColor: _textMuted.withValues(
                                  alpha: 0.15,
                                ),
                                foregroundColor: Colors.white,
                                disabledForegroundColor: _textMuted.withValues(
                                  alpha: 0.5,
                                ),
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    isOnDuty
                                        ? Icons.calendar_today_rounded
                                        : Icons.schedule_rounded,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    isOnDuty
                                        ? 'Book ${pro['name'].toString().split(' ').first}'
                                        : 'Currently Unavailable',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          if (!isOnDuty) ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  Navigator.of(this.context).pop();
                                  widget.onMessageRequested(
                                    (pro['name'] ?? '').toString(),
                                    (pro['trade'] ?? '').toString(),
                                    (pro['avatar'] ?? '').toString(),
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: _primaryBlue,
                                  side: BorderSide(
                                    color: _primaryBlue.withValues(alpha: 0.3),
                                    width: 1.5,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.chat_bubble_outline_rounded,
                                      size: 16,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Send a Message',
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
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSheetStat(
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: _textDark,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: _textMuted.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewCard(
    String comment,
    String reviewer,
    int stars,
    String time,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _backgroundGray,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _primaryBlue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    reviewer.substring(0, 1),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: _primaryBlue,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reviewer,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _textDark,
                      ),
                    ),
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 11,
                        color: _textMuted.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    Icons.star_rounded,
                    size: 13,
                    color: i < stars
                        ? _warningYellow
                        : _textMuted.withValues(alpha: 0.2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            comment,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: _textMuted,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
