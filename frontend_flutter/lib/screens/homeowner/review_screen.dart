import 'package:flutter/material.dart';
<<<<<<< HEAD
=======
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/api_service.dart';
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
import 'booking_store.dart';

/// Review Screen - A mandatory overlay that appears when a booking is completed.
/// Allows homeowners to rate and review the tradesperson with a beautiful modal UI.
class ReviewScreen extends StatefulWidget {
  final BookingModel booking;

  const ReviewScreen({super.key, required this.booking});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  double _rating = 0;
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();
  final GlobalKey _commentFieldKey = GlobalKey();
  final List<String> _quickTags = [
    'Punctual',
    'Clean',
    'Expert',
    'Friendly',
    'Professional',
    'Quick',
  ];
  final Set<String> _selectedTags = {};
<<<<<<< HEAD
=======
  bool _isSubmitting = false;
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe

  // ── Color Palette ──────────────────────────────────────────────
  static const Color _primaryBlue = Color(0xFF1E3A8A);
  static const Color _accentOrange = Color(0xFFF97316);
  static const Color _backgroundGray = Color(0xFFF9FAFB);
  static const Color _textDark = Color(0xFF111827);
  static const Color _textMuted = Color(0xFF6B7280);
  static const Color _cardWhite = Color(0xFFFFFFFF);
  static const Color _successGreen = Color(0xFF10B981);
  static const Color _warningYellow = Color(0xFFF59E0B);

  @override
  void initState() {
    super.initState();
    _commentFocusNode.addListener(_handleCommentFocus);
  }

  void _handleCommentFocus() {
    if (!_commentFocusNode.hasFocus) return;

    // Wait for keyboard animation, then make sure the comment field is visible.
    Future.delayed(const Duration(milliseconds: 140), () {
      _scrollCommentFieldIntoView();
    });
  }

  void _scrollCommentFieldIntoView() {
    if (!mounted) return;
    final context = _commentFieldKey.currentContext;
    if (context == null) return;

    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
      alignment: 0.15,
    );
  }

  @override
  void dispose() {
    _commentFocusNode.removeListener(_handleCommentFocus);
    _commentFocusNode.dispose();
    _commentController.dispose();
    super.dispose();
  }

<<<<<<< HEAD
  void _submitReview() {
=======
  Future<void> _submitReview() async {
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a rating'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

<<<<<<< HEAD
    // Submit review to store
    BookingStore.submitReview(
      widget.booking.id,
      _rating,
      _commentController.text.trim(),
      _selectedTags.toList(),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Thank you for your review!'),
        duration: Duration(seconds: 2),
        backgroundColor: _successGreen,
      ),
    );

    Navigator.pop(context);
=======
    setState(() => _isSubmitting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token')?.trim();
      if (token == null || token.isEmpty) {
        throw Exception('Session expired. Please log in again.');
      }

      await ApiService.submitBookingReview(
        token: token,
        bookingId: widget.booking.id,
        rating: _rating,
        comment: _commentController.text.trim(),
        tags: _selectedTags.toList(),
      );

      BookingStore.submitReview(
        widget.booking.id,
        _rating,
        _commentController.text.trim(),
        _selectedTags.toList(),
      );

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thank you for your review!'),
          duration: Duration(seconds: 2),
          backgroundColor: _successGreen,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          duration: const Duration(seconds: 2),
        ),
      );
    }
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
  }

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;

    return PopScope(
      canPop: false,
      child: FractionallySizedBox(
        heightFactor: 0.9,
        child: SafeArea(
          top: false,
          child: Container(
            decoration: const BoxDecoration(
              color: _cardWhite,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, keyboardInset + 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Handle Bar ────────────────────────────────────
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12, bottom: 4),
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: _textMuted.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Header ────────────────────────────────────
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'How was your experience?',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: _textDark,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Help us improve by rating ${widget.booking.tradespersonName}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: _textMuted.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // ── Tradesperson Info ─────────────────────────────
                    _buildTradespersonInfo(),

                    const SizedBox(height: 28),

                    // ── Star Rating ────────────────────────────────
                    _buildStarRating(),

                    const SizedBox(height: 28),

                    // ── Quick Tags ────────────────────────────────
                    _buildQuickTags(),

                    const SizedBox(height: 24),

                    // ── Comment Input ─────────────────────────────
                    _buildCommentInput(),

                    const SizedBox(height: 24),

                    // ── Action Buttons ────────────────────────────
                    _buildActionButtons(),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTradespersonInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _backgroundGray,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 56,
            height: 56,
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
                widget.booking.tradespersonAvatar,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
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
                  widget.booking.tradespersonName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.booking.trade,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStarRating() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your Rating',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: _textDark,
          ),
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            const starCount = 5;
            const maxStarSize = 50.0;
            const minStarSize = 34.0;
            const maxGap = 12.0;
            const minGap = 4.0;

            final availableWidth = constraints.maxWidth;
            final preferredWidth =
                (starCount * maxStarSize) + ((starCount - 1) * maxGap);
            final compactWidth =
                (starCount * minStarSize) + ((starCount - 1) * minGap);

            final starSize = availableWidth >= preferredWidth
                ? maxStarSize
                : ((availableWidth - ((starCount - 1) * minGap)) / starCount)
                      .clamp(minStarSize, maxStarSize)
                      .toDouble();

            final gap = availableWidth >= preferredWidth
                ? maxGap
                : ((availableWidth - (starCount * starSize)) / (starCount - 1))
                      .clamp(minGap, maxGap)
                      .toDouble();

            final showCompact = availableWidth < compactWidth;

            if (showCompact) {
              return Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: minGap,
                  runSpacing: minGap,
                  children: List.generate(starCount, (index) {
                    final isFilled = index < _rating;
                    return _buildRatingStar(index, isFilled, minStarSize);
                  }),
                ),
              );
            }

            return Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(starCount, (index) {
                  final isFilled = index < _rating;
                  return Padding(
                    padding: EdgeInsets.only(
                      right: index == starCount - 1 ? 0 : gap,
                    ),
                    child: _buildRatingStar(index, isFilled, starSize),
                  );
                }),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        if (_rating > 0)
          Center(
            child: Text(
              _getRatingText(_rating.toInt()),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _warningYellow,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildRatingStar(int index, bool isFilled, double size) {
    return GestureDetector(
      onTap: () => setState(() => _rating = (index + 1).toDouble()),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 1.0, end: isFilled ? 1.1 : 1.0),
        duration: const Duration(milliseconds: 200),
        builder: (context, scale, child) => Transform.scale(
          scale: scale,
          child: Icon(
            isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
            size: size,
            color: isFilled
                ? _warningYellow
                : _textMuted.withValues(alpha: 0.3),
          ),
        ),
      ),
    );
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very Good';
      case 5:
        return 'Excellent';
      default:
        return '';
    }
  }

  Widget _buildQuickTags() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What stood out? (Optional)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: _textDark,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _quickTags.map((tag) {
            final isSelected = _selectedTags.contains(tag);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedTags.remove(tag);
                  } else {
                    _selectedTags.add(tag);
                  }
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? _primaryBlue : _cardWhite,
                  border: Border.all(
                    color: isSelected
                        ? _primaryBlue
                        : _textMuted.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  tag,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : _textDark,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCommentInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Additional Comments (Optional)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: _textDark,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          key: _commentFieldKey,
          decoration: BoxDecoration(
            color: _backgroundGray,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _textMuted.withValues(alpha: 0.1),
              width: 1.5,
            ),
          ),
          child: TextField(
            controller: _commentController,
            focusNode: _commentFocusNode,
            onTap: _scrollCommentFieldIntoView,
            maxLines: 4,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _textDark,
            ),
            decoration: InputDecoration(
              hintText: 'Share your feedback...',
              hintStyle: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: _textMuted.withValues(alpha: 0.6),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
<<<<<<< HEAD
        onPressed: _submitReview,
=======
        onPressed: _isSubmitting ? null : _submitReview,
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
        style: ElevatedButton.styleFrom(
          backgroundColor: _accentOrange,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
<<<<<<< HEAD
        child: const Text(
          'Submit Review',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
=======
        child: _isSubmitting
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text(
                'Submit Review',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
      ),
    );
  }
}
