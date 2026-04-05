import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../services/api_service.dart';

/// Edit Profile Screen for the Fix It Marketplace Homeowner App.
///
/// Allows the homeowner to update their personal information:
/// first/last name, phone number, email, and gender.
/// Also supports changing the profile picture.
///
/// On successful save it pops with [true] so the calling screen
/// (ProfileScreen) can trigger a data refresh.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  // ── Color Palette ──────────────────────────────────────────────
  static const Color _primaryBlue = Color(0xFF1E3A8A);
  static const Color _accentOrange = Color(0xFFF97316);
  static const Color _backgroundGray = Color(0xFFF9FAFB);
  static const Color _textDark = Color(0xFF111827);
  static const Color _textMuted = Color(0xFF6B7280);
  static const Color _cardWhite = Color(0xFFFFFFFF);
  static const Color _successGreen = Color(0xFF10B981);
  static const Color _errorRed = Color(0xFFEF4444);
  static const Color _borderGray = Color(0xFFE5E7EB);

  static const List<String> _genders = ['Male', 'Female', 'Prefer not to say'];

  // ── Controllers ────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _bioController = TextEditingController();

  // ── State ──────────────────────────────────────────────────────
  String? _selectedGender;
  String? _profileImagePath; // current URL or local path
  File? _pendingImageFile; // newly picked but not yet uploaded
  bool _isUploadingPhoto = false;
  bool _isSaving = false;
  bool _hasUnsavedChanges = false;

  final ImagePicker _imagePicker = ImagePicker();

  // ── Lifecycle ──────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadExistingData();

    // Mark dirty whenever any field changes
    for (final c in [
      _firstNameController,
      _lastNameController,
      _phoneController,
      _emailController,
      _bioController,
    ]) {
      c.addListener(_onFieldChanged);
    }
  }

  void _onFieldChanged() {
    if (!_hasUnsavedChanges) setState(() => _hasUnsavedChanges = true);
  }

  @override
  void dispose() {
    for (final c in [
      _firstNameController,
      _lastNameController,
      _phoneController,
      _emailController,
      _bioController,
    ]) {
      c.removeListener(_onFieldChanged);
      c.dispose();
    }
    super.dispose();
  }

  // ── Load data from cache / API ─────────────────────────────────

  Future<void> _loadExistingData() async {
    final prefs = await SharedPreferences.getInstance();

    // Try fresh from API first
    final token = prefs.getString('token')?.trim();
    if (token != null && token.isNotEmpty) {
      try {
        final result = await ApiService.getProfile(token);
        final user =
            (result['user'] as Map?)?.cast<String, dynamic>() ??
            <String, dynamic>{};

        // Persist to cache
        _cacheFromMap(prefs, user);
      } catch (_) {
        // Silently fall through to cached values.
      }
    }

    if (!mounted) return;

    // Read from cache (always reliable after the above)
    setState(() {
      _firstNameController.text = prefs.getString('first_name') ?? '';
      _lastNameController.text = prefs.getString('last_name') ?? '';
      _phoneController.text = prefs.getString('phone') ?? '';
      _emailController.text = prefs.getString('email') ?? '';
      _bioController.text = prefs.getString('bio') ?? '';
      _profileImagePath = prefs.getString('profile_image_url');

      final savedGender = prefs.getString('gender') ?? '';
      _selectedGender = _genders.contains(savedGender) ? savedGender : null;

      _hasUnsavedChanges = false;
    });
  }

  void _cacheFromMap(SharedPreferences prefs, Map<String, dynamic> user) {
    void set(String key, dynamic val) {
      final s = (val ?? '').toString().trim();
      if (s.isNotEmpty) prefs.setString(key, s);
    }

    set('first_name', user['first_name']);
    set('last_name', user['last_name']);
    set('phone', user['phone']);
    set('email', user['email']);
    set('bio', user['bio']);
    set('gender', user['gender']);

    final imageUrl = (user['profile_image_url'] ?? '').toString().trim();
    if (imageUrl.isNotEmpty) {
      prefs.setString('profile_image_url', imageUrl);
    } else {
      prefs.remove('profile_image_url');
    }
  }

  // ── Avatar helpers ─────────────────────────────────────────────

  String get _initials {
    final first = _firstNameController.text.trim();
    final last = _lastNameController.text.trim();
    if (first.isEmpty && last.isEmpty) return 'GA';
    final f = first.isNotEmpty ? first[0].toUpperCase() : '';
    final l = last.isNotEmpty ? last[0].toUpperCase() : '';
    return '$f$l';
  }

  // ── Photo picker ───────────────────────────────────────────────

  Future<void> _pickImage() async {
    final source = await _showImageSourceSheet();
    if (source == null) return;

    setState(() => _isUploadingPhoto = true);
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        imageQuality: 88,
        maxWidth: 1400,
      );
      if (picked == null) return;
      setState(() {
        _pendingImageFile = File(picked.path);
        _hasUnsavedChanges = true;
      });
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  Future<ImageSource?> _showImageSourceSheet() {
    return showModalBottomSheet<ImageSource>(
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
              child: Text(
                'Change Profile Photo',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: _textDark,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildSourceOption(
              icon: Icons.photo_library_rounded,
              label: 'Choose from Gallery',
              color: _primaryBlue,
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            _buildSourceOption(
              icon: Icons.camera_alt_rounded,
              label: 'Take a Photo',
              color: _accentOrange,
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            if (_profileImagePath != null || _pendingImageFile != null)
              _buildSourceOption(
                icon: Icons.delete_outline_rounded,
                label: 'Remove Photo',
                color: _errorRed,
                onTap: () {
                  setState(() {
                    _pendingImageFile = null;
                    _profileImagePath = null;
                    _hasUnsavedChanges = true;
                  });
                  Navigator.pop(context);
                },
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: color == _errorRed ? _errorRed : _textDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Save ───────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    setState(() => _isSaving = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token')?.trim();

      // 1. Upload new photo if picked
      String? newImageUrl;
      if (_pendingImageFile != null && token != null && token.isNotEmpty) {
        final uploadResult = await ApiService.uploadProfileImage(
          token: token,
          image: _pendingImageFile!,
        );
        newImageUrl = (uploadResult['profile_image_url'] ?? '')
            .toString()
            .trim();
        if (newImageUrl.isNotEmpty) {
          await prefs.setString('profile_image_url', newImageUrl);
        }
      } else if (_profileImagePath == null) {
        // User removed the photo
        await prefs.remove('profile_image_url');
      }

      // 2. Build payload
      final payload = <String, dynamic>{
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'bio': _bioController.text.trim(),
        'gender': _selectedGender ?? '',
      };

      // 3. Call API
      if (token != null && token.isNotEmpty) {
        final apiService = ApiService();
        await (apiService as dynamic).updateProfile(
          token: token,
          data: payload,
        );
      }

      // 4. Persist to local cache
      payload.forEach((key, value) {
        if ((value as String).isNotEmpty) {
          prefs.setString(key, value);
        }
      });

      // Rebuild full_name cache
      final fullName =
          '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}'
              .trim();
      if (fullName.isNotEmpty) await prefs.setString('full_name', fullName);

      if (!mounted) return;

      _showSuccessSnackbar('Profile updated successfully!');
      setState(() => _hasUnsavedChanges = false);

      // Pop with true so ProfileScreen refreshes
      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackbar('Failed to save. Please try again.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Unsaved-changes guard ──────────────────────────────────────

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) return true;
    final discard = await showDialog<bool>(
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
                  color: _accentOrange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: _accentOrange,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Discard Changes?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _textDark,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You have unsaved changes. Are you sure you want to leave?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _textMuted.withValues(alpha: 0.9),
                  height: 1.5,
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
                        'Keep Editing',
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
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Discard',
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
    return discard ?? false;
  }

  // ── Snackbars ──────────────────────────────────────────────────

  void _showSuccessSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                msg,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: _successGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                msg,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: _errorRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) {
          final shouldPop = await _onWillPop();
          if (shouldPop && mounted) Navigator.of(context).pop();
        }
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
        ),
        child: Scaffold(
          backgroundColor: _backgroundGray,
          body: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(28, 24, 20, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Avatar Section ──────────────────────────
                        _buildAvatarSection(),
                        const SizedBox(height: 28),

                        // ── Personal Information ────────────────────
                        _buildSectionHeader(
                          'Personal Information',
                          Icons.person_outline_rounded,
                        ),
                        const SizedBox(height: 14),
                        _buildNameRow(),
                        const SizedBox(height: 14),
                        _buildField(
                          controller: _phoneController,
                          label: 'Phone Number',
                          hint: '+63 9XX XXX XXXX',
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9+\- ]'),
                            ),
                          ],
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Phone number is required.';
                            }
                            final digits = val.replaceAll(
                              RegExp(r'[^0-9]'),
                              '',
                            );
                            if (digits.length < 10) {
                              return 'Enter a valid phone number.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        _buildField(
                          controller: _emailController,
                          label: 'Email Address',
                          hint: 'you@example.com',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Email address is required.';
                            }
                            final emailRegex = RegExp(
                              r'^[\w\.-]+@[\w\.-]+\.\w{2,}$',
                            );
                            if (!emailRegex.hasMatch(val.trim())) {
                              return 'Enter a valid email address.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 28),

                        // ── Additional Details ──────────────────────
                        _buildSectionHeader(
                          'Additional Details',
                          Icons.tune_rounded,
                        ),
                        const SizedBox(height: 14),
                        _buildGenderDropdown(),
                        const SizedBox(height: 14),
                        _buildBioField(),
                        const SizedBox(height: 32),
                      ],
                    ),
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
  //  HEADER
  // ═══════════════════════════════════════════════════════════════

  Widget _buildHeader() {
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
          padding: const EdgeInsets.fromLTRB(8, 4, 20, 16),
          child: Row(
            children: [
              IconButton(
                onPressed: () async {
                  final shouldPop = await _onWillPop();
                  if (shouldPop && mounted) Navigator.of(context).pop();
                },
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
                      'Edit Profile',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ],
                ),
              ),
              // Save shortcut in header
              if (_hasUnsavedChanges)
                TextButton(
                  onPressed: _isSaving ? null : _save,
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.15),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Save',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
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
  //  AVATAR SECTION
  // ═══════════════════════════════════════════════════════════════

  Widget _buildAvatarSection() {
    final hasNetworkImage =
        _profileImagePath != null && _profileImagePath!.startsWith('http');
    final hasLocalImage = _pendingImageFile != null;

    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: Stack(
              children: [
                // ── Avatar ───────────────────────────────────────
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: (!hasNetworkImage && !hasLocalImage)
                        ? const LinearGradient(
                            colors: [_primaryBlue, Color(0xFF3B82F6)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: _primaryBlue.withValues(alpha: 0.25),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: hasLocalImage
                        ? Image.file(_pendingImageFile!, fit: BoxFit.cover)
                        : hasNetworkImage
                        ? Image.network(
                            _profileImagePath!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Center(
                              child: Text(
                                _initials,
                                style: const TextStyle(
                                  fontSize: 34,
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
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                  ),
                ),

                // ── Upload spinner ────────────────────────────────
                if (_isUploadingPhoto)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Center(
                        child: SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        ),
                      ),
                    ),
                  ),

                // ── Camera badge ──────────────────────────────────
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_accentOrange, Color(0xFFFB923C)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _cardWhite, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: _accentOrange.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      size: 15,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Text(
            'Tap to change photo',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _primaryBlue.withValues(alpha: 0.7),
            ),
          ),

          if (_pendingImageFile != null) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: _accentOrange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'New photo selected — save to apply',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _accentOrange,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  SECTION HEADER
  // ═══════════════════════════════════════════════════════════════

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: _primaryBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: _primaryBlue, size: 18),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: _textDark,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  NAME ROW
  // ═══════════════════════════════════════════════════════════════

  Widget _buildNameRow() {
    return Row(
      children: [
        Expanded(
          child: _buildField(
            controller: _firstNameController,
            label: 'First Name',
            hint: 'Juan',
            icon: Icons.person_outline_rounded,
            validator: (val) => (val == null || val.trim().isEmpty)
                ? 'First name is required.'
                : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildField(
            controller: _lastNameController,
            label: 'Last Name',
            hint: 'Dela Cruz',
            icon: Icons.person_outline_rounded,
            validator: (val) => (val == null || val.trim().isEmpty)
                ? 'Last name is required.'
                : null,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  TEXT FIELD
  // ═══════════════════════════════════════════════════════════════

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(label),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          maxLines: maxLines,
          style: const TextStyle(
            fontSize: 15,
            color: _textDark,
            fontWeight: FontWeight.w600,
          ),
          decoration: _inputDecoration(hint: hint, prefixIcon: icon),
          validator: validator,
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  GENDER DROPDOWN
  // ═══════════════════════════════════════════════════════════════

  Widget _buildGenderDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('Gender'),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedGender,
          items: _genders
              .map(
                (g) => DropdownMenuItem(
                  value: g,
                  child: Text(
                    g,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _textDark,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: (val) => setState(() {
            _selectedGender = val;
            _hasUnsavedChanges = true;
          }),
          hint: Text(
            'Select gender',
            style: TextStyle(
              fontSize: 14,
              color: _textMuted.withValues(alpha: 0.6),
              fontWeight: FontWeight.w400,
            ),
          ),
          icon: Icon(
            Icons.expand_more_rounded,
            color: _textMuted.withValues(alpha: 0.6),
          ),
          dropdownColor: _cardWhite,
          elevation: 3,
          isExpanded: true,
          decoration:
              _inputDecoration(
                hint: 'Select gender',
                prefixIcon: Icons.wc_rounded,
              ).copyWith(
                prefixIcon: const Icon(
                  Icons.wc_rounded,
                  color: _textMuted,
                  size: 20,
                ),
              ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  BIO FIELD
  // ═══════════════════════════════════════════════════════════════

  Widget _buildBioField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('About Me'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _bioController,
          maxLines: 4,
          maxLength: 200,
          keyboardType: TextInputType.multiline,
          style: const TextStyle(
            fontSize: 15,
            color: _textDark,
            fontWeight: FontWeight.w500,
            height: 1.5,
          ),
          decoration:
              _inputDecoration(
                hint: 'Write a short description about yourself (optional)...',
              ).copyWith(
                alignLabelWithHint: true,
                counterStyle: TextStyle(
                  fontSize: 11,
                  color: _textMuted.withValues(alpha: 0.6),
                ),
              ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  HELPERS
  // ═══════════════════════════════════════════════════════════════

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: _textDark.withValues(alpha: 0.75),
        letterSpacing: 0.1,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    IconData? prefixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: _textMuted.withValues(alpha: 0.55),
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: _textMuted.withValues(alpha: 0.5), size: 20)
          : null,
      filled: true,
      fillColor: _cardWhite,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _borderGray, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _borderGray, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _primaryBlue, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _errorRed, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _errorRed, width: 2),
      ),
      errorStyle: const TextStyle(
        fontSize: 12,
        color: _errorRed,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
