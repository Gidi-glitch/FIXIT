import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../login_screen.dart';
import '../../services/api_service.dart';

/// Profile Screen for the Fix It Marketplace Tradesperson App.
/// Displays the tradesperson's professional profile, stats,
/// verification status, and account settings.
class TradespersonProfileScreen extends StatefulWidget {
  const TradespersonProfileScreen({super.key, this.onDutyNotifier});

  final ValueNotifier<bool>? onDutyNotifier;

  @override
  State<TradespersonProfileScreen> createState() =>
      _TradespersonProfileScreenState();
}

class _TradespersonProfileScreenState extends State<TradespersonProfileScreen>
    with SingleTickerProviderStateMixin {
  // ── Color Palette ──────────────────────────────────────────────
  static const Color _primaryBlue = Color(0xFF1E3A8A);
  static const Color _accentOrange = Color(0xFFF97316);
  static const Color _backgroundGray = Color(0xFFF9FAFB);
  static const Color _textDark = Color(0xFF111827);
  static const Color _textMuted = Color(0xFF6B7280);
  static const Color _cardWhite = Color(0xFFFFFFFF);
  static const Color _successGreen = Color(0xFF10B981);
  static const Color _dangerRed = Color(0xFFEF4444);

  final ImagePicker _imagePicker = ImagePicker();
  String _displayName = 'Juan Dela Cruz';
  String _barangay = '';
  String? _profileImagePath;
  bool _isUploadingPhoto = false;
  bool _isOnDuty = true;
  late final AnimationController _cameraTapController;
  late final Animation<double> _cameraScaleAnimation;

  // Professional info (would come from API in real use)
  static const String _trade = 'Plumber';
  static const String _specialization = 'Pipe Repair & Installation';

  @override
  void initState() {
    super.initState();
    _isOnDuty = widget.onDutyNotifier?.value ?? _isOnDuty;
    widget.onDutyNotifier?.addListener(_syncOnDutyFromNotifier);
    _cameraTapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );
    _cameraScaleAnimation =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.88), weight: 50),
          TweenSequenceItem(tween: Tween(begin: 0.88, end: 1.0), weight: 50),
        ]).animate(
          CurvedAnimation(
            parent: _cameraTapController,
            curve: Curves.easeOutCubic,
          ),
        );
    _loadProfileData();
  }

  void _syncOnDutyFromNotifier() {
    final externalValue = widget.onDutyNotifier?.value;
    if (externalValue == null || externalValue == _isOnDuty || !mounted) {
      return;
    }
    setState(() => _isOnDuty = externalValue);
  }

  @override
  void dispose() {
    widget.onDutyNotifier?.removeListener(_syncOnDutyFromNotifier);
    _cameraTapController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString('token')?.trim();
    if (token != null && token.isNotEmpty) {
      try {
        final result = await ApiService.getProfile(token);
        final user =
            (result['user'] as Map?)?.cast<String, dynamic>() ??
            <String, dynamic>{};
        final firstName = (user['first_name'] ?? '').toString().trim();
        final lastName = (user['last_name'] ?? '').toString().trim();
        final fullName = '$firstName $lastName'.trim();
        final profileImageUrl = (user['profile_image_url'] ?? '')
            .toString()
            .trim();
        final barangay = (user['barangay'] ?? '').toString().trim();

        if (firstName.isNotEmpty) {
          await prefs.setString('first_name', firstName);
        }
        if (lastName.isNotEmpty) {
          await prefs.setString('last_name', lastName);
        }
        if (fullName.isNotEmpty) {
          await prefs.setString('full_name', fullName);
        }
        if (profileImageUrl.isNotEmpty) {
          await prefs.setString('profile_image_url', profileImageUrl);
        } else {
          await prefs.remove('profile_image_url');
        }
        if (barangay.isNotEmpty) {
          await prefs.setString('barangay', barangay);
        }
      } catch (_) {
        // Fallback to cached values if backend request fails.
      }
    }

    final firstName = prefs.getString('first_name')?.trim();
    final lastName = prefs.getString('last_name')?.trim();
    final fullNameFromPrefs = prefs.getString('full_name')?.trim();
    final fullName = fullNameFromPrefs?.isNotEmpty == true
        ? fullNameFromPrefs!
        : '${firstName ?? ''} ${lastName ?? ''}'.trim();

    if (!mounted) return;

    setState(() {
      _displayName = fullName.isNotEmpty ? fullName : 'Juan Dela Cruz';
      _barangay = prefs.getString('barangay')?.trim() ?? '';
      _profileImagePath = prefs.getString('profile_image_url');
    });
  }

  String get _addressLabel {
    if (_barangay.trim().isEmpty) return 'Calauan, Laguna';
    return '${_barangay.trim()}, Calauan, Laguna';
  }

  String get _initials {
    final parts = _displayName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'JD';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

  Future<void> _pickProfileImage() async {
    setState(() => _isUploadingPhoto = true);
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 88,
        maxWidth: 1400,
      );

      if (picked == null) return;

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token')?.trim();
      if (token == null || token.isEmpty) {
        throw Exception('Session expired. Please log in again.');
      }

      final uploadResult = await ApiService.uploadProfileImage(
        token: token,
        image: File(picked.path),
      );
      final imageUrl = (uploadResult['profile_image_url'] ?? '')
          .toString()
          .trim();
      if (imageUrl.isNotEmpty) {
        await prefs.setString('profile_image_url', imageUrl);
      }

      if (!mounted) return;
      setState(() => _profileImagePath = imageUrl);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profile picture updated.'),
          backgroundColor: _primaryBlue,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  Future<void> _onCameraIconTap() async {
    if (_isUploadingPhoto) return;
    HapticFeedback.lightImpact();
    await _cameraTapController.forward(from: 0);
    if (!mounted) return;
    await _pickProfileImage();
  }

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('role');
    await prefs.remove('first_name');
    await prefs.remove('last_name');
    await prefs.remove('full_name');
    await prefs.remove('barangay');
    await prefs.remove('profile_image_url');

    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const UserLoginScreen()),
      (route) => false,
    );
  }

  Future<void> _showLogoutPrompt(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => Dialog(
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
                    colors: [_dangerRed, Color(0xFFF97316)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Log out?',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: _textDark,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Are you sure you want to log out?',
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
                      onPressed: () => Navigator.pop(dialogContext, false),
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
                      onPressed: () => Navigator.pop(dialogContext, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _dangerRed,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Log Out',
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

    if (shouldLogout == true && context.mounted) {
      await _logout(context);
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundGray,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              _buildProfileHeader(),
              _buildOnDutyToggle(),
              _buildStatsRow(),
              _buildVerificationCard(),
              _buildMenuSection(),
              _buildLogoutButton(context),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  PROFILE HEADER
  // ═══════════════════════════════════════════════════════════════

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_primaryBlue, Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _primaryBlue.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Avatar ──────────────────────────────────────────────
          Stack(
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.4),
                    width: 2,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child:
                      _profileImagePath != null &&
                          _profileImagePath!.startsWith('http')
                      ? Image.network(
                          _profileImagePath!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Center(
                            child: Text(
                              _initials,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            _initials,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                ),
              ),
              if (_isUploadingPhoto)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      ),
                    ),
                  ),
                ),
              // Camera icon
              Positioned(
                bottom: 0,
                right: 0,
                child: ScaleTransition(
                  scale: _cameraScaleAnimation,
                  child: GestureDetector(
                    onTap: _onCameraIconTap,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: _accentOrange,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ── Name ────────────────────────────────────────────────
          Text(
            _displayName,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),

          // ── Trade & Verification row ────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _trade,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _successGreen.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.verified_rounded, size: 12, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'Verified',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ── Specialization & Location ───────────────────────────
          Text(
            _specialization,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 14,
                color: Colors.white.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 4),
              Text(
                _addressLabel,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  ON-DUTY TOGGLE
  // ═══════════════════════════════════════════════════════════════

  Widget _buildOnDutyToggle() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: _isOnDuty ? _successGreen.withValues(alpha: 0.08) : _cardWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _isOnDuty
              ? _successGreen.withValues(alpha: 0.3)
              : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _isOnDuty
                  ? _successGreen.withValues(alpha: 0.15)
                  : _textMuted.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              _isOnDuty
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: _isOnDuty ? _successGreen : _textMuted,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isOnDuty ? 'Currently On Duty' : 'Currently Off Duty',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _isOnDuty ? _successGreen : _textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _isOnDuty
                      ? 'You are visible to homeowners nearby.'
                      : 'Toggle on to start receiving requests.',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _textMuted.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: _isOnDuty,
            onChanged: (val) {
              if (widget.onDutyNotifier != null) {
                widget.onDutyNotifier!.value = val;
              } else {
                setState(() => _isOnDuty = val);
              }
            },
            activeColor: _successGreen,
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  STATS ROW
  // ═══════════════════════════════════════════════════════════════

  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              icon: Icons.handyman_rounded,
              value: '2',
              label: 'Active Jobs',
              color: _primaryBlue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.check_circle_outline_rounded,
              value: '47',
              label: 'Completed',
              color: _successGreen,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.star_outline_rounded,
              value: '4.9',
              label: 'Avg. Rating',
              color: _accentOrange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardWhite,
        borderRadius: BorderRadius.circular(16),
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
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: _textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _textMuted.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  VERIFICATION CARD
  // ═══════════════════════════════════════════════════════════════

  Widget _buildVerificationCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _primaryBlue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _primaryBlue.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_rounded, color: _primaryBlue, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Verification Status',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: _primaryBlue,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _successGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Verified',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _successGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildVerificationItem(
            Icons.badge_rounded,
            'Government ID',
            'Verified',
            _successGreen,
          ),
          const SizedBox(height: 10),
          _buildVerificationItem(
            Icons.workspace_premium_rounded,
            'Trade License',
            'Verified',
            _successGreen,
          ),
          const SizedBox(height: 10),
          _buildVerificationItem(
            Icons.phone_android_rounded,
            'Phone Number',
            'Verified',
            _successGreen,
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationItem(
    IconData icon,
    String label,
    String statusText,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _textDark,
            ),
          ),
        ),
        Row(
          children: [
            Icon(Icons.check_circle_rounded, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              statusText,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  MENU SECTION
  // ═══════════════════════════════════════════════════════════════

  Widget _buildMenuSection() {
    final menuItems = [
      {
        'icon': Icons.person_outline_rounded,
        'title': 'Edit Profile',
        'subtitle': 'Update your personal information',
        'color': _primaryBlue,
      },
      {
        'icon': Icons.map_rounded,
        'title': 'Service Area',
        'subtitle': 'Manage barangays you serve',
        'color': _successGreen,
      },
      {
        'icon': Icons.build_outlined,
        'title': 'Trade & Skills',
        'subtitle': 'Update your services and specializations',
        'color': _accentOrange,
      },
      {
        'icon': Icons.description_rounded,
        'title': 'My Documents',
        'subtitle': 'View or update your verification docs',
        'color': const Color(0xFF8B5CF6),
      },
      {
        'icon': Icons.notifications_outlined,
        'title': 'Notifications',
        'subtitle': 'Configure notification preferences',
        'color': const Color(0xFF06B6D4),
      },
      {
        'icon': Icons.security_outlined,
        'title': 'Privacy & Security',
        'subtitle': 'Manage your account security',
        'color': const Color(0xFFEC4899),
      },
      {
        'icon': Icons.help_outline_rounded,
        'title': 'Help & Support',
        'subtitle': 'Get help or contact support',
        'color': const Color(0xFF64748B),
      },
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      decoration: BoxDecoration(
        color: _cardWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: menuItems.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isLast = index == menuItems.length - 1;
          return _buildMenuItem(
            icon: item['icon'] as IconData,
            title: item['title'] as String,
            subtitle: item['subtitle'] as String,
            color: item['color'] as Color,
            showDivider: !isLast,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool showDivider,
  }) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {},
            borderRadius: showDivider
                ? null
                : const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: _textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _textMuted.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: _textMuted.withValues(alpha: 0.4),
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Container(height: 1, color: Colors.grey.shade100),
          ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  LOGOUT BUTTON
  // ═══════════════════════════════════════════════════════════════

  Widget _buildLogoutButton(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _showLogoutPrompt(context),
        icon: const Icon(Icons.logout_rounded, size: 20),
        label: const Text('Log Out'),
        style: OutlinedButton.styleFrom(
          foregroundColor: _dangerRed,
          side: BorderSide(color: _dangerRed.withValues(alpha: 0.3)),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
