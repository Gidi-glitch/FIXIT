import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service Area Screen for the Fix It Marketplace Tradesperson App.
///
/// The tradesperson selects which Calauan barangays they serve.
/// At least one barangay must always be selected.
/// Selections are persisted in SharedPreferences as a JSON list.
class TradespersonServiceAreaScreen extends StatefulWidget {
  const TradespersonServiceAreaScreen({super.key});

  @override
  State<TradespersonServiceAreaScreen> createState() =>
      _TradespersonServiceAreaScreenState();
}

class _TradespersonServiceAreaScreenState
    extends State<TradespersonServiceAreaScreen> {
  // ── Color Palette ──────────────────────────────────────────────
  static const Color _primaryBlue = Color(0xFF1E3A8A);
  static const Color _backgroundGray = Color(0xFFF9FAFB);
  static const Color _textDark = Color(0xFF111827);
  static const Color _textMuted = Color(0xFF6B7280);
  static const Color _cardWhite = Color(0xFFFFFFFF);
  static const Color _successGreen = Color(0xFF10B981);
  static const Color _errorRed = Color(0xFFEF4444);

  static const String _prefsKey = 'tradesperson_service_barangays';

  static const List<String> _allBarangays = [ 'Balayhangin', 'Bangyas', 'Dayap',
  'Hanggan', 'Imok', 'Kanluran', 'Lamot 1', 'Lamot 2','Limao', 'Mabacan','Masiit', 
  'Paliparan', 'Perez', 'Prinza', 'San Isidro', 'Santo Tomas','Silangan'];

  Set<String> _selected = {};
  bool _isLoading = true;
  bool _isSaving = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null) {
      try {
        final list = (jsonDecode(raw) as List).cast<String>();
        _selected = Set.from(list);
      } catch (_) {}
    }
    // Default: home barangay
    if (_selected.isEmpty) {
      final home = prefs.getString('barangay') ?? '';
      if (_allBarangays.contains(home)) _selected.add(home);
      if (_selected.isEmpty) _selected.add(_allBarangays.first);
    }
    if (!mounted) return;
    setState(() { _isLoading = false; _hasChanges = false; });
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(_selected.toList()));
    setState(() { _isSaving = false; _hasChanges = false; });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Row(children: [
        Icon(Icons.check_circle_rounded, color: Colors.white, size: 18), SizedBox(width: 10),
        Text('Service area saved.', style: TextStyle(fontWeight: FontWeight.w600)),
      ]),
      backgroundColor: _successGreen, behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  void _toggle(String barangay) {
    if (_selected.contains(barangay)) {
      if (_selected.length == 1) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('At least one barangay must be selected.', style: TextStyle(fontWeight: FontWeight.w600)),
          backgroundColor: _errorRed, behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), margin: const EdgeInsets.all(16),
        ));
        return;
      }
      setState(() { _selected.remove(barangay); _hasChanges = true; });
    } else {
      setState(() { _selected.add(barangay); _hasChanges = true; });
    }
  }

  void _selectAll() { setState(() { _selected = Set.from(_allBarangays); _hasChanges = true; }); }
  void _clearAll() {
    if (_selected.length <= 1) return;
    setState(() { _selected = {_selected.first}; _hasChanges = true; });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: _backgroundGray,
        body: Column(children: [
          _buildHeader(),
          Expanded(child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(physics: const BouncingScrollPhysics(), padding: const EdgeInsets.fromLTRB(20, 20, 20, 120), children: [
                _buildInfoBanner(),
                const SizedBox(height: 16),
                _buildSelectionControls(),
                const SizedBox(height: 16),
                _buildGrid(),
              ]),
          ),
        ]),
        floatingActionButton: _hasChanges ? FloatingActionButton.extended(
          onPressed: _isSaving ? null : _save,
          backgroundColor: _primaryBlue,
          elevation: 4,
          icon: _isSaving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)) : const Icon(Icons.save_rounded, color: Colors.white, size: 20),
          label: Text(_isSaving ? 'Saving...' : 'Save Service Area', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
        ) : null,
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(gradient: LinearGradient(colors: [_primaryBlue, Color(0xFF2563EB)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
      child: SafeArea(bottom: false, child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 20, 20),
        child: Row(children: [
          IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20)),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Service Area', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.4)),
            Text('${_selected.length} of ${_allBarangays.length} barangays selected',
              style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.7), fontWeight: FontWeight.w500)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(12)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.location_on_rounded, size: 14, color: Colors.white),
              const SizedBox(width: 4),
              Text('${_selected.length} areas', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
            ]),
          ),
        ]),
      )),
    );
  }

  Widget _buildInfoBanner() => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: _primaryBlue.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(14), border: Border.all(color: _primaryBlue.withValues(alpha: 0.15))),
    child: Row(children: [
      Icon(Icons.info_outline_rounded, color: _primaryBlue.withValues(alpha: 0.8), size: 18), const SizedBox(width: 10),
      Expanded(child: Text('Select the barangays in Calauan, Laguna where you are willing to provide your trade services. Homeowners in these areas can find and book you.',
        style: TextStyle(fontSize: 12, color: _primaryBlue.withValues(alpha: 0.85), fontWeight: FontWeight.w500, height: 1.45))),
    ]),
  );

  Widget _buildSelectionControls() => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: _cardWhite, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3))]),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Quick select', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _textMuted.withValues(alpha: 0.75))),
        const SizedBox(height: 2),
        Text('${_selected.length} barangay${_selected.length != 1 ? 's' : ''} selected', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _textDark)),
      ])),
      OutlinedButton(
        onPressed: _selected.length == _allBarangays.length ? null : _selectAll,
        style: OutlinedButton.styleFrom(foregroundColor: _primaryBlue, side: BorderSide(color: _primaryBlue.withValues(alpha: 0.4)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        child: const Text('All'),
      ),
      const SizedBox(width: 8),
      OutlinedButton(
        onPressed: _selected.length <= 1 ? null : _clearAll,
        style: OutlinedButton.styleFrom(foregroundColor: _errorRed, side: BorderSide(color: _errorRed.withValues(alpha: 0.4)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        child: const Text('Clear'),
      ),
    ]),
  );

  Widget _buildGrid() {
    return GridView.builder(
      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 2.8, mainAxisSpacing: 10, crossAxisSpacing: 10),
      itemCount: _allBarangays.length,
      itemBuilder: (_, i) {
        final b = _allBarangays[i];
        final isSelected = _selected.contains(b);
        return GestureDetector(
          onTap: () => _toggle(b),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? _primaryBlue : _cardWhite,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isSelected ? _primaryBlue : Colors.grey.shade200, width: isSelected ? 1.5 : 1),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isSelected ? 0.08 : 0.04), blurRadius: isSelected ? 10 : 6, offset: const Offset(0, 3))],
            ),
            child: Row(children: [
              AnimatedContainer(duration: const Duration(milliseconds: 180),
                width: 22, height: 22,
                decoration: BoxDecoration(color: isSelected ? Colors.white.withValues(alpha: 0.25) : Colors.grey.shade100, shape: BoxShape.circle),
                child: Icon(isSelected ? Icons.check_rounded : Icons.add_rounded, size: 13, color: isSelected ? Colors.white : _textMuted.withValues(alpha: 0.5))),
              const SizedBox(width: 8),
              Expanded(child: Text(b, style: TextStyle(fontSize: 13, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600, color: isSelected ? Colors.white : _textDark), maxLines: 1, overflow: TextOverflow.ellipsis)),
            ]),
          ),
        );
      },
    );
  }
}