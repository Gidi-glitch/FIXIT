<<<<<<< HEAD
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_fixit_application/screens/login_screen.dart';

/// Profile Screen for the Fix It Marketplace Homeowner App.
/// Displays user profile information and settings menu options.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

=======
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../login_screen.dart';
import '../../services/api_service.dart';
import 'booking_store.dart';
import 'settings/edit_profile_screen.dart';
import 'settings/help_support_screen.dart';
import 'settings/my_addresses_screen.dart';
import 'settings/notifications_screen.dart';
import 'settings/payment_methods.dart';
import 'settings/privacy_security_screen.dart';

/// Profile Screen for the Fix It Marketplace Homeowner App.
/// Displays user profile information and settings menu options.
class ProfileScreen extends StatefulWidget {
  final void Function(String tradespersonName, String trade, String avatar)?
  onMessageRequested;

  const ProfileScreen({super.key, this.onMessageRequested});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
  // ── Color Palette ──────────────────────────────────────────────
  static const Color _primaryBlue = Color(0xFF1E3A8A);
  static const Color _accentOrange = Color(0xFFF97316);
  static const Color _backgroundGray = Color(0xFFF9FAFB);
  static const Color _textDark = Color(0xFF111827);
  static const Color _textMuted = Color(0xFF6B7280);
  static const Color _cardWhite = Color(0xFFFFFFFF);
  static const Color _dangerRed = Color(0xFFEF4444);

<<<<<<< HEAD
=======
  final ImagePicker _imagePicker = ImagePicker();
  String _displayName = 'Gideon Alcantara';
  String _barangay = '';
  String? _profileImagePath;
  bool _isUploadingPhoto = false;
  int _totalBookings = 0;
  int _completedBookings = 0;
  double _averageGivenRating = 0;

  @override
  void initState() {
    super.initState();
    BookingStore.notifier.addListener(_onBookingStoreChanged);
    _applyStatsFromBookings(BookingStore.all);
    _loadProfileData();
  }

  @override
  void dispose() {
    BookingStore.notifier.removeListener(_onBookingStoreChanged);
    super.dispose();
  }

  void _onBookingStoreChanged() {
    if (!mounted) return;
    _applyStatsFromBookings(BookingStore.all);
  }

  void _applyStatsFromBookings(List<BookingModel> bookings) {
    var totalBookings = bookings.length;
    var completedBookings = 0;
    var ratingSum = 0.0;
    var ratingCount = 0;

    for (final booking in bookings) {
      if (booking.status.toLowerCase() == 'completed') {
        completedBookings += 1;
      }

      final rating = booking.reviewRating;
      if (rating != null && rating > 0) {
        ratingSum += rating;
        ratingCount += 1;
      }
    }

    final averageGivenRating = ratingCount > 0 ? ratingSum / ratingCount : 0.0;

    if (!mounted) return;
    setState(() {
      _totalBookings = totalBookings;
      _completedBookings = completedBookings;
      _averageGivenRating = averageGivenRating;
    });
  }

  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();

    var totalBookings = _totalBookings;
    var completedBookings = _completedBookings;
    var averageGivenRating = _averageGivenRating;

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

      try {
        final result = await ApiService.getHomeownerBookings(token: token);
        final rawRows = result['bookings'];
        final rows = rawRows is List
            ? rawRows
                  .whereType<Map>()
                  .map((e) => e.cast<String, dynamic>())
                  .toList()
            : <Map<String, dynamic>>[];

        BookingStore.setAllFromApi(rows);

        totalBookings = BookingStore.all.length;
        completedBookings = BookingStore.all
            .where((b) => b.status.toLowerCase() == 'completed')
            .length;
        final ratedBookings = BookingStore.all
            .where((b) => (b.reviewRating ?? 0) > 0)
            .toList();
        final ratingSum = ratedBookings.fold<double>(
          0,
          (sum, b) => sum + (b.reviewRating ?? 0),
        );
        averageGivenRating = ratedBookings.isNotEmpty
            ? ratingSum / ratedBookings.length
            : 0;
      } catch (_) {
        // Keep previous stats if bookings request fails.
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
      _displayName = fullName.isNotEmpty ? fullName : 'Gideon Alcantara';
      _barangay = prefs.getString('barangay')?.trim() ?? '';
      _profileImagePath = prefs.getString('profile_image_url');
      _totalBookings = totalBookings;
      _completedBookings = completedBookings;
      _averageGivenRating = averageGivenRating;
    });
  }

  String get _addressLabel {
    if (_barangay.trim().isEmpty) {
      return 'Calauan, Laguna';
    }
    return '${_barangay.trim()}, Calauan, Laguna';
  }

  String get _initials {
    final parts = _displayName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'GA';
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
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
      }
    }
  }

  // ── Navigate to Edit Profile ────────────────────────────────────
  Future<void> _openEditProfile() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
    );
    // Refresh profile data when returning if changes were saved
    if (result == true && mounted) {
      await _loadProfileData();
    }
  }

  Future<void> _openMyAddresses() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => const MyAddressesScreen()),
    );
  }

  Future<void> _openPaymentMethods() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => const PaymentMethodsScreen()),
    );
  }

  Future<void> _openNotifications() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
  }

  Future<void> _openPrivacySecurity() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => const PrivacySecurityScreen()),
    );
  }

  Future<void> _openHelpSupport() async {
    final openSupportChat = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const HelpSupportScreen()),
    );

    if (openSupportChat == true) {
      widget.onMessageRequested?.call('Fix It Support', 'Support', 'FI');
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('role');
    await prefs.remove('first_name');
    await prefs.remove('last_name');
    await prefs.remove('full_name');
    await prefs.remove('barangay');
    await prefs.remove('profile_image_url');

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const UserLoginScreen()),
      (route) => false,
    );
  }

  Future<void> _showLogoutPrompt(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
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
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _textMuted,
                          side: BorderSide(
                            color: _textMuted.withValues(alpha: 0.35),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _dangerRed,
                          foregroundColor: Colors.white,
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
                            fontSize: 14,
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
      },
    );

    if (shouldLogout == true) {
      await _logout();
    }
  }

>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundGray,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              // ── App Bar ───────────────────────────────────────────
              _buildAppBar(),

              // ── Profile Header ────────────────────────────────────
              _buildProfileHeader(),

              // ── Stats Cards ───────────────────────────────────────
              _buildStatsSection(),

              // ── Menu Options ──────────────────────────────────────
              _buildMenuSection(),

              // ── Logout Button ─────────────────────────────────────
              _buildLogoutButton(context),

              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Profile',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: _textDark,
                letterSpacing: -0.5,
              ),
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
              onPressed: () {},
=======
              onPressed: _openPrivacySecurity,
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
              icon: const Icon(
                Icons.settings_outlined,
                color: _textDark,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(24),
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
        children: [
          // ── Avatar ────────────────────────────────────────────────
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_primaryBlue, Color(0xFF3B82F6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: _primaryBlue.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
<<<<<<< HEAD
            child: const Center(
              child: Text(
                'GA',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
=======
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: _profileImagePath != null && _profileImagePath!.isNotEmpty
                  ? Image.network(
                      _profileImagePath!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Center(
                        child: Text(
                          _initials,
                          style: const TextStyle(
                            fontSize: 32,
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
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
            ),
          ),
          const SizedBox(height: 16),

          // ── Name ──────────────────────────────────────────────────
<<<<<<< HEAD
          const Text(
            'Gideon Alcantara',
            style: TextStyle(
=======
          Text(
            _displayName,
            style: const TextStyle(
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: _textDark,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),

          // ── Location ──────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: _primaryBlue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
<<<<<<< HEAD
                Icon(Icons.location_on_rounded, size: 16, color: _primaryBlue),
                const SizedBox(width: 6),
                Text(
                  'Dayap, Calauan, Laguna',
                  style: TextStyle(
=======
                const Icon(
                  Icons.location_on_rounded,
                  size: 16,
                  color: _primaryBlue,
                ),
                const SizedBox(width: 6),
                Text(
                  _addressLabel,
                  style: const TextStyle(
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _primaryBlue,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

<<<<<<< HEAD
          // ── Edit Profile Button ───────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Edit Profile Picture'),
=======
          // ── Edit Profile Button ────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isUploadingPhoto ? null : _pickProfileImage,
              icon: _isUploadingPhoto
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(_primaryBlue),
                      ),
                    )
                  : const Icon(Icons.edit_outlined, size: 18),
              label: Text(
                _isUploadingPhoto ? 'Uploading...' : 'Edit Profile Picture',
              ),
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
              style: OutlinedButton.styleFrom(
                foregroundColor: _primaryBlue,
                side: BorderSide(color: _primaryBlue.withValues(alpha: 0.3)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              icon: Icons.calendar_today_rounded,
<<<<<<< HEAD
              value: '12',
=======
              value: _totalBookings.toString(),
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
              label: 'Bookings',
              color: _primaryBlue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.check_circle_outline_rounded,
<<<<<<< HEAD
              value: '10',
=======
              value: _completedBookings.toString(),
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
              label: 'Completed',
              color: const Color(0xFF10B981),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.star_outline_rounded,
<<<<<<< HEAD
              value: '4.8',
=======
              value: _averageGivenRating.toStringAsFixed(1),
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
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

  Widget _buildMenuSection() {
    final menuItems = [
      {
        'icon': Icons.person_outline_rounded,
        'title': 'Edit Profile',
        'subtitle': 'Update your personal information',
        'color': _primaryBlue,
<<<<<<< HEAD
=======
        'onTap': _openEditProfile, // ← wired up
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
      },
      {
        'icon': Icons.location_on_outlined,
        'title': 'My Addresses',
        'subtitle': 'Manage your saved addresses',
        'color': const Color(0xFF10B981),
<<<<<<< HEAD
=======
        'onTap': _openMyAddresses,
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
      },
      {
        'icon': Icons.payment_rounded,
        'title': 'Payment Methods',
        'subtitle': 'Add or manage payment options',
        'color': _accentOrange,
<<<<<<< HEAD
=======
        'onTap': _openPaymentMethods,
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
      },
      {
        'icon': Icons.notifications_outlined,
        'title': 'Notifications',
        'subtitle': 'Configure notification preferences',
        'color': const Color(0xFF8B5CF6),
<<<<<<< HEAD
=======
        'onTap': _openNotifications,
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
      },
      {
        'icon': Icons.security_outlined,
        'title': 'Privacy & Security',
        'subtitle': 'Manage your account security',
        'color': const Color(0xFF06B6D4),
<<<<<<< HEAD
=======
        'onTap': _openPrivacySecurity,
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
      },
      {
        'icon': Icons.help_outline_rounded,
        'title': 'Help & Support',
        'subtitle': 'Get help or contact support',
        'color': const Color(0xFFEC4899),
<<<<<<< HEAD
=======
        'onTap': _openHelpSupport,
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
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
<<<<<<< HEAD
=======
            onTap: item['onTap'] as VoidCallback,
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
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
<<<<<<< HEAD
=======
    required VoidCallback onTap,
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
    required bool showDivider,
  }) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
<<<<<<< HEAD
            onTap: () {},
=======
            onTap: onTap,
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
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

  Widget _buildLogoutButton(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      width: double.infinity,
      child: OutlinedButton.icon(
<<<<<<< HEAD
        onPressed: () => _handleLogout(context),
=======
        onPressed: () => _showLogoutPrompt(context),
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
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
<<<<<<< HEAD

  Future<void> _handleLogout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('role');
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const UserLoginScreen()),
      (route) => false,
    );
  }
=======
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
}
