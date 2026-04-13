import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

/// My Documents Screen for the Fix It Marketplace Tradesperson App.
///
/// Shows verification documents (Government ID, Trade License, Phone).
/// Tradesperson can view status and upload a replacement for each doc.
class TradespersonMyDocumentsScreen extends StatefulWidget {
  const TradespersonMyDocumentsScreen({super.key});

  @override
  State<TradespersonMyDocumentsScreen> createState() =>
      _TradespersonMyDocumentsScreenState();
}

class _TradespersonMyDocumentsScreenState
    extends State<TradespersonMyDocumentsScreen> {
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

  final ImagePicker _imagePicker = ImagePicker();
  String? _uploadingDocId;

  // Mock document state — in real app comes from API
  final List<Map<String, dynamic>> _documents = [
    {
      'id': 'gov_id',
      'icon': Icons.badge_rounded,
      'color': const Color(0xFF1E3A8A),
      'title': 'Government ID',
      'subtitle': 'Any valid government-issued ID',
      'status': 'Verified',
      'uploadedOn': 'Feb 10, 2026',
      'expiresOn': null,
      'required': true,
      'localPath': null,
    },
    {
      'id': 'trade_license',
      'icon': Icons.workspace_premium_rounded,
      'color': const Color(0xFF10B981),
      'title': 'Trade License / Certificate',
      'subtitle': 'TESDA NC, PhilSAGA cert, or equivalent',
      'status': 'Verified',
      'uploadedOn': 'Feb 10, 2026',
      'expiresOn': 'Feb 10, 2028',
      'required': true,
      'localPath': null,
    },
  ];

  Future<void> _pickDocument(Map<String, dynamic> doc) async {
    final source = await _showSourceSheet(doc['title'] as String);
    if (source == null) return;

    setState(() => _uploadingDocId = doc['id'] as String);
    try {
      final picked = await _imagePicker.pickImage(source: source, imageQuality: 90, maxWidth: 1800);
      if (picked == null) return;

      await Future.delayed(const Duration(milliseconds: 1200)); // simulate upload
      setState(() {
        final idx = _documents.indexWhere((d) => d['id'] == doc['id']);
        if (idx != -1) {
          _documents[idx] = {
            ..._documents[idx],
            'status': 'Under Review',
            'localPath': picked.path,
            'uploadedOn': 'Just now',
          };
        }
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Row(children: [
          Icon(Icons.cloud_upload_rounded, color: Colors.white, size: 18), SizedBox(width: 10),
          Expanded(child: Text('Document submitted for review.', style: TextStyle(fontWeight: FontWeight.w600))),
        ]),
        backgroundColor: _accentOrange, behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), margin: const EdgeInsets.all(16),
      ));
    } finally {
      if (mounted) setState(() => _uploadingDocId = null);
    }
  }

  Future<ImageSource?> _showSourceSheet(String docTitle) {
    return showModalBottomSheet<ImageSource>(
      context: context, backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        decoration: BoxDecoration(color: _cardWhite, borderRadius: BorderRadius.circular(24)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Text('Upload $docTitle', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _textDark, letterSpacing: -0.3))),
          const SizedBox(height: 6),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Text('Upload a clear, well-lit photo or scan. Blurry images will be rejected.', style: TextStyle(fontSize: 12, color: _textMuted.withValues(alpha: 0.75), fontWeight: FontWeight.w500, height: 1.4))),
          const SizedBox(height: 16),
          _srcOption(Icons.photo_library_rounded, 'Choose from Gallery', _primaryBlue, () => Navigator.pop(context, ImageSource.gallery)),
          _srcOption(Icons.camera_alt_rounded, 'Take a Photo', _accentOrange, () => Navigator.pop(context, ImageSource.camera)),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }

  Widget _srcOption(IconData icon, String label, Color color, VoidCallback onTap) {
    return Material(color: Colors.transparent, child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(14), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14), child: Row(children: [
      Container(width: 44, height: 44, decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(13)), child: Icon(icon, color: color, size: 22)),
      const SizedBox(width: 14),
      Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _textDark)),
    ]))));
  }

  Color _statusColor(String status) => switch (status) {
    'Verified' => _successGreen,
    'Under Review' => _warningYellow,
    'Rejected' => _errorRed,
    _ => _textMuted,
  };

  IconData _statusIcon(String status) => switch (status) {
    'Verified' => Icons.check_circle_rounded,
    'Under Review' => Icons.hourglass_empty_rounded,
    'Rejected' => Icons.cancel_rounded,
    _ => Icons.circle_outlined,
  };

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
            _buildInfoBanner(),
            const SizedBox(height: 20),
            ..._documents.map((doc) => _buildDocCard(doc)),
            const SizedBox(height: 16),
            _buildPhoneVerification(),
            const SizedBox(height: 20),
            _buildRequirementsCard(),
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
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('My Documents', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.4)),
          Text('Verification & credentials', style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.7), fontWeight: FontWeight.w500)),
        ])),
        Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: _successGreen.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(12)),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.shield_rounded, size: 14, color: Colors.white), SizedBox(width: 4),
            Text('Verified', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
          ])),
      ]),
    )),
  );

  Widget _buildInfoBanner() => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: _primaryBlue.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(14), border: Border.all(color: _primaryBlue.withValues(alpha: 0.15))),
    child: Row(children: [
      Icon(Icons.shield_outlined, color: _primaryBlue.withValues(alpha: 0.8), size: 18), const SizedBox(width: 10),
      Expanded(child: Text('Your documents are reviewed by the Fix It team. Verified tradesperson accounts build homeowner trust and receive more bookings.',
        style: TextStyle(fontSize: 12, color: _primaryBlue.withValues(alpha: 0.85), fontWeight: FontWeight.w500, height: 1.45))),
    ]),
  );

  Widget _buildDocCard(Map<String, dynamic> doc) {
    final status = doc['status'] as String;
    final statusColor = _statusColor(status);
    final isUploading = _uploadingDocId == doc['id'];
    final hasNewUpload = doc['localPath'] != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardWhite, borderRadius: BorderRadius.circular(18),
        border: status == 'Under Review' ? Border.all(color: _warningYellow.withValues(alpha: 0.35), width: 1.5) : null,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 14, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Header ──────────────────────────────────────────────
        Row(children: [
          Container(width: 50, height: 50,
            decoration: BoxDecoration(color: (doc['color'] as Color).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(15)),
            child: Icon(doc['icon'] as IconData, color: doc['color'] as Color, size: 24)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(doc['title'] as String, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _textDark)),
            const SizedBox(height: 3),
            Text(doc['subtitle'] as String, style: TextStyle(fontSize: 12, color: _textMuted.withValues(alpha: 0.75), fontWeight: FontWeight.w500)),
          ])),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(_statusIcon(status), size: 12, color: statusColor), const SizedBox(width: 4),
              Text(status, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: statusColor)),
            ])),
        ]),

        const SizedBox(height: 14),
        Container(height: 1, color: Colors.grey.shade100),
        const SizedBox(height: 12),

        // ── Preview / placeholder ────────────────────────────────
        Container(
          height: 120, width: double.infinity,
          decoration: BoxDecoration(
            color: hasNewUpload ? Colors.transparent : _backgroundGray,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: hasNewUpload ? Colors.transparent : Colors.grey.shade200),
          ),
          child: hasNewUpload
            ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(File(doc['localPath'] as String), fit: BoxFit.cover))
            : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(doc['icon'] as IconData, color: _textMuted.withValues(alpha: 0.25), size: 40),
                const SizedBox(height: 8),
                Text('Document on file', style: TextStyle(fontSize: 12, color: _textMuted.withValues(alpha: 0.5), fontWeight: FontWeight.w500)),
              ]),
        ),

        const SizedBox(height: 12),

        // ── Meta info ────────────────────────────────────────────
        Row(children: [
          Icon(Icons.upload_rounded, size: 13, color: _textMuted.withValues(alpha: 0.5)), const SizedBox(width: 5),
          Text('Uploaded: ${doc['uploadedOn']}', style: TextStyle(fontSize: 12, color: _textMuted.withValues(alpha: 0.7), fontWeight: FontWeight.w500)),
          if (doc['expiresOn'] != null) ...[
            const SizedBox(width: 12),
            Icon(Icons.event_available_rounded, size: 13, color: _textMuted.withValues(alpha: 0.5)), const SizedBox(width: 5),
            Text('Expires: ${doc['expiresOn']}', style: TextStyle(fontSize: 12, color: _textMuted.withValues(alpha: 0.7), fontWeight: FontWeight.w500)),
          ],
        ]),

        const SizedBox(height: 14),

        // ── Upload button ────────────────────────────────────────
        SizedBox(width: double.infinity, child: ElevatedButton.icon(
          onPressed: isUploading ? null : () => _pickDocument(doc),
          icon: isUploading
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
            : const Icon(Icons.cloud_upload_rounded, size: 18),
          label: Text(isUploading ? 'Uploading...' : (hasNewUpload ? 'Re-upload Document' : 'Upload New Document')),
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryBlue, foregroundColor: Colors.white, elevation: 0,
            disabledBackgroundColor: _primaryBlue.withValues(alpha: 0.5),
            padding: const EdgeInsets.symmetric(vertical: 13),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
        )),

        if (status == 'Under Review') ...[
          const SizedBox(height: 10),
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: _warningYellow.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: _warningYellow.withValues(alpha: 0.3))),
            child: Row(children: [
              Icon(Icons.hourglass_empty_rounded, size: 14, color: _warningYellow.withValues(alpha: 0.9)), const SizedBox(width: 8),
              Expanded(child: Text('Under review — our team will verify this within 24–48 hours.', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _warningYellow.withValues(alpha: 0.9), height: 1.35))),
            ])),
        ],
      ]),
    );
  }

  Widget _buildPhoneVerification() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: _cardWhite, borderRadius: BorderRadius.circular(18),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))]),
    child: Row(children: [
      Container(width: 50, height: 50, decoration: BoxDecoration(color: _successGreen.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(15)),
        child: const Icon(Icons.phone_android_rounded, color: _successGreen, size: 24)),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Phone Number', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _textDark)),
        const SizedBox(height: 3),
        Text('Used for booking notifications and OTP', style: TextStyle(fontSize: 12, color: _textMuted.withValues(alpha: 0.75), fontWeight: FontWeight.w500)),
      ])),
      Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: _successGreen.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
        child: const Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.check_circle_rounded, size: 12, color: _successGreen), SizedBox(width: 4),
          Text('Verified', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _successGreen)),
        ])),
    ]),
  );

  Widget _buildRequirementsCard() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: _cardWhite, borderRadius: BorderRadius.circular(18),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 32, height: 32, decoration: BoxDecoration(color: _primaryBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(9)), child: const Icon(Icons.info_outline_rounded, color: _primaryBlue, size: 16)),
        const SizedBox(width: 9),
        const Text('Document Requirements', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _textDark)),
      ]),
      const SizedBox(height: 14),
      ...[
        'Photos must be clear, well-lit, and unobstructed.',
        'File formats accepted: JPG, PNG (max 5 MB each).',
        'Government ID must not be expired.',
        'Trade License must show your full name and trade.',
        'Renewal uploads trigger a 24–48 hour re-review.',
        'Contact support if your document is repeatedly rejected.',
      ].map((r) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 6, height: 6, margin: const EdgeInsets.only(top: 5), decoration: BoxDecoration(color: _primaryBlue.withValues(alpha: 0.5), shape: BoxShape.circle)),
        const SizedBox(width: 10),
        Expanded(child: Text(r, style: TextStyle(fontSize: 13, color: _textMuted.withValues(alpha: 0.85), fontWeight: FontWeight.w500, height: 1.4))),
      ]))),
    ]),
  );
}