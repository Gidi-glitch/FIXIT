import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../login_screen.dart';
import '../../services/api_service.dart';
import 'settings/tradesperson_edit_profile_screen.dart';
import 'settings/tradesperson_service_area_screen.dart';
import 'settings/tradesperson_trade_skills_screen.dart';
import 'settings/tradesperson_my_documents_screen.dart';
import 'settings/tradesperson_notifications_screen.dart';
import 'settings/tradesperson_privacy_security_screen.dart';
import 'settings/tradesperson_help_support_screen.dart';

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
  bool _isUpdatingOnDuty = false;
  bool _isOnDuty = true;
  int _activeJobs = 0;
  int _completedJobs = 0;
  double _averageRating = 0;
  int _reviewCount = 0;
  String _verificationStatus = 'pending';
  String _governmentIdStatus = 'pending';
  String _licenseStatus = 'pending';
  String _phoneStatus = 'missing';
  late final AnimationController _cameraTapController;
  late final Animation<double> _cameraScaleAnimation;

  // Professional info — refreshed after Edit Profile
  String _trade = 'Plumber';
  String _specialization = 'Pipe Repair & Installation';

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
    final v = widget.onDutyNotifier?.value;
    if (v == null || v == _isOnDuty || !mounted) return;
    setState(() => _isOnDuty = v);
  }

  bool? _asBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final text = value?.toString().trim().toLowerCase() ?? '';
    if (text == 'true' || text == '1' || text == 'yes') return true;
    if (text == 'false' || text == '0' || text == 'no') return false;
    return null;
  }

  bool? _readOnDutyFromProfilePayload(
    Map<String, dynamic> payload,
    Map<String, dynamic> user,
  ) {
    final direct = _asBool(user['on_duty']);
    if (direct != null) return direct;

    final embedded = user['tradesperson_profile'];
    if (embedded is Map) {
      final profile = embedded.cast<String, dynamic>();
      final fromEmbedded =
          _asBool(profile['on_duty']) ??
          _asBool(profile['is_available']) ??
          _asBool(profile['availability']);
      if (fromEmbedded != null) return fromEmbedded;
    }

    final topLevel = payload['tradesperson_profile'];
    if (topLevel is Map) {
      final profile = topLevel.cast<String, dynamic>();
      return _asBool(profile['on_duty']) ??
          _asBool(profile['is_available']) ??
          _asBool(profile['availability']);
    }

    return null;
  }

  Future<void> _setOnDutyStatus(bool value) async {
    if (_isUpdatingOnDuty || value == _isOnDuty) return;

    final previous = _isOnDuty;
    setState(() {
      _isUpdatingOnDuty = true;
      _isOnDuty = value;
    });
    widget.onDutyNotifier?.value = value;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token')?.trim() ?? '';
      if (token.isEmpty) {
        throw Exception('Session expired. Please log in again.');
      }

      await ApiService.updateMyOnDutyStatus(token: token, isOnDuty: value);
      await prefs.setBool('on_duty', value);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isOnDuty = previous);
      widget.onDutyNotifier?.value = previous;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: _dangerRed,
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

  @override
  void dispose() {
    widget.onDutyNotifier?.removeListener(_syncOnDutyFromNotifier);
    _cameraTapController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    bool? onDutyFromApi;
    var verificationStatus = _verificationStatus;
    var governmentIdStatus = _governmentIdStatus;
    var licenseStatus = _licenseStatus;
    var phoneStatus = _phoneStatus;
    final token = prefs.getString('token')?.trim();
    if (token != null && token.isNotEmpty) {
      try {
        final result = await ApiService.getProfile(token);
        final user = (result['user'] as Map?)?.cast<String, dynamic>() ?? {};
        final profile =
            (result['profile'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{};
        final documents = (result['documents'] as List?) ?? const [];
        onDutyFromApi = _readOnDutyFromProfilePayload(result, user);
        Future<void> syncPref(String k, dynamic v) async {
          final s = (v ?? '').toString().trim();
          if (s.isNotEmpty) {
            await prefs.setString(k, s);
          } else {
            await prefs.remove(k);
          }
        }

        await syncPref('first_name', user['first_name']);
        await syncPref('last_name', user['last_name']);
        await syncPref('barangay', user['barangay'] ?? profile['barangay']);
        await syncPref('trade', user['trade'] ?? profile['trade_category']);
        await syncPref(
          'specializations',
          user['specializations'] ?? profile['specializations'],
        );
        final img = (user['profile_image_url'] ?? '').toString().trim();
        img.isNotEmpty
            ? prefs.setString('profile_image_url', img)
            : prefs.remove('profile_image_url');
        final full =
            '${(user['first_name'] ?? '').toString().trim()} ${(user['last_name'] ?? '').toString().trim()}'
                .trim();
        if (full.isNotEmpty) prefs.setString('full_name', full);
        if (onDutyFromApi != null) {
          await prefs.setBool('on_duty', onDutyFromApi);
        }

        verificationStatus = _normalizeStatus(
          profile['verification_status'] ?? user['verification_status'],
          fallback: 'pending',
        );
        governmentIdStatus = verificationStatus;
        licenseStatus = verificationStatus;

        for (final doc in documents.whereType<Map>()) {
          final type = (doc['document_type'] ?? '')
              .toString()
              .trim()
              .toLowerCase();
          final status = _normalizeStatus(
            doc['status'],
            fallback: verificationStatus,
          );
          if (type == 'government_id') {
            governmentIdStatus = status;
          } else if (type == 'license') {
            licenseStatus = status;
          }
        }

        final phone = (profile['phone'] ?? user['phone'] ?? '')
            .toString()
            .trim();
        phoneStatus = phone.isEmpty ? 'missing' : 'on_file';
      } catch (_) {}

      await _loadPerformanceStats(token);
    }
    final cachedOnDuty = prefs.getBool('on_duty');
    final effectiveOnDuty = onDutyFromApi ?? cachedOnDuty;
    final firstName = prefs.getString('first_name')?.trim();
    final lastName = prefs.getString('last_name')?.trim();
    final fullNamePref = prefs.getString('full_name')?.trim();
    final fullName = fullNamePref?.isNotEmpty == true
        ? fullNamePref!
        : '${firstName ?? ''} ${lastName ?? ''}'.trim();
    if (!mounted) return;
    setState(() {
      _displayName = fullName.isNotEmpty ? fullName : 'Juan Dela Cruz';
      _barangay = prefs.getString('barangay')?.trim() ?? '';
      _profileImagePath = prefs.getString('profile_image_url');
      _trade = prefs.getString('trade') ?? 'Plumber';
      final specs = prefs.getString('specializations') ?? '';
      _specialization = specs.isNotEmpty
          ? specs.split(',').first.trim()
          : 'Pipe Repair & Installation';
      _verificationStatus = verificationStatus;
      _governmentIdStatus = governmentIdStatus;
      _licenseStatus = licenseStatus;
      _phoneStatus = phoneStatus;
      if (effectiveOnDuty != null) {
        _isOnDuty = effectiveOnDuty;
      }
    });
    if (effectiveOnDuty != null) {
      widget.onDutyNotifier?.value = effectiveOnDuty;
    }
  }

  Future<void> _loadPerformanceStats(String token) async {
    var activeJobs = 0;
    var completedJobs = 0;
    var averageRating = 0.0;
    var reviewCount = 0;

    try {
      final jobsResult = await ApiService.getTradespersonJobs(token: token);
      final jobs = (jobsResult['jobs'] as List?) ?? const [];
      for (final row in jobs.whereType<Map>()) {
        final status = (row['status'] ?? '').toString().trim().toLowerCase();
        if (status == 'in progress' ||
            status == 'accepted' ||
            status == 'under review') {
          activeJobs++;
        }
        if (status == 'completed') {
          completedJobs++;
        }
      }
    } catch (_) {
      // Keep zero default when jobs fetch fails.
    }

    try {
      final reviewsResult = await ApiService.getMyTradespersonReviews(
        token: token,
        sort: 'recent',
      );
      final summary =
          (reviewsResult['summary'] as Map?)?.cast<String, dynamic>() ??
          const <String, dynamic>{};
      final rows = (reviewsResult['reviews'] as List?) ?? const [];

      averageRating = _asDouble(summary['average_rating']);
      reviewCount = _asInt(summary['review_count']);

      if (reviewCount <= 0 && rows.isNotEmpty) {
        var sum = 0.0;
        var count = 0;
        for (final row in rows.whereType<Map>()) {
          sum += _asDouble(row['rating']);
          count++;
        }
        if (count > 0) {
          averageRating = sum / count;
          reviewCount = count;
        }
      }
    } catch (_) {
      // Keep zero default when reviews fetch fails.
    }

    if (!mounted) return;
    setState(() {
      _activeJobs = activeJobs;
      _completedJobs = completedJobs;
      _averageRating = averageRating.clamp(0.0, 5.0);
      _reviewCount = reviewCount;
    });
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

  String _normalizeStatus(dynamic value, {String fallback = 'pending'}) {
    final raw = value?.toString().trim().toLowerCase() ?? '';
    switch (raw) {
      case 'approved':
      case 'verified':
        return 'approved';
      case 'pending':
      case 'for_review':
      case 'in_review':
        return 'pending';
      case 'rejected':
        return 'rejected';
      case 'on_file':
        return 'on_file';
      case 'missing':
        return 'missing';
      case '':
        return fallback;
      default:
        return raw;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'approved':
        return 'Verified';
      case 'pending':
        return 'Pending';
      case 'rejected':
        return 'Rejected';
      case 'on_file':
        return 'On File';
      case 'missing':
        return 'Missing';
      default:
        final normalized = status.replaceAll('_', ' ').trim();
        if (normalized.isEmpty) return 'Pending';
        return normalized[0].toUpperCase() + normalized.substring(1);
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return _successGreen;
      case 'pending':
        return _accentOrange;
      case 'rejected':
        return _dangerRed;
      case 'on_file':
        return _primaryBlue;
      case 'missing':
        return _textMuted;
      default:
        return _primaryBlue;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'approved':
        return Icons.check_circle_rounded;
      case 'pending':
        return Icons.schedule_rounded;
      case 'rejected':
        return Icons.cancel_rounded;
      case 'on_file':
        return Icons.info_rounded;
      case 'missing':
        return Icons.remove_circle_outline_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  String get _addressLabel => _barangay.trim().isEmpty
      ? 'Calauan, Laguna'
      : '${_barangay.trim()}, Calauan, Laguna';

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
      if (token == null || token.isEmpty) throw Exception('Session expired.');
      final res = await ApiService.uploadProfileImage(
        token: token,
        image: File(picked.path),
      );
      final url = (res['profile_image_url'] ?? '').toString().trim();
      if (url.isNotEmpty) await prefs.setString('profile_image_url', url);
      if (!mounted) return;
      setState(() => _profileImagePath = url);
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

  // ── Menu navigation ─────────────────────────────────────────────
  Future<void> _openEditProfile() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const TradespersonEditProfileScreen()),
    );
    if (result == true && mounted) await _loadProfileData();
  }

  Future<void> _openServiceArea() => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const TradespersonServiceAreaScreen()),
  );

  Future<void> _openTradeSkills() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const TradespersonTradeSkillsScreen()),
    );
    if (result == true && mounted) await _loadProfileData();
  }

  Future<void> _openMyDocuments() => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const TradespersonMyDocumentsScreen()),
  );
  Future<void> _openNotifications() => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const TradespersonNotificationsScreen()),
  );
  Future<void> _openPrivacySecurity() => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const TradespersonPrivacySecurityScreen(),
    ),
  );
  Future<void> _openHelpSupport() => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const TradespersonHelpSupportScreen()),
  );

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
      (r) => false,
    );
  }

  Future<void> _showLogoutPrompt(BuildContext context) async {
    final should = await showDialog<bool>(
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
                        style: TextStyle(fontWeight: FontWeight.w700),
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
    if (should == true && context.mounted) await _logout(context);
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
                          errorBuilder: (context, error, stackTrace) => Center(
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
                  color: _statusColor(
                    _verificationStatus,
                  ).withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _statusIcon(_verificationStatus),
                      size: 12,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _statusLabel(_verificationStatus),
                      style: const TextStyle(
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
            onChanged: _isUpdatingOnDuty ? null : _setOnDutyStatus,
            activeThumbColor: _successGreen,
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  STATS ROW
  // ═══════════════════════════════════════════════════════════════
  Widget _buildStatsRow() {
    final ratingValue = _reviewCount > 0
        ? _averageRating.toStringAsFixed(1)
        : '0.0';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              icon: Icons.handyman_rounded,
              value: '$_activeJobs',
              label: 'Active Jobs',
              color: _primaryBlue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.check_circle_outline_rounded,
              value: '$_completedJobs',
              label: 'Completed',
              color: _successGreen,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.star_outline_rounded,
              value: ratingValue,
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
    final statusColor = _statusColor(_verificationStatus);
    final statusLabel = _statusLabel(_verificationStatus);
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: statusColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield_rounded, color: statusColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Verification Status',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: _textDark,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _verificationItem(
            Icons.badge_rounded,
            'Government ID',
            _governmentIdStatus,
          ),
          const SizedBox(height: 10),
          _verificationItem(
            Icons.workspace_premium_rounded,
            'Trade License',
            _licenseStatus,
          ),
          const SizedBox(height: 10),
          _verificationItem(
            Icons.phone_android_rounded,
            'Phone Number',
            _phoneStatus,
          ),
        ],
      ),
    );
  }

  Widget _verificationItem(IconData icon, String label, String status) {
    final color = _statusColor(status);
    final statusText = _statusLabel(status);
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
            Icon(_statusIcon(status), size: 14, color: color),
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
  //  MENU SECTION  (all items wired up)
  // ═══════════════════════════════════════════════════════════════
  Widget _buildMenuSection() {
    final menuItems = [
      {
        'icon': Icons.person_outline_rounded,
        'title': 'Edit Profile',
        'subtitle': 'Update your personal information',
        'color': _primaryBlue,
        'onTap': _openEditProfile,
      },
      {
        'icon': Icons.map_rounded,
        'title': 'Service Area',
        'subtitle': 'Manage barangays you serve',
        'color': _successGreen,
        'onTap': _openServiceArea,
      },
      {
        'icon': Icons.build_outlined,
        'title': 'Trade & Skills',
        'subtitle': 'Update your services and specializations',
        'color': _accentOrange,
        'onTap': _openTradeSkills,
      },
      {
        'icon': Icons.description_rounded,
        'title': 'My Documents',
        'subtitle': 'View or update your verification docs',
        'color': const Color(0xFF8B5CF6),
        'onTap': _openMyDocuments,
      },
      {
        'icon': Icons.notifications_outlined,
        'title': 'Notifications',
        'subtitle': 'Configure notification preferences',
        'color': const Color(0xFF06B6D4),
        'onTap': _openNotifications,
      },
      {
        'icon': Icons.security_outlined,
        'title': 'Privacy & Security',
        'subtitle': 'Manage your account security',
        'color': const Color(0xFFEC4899),
        'onTap': _openPrivacySecurity,
      },
      {
        'icon': Icons.help_outline_rounded,
        'title': 'Help & Support',
        'subtitle': 'Get help or contact support',
        'color': const Color(0xFF64748B),
        'onTap': _openHelpSupport,
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
            onTap: item['onTap'] as VoidCallback,
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
    required VoidCallback onTap,
    required bool showDivider,
  }) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
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
