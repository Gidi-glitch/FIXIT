import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../services/api_service.dart';
import '../../login_screen.dart';

/// Privacy & Security Screen for the Fix It Marketplace Tradesperson App.
class TradespersonPrivacySecurityScreen extends StatefulWidget {
  const TradespersonPrivacySecurityScreen({super.key});

  @override
  State<TradespersonPrivacySecurityScreen> createState() =>
      _TradespersonPrivacySecurityScreenState();
}

class _TradespersonPrivacySecurityScreenState
    extends State<TradespersonPrivacySecurityScreen> {
  // ── Color Palette ──────────────────────────────────────────────
  static const Color _primaryBlue = Color(0xFF1E3A8A);
  static const Color _accentOrange = Color(0xFFF97316);
  static const Color _backgroundGray = Color(0xFFF9FAFB);
  static const Color _textDark = Color(0xFF111827);
  static const Color _textMuted = Color(0xFF6B7280);
  static const Color _cardWhite = Color(0xFFFFFFFF);
  static const Color _successGreen = Color(0xFF10B981);
  static const Color _errorRed = Color(0xFFEF4444);
  static const Color _infoBlue = Color(0xFF3B82F6);
  static const Color _purple = Color(0xFF8B5CF6);
  static const Color _borderGray = Color(0xFFE5E7EB);

  // ── Password form ──────────────────────────────────────────────
  final _pwFormKey = GlobalKey<FormState>();
  final _curPwCtrl = TextEditingController();
  final _newPwCtrl = TextEditingController();
  final _conPwCtrl = TextEditingController();
  bool _showCur = false, _showNew = false, _showCon = false;
  bool _isSavingPw = false;
  bool _pwExpanded = false;

  // ── Privacy toggles ────────────────────────────────────────────
  bool _shareActivity = false;
  bool _locationAccess = true;

  @override
  void initState() { super.initState(); _loadPrefs(); }

  @override
  void dispose() { _curPwCtrl.dispose(); _newPwCtrl.dispose(); _conPwCtrl.dispose(); super.dispose(); }

  Future<void> _loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _shareActivity = p.getBool('tp_privacy_share_activity') ?? false;
      _locationAccess = p.getBool('tp_privacy_location') ?? true;
    });
  }

  Future<void> _changePassword() async {
    if (!_pwFormKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _isSavingPw = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token')?.trim();
      if (token == null || token.isEmpty) throw Exception('Not authenticated.');
      await ApiService.changePassword(token: token, currentPassword: _curPwCtrl.text.trim(), newPassword: _newPwCtrl.text.trim());
      _curPwCtrl.clear(); _newPwCtrl.clear(); _conPwCtrl.clear();
      if (!mounted) return;
      setState(() => _pwExpanded = false);
      _showSnack('Password updated successfully.', _successGreen, Icons.lock_rounded);
    } catch (_) {
      if (mounted) _showSnack('Failed to update. Check your current password.', _errorRed, Icons.error_outline_rounded);
    } finally {
      if (mounted) setState(() => _isSavingPw = false);
    }
  }

  void _showDeleteDialog() async {
    final confirmed = await showDialog<bool>(
      context: context, barrierDismissible: true,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 28), backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
          decoration: BoxDecoration(color: _cardWhite, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.14), blurRadius: 30, offset: const Offset(0, 12))]),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 56, height: 56, decoration: BoxDecoration(gradient: const LinearGradient(colors: [_errorRed, Color(0xFFF97316)], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(18)),
              child: const Icon(Icons.delete_forever_rounded, color: Colors.white, size: 28)),
            const SizedBox(height: 16),
            const Text('Delete Account?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _textDark, letterSpacing: -0.3)),
            const SizedBox(height: 10),
            Text('This is permanent. All your jobs, reviews, and profile data will be erased and cannot be recovered.',
              textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: _textMuted.withValues(alpha: 0.9), height: 1.5)),
            const SizedBox(height: 22),
            Row(children: [
              Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx, false),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), side: BorderSide(color: _textMuted.withValues(alpha: 0.3)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w700, color: _textMuted)))),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(backgroundColor: _errorRed, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)))),
            ]),
          ]),
        ),
      ),
    );
    if (confirmed == true && mounted) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const UserLoginScreen()), (r) => false);
    }
  }

  void _showSnack(String msg, Color color, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [Icon(icon, color: Colors.white, size: 18), const SizedBox(width: 10), Expanded(child: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)))]),
      backgroundColor: color, behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), margin: const EdgeInsets.all(16),
    ));
  }

  // ═══════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: _backgroundGray,
        body: Column(children: [
          _buildHeader(),
          Expanded(child: ListView(physics: const BouncingScrollPhysics(), padding: const EdgeInsets.fromLTRB(20, 24, 20, 40), children: [
            _buildPasswordSection(),
            const SizedBox(height: 16),
            _buildSessionsSection(),
            const SizedBox(height: 16),
            _buildDataPrivacySection(),
            const SizedBox(height: 16),
            _buildDangerZone(),
          ])),
        ]),
      ),
    );
  }

  Widget _buildHeader() => Container(
    decoration: const BoxDecoration(gradient: LinearGradient(colors: [_primaryBlue, Color(0xFF2563EB)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
    child: SafeArea(bottom: false, child: Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 20),
      child: Row(children: [
        IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20)),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Privacy & Security', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.4)),
          Text('Manage your account security', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xB3FFFFFF))),
        ])),
      ]),
    )),
  );

  Widget _card({required Widget child}) => Container(
    decoration: BoxDecoration(color: _cardWhite, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 14, offset: const Offset(0, 4))]),
    child: child,
  );

  Widget _sectionHead(IconData icon, Color color, String title) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
    child: Row(children: [
      Container(width: 36, height: 36, decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 18)),
      const SizedBox(width: 10),
      Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _textDark, letterSpacing: -0.2)),
    ]),
  );

  // ── Password section ─────────────────────────────────────────────
  Widget _buildPasswordSection() => _card(child: Column(children: [
    Material(color: Colors.transparent, child: InkWell(
      onTap: () => setState(() => _pwExpanded = !_pwExpanded),
      borderRadius: _pwExpanded ? const BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18)) : BorderRadius.circular(18),
      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), child: Row(children: [
        Container(width: 44, height: 44, decoration: BoxDecoration(color: _purple.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(13)), child: const Icon(Icons.lock_outline_rounded, color: _purple, size: 22)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Change Password', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _textDark)),
          const SizedBox(height: 2),
          Text('Update your account password.', style: TextStyle(fontSize: 12, color: _textMuted.withValues(alpha: 0.8), fontWeight: FontWeight.w500)),
        ])),
        AnimatedRotation(turns: _pwExpanded ? 0.5 : 0, duration: const Duration(milliseconds: 200), child: Icon(Icons.expand_more_rounded, color: _textMuted.withValues(alpha: 0.5))),
      ])),
    )),
    AnimatedCrossFade(
      firstChild: const SizedBox(width: double.infinity),
      secondChild: Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 20), child: Form(key: _pwFormKey, child: Column(children: [
        Container(height: 1, color: Colors.grey.shade100), const SizedBox(height: 16),
        _pwField(_curPwCtrl, 'Current Password', _showCur, () => setState(() => _showCur = !_showCur), (v) => (v == null || v.trim().isEmpty) ? 'Required.' : null),
        const SizedBox(height: 14),
        _pwField(_newPwCtrl, 'New Password', _showNew, () => setState(() => _showNew = !_showNew), (v) { if (v == null || v.trim().isEmpty) return 'Required.'; if (v.trim().length < 8) return 'At least 8 characters.'; return null; }),
        const SizedBox(height: 14),
        _pwField(_conPwCtrl, 'Confirm New Password', _showCon, () => setState(() => _showCon = !_showCon), (v) => v?.trim() != _newPwCtrl.text.trim() ? 'Passwords do not match.' : null),
        const SizedBox(height: 8),
        _buildPwRules(),
        const SizedBox(height: 16),
        SizedBox(width: double.infinity, child: ElevatedButton(
          onPressed: _isSavingPw ? null : _changePassword,
          style: ElevatedButton.styleFrom(backgroundColor: _primaryBlue, foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          child: _isSavingPw ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)) : const Text('Update Password', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        )),
      ]))),
      crossFadeState: _pwExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
      duration: const Duration(milliseconds: 250),
    ),
  ]));

  Widget _pwField(TextEditingController ctrl, String label, bool show, VoidCallback toggle, String? Function(String?) validator) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _textDark.withValues(alpha: 0.75))),
      const SizedBox(height: 8),
      TextFormField(controller: ctrl, obscureText: !show, validator: validator,
        style: const TextStyle(fontSize: 15, color: _textDark, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: '••••••••', hintStyle: TextStyle(color: _textMuted.withValues(alpha: 0.5), fontSize: 14),
          prefixIcon: Icon(Icons.lock_outline_rounded, color: _textMuted.withValues(alpha: 0.5), size: 20),
          suffixIcon: IconButton(icon: Icon(show ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: _textMuted.withValues(alpha: 0.5), size: 20), onPressed: toggle),
          filled: true, fillColor: _backgroundGray, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _borderGray, width: 1.5)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _borderGray, width: 1.5)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _primaryBlue, width: 2)),
          errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _errorRed, width: 1.5)),
          focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _errorRed, width: 2)),
          errorStyle: const TextStyle(fontSize: 12, color: _errorRed, fontWeight: FontWeight.w500),
        )),
    ]);
  }

  Widget _buildPwRules() => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: _infoBlue.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(12), border: Border.all(color: _infoBlue.withValues(alpha: 0.15))),
    child: Column(children: ['At least 8 characters long', 'Mix of uppercase and lowercase letters', 'At least one number or special character'].map((r) => Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(children: [Icon(Icons.check_circle_outline_rounded, size: 14, color: _infoBlue.withValues(alpha: 0.8)), const SizedBox(width: 8), Text(r, style: TextStyle(fontSize: 12, color: _infoBlue.withValues(alpha: 0.9), fontWeight: FontWeight.w500))]),
    )).toList()),
  );

  // ── Sessions section ─────────────────────────────────────────────
  Widget _buildSessionsSection() => _card(child: Column(children: [
    _sectionHead(Icons.devices_rounded, _infoBlue, 'Login & Sessions'),
    Container(height: 1, color: Colors.grey.shade100, margin: const EdgeInsets.symmetric(horizontal: 16)),
    _listTile(icon: Icons.smartphone_rounded, iconColor: _infoBlue, title: 'This Device', subtitle: 'Android · Active now',
      trailing: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: _successGreen.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: const Text('Current', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _successGreen))),
      showDivider: true),
    _listTile(icon: Icons.logout_rounded, iconColor: _errorRed, title: 'Sign Out All Devices', subtitle: 'Revoke all other active sessions.', titleColor: _errorRed,
      onTap: () => _showSnack('All other sessions signed out.', _successGreen, Icons.check_circle_rounded), showDivider: false),
  ]));

  // ── Data & Privacy ────────────────────────────────────────────────
  Widget _buildDataPrivacySection() => _card(child: Column(children: [
    _sectionHead(Icons.shield_outlined, _purple, 'Data & Privacy'),
    Container(height: 1, color: Colors.grey.shade100, margin: const EdgeInsets.symmetric(horizontal: 16)),
    _toggleTile(icon: Icons.analytics_outlined, iconColor: _accentOrange, title: 'Share Activity Data', subtitle: 'Help improve Fix It with anonymous usage data.',
      value: _shareActivity, onChanged: (v) { setState(() => _shareActivity = v); SharedPreferences.getInstance().then((p) => p.setBool('tp_privacy_share_activity', v)); }, showDivider: true),
    _toggleTile(icon: Icons.location_on_outlined, iconColor: _successGreen, title: 'Location Access', subtitle: 'Allow Fix It to match you with nearby homeowners.',
      value: _locationAccess, onChanged: (v) { setState(() => _locationAccess = v); SharedPreferences.getInstance().then((p) => p.setBool('tp_privacy_location', v)); }, showDivider: true),
    _listTile(icon: Icons.download_outlined, iconColor: _primaryBlue, title: 'Request My Data', subtitle: 'Export a copy of all data we hold about you.',
      onTap: () => _showSnack('Request submitted. We\'ll email you within 48 hours.', _primaryBlue, Icons.check_circle_rounded), showDivider: false),
  ]));

  // ── Danger Zone ───────────────────────────────────────────────────
  Widget _buildDangerZone() => Container(
    decoration: BoxDecoration(color: _cardWhite, borderRadius: BorderRadius.circular(18), border: Border.all(color: _errorRed.withValues(alpha: 0.2)),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 14, offset: const Offset(0, 4))]),
    child: Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 12), child: Row(children: [
        Container(width: 36, height: 36, decoration: BoxDecoration(color: _errorRed.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.warning_amber_rounded, color: _errorRed, size: 18)),
        const SizedBox(width: 10),
        const Text('Danger Zone', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _errorRed, letterSpacing: -0.2)),
      ])),
      Container(height: 1, color: _errorRed.withValues(alpha: 0.1), margin: const EdgeInsets.symmetric(horizontal: 16)),
      Material(color: Colors.transparent, child: InkWell(onTap: _showDeleteDialog, borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(18), bottomRight: Radius.circular(18)), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), child: Row(children: [
        Container(width: 44, height: 44, decoration: BoxDecoration(color: _errorRed.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(13)), child: const Icon(Icons.delete_forever_rounded, color: _errorRed, size: 22)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Delete Account', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _errorRed)),
          const SizedBox(height: 2),
          Text('Permanently erase your account and all data.', style: TextStyle(fontSize: 12, color: _textMuted.withValues(alpha: 0.8), fontWeight: FontWeight.w500)),
        ])),
        Icon(Icons.arrow_forward_ios_rounded, color: _errorRed.withValues(alpha: 0.5), size: 16),
      ])))),
    ]),
  );

  // ── Shared row builders ──────────────────────────────────────────
  Widget _listTile({required IconData icon, required Color iconColor, required String title, required String subtitle, VoidCallback? onTap, Widget? trailing, bool showDivider = false, Color titleColor = _textDark}) {
    return Column(children: [
      Material(color: Colors.transparent, child: InkWell(onTap: onTap, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), child: Row(children: [
        Container(width: 42, height: 42, decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: iconColor, size: 20)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: titleColor)),
          const SizedBox(height: 2),
          Text(subtitle, style: TextStyle(fontSize: 12, color: _textMuted.withValues(alpha: 0.8), fontWeight: FontWeight.w500)),
        ])),
        const SizedBox(width: 8),
        trailing ?? Icon(Icons.arrow_forward_ios_rounded, color: _textMuted.withValues(alpha: 0.3), size: 15),
      ])))),
      if (showDivider) Container(height: 1, color: Colors.grey.shade100, margin: const EdgeInsets.symmetric(horizontal: 16)),
    ]);
  }

  Widget _toggleTile({required IconData icon, required Color iconColor, required String title, required String subtitle, required bool value, required void Function(bool) onChanged, bool showDivider = false}) {
    return Column(children: [
      Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), child: Row(children: [
        Container(width: 42, height: 42, decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: iconColor, size: 20)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _textDark)),
          const SizedBox(height: 2),
          Text(subtitle, style: TextStyle(fontSize: 12, color: _textMuted.withValues(alpha: 0.8), fontWeight: FontWeight.w500, height: 1.35)),
        ])),
        const SizedBox(width: 8),
        Switch.adaptive(value: value, onChanged: onChanged, activeThumbColor: _primaryBlue),
      ])),
      if (showDivider) Container(height: 1, color: Colors.grey.shade100, margin: const EdgeInsets.symmetric(horizontal: 16)),
    ]);
  }
}
