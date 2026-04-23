import 'package:flutter/material.dart';
<<<<<<< HEAD

=======
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/api_service.dart';
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
import 'tradesperson_work_store.dart';

/// Requests Screen for the Fix It Marketplace Tradesperson App.
/// Displays all incoming booking requests from homeowners.
/// Tradespeople can Accept or Decline each request from this screen.
class RequestsScreen extends StatefulWidget {
  const RequestsScreen({
    super.key,
    required this.onNavigateToJobs,
    required this.onMessageRequested,
  });

  final VoidCallback onNavigateToJobs;
  final void Function(String homeownerName, String service, String avatar)
  onMessageRequested;

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen>
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

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    TradespersonWorkStore.notifier.addListener(_handleStoreChanged);
<<<<<<< HEAD
    _refreshFromBackend();
=======
    _refreshRequests();
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
  }

  @override
  void dispose() {
    TradespersonWorkStore.notifier.removeListener(_handleStoreChanged);
    super.dispose();
  }

  void _handleStoreChanged() {
    if (!mounted) return;
    setState(() {});
  }

<<<<<<< HEAD
  Future<void> _refreshFromBackend() async {
    await TradespersonWorkStore.syncFromBackend();
    if (!mounted) return;
    setState(() {});
  }

  String _activeFilter = 'All';
=======
  String _activeFilter = 'All';
  bool _isLoading = true;
  String? _errorMessage;
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
  final List<String> _filters = ['All', 'High', 'Medium', 'Low'];

  List<Map<String, dynamic>> get _requests => TradespersonWorkStore.requests;

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

  Future<void> _refreshRequests() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await _readToken();
      final response = await ApiService.getIncomingRequests(token: token);
      final rows = (response['requests'] as List?) ?? const [];
      TradespersonWorkStore.setRequestsFromApi(rows);

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
  // ── Urgency helpers ────────────────────────────────────────────
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

  IconData _urgencyIcon(String urgency) {
    switch (urgency) {
      case 'High':
        return Icons.priority_high_rounded;
      case 'Medium':
        return Icons.remove_rounded;
      case 'Low':
        return Icons.keyboard_arrow_down_rounded;
      default:
        return Icons.circle_outlined;
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_activeFilter == 'All') return List.from(_requests);
    return _requests.where((r) => r['urgency'] == _activeFilter).toList();
  }

  // ── Accept / Decline Actions ───────────────────────────────────
  Future<void> _acceptRequest(Map<String, dynamic> request) async {
<<<<<<< HEAD
    final accepted = await TradespersonWorkStore.acceptRequestById(
      request['id'] as String,
    );
    if (!accepted || !mounted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Unable to accept request right now.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            backgroundColor: _errorRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Request from ${request['homeowner']} accepted!',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: _successGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
    widget.onNavigateToJobs();
=======
    try {
      final token = await _readToken();
      final requestId = (request['bookingId'] as int?) ?? 0;
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
      widget.onNavigateToJobs();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: _errorRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
  }

  void _declineRequest(Map<String, dynamic> request) {
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
                    colors: [_errorRed, Color(0xFFF97316)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Decline Request?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _textDark,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Are you sure you want to decline this request from ${request['homeowner']}?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _textMuted.withValues(alpha: 0.9),
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
                        backgroundColor: _errorRed,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Decline',
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
        final declined = await TradespersonWorkStore.declineRequestById(
          request['id'] as String,
        );
        if (!declined || !mounted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'Unable to decline request right now.',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                backgroundColor: _errorRed,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.all(16),
              ),
            );
          }
          return;
        }
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
=======
        try {
          final token = await _readToken();
          final requestId = (request['bookingId'] as int?) ?? 0;
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
              content: Text(
                e.toString().replaceFirst('Exception: ', ''),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              backgroundColor: _errorRed,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
      }
    });
  }

  void _messageHomeowner(Map<String, dynamic> request) {
    final homeowner = (request['homeowner'] ?? '').toString().trim();
    final service = (request['service'] ?? '').toString().trim();
    final avatar = (request['avatar'] ?? '').toString().trim();

    if (homeowner.isEmpty) return;
    widget.onMessageRequested(homeowner, service, avatar);
  }

  // ═══════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final requests = _filtered;

    return Scaffold(
      backgroundColor: _backgroundGray,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAppBar(),
            _buildFilterTabs(),
            Expanded(
<<<<<<< HEAD
              child: requests.isEmpty
=======
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                  ? _buildErrorState()
                  : requests.isEmpty
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
                  ? _buildEmptyState()
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                      itemCount: requests.length,
                      itemBuilder: (context, index) {
                        return TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: Duration(milliseconds: 300 + (index * 50)),
                          curve: Curves.easeOut,
                          builder: (context, val, child) => Opacity(
                            opacity: val,
                            child: Transform.translate(
                              offset: Offset(0, 16 * (1 - val)),
                              child: child,
                            ),
                          ),
                          child: _buildRequestCard(requests[index]),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  APP BAR
  // ═══════════════════════════════════════════════════════════════

  Widget _buildAppBar() {
    final newCount = _requests.where((r) => r['isNew'] == true).length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Requests',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: _textDark,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${_requests.length} total · $newCount new',
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
              onPressed: _refreshRequests,
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
              ? _requests.length
              : _requests.where((r) => r['urgency'] == filter).length;

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
  //  REQUEST CARD
  // ═══════════════════════════════════════════════════════════════

  Widget _buildRequestCard(Map<String, dynamic> request) {
    final urgencyColor = _urgencyColor(request['urgency'] as String);
    final isNew = request['isNew'] == true;
<<<<<<< HEAD
=======
    final homeownerProfileImageUrl = (request['homeownerProfileImageUrl'] ?? '')
        .toString()
        .trim();
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _cardWhite,
        borderRadius: BorderRadius.circular(20),
        border: isNew
            ? Border.all(
                color: _accentOrange.withValues(alpha: 0.4),
                width: 1.5,
              )
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
            // ── Header Row ─────────────────────────────────────────
            Row(
              children: [
                // Avatar
                Container(
                  width: 46,
                  height: 46,
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
                      request['avatar'] as String,
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
                                    request['avatar'] as String,
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
                              request['avatar'] as String,
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
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              request['homeowner'] as String,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: _textDark,
                              ),
                            ),
                          ),
                          if (isNew)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: _accentOrange,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'NEW',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 13,
                                color: _textMuted.withValues(alpha: 0.7),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                request['barangay'] as String,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: _textMuted.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                size: 13,
                                color: _textMuted.withValues(alpha: 0.7),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                request['postedAt'] as String,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: _textMuted.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Align(
                    alignment: Alignment.topRight,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: urgencyColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _urgencyIcon(request['urgency'] as String),
                              size: 12,
                              color: urgencyColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              request['urgency'] as String,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: urgencyColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),
            Container(height: 1, color: Colors.grey.shade100),
            const SizedBox(height: 12),

            // ── Service Title ──────────────────────────────────────
            Text(
              request['service'] as String,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: _textDark,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 6),

            // ── Description ───────────────────────────────────────
            Text(
              request['description'] as String,
              style: TextStyle(
                fontSize: 13,
                color: _textMuted.withValues(alpha: 0.85),
                height: 1.45,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 12),
            Container(height: 1, color: Colors.grey.shade100),
            const SizedBox(height: 12),

            // ── Details Row ───────────────────────────────────────
            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _buildDetailChip(
                  Icons.calendar_today_rounded,
                  request['date'] as String,
                ),
                _buildDetailChip(
                  Icons.access_time_rounded,
                  request['time'] as String,
                ),
                _buildDetailChip(
                  Icons.payments_outlined,
                  '₱${(request['budget'] as double).toStringAsFixed(0)}',
                  highlight: true,
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ── Action Buttons ────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _declineRequest(request),
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
                    onPressed: () => _messageHomeowner(request),
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
                    onPressed: () => _acceptRequest(request),
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text(
                      'Accept',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailChip(
    IconData icon,
    String label, {
    bool highlight = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: highlight ? _successGreen : _textMuted.withValues(alpha: 0.6),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: highlight
                ? _successGreen
                : _textMuted.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
<<<<<<< HEAD
=======
  //  ERROR STATE
  // ═══════════════════════════════════════════════════════════════

  Widget _buildErrorState() {
    return Center(
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
              'Failed to load requests',
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
              onPressed: _refreshRequests,
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

  // ═══════════════════════════════════════════════════════════════
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
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
                Icons.inbox_rounded,
                size: 38,
                color: _primaryBlue.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _activeFilter == 'All'
                  ? 'No Requests Yet'
                  : 'No $_activeFilter Requests',
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
                  ? 'New job requests will appear here once homeowners book you.'
                  : 'There are no ${_activeFilter.toLowerCase()} priority requests at the moment.',
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
