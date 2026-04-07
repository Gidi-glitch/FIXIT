import 'package:flutter/material.dart';
import 'booking_store.dart';
import 'booking_details_screen.dart';

/// Bookings Screen for the Fix It Marketplace Homeowner App.
/// Reads live data from BookingStore so new bookings appear immediately.
class BookingsScreen extends StatefulWidget {
  final void Function(String tradespersonName, String trade, String avatar)
  onMessageRequested;

  const BookingsScreen({super.key, required this.onMessageRequested});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen>
    with AutomaticKeepAliveClientMixin {
  // ── Color Palette ──────────────────────────────────────────────
  static const Color _primaryBlue = Color(0xFF1E3A8A);
  static const Color _backgroundGray = Color(0xFFF9FAFB);
  static const Color _textDark = Color(0xFF111827);
  static const Color _textMuted = Color(0xFF6B7280);
  static const Color _cardWhite = Color(0xFFFFFFFF);
  static const Color _successGreen = Color(0xFF10B981);
  static const Color _warningYellow = Color(0xFFF59E0B);
  static const Color _infoBlue = Color(0xFF3B82F6);
  static const Color _errorRed = Color(0xFFEF4444);

  // Keep this tab alive inside IndexedStack so it doesn't reset
  @override
  bool get wantKeepAlive => true;

  String _activeFilter = 'All';
  final List<String> _filters = [
    'All',
    'Pending',
    'Accepted',
    'In Progress',
    'Completed',
    'Cancelled',
    'Under Review',
    'Disputed',
  ];

  // ── Status → color mapping ─────────────────────────────────────
  Color _statusColor(String status) {
    switch (status) {
      case 'In Progress':
        return _infoBlue;
      case 'Accepted':
        return _successGreen;
      case 'Pending':
        return _warningYellow;
      case 'Completed':
        return _successGreen;
      case 'Under Review':
        return _warningYellow;
      case 'Disputed':
        return _errorRed;
      case 'Cancelled':
        return _errorRed;
      default:
        return _textMuted;
    }
  }

  List<BookingModel> get _filtered {
    final all = BookingStore.all;
    if (_activeFilter == 'All') return all.toList();
    return all.where((b) => b.status == _activeFilter).toList();
  }

  // ═══════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final bookings = _filtered;

    return Scaffold(
      backgroundColor: _backgroundGray,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAppBar(),
            _buildFilterTabs(),
            Expanded(
              child: bookings.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                      itemCount: bookings.length,
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
                          child: _buildBookingCard(bookings[index]),
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
    final total = BookingStore.all.length;
    final pending = BookingStore.all.where((b) => b.status == 'Pending').length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'My Bookings',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: _textDark,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$total total · $pending pending',
                  style: TextStyle(
                    fontSize: 13,
                    color: _textMuted.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Refresh button — triggers a setState to re-read BookingStore
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
              onPressed: () => setState(() {}),
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
              ? BookingStore.all.length
              : BookingStore.all.where((b) => b.status == filter).length;

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
                children: [
                  Text(
                    filter,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSelected ? Colors.white : _textMuted,
                    ),
                  ),
                  if (count > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
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
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  EMPTY STATE
  // ═══════════════════════════════════════════════════════════════

  Widget _buildEmptyState() {
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
              Icons.calendar_today_rounded,
              size: 34,
              color: _primaryBlue.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _activeFilter == 'All'
                ? 'No bookings yet'
                : 'No $_activeFilter bookings',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _activeFilter == 'All'
                ? 'Book a tradesperson to get started.'
                : 'Switch filters to see other bookings.',
            style: TextStyle(
              fontSize: 13,
              color: _textMuted.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  BOOKING CARD
  // ═══════════════════════════════════════════════════════════════

  Widget _buildBookingCard(BookingModel booking) {
    final color = _statusColor(booking.status);
    final isCompleted = booking.status == 'Completed';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _cardWhite,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            final result = await Navigator.push<Map<String, dynamic>>(
              context,
              MaterialPageRoute(
                builder: (_) => BookingDetailsScreen(booking: booking),
              ),
            );

            if (!mounted) return;

            if (result?['openMessage'] == true) {
              final name = (result?['tradespersonName'] ?? '')
                  .toString()
                  .trim();
              final trade = (result?['trade'] ?? '').toString().trim();
              final avatar = (result?['avatar'] ?? '').toString().trim();

              if (name.isNotEmpty) {
                widget.onMessageRequested(name, trade, avatar);
              }
            }

            setState(() {});
          }, // Refresh on return to check for reviews
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header Row ────────────────────────────────
                Row(
                  children: [
                    // Avatar
                    Opacity(
                      opacity: isCompleted ? 0.5 : 1.0,
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [_primaryBlue, Color(0xFF3B82F6)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Text(
                            booking.tradespersonAvatar,
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
                    // Service & Tradesperson
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            booking.specialization,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isCompleted
                                  ? _textMuted.withValues(alpha: 0.6)
                                  : _textDark,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${booking.tradespersonName} · ${booking.trade}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isCompleted
                                  ? _textMuted.withValues(alpha: 0.6)
                                  : _textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Status Badge or Reviewed Checkmark
                    if (isCompleted && booking.isReviewed)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: _successGreen.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_rounded,
                              size: 12,
                              color: _successGreen,
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'Reviewed',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: _successGreen,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          booking.status,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 14),
                Container(
                  height: 1,
                  color: isCompleted
                      ? Colors.grey.shade100.withValues(alpha: 0.5)
                      : Colors.grey.shade100,
                ),
                const SizedBox(height: 12),

                // ── Problem Description ───────────────────────────
                Text(
                  booking.problemDescription,
                  style: TextStyle(
                    fontSize: 13,
                    color: isCompleted
                        ? _textMuted.withValues(alpha: 0.5)
                        : _textMuted.withValues(alpha: 0.85),
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 12),
                Container(
                  height: 1,
                  color: isCompleted
                      ? Colors.grey.shade100.withValues(alpha: 0.5)
                      : Colors.grey.shade100,
                ),
                const SizedBox(height: 12),

                // ── Details Row ───────────────────────────────────
                Row(
                  children: [
                    _buildDetailItem(
                      Icons.calendar_today_rounded,
                      booking.date,
                      isCompleted: isCompleted,
                    ),
                    const SizedBox(width: 16),
                    _buildDetailItem(
                      Icons.access_time_rounded,
                      booking.time,
                      isCompleted: isCompleted,
                    ),
                    const SizedBox(width: 16),
                    _buildDetailItem(
                      Icons.attach_money_rounded,
                      booking.offeredBudget.toStringAsFixed(0),
                      isCompleted: isCompleted,
                    ),
                    const Spacer(),
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: _primaryBlue.withValues(
                          alpha: isCompleted ? 0.04 : 0.08,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: _primaryBlue.withValues(
                          alpha: isCompleted ? 0.4 : 1.0,
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
                      color: _textMuted.withValues(
                        alpha: isCompleted ? 0.3 : 0.6,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        booking.address,
                        style: TextStyle(
                          fontSize: 12,
                          color: _textMuted.withValues(
                            alpha: isCompleted ? 0.4 : 0.75,
                          ),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
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
    bool isCompleted = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 15,
          color: _textMuted.withValues(alpha: isCompleted ? 0.3 : 0.6),
        ),
        const SizedBox(width: 5),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _textMuted.withValues(alpha: isCompleted ? 0.4 : 0.9),
          ),
        ),
      ],
    );
  }
}
