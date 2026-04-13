import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '/../../services/api_service.dart';

/// Edit Profile Screen for the Fix It Marketplace Tradesperson App.
///
/// Updates personal info: name, phone, email, bio, barangay, gender.
/// Also handles profile photo changes.
/// Pops with [true] on save so TradespersonProfileScreen can refresh.
class TradespersonEditProfileScreen extends StatefulWidget {
  const TradespersonEditProfileScreen({super.key});

  @override
  State<TradespersonEditProfileScreen> createState() =>
      _TradespersonEditProfileScreenState();
}

class _TradespersonEditProfileScreenState
    extends State<TradespersonEditProfileScreen> {
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

  static const List<String> _barangays = [
    'Balayhangin', 'Cansuso', 'Dayap', 'Hanggan', 'Imok',
    'Kanlurang Mayao', 'Laguna', 'Lagunat', 'Matuon', 'Palayan',
    'Pansol', 'Silangan Mayao', 'Sucol', 'Turbina', 'Ulango', 'Wawa',
  ];
  static const List<String> _genders = ['Male', 'Female', 'Prefer not to say'];

  // ── Controllers ────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();

  String? _selectedBarangay;
  String? _selectedGender;
  String? _profileImagePath;
  File? _pendingImageFile;
  bool _isUploadingPhoto = false;
  bool _isSaving = false;
  bool _hasChanges = false;

  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadData();
    for (final c in [_firstNameCtrl, _lastNameCtrl, _phoneCtrl, _emailCtrl, _bioCtrl]) {
      c.addListener(_markDirty);
    }
  }

  void _markDirty() { if (!_hasChanges) setState(() => _hasChanges = true); }

  @override
  void dispose() {
    for (final c in [_firstNameCtrl, _lastNameCtrl, _phoneCtrl, _emailCtrl, _bioCtrl]) {
      c.removeListener(_markDirty);
      c.dispose();
    }
    super.dispose();
  }

  // ── Load ────────────────────────────────────────────────────────
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token')?.trim();
    if (token != null && token.isNotEmpty) {
      try {
        final result = await ApiService.getProfile(token);
        final user = (result['user'] as Map?)?.cast<String, dynamic>() ?? {};
        void set(String k, dynamic v) {
          final s = (v ?? '').toString().trim();
          if (s.isNotEmpty) prefs.setString(k, s);
        }
        set('first_name', user['first_name']);
        set('last_name', user['last_name']);
        set('phone', user['phone']);
        set('email', user['email']);
        set('bio', user['bio']);
        set('barangay', user['barangay']);
        set('gender', user['gender']);
        final img = (user['profile_image_url'] ?? '').toString().trim();
        img.isNotEmpty ? prefs.setString('profile_image_url', img) : prefs.remove('profile_image_url');
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() {
      _firstNameCtrl.text = prefs.getString('first_name') ?? '';
      _lastNameCtrl.text = prefs.getString('last_name') ?? '';
      _phoneCtrl.text = prefs.getString('phone') ?? '';
      _emailCtrl.text = prefs.getString('email') ?? '';
      _bioCtrl.text = prefs.getString('bio') ?? '';
      _profileImagePath = prefs.getString('profile_image_url');
      final b = prefs.getString('barangay') ?? '';
      _selectedBarangay = _barangays.contains(b) ? b : null;
      final g = prefs.getString('gender') ?? '';
      _selectedGender = _genders.contains(g) ? g : null;
      _hasChanges = false;
    });
  }

  // ── Avatar ──────────────────────────────────────────────────────
  String get _initials {
    final f = _firstNameCtrl.text.trim();
    final l = _lastNameCtrl.text.trim();
    if (f.isEmpty && l.isEmpty) return 'JD';
    return '${f.isNotEmpty ? f[0] : ''}${l.isNotEmpty ? l[0] : ''}'.toUpperCase();
  }

  Future<void> _pickImage() async {
    final src = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ImageSourceSheet(
        primaryBlue: _primaryBlue, accentOrange: _accentOrange,
        errorRed: _errorRed, cardWhite: _cardWhite, textDark: _textDark,
        textMuted: _textMuted,
        hasPhoto: _profileImagePath != null || _pendingImageFile != null,
        onRemove: () {
          setState(() { _pendingImageFile = null; _profileImagePath = null; _hasChanges = true; });
        },
      ),
    );
    if (src == null) return;
    setState(() => _isUploadingPhoto = true);
    try {
      final picked = await _imagePicker.pickImage(source: src, imageQuality: 88, maxWidth: 1400);
      if (picked == null) return;
      setState(() { _pendingImageFile = File(picked.path); _hasChanges = true; });
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  // ── Save ────────────────────────────────────────────────────────
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token')?.trim();

      if (_pendingImageFile != null && token != null && token.isNotEmpty) {
        final res = await ApiService.uploadProfileImage(token: token, image: _pendingImageFile!);
        final url = (res['profile_image_url'] ?? '').toString().trim();
        if (url.isNotEmpty) await prefs.setString('profile_image_url', url);
      } else if (_profileImagePath == null) {
        await prefs.remove('profile_image_url');
      }

      final payload = {
        'first_name': _firstNameCtrl.text.trim(),
        'last_name': _lastNameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'bio': _bioCtrl.text.trim(),
        'barangay': _selectedBarangay ?? '',
        'gender': _selectedGender ?? '',
      };
      if (token != null && token.isNotEmpty) {
        await ApiService.updateProfile(token: token, data: payload);
      }
      for (final e in payload.entries) {
        if (e.value.isNotEmpty) prefs.setString(e.key, e.value);
      }
      final full = '${_firstNameCtrl.text.trim()} ${_lastNameCtrl.text.trim()}'.trim();
      if (full.isNotEmpty) await prefs.setString('full_name', full);

      if (!mounted) return;
      _showSnack('Profile updated successfully!', _successGreen, Icons.check_circle_rounded);
      setState(() => _hasChanges = false);
      await Future.delayed(const Duration(milliseconds: 350));
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) _showSnack('Failed to save. Please try again.', _errorRed, Icons.error_outline_rounded);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;
    final discard = await showDialog<bool>(
      context: context, barrierDismissible: true,
      builder: (ctx) => _ConfirmDialog(
        icon: Icons.warning_amber_rounded, iconColor: _accentOrange,
        title: 'Discard Changes?',
        message: 'You have unsaved changes. Are you sure you want to leave?',
        confirmLabel: 'Discard', confirmColor: _errorRed,
        cancelLabel: 'Keep Editing',
        cardWhite: _cardWhite, textDark: _textDark, textMuted: _textMuted,
      ),
    );
    return discard ?? false;
  }

  void _showSnack(String msg, Color color, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(icon, color: Colors.white, size: 18), const SizedBox(width: 10),
        Expanded(child: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600))),
      ]),
      backgroundColor: color, behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  // ═══════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) { final ok = await _onWillPop(); if (ok && mounted) Navigator.pop(context); }
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
        child: Scaffold(
          backgroundColor: _backgroundGray,
          body: Column(children: [
            _buildHeader(),
            Expanded(child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _buildAvatarSection(),
                  const SizedBox(height: 28),
                  _sectionHeader('Personal Information', Icons.person_outline_rounded),
                  const SizedBox(height: 14),
                  _buildNameRow(),
                  const SizedBox(height: 14),
                  _buildField(controller: _phoneCtrl, label: 'Phone Number', hint: '+63 9XX XXX XXXX',
                    icon: Icons.phone_outlined, keyboardType: TextInputType.phone,
                    formatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+\- ]'))],
                    validator: (v) { if (v == null || v.trim().isEmpty) return 'Phone is required.';
                      if (v.replaceAll(RegExp(r'[^0-9]'), '').length < 10) return 'Enter a valid phone number.';
                      return null; }),
                  const SizedBox(height: 14),
                  _buildField(controller: _emailCtrl, label: 'Email Address', hint: 'you@example.com',
                    icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress,
                    validator: (v) { if (v == null || v.trim().isEmpty) return 'Email is required.';
                      if (!RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$').hasMatch(v.trim())) return 'Enter a valid email.';
                      return null; }),
                  const SizedBox(height: 28),
                  _sectionHeader('Location', Icons.location_on_outlined),
                  const SizedBox(height: 14),
                  _buildDropdown(label: 'Home Barangay', value: _selectedBarangay,
                    items: _barangays, hint: 'Select your barangay', icon: Icons.home_outlined,
                    onChanged: (v) => setState(() { _selectedBarangay = v; _hasChanges = true; }),
                    validator: (v) => (v == null || v.isEmpty) ? 'Please select your barangay.' : null),
                  const SizedBox(height: 8),
                  _buildHint('Your home barangay — manage your service area separately under "Service Area".'),
                  const SizedBox(height: 28),
                  _sectionHeader('Additional Details', Icons.tune_rounded),
                  const SizedBox(height: 14),
                  _buildDropdown(label: 'Gender', value: _selectedGender,
                    items: _genders, hint: 'Select gender', icon: Icons.wc_rounded,
                    onChanged: (v) => setState(() { _selectedGender = v; _hasChanges = true; })),
                  const SizedBox(height: 14),
                  _buildBioField(),
                  const SizedBox(height: 32),
                  _buildSaveButton(),
                ]),
              ),
            )),
          ]),
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(gradient: LinearGradient(
        colors: [_primaryBlue, Color(0xFF2563EB)],
        begin: Alignment.topLeft, end: Alignment.bottomRight,
      )),
      child: SafeArea(bottom: false, child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 20, 20),
        child: Row(children: [
          IconButton(
            onPressed: () async { final ok = await _onWillPop(); if (ok && mounted) Navigator.pop(context); },
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          ),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Edit Profile', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.4)),
            Text('Update your personal information', style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.7), fontWeight: FontWeight.w500)),
          ])),
          if (_hasChanges)
            TextButton(
              onPressed: _isSaving ? null : _save,
              style: TextButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.15),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSaving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Save', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            ),
        ]),
      )),
    );
  }

  // ── Avatar ──────────────────────────────────────────────────────
  Widget _buildAvatarSection() {
    final hasNet = _profileImagePath != null && _profileImagePath!.startsWith('http');
    final hasLocal = _pendingImageFile != null;
    return Center(child: Column(children: [
      GestureDetector(
        onTap: _pickImage,
        child: Stack(children: [
          Container(
            width: 100, height: 100,
            decoration: BoxDecoration(
              gradient: (!hasNet && !hasLocal) ? const LinearGradient(colors: [_primaryBlue, Color(0xFF3B82F6)], begin: Alignment.topLeft, end: Alignment.bottomRight) : null,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [BoxShadow(color: _primaryBlue.withValues(alpha: 0.25), blurRadius: 20, offset: const Offset(0, 8))],
            ),
            child: ClipRRect(borderRadius: BorderRadius.circular(30), child: hasLocal
              ? Image.file(_pendingImageFile!, fit: BoxFit.cover)
              : hasNet ? Image.network(_profileImagePath!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Center(child: Text(_initials, style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: Colors.white))))
              : Center(child: Text(_initials, style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: Colors.white)))),
          ),
          if (_isUploadingPhoto)
            Positioned.fill(child: Container(decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.45), borderRadius: BorderRadius.circular(30)), child: const Center(child: SizedBox(width: 28, height: 28, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))))),
          Positioned(bottom: 0, right: 0, child: Container(
            width: 32, height: 32,
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [_accentOrange, Color(0xFFFB923C)], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(12), border: Border.all(color: _cardWhite, width: 2.5),
              boxShadow: [BoxShadow(color: _accentOrange.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 3))]),
            child: const Icon(Icons.camera_alt_rounded, size: 15, color: Colors.white),
          )),
        ]),
      ),
      const SizedBox(height: 10),
      Text('Tap to change photo', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _primaryBlue.withValues(alpha: 0.7))),
      if (hasLocal) ...[
        const SizedBox(height: 6),
        Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5), decoration: BoxDecoration(color: _accentOrange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: const Text('New photo selected — save to apply', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _accentOrange))),
      ],
    ]));
  }

  // ── Section header ───────────────────────────────────────────────
  Widget _sectionHeader(String title, IconData icon) {
    return Row(children: [
      Container(width: 34, height: 34, decoration: BoxDecoration(color: _primaryBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: _primaryBlue, size: 18)),
      const SizedBox(width: 10),
      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _textDark, letterSpacing: -0.2)),
    ]);
  }

  // ── Name row ─────────────────────────────────────────────────────
  Widget _buildNameRow() => Row(children: [
    Expanded(child: _buildField(controller: _firstNameCtrl, label: 'First Name', hint: 'Juan', icon: Icons.person_outline_rounded,
      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required.' : null)),
    const SizedBox(width: 12),
    Expanded(child: _buildField(controller: _lastNameCtrl, label: 'Last Name', hint: 'Dela Cruz', icon: Icons.person_outline_rounded,
      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required.' : null)),
  ]);

  // ── Generic text field ────────────────────────────────────────────
  Widget _buildField({required TextEditingController controller, required String label, required String hint, required IconData icon, TextInputType keyboardType = TextInputType.text, List<TextInputFormatter>? formatters, String? Function(String?)? validator, int maxLines = 1}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _fieldLabel(label), const SizedBox(height: 8),
      TextFormField(controller: controller, keyboardType: keyboardType, inputFormatters: formatters, maxLines: maxLines,
        style: const TextStyle(fontSize: 15, color: _textDark, fontWeight: FontWeight.w600),
        decoration: _dec(hint: hint, prefixIcon: icon), validator: validator),
    ]);
  }

  // ── Dropdown field ────────────────────────────────────────────────
  Widget _buildDropdown({required String label, required String? value, required List<String> items, required String hint, required IconData icon, required void Function(String?) onChanged, String? Function(String?)? validator}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _fieldLabel(label), const SizedBox(height: 8),
      DropdownButtonFormField<String>(
        value: value, onChanged: onChanged, dropdownColor: _cardWhite, isExpanded: true,
        decoration: _dec(hint: hint, prefixIcon: icon),
        icon: Icon(Icons.expand_more_rounded, color: _textMuted.withValues(alpha: 0.6)),
        hint: Text(hint, style: TextStyle(fontSize: 14, color: _textMuted.withValues(alpha: 0.6))),
        items: items.map((i) => DropdownMenuItem(value: i, child: Text(i, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _textDark)))).toList(),
        validator: validator,
      ),
    ]);
  }

  // ── Bio field ─────────────────────────────────────────────────────
  Widget _buildBioField() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _fieldLabel('About Me'), const SizedBox(height: 8),
    TextFormField(controller: _bioCtrl, maxLines: 4, maxLength: 250, keyboardType: TextInputType.multiline,
      style: const TextStyle(fontSize: 15, color: _textDark, fontWeight: FontWeight.w500, height: 1.5),
      decoration: _dec(hint: 'Write a short description about yourself (optional)...').copyWith(
        alignLabelWithHint: true, counterStyle: TextStyle(fontSize: 11, color: _textMuted.withValues(alpha: 0.6)))),
  ]);

  Widget _buildHint(String text) => Row(children: [
    Icon(Icons.info_outline_rounded, size: 13, color: _textMuted.withValues(alpha: 0.6)), const SizedBox(width: 6),
    Expanded(child: Text(text, style: TextStyle(fontSize: 12, color: _textMuted.withValues(alpha: 0.75), height: 1.4))),
  ]);

  // ── Save button ───────────────────────────────────────────────────
  Widget _buildSaveButton() => SizedBox(width: double.infinity,
    child: ElevatedButton(
      onPressed: _isSaving ? null : _save,
      style: ElevatedButton.styleFrom(backgroundColor: _primaryBlue, disabledBackgroundColor: _primaryBlue.withValues(alpha: 0.5), foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
      child: AnimatedSwitcher(duration: const Duration(milliseconds: 200), child: _isSaving
        ? const SizedBox(key: ValueKey('l'), width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
        : const Row(key: ValueKey('t'), mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.save_rounded, size: 20), SizedBox(width: 10),
            Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.2)),
          ])),
    ),
  );

  Widget _fieldLabel(String text) => Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _textDark.withValues(alpha: 0.75), letterSpacing: 0.1));

  InputDecoration _dec({required String hint, IconData? prefixIcon}) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: _textMuted.withValues(alpha: 0.55), fontSize: 14, fontWeight: FontWeight.w400),
    prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: _textMuted.withValues(alpha: 0.5), size: 20) : null,
    filled: true, fillColor: _cardWhite,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _borderGray, width: 1.5)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _borderGray, width: 1.5)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _primaryBlue, width: 2)),
    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _errorRed, width: 1.5)),
    focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _errorRed, width: 2)),
    errorStyle: const TextStyle(fontSize: 12, color: _errorRed, fontWeight: FontWeight.w500),
  );
}

// ── Reusable image source sheet ────────────────────────────────────
class _ImageSourceSheet extends StatelessWidget {
  const _ImageSourceSheet({required this.primaryBlue, required this.accentOrange, required this.errorRed, required this.cardWhite, required this.textDark, required this.textMuted, required this.hasPhoto, required this.onRemove});
  final Color primaryBlue, accentOrange, errorRed, cardWhite, textDark, textMuted;
  final bool hasPhoto;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      decoration: BoxDecoration(color: cardWhite, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 30, offset: const Offset(0, -4))]),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 12),
        Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 20),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Text('Change Profile Photo', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: textDark, letterSpacing: -0.3))),
        const SizedBox(height: 16),
        _option(context, Icons.photo_library_rounded, 'Choose from Gallery', primaryBlue, () => Navigator.pop(context, ImageSource.gallery)),
        _option(context, Icons.camera_alt_rounded, 'Take a Photo', accentOrange, () => Navigator.pop(context, ImageSource.camera)),
        if (hasPhoto) _option(context, Icons.delete_outline_rounded, 'Remove Photo', errorRed, () { onRemove(); Navigator.pop(context); }, isDestructive: true),
        const SizedBox(height: 16),
      ]),
    );
  }

  Widget _option(BuildContext ctx, IconData icon, String label, Color color, VoidCallback onTap, {bool isDestructive = false}) {
    return Material(color: Colors.transparent, child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(14), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14), child: Row(children: [
      Container(width: 44, height: 44, decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(13)), child: Icon(icon, color: color, size: 22)),
      const SizedBox(width: 14),
      Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: isDestructive ? errorRed : textDark)),
    ]))));
  }
}

// ── Reusable confirm dialog ────────────────────────────────────────
class _ConfirmDialog extends StatelessWidget {
  const _ConfirmDialog({required this.icon, required this.iconColor, required this.title, required this.message, required this.confirmLabel, required this.confirmColor, required this.cancelLabel, required this.cardWhite, required this.textDark, required this.textMuted});
  final IconData icon; final Color iconColor, confirmColor, cardWhite, textDark, textMuted;
  final String title, message, confirmLabel, cancelLabel;

  @override
  Widget build(BuildContext context) {
    return Dialog(insetPadding: const EdgeInsets.symmetric(horizontal: 28), backgroundColor: Colors.transparent, child: Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(color: cardWhite, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.14), blurRadius: 30, offset: const Offset(0, 12))]),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 56, height: 56, decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(18)), child: Icon(icon, color: iconColor, size: 28)),
        const SizedBox(height: 16),
        Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: textDark, letterSpacing: -0.3)),
        const SizedBox(height: 8),
        Text(message, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textMuted.withValues(alpha: 0.9), height: 1.5)),
        const SizedBox(height: 22),
        Row(children: [
          Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context, false),
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), side: BorderSide(color: textMuted.withValues(alpha: 0.3)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            child: Text(cancelLabel, style: TextStyle(fontWeight: FontWeight.w700, color: textMuted)))),
          const SizedBox(width: 12),
          Expanded(child: ElevatedButton(onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: confirmColor, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            child: Text(confirmLabel, style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white)))),
        ]),
      ]),
    ));
  }
}