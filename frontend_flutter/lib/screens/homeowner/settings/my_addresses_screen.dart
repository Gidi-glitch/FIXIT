import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../services/api_service.dart';

/// My Addresses Screen for the Fix It Marketplace Homeowner App.
///
/// Lets the homeowner manage one or more service addresses.
/// All addresses are locked to Calauan, Laguna.
/// The primary address is used as the default for bookings.
class MyAddressesScreen extends StatefulWidget {
  const MyAddressesScreen({super.key});

  @override
  State<MyAddressesScreen> createState() => _MyAddressesScreenState();
}

// ── Address model ──────────────────────────────────────────────────
class _AddressEntry {
  final String id;
  String label; // Home | Work | Other | custom
  String unit; // Unit / House No.
  String street; // Street / Subdivision
  String barangay;
  bool isPrimary;

  static const String municipality = 'Calauan';
  static const String province = 'Laguna';

  _AddressEntry({
    required this.id,
    required this.label,
    required this.unit,
    required this.street,
    required this.barangay,
    this.isPrimary = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'unit': unit,
    'street': street,
    'barangay': barangay,
    'isPrimary': isPrimary,
  };

  factory _AddressEntry.fromJson(Map<String, dynamic> j) => _AddressEntry(
    id: j['id'] as String,
    label: j['label'] as String,
    unit: j['unit'] as String,
    street: j['street'] as String,
    barangay: j['barangay'] as String,
    isPrimary: j['isPrimary'] as bool? ?? false,
  );

  factory _AddressEntry.fromApi(Map<String, dynamic> j) => _AddressEntry(
    id: (j['id'] ?? '').toString(),
    label: (j['label'] ?? '').toString().trim(),
    unit: (j['unit'] ?? '').toString().trim(),
    street: (j['street'] ?? '').toString().trim(),
    barangay: (j['barangay'] ?? '').toString().trim(),
    isPrimary: j['is_primary'] == true || j['isPrimary'] == true,
  );

  Map<String, dynamic> toApiPayload({bool includePrimary = true}) {
    final payload = <String, dynamic>{
      'label': label,
      'unit': unit,
      'street': street,
      'barangay': barangay,
      'municipality': municipality,
      'province': province,
    };
    if (includePrimary) {
      payload['is_primary'] = isPrimary;
    }
    return payload;
  }

  String get fullAddress {
    final parts = <String>[
      if (unit.trim().isNotEmpty) unit.trim(),
      if (street.trim().isNotEmpty) street.trim(),
      if (barangay.trim().isNotEmpty) 'Brgy. ${barangay.trim()}',
      municipality,
      province,
    ];
    return parts.join(', ');
  }
}

// ── Screen ─────────────────────────────────────────────────────────
class _MyAddressesScreenState extends State<MyAddressesScreen> {
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

  static const String _prefsKey = 'saved_addresses';

  static const List<String> _barangays = [
    'Balayhangin',
    'Bangyas',
    'Dayap',
    'Hanggan',
    'Imok',
    'Kanluran',
    'Lamot 1',
    'Lamot 2',
    'Limao',
    'Mabacan',
    'Masiit',
    'Paliparan',
    'Perez',
    'Prinza',
    'San Isidro',
    'Santo Tomas',
    'Silangan',
  ];

  static const List<String> _labelOptions = ['Home', 'Work', 'Other'];

  List<_AddressEntry> _addresses = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  // ── Persistence ─────────────────────────────────────────────────

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token')?.trim() ?? '';

    if (token.isEmpty) {
      _addresses = _readLocalAddresses(prefs);
      if (!mounted) return;
      setState(() => _isLoading = false);
      return;
    }

    try {
      await _fetchAddressesFromBackend(token);

      if (_addresses.isEmpty) {
        final local = _readLocalAddresses(prefs);
        if (local.isNotEmpty) {
          await _migrateLocalAddressesToBackend(
            prefs: prefs,
            token: token,
            localAddresses: local,
          );
          await _fetchAddressesFromBackend(token);
        }
      }

      await _cachePrimaryBarangay();
    } catch (_) {
      _addresses = _readLocalAddresses(prefs);
      if (mounted) {
        _showSnack(
          'Unable to reach server. Showing saved local addresses.',
          _accentOrange,
        );
      }
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  // ── Helpers ─────────────────────────────────────────────────────

  List<_AddressEntry> _readLocalAddresses(SharedPreferences prefs) {
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) {
      return [];
    }

    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => _AddressEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _migrateLocalAddressesToBackend({
    required SharedPreferences prefs,
    required String token,
    required List<_AddressEntry> localAddresses,
  }) async {
    for (final address in localAddresses) {
      if (address.street.trim().isEmpty || address.barangay.trim().isEmpty) {
        continue;
      }
      await ApiService.createMyAddress(
        token: token,
        data: address.toApiPayload(includePrimary: true),
      );
    }
    await prefs.remove(_prefsKey);
  }

  Future<void> _fetchAddressesFromBackend(String token) async {
    final result = await ApiService.getMyAddresses(token: token);
    final rawRows = result['addresses'];

    final rows = (rawRows is List)
        ? rawRows
              .whereType<Map>()
              .map((e) => e.cast<String, dynamic>())
              .toList()
        : <Map<String, dynamic>>[];

    _addresses = rows.map(_AddressEntry.fromApi).toList();
  }

  Future<void> _cachePrimaryBarangay() async {
    if (_addresses.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final primary = _addresses.firstWhere(
      (a) => a.isPrimary,
      orElse: () => _addresses.first,
    );
    if (primary.barangay.trim().isNotEmpty) {
      await prefs.setString('barangay', primary.barangay.trim());
    }
  }

  int? _parseAddressId(String id) {
    final parsed = int.tryParse(id.trim());
    return parsed != null && parsed > 0 ? parsed : null;
  }

  Future<String> _requireToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token')?.trim() ?? '';
    if (token.isEmpty) {
      throw Exception('Session expired. Please log in again.');
    }
    return token;
  }

  Future<void> _saveAddress(
    _AddressEntry entry, {
    _AddressEntry? existing,
  }) async {
    final token = await _requireToken();

    setState(() => _isSaving = true);
    try {
      if (existing == null) {
        await ApiService.createMyAddress(
          token: token,
          data: entry.toApiPayload(includePrimary: true),
        );
      } else {
        final addressId = _parseAddressId(existing.id);
        if (addressId == null) {
          throw Exception('Invalid address id.');
        }
        await ApiService.updateMyAddress(
          token: token,
          addressId: addressId,
          data: entry.toApiPayload(includePrimary: false),
        );
      }

      await _fetchAddressesFromBackend(token);
      await _cachePrimaryBarangay();

      if (!mounted) return;
      setState(() {});
      _showSnack(
        existing != null ? 'Address updated.' : 'Address added.',
        _successGreen,
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _setPrimary(String id) async {
    final addressId = _parseAddressId(id);
    if (addressId == null) {
      _showSnack('Invalid address id.', _errorRed);
      return;
    }

    setState(() => _isSaving = true);
    try {
      final token = await _requireToken();
      await ApiService.setPrimaryMyAddress(token: token, addressId: addressId);
      await _fetchAddressesFromBackend(token);
      await _cachePrimaryBarangay();

      if (!mounted) return;
      setState(() {});
      _showSnack('Primary address updated.', _successGreen);
    } catch (e) {
      if (mounted) {
        _showSnack(e.toString().replaceFirst('Exception: ', ''), _errorRed);
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _deleteAddress(_AddressEntry entry) async {
    if (_addresses.length == 1) {
      _showSnack('You must have at least one address.', _errorRed);
      return;
    }

    final confirmed = await _showDeleteDialog(entry.label);
    if (!confirmed) return;

    final addressId = _parseAddressId(entry.id);
    if (addressId == null) {
      _showSnack('Invalid address id.', _errorRed);
      return;
    }

    setState(() => _isSaving = true);
    try {
      final token = await _requireToken();
      await ApiService.deleteMyAddress(token: token, addressId: addressId);
      await _fetchAddressesFromBackend(token);
      await _cachePrimaryBarangay();

      if (!mounted) return;
      setState(() {});
      _showSnack('Address removed.', _textMuted);
    } catch (e) {
      if (mounted) {
        _showSnack(e.toString().replaceFirst('Exception: ', ''), _errorRed);
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<bool> _showDeleteDialog(String label) async {
    final result = await showDialog<bool>(
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
                  color: _errorRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: _errorRed,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Remove "$label" Address?',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This address will be permanently deleted.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
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
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Remove',
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
    return result ?? false;
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ── Address form bottom sheet ────────────────────────────────────

  void _openAddressSheet({_AddressEntry? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddressFormSheet(
        existing: existing,
        barangays: _barangays,
        labelOptions: _labelOptions,
        onSave: (entry) => _saveAddress(entry, existing: existing),
        primaryBlue: _primaryBlue,
        accentOrange: _accentOrange,
        backgroundGray: _backgroundGray,
        textDark: _textDark,
        textMuted: _textMuted,
        cardWhite: _cardWhite,
        successGreen: _successGreen,
        errorRed: _errorRed,
        borderGray: _borderGray,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: _backgroundGray,
        body: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
                      children: [
                        _buildInfoBanner(),
                        const SizedBox(height: 20),
                        ..._addresses.map((a) => _buildAddressCard(a)),
                        const SizedBox(height: 8),
                        _buildAddButton(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────

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
          padding: const EdgeInsets.fromLTRB(8, 8, 20, 20),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
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
                      'My Addresses',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.4,
                      ),
                    ),
                    Text(
                      '${_addresses.length} saved address${_addresses.length != 1 ? 'es' : ''}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Info banner ─────────────────────────────────────────────────

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _primaryBlue.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _primaryBlue.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: _primaryBlue.withValues(alpha: 0.8),
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'All addresses must be within Calauan, Laguna. '
              'Your primary address is used as the default for bookings.',
              style: TextStyle(
                fontSize: 12,
                color: _primaryBlue.withValues(alpha: 0.85),
                fontWeight: FontWeight.w500,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Address card ─────────────────────────────────────────────────

  Widget _buildAddressCard(_AddressEntry entry) {
    final iconData = entry.label == 'Home'
        ? Icons.home_rounded
        : entry.label == 'Work'
        ? Icons.work_rounded
        : Icons.location_on_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _cardWhite,
        borderRadius: BorderRadius.circular(18),
        border: entry.isPrimary
            ? Border.all(color: _primaryBlue.withValues(alpha: 0.4), width: 1.5)
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
            // ── Top row ─────────────────────────────────────────────
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: entry.isPrimary
                        ? _primaryBlue.withValues(alpha: 0.1)
                        : _textMuted.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    iconData,
                    color: entry.isPrimary ? _primaryBlue : _textMuted,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            entry.label,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: _textDark,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (entry.isPrimary)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: _primaryBlue,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Primary',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Calauan, Laguna',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _textMuted.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                // ── Options menu ────────────────────────────────────
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert_rounded,
                    color: _textMuted.withValues(alpha: 0.6),
                    size: 22,
                  ),
                  color: _cardWhite,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  onSelected: (val) {
                    if (_isSaving) return;
                    if (val == 'edit') _openAddressSheet(existing: entry);
                    if (val == 'primary') _setPrimary(entry.id);
                    if (val == 'delete') _deleteAddress(entry);
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(
                            Icons.edit_rounded,
                            size: 18,
                            color: Color(0xFF1E3A8A),
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Edit',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    if (!entry.isPrimary)
                      const PopupMenuItem(
                        value: 'primary',
                        child: Row(
                          children: [
                            Icon(
                              Icons.star_rounded,
                              size: 18,
                              color: Color(0xFF10B981),
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Set as Primary',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline_rounded,
                            size: 18,
                            color: Color(0xFFEF4444),
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Remove',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFEF4444),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),
            Container(height: 1, color: Colors.grey.shade100),
            const SizedBox(height: 12),

            // ── Address detail ───────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 15,
                  color: _textMuted.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    entry.fullAddress.isNotEmpty
                        ? entry.fullAddress
                        : 'No address details yet — tap Edit to complete.',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: entry.fullAddress.isNotEmpty
                          ? _textMuted.withValues(alpha: 0.85)
                          : _textMuted.withValues(alpha: 0.5),
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),

            // ── Edit shortcut ────────────────────────────────────────
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isSaving
                    ? null
                    : () => _openAddressSheet(existing: entry),
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Edit Address'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _primaryBlue,
                  side: BorderSide(color: _primaryBlue.withValues(alpha: 0.3)),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Add button ───────────────────────────────────────────────────

  Widget _buildAddButton() {
    return ElevatedButton.icon(
      onPressed: _isSaving || _addresses.length >= 5
          ? null
          : () => _openAddressSheet(),
      icon: const Icon(Icons.add_rounded, size: 20),
      label: Text(
        _addresses.length >= 5
            ? 'Max 5 addresses reached'
            : 'Add Another Address',
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: _accentOrange,
        disabledBackgroundColor: _textMuted.withValues(alpha: 0.15),
        foregroundColor: Colors.white,
        disabledForegroundColor: _textMuted,
        elevation: 0,
        minimumSize: const Size(double.infinity, 54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  ADDRESS FORM BOTTOM SHEET
// ══════════════════════════════════════════════════════════════════

class _AddressFormSheet extends StatefulWidget {
  final _AddressEntry? existing;
  final List<String> barangays;
  final List<String> labelOptions;
  final Future<void> Function(_AddressEntry) onSave;
  final Color primaryBlue,
      accentOrange,
      backgroundGray,
      textDark,
      textMuted,
      cardWhite,
      successGreen,
      errorRed,
      borderGray;

  const _AddressFormSheet({
    required this.existing,
    required this.barangays,
    required this.labelOptions,
    required this.onSave,
    required this.primaryBlue,
    required this.accentOrange,
    required this.backgroundGray,
    required this.textDark,
    required this.textMuted,
    required this.cardWhite,
    required this.successGreen,
    required this.errorRed,
    required this.borderGray,
  });

  @override
  State<_AddressFormSheet> createState() => _AddressFormSheetState();
}

class _AddressFormSheetState extends State<_AddressFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _unitCtrl;
  late final TextEditingController _streetCtrl;
  late final TextEditingController _customLabelCtrl;
  String? _selectedBarangay;
  late String _selectedLabel;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _unitCtrl = TextEditingController(text: e?.unit ?? '');
    _streetCtrl = TextEditingController(text: e?.street ?? '');
    _selectedBarangay = widget.barangays.contains(e?.barangay ?? '')
        ? e!.barangay
        : null;
    _selectedLabel = (e != null && widget.labelOptions.contains(e.label))
        ? e.label
        : (e != null ? 'Other' : 'Home');
    _customLabelCtrl = TextEditingController(
      text: (e != null && !widget.labelOptions.contains(e.label))
          ? e.label
          : '',
    );
  }

  @override
  void dispose() {
    _unitCtrl.dispose();
    _streetCtrl.dispose();
    _customLabelCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final label =
        _selectedLabel == 'Other' && _customLabelCtrl.text.trim().isNotEmpty
        ? _customLabelCtrl.text.trim()
        : _selectedLabel;

    final entry = _AddressEntry(
      id:
          widget.existing?.id ??
          'addr_${DateTime.now().millisecondsSinceEpoch}',
      label: label,
      unit: _unitCtrl.text.trim(),
      street: _streetCtrl.text.trim(),
      barangay: _selectedBarangay ?? '',
      isPrimary: widget.existing?.isPrimary ?? false,
    );

    setState(() => _isSubmitting = true);
    try {
      await widget.onSave(entry);
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: widget.errorRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  InputDecoration _dec(String hint, IconData icon) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(
      color: widget.textMuted.withValues(alpha: 0.5),
      fontSize: 14,
      fontWeight: FontWeight.w400,
    ),
    prefixIcon: Icon(
      icon,
      color: widget.textMuted.withValues(alpha: 0.5),
      size: 20,
    ),
    filled: true,
    fillColor: widget.backgroundGray,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: widget.borderGray, width: 1.5),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: widget.borderGray, width: 1.5),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: widget.primaryBlue, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: widget.errorRed, width: 1.5),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: widget.errorRed, width: 2),
    ),
    errorStyle: TextStyle(
      fontSize: 12,
      color: widget.errorRed,
      fontWeight: FontWeight.w500,
    ),
  );

  Widget _label(String text) => Text(
    text,
    style: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: widget.textDark.withValues(alpha: 0.75),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 16),
        decoration: BoxDecoration(
          color: widget.cardWhite,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 30,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Drag handle ────────────────────────────────────
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Title ──────────────────────────────────────────
                Text(
                  isEdit ? 'Edit Address' : 'Add New Address',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: widget.textDark,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'All addresses are within Calauan, Laguna.',
                  style: TextStyle(
                    fontSize: 12,
                    color: widget.textMuted.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 20),

                // ── Label selector ─────────────────────────────────
                _label('Address Label'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [...widget.labelOptions, 'Other'].map((opt) {
                    final isSelected = _selectedLabel == opt;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedLabel = opt),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? widget.primaryBlue
                              : widget.backgroundGray,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? widget.primaryBlue
                                : widget.borderGray,
                          ),
                        ),
                        child: Text(
                          opt,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? Colors.white : widget.textMuted,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                // ── Custom label field ─────────────────────────────
                if (_selectedLabel == 'Other') ...[
                  const SizedBox(height: 12),
                  _label('Custom Label'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _customLabelCtrl,
                    style: TextStyle(
                      fontSize: 15,
                      color: widget.textDark,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: _dec(
                      'e.g. Parents\' House',
                      Icons.label_outline_rounded,
                    ),
                    validator: (val) => (val == null || val.trim().isEmpty)
                        ? 'Enter a custom label.'
                        : null,
                  ),
                ],

                const SizedBox(height: 16),

                // ── Unit / House No. ───────────────────────────────
                _label('Unit / House No. (optional)'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _unitCtrl,
                  style: TextStyle(
                    fontSize: 15,
                    color: widget.textDark,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: _dec('e.g. Blk 4 Lot 12', Icons.tag_rounded),
                ),
                const SizedBox(height: 14),

                // ── Street / Subdivision ───────────────────────────
                _label('Street / Subdivision'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _streetCtrl,
                  style: TextStyle(
                    fontSize: 15,
                    color: widget.textDark,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: _dec(
                    'e.g. Maharlika Highway',
                    Icons.route_rounded,
                  ),
                  validator: (val) => (val == null || val.trim().isEmpty)
                      ? 'Street is required.'
                      : null,
                ),
                const SizedBox(height: 14),

                // ── Barangay ───────────────────────────────────────
                _label('Barangay'),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _selectedBarangay,
                  items: widget.barangays
                      .map(
                        (b) => DropdownMenuItem(
                          value: b,
                          child: Text(
                            b,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: widget.textDark,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (val) => setState(() => _selectedBarangay = val),
                  hint: Text(
                    'Select barangay',
                    style: TextStyle(
                      fontSize: 14,
                      color: widget.textMuted.withValues(alpha: 0.6),
                    ),
                  ),
                  dropdownColor: widget.cardWhite,
                  isExpanded: true,
                  decoration: _dec(
                    'Select barangay',
                    Icons.location_on_outlined,
                  ),
                  validator: (val) => (val == null || val.isEmpty)
                      ? 'Please select a barangay.'
                      : null,
                ),
                const SizedBox(height: 14),

                // ── Fixed fields (read-only) ───────────────────────
                Row(
                  children: [
                    Expanded(child: _buildReadOnly('Municipality', 'Calauan')),
                    const SizedBox(width: 12),
                    Expanded(child: _buildReadOnly('Province', 'Laguna')),
                  ],
                ),

                const SizedBox(height: 24),

                // ── Save button ────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.primaryBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            isEdit ? 'Update Address' : 'Save Address',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReadOnly(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: widget.textMuted.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: widget.borderGray),
          ),
          child: Row(
            children: [
              Icon(
                Icons.lock_outline_rounded,
                size: 16,
                color: widget.textMuted.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: widget.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
