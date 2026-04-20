import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../services/api_service.dart';

/// Trade & Skills Screen for the Fix It Marketplace Tradesperson App.
///
/// Lets the tradesperson manage their:
///   • Primary trade category
///   • Specializations (multi-select chips)
///   • Years of experience
///   • Hourly / service rate range
///   • Short professional bio visible to homeowners
class TradespersonTradeSkillsScreen extends StatefulWidget {
  const TradespersonTradeSkillsScreen({super.key});

  @override
  State<TradespersonTradeSkillsScreen> createState() =>
      _TradespersonTradeSkillsScreenState();
}

class _TradespersonTradeSkillsScreenState
    extends State<TradespersonTradeSkillsScreen> {
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

  // ── Trade categories with specializations ──────────────────────
  static const Map<String, List<String>> _tradeSpecializations = {
    'Plumbing': [
      'Pipe Repair',
      'Pipe Installation',
      'Drain Cleaning',
      'Faucet Repair',
      'Water Heater',
      'Toilet Repair',
      'Sewage System',
      'Leak Detection',
    ],
    'Electrical': [
      'Wiring',
      'Panel Upgrades',
      'Outlet Installation',
      'Lighting',
      'Circuit Breaker',
      'Grounding',
      'Surge Protection',
      'Electrical Inspection',
    ],
    'HVAC': [
      'AC Installation',
      'AC Maintenance',
      'AC Repair',
      'Refrigerant Recharge',
      'Duct Cleaning',
      'Ventilation',
      'Thermostat',
      'Aircon Cleaning',
    ],
    'Carpentry': [
      'Cabinet Making',
      'Cabinet Repair',
      'Door Installation',
      'Flooring',
      'Roofing',
      'Furniture Repair',
      'Framing',
      'Wood Finishing',
    ],
    'Appliance Repair': [
      'Washing Machine',
      'Refrigerator',
      'Microwave',
      'Electric Fan',
      'Water Dispenser',
      'Rice Cooker',
      'Iron',
      'TV / Electronics',
    ],
  };

  static const List<String> _experienceLevels = [
    '< 1 year',
    '1–2 years',
    '3–5 years',
    '6–10 years',
    '10+ years',
  ];

  static const List<String> _rateRanges = [
    '₱100–₱200 / hr',
    '₱200–₱350 / hr',
    '₱350–₱500 / hr',
    '₱500–₱750 / hr',
    '₱750–₱1,000 / hr',
    '₱1,000+ / hr',
  ];

  // ── Form state ──────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _proBioCtrl = TextEditingController();

  String? _selectedTrade;
  Set<String> _selectedSpecs = {};
  String? _selectedExperience;
  String? _selectedRate;
  bool _isSaving = false;
  bool _hasChanges = false;
  bool _isLoading = true;

  List<String> get _currentSpecs => _tradeSpecializations[_selectedTrade] ?? [];

  @override
  void initState() {
    super.initState();
    _proBioCtrl.addListener(() {
      if (!_hasChanges) setState(() => _hasChanges = true);
    });
    _loadData();
  }

  @override
  void dispose() {
    _proBioCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token')?.trim() ?? '';
      if (token.isEmpty) {
        throw Exception('Session expired. Please log in again.');
      }

      final response = await ApiService.getMyTradeSkills(token: token);
      final data =
          (response['trade_skills'] as Map?)?.cast<String, dynamic>() ??
          <String, dynamic>{};

      final specs = ((data['specializations'] as List?) ?? const [])
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toSet();

      final level = (data['experience_level'] ?? '').toString().trim();
      final yearsRaw = data['years_experience'];
      int? years;
      if (yearsRaw is num) {
        years = yearsRaw.toInt();
      }

      if (!mounted) return;
      setState(() {
        final tradeValue = (data['trade_category'] ?? '').toString().trim();
        final rateValue = (data['rate_range'] ?? '').toString().trim();
        _selectedTrade = tradeValue.isEmpty ? null : tradeValue;
        _selectedExperience = level.isNotEmpty
            ? level
            : _experienceLevelFromYears(years);
        _selectedRate = rateValue.isEmpty ? null : rateValue;
        _proBioCtrl.text = (data['bio'] ?? '').toString();
        _selectedSpecs = specs;
        _isLoading = false;
        _hasChanges = false;
      });
    } catch (e) {
      if (!mounted) return;
      _showSnack(
        e.toString().replaceFirst('Exception: ', ''),
        _errorRed,
        Icons.error_outline_rounded,
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTrade == null) {
      _showSnack(
        'Please select a trade category.',
        _errorRed,
        Icons.error_outline_rounded,
      );
      return;
    }
    if (_selectedSpecs.isEmpty) {
      _showSnack(
        'Please select at least one specialization.',
        _errorRed,
        Icons.error_outline_rounded,
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token')?.trim() ?? '';
      if (token.isEmpty) {
        throw Exception('Session expired. Please log in again.');
      }

      await ApiService.saveMyTradeSkills(
        token: token,
        data: {
          'trade_category': _selectedTrade,
          'specializations': _selectedSpecs.toList(),
          'experience_level': _selectedExperience,
          'years_experience': _yearsFromExperienceLevel(_selectedExperience),
          'rate_range': _selectedRate,
          'bio': _proBioCtrl.text.trim(),
        },
      );

      setState(() {
        _hasChanges = false;
      });
      if (!mounted) return;
      _showSnack(
        'Trade & Skills updated!',
        _successGreen,
        Icons.check_circle_rounded,
      );
      await Future.delayed(const Duration(milliseconds: 350));
      if (mounted) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String? _experienceLevelFromYears(int? years) {
    if (years == null) return null;
    if (years <= 0) return '< 1 year';
    if (years <= 2) return '1–2 years';
    if (years <= 5) return '3–5 years';
    if (years <= 10) return '6–10 years';
    return '10+ years';
  }

  int _yearsFromExperienceLevel(String? level) {
    switch (level) {
      case '< 1 year':
        return 0;
      case '1–2 years':
        return 2;
      case '3–5 years':
        return 5;
      case '6–10 years':
        return 10;
      case '10+ years':
        return 11;
      default:
        return 0;
    }
  }

  void _onTradeChanged(String? trade) {
    setState(() {
      _selectedTrade = trade;
      _selectedSpecs = {};
      _hasChanges = true;
    });
  }

  void _toggleSpec(String spec) {
    setState(() {
      _selectedSpecs.contains(spec)
          ? _selectedSpecs.remove(spec)
          : _selectedSpecs.add(spec);
      _hasChanges = true;
    });
  }

  void _showSnack(String msg, Color color, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                msg,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: color,
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
                  : Form(
                      key: _formKey,
                      child: ListView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
                        children: [
                          // ── Trade Category ───────────────────────────────
                          _sectionHeader(
                            'Primary Trade',
                            Icons.build_rounded,
                            _primaryBlue,
                          ),
                          const SizedBox(height: 14),
                          _buildTradeCards(),
                          const SizedBox(height: 24),

                          // ── Specializations ──────────────────────────────
                          _sectionHeader(
                            'Specializations',
                            Icons.tune_rounded,
                            _accentOrange,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _selectedTrade == null
                                ? 'Select a trade category above first.'
                                : 'Select all that apply.',
                            style: TextStyle(
                              fontSize: 13,
                              color: _textMuted.withValues(alpha: 0.75),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 14),
                          _buildSpecChips(),
                          const SizedBox(height: 24),

                          // ── Experience & Rate ────────────────────────────
                          _sectionHeader(
                            'Experience & Rate',
                            Icons.workspace_premium_rounded,
                            _successGreen,
                          ),
                          const SizedBox(height: 14),
                          _buildDropdownCard(
                            'Years of Experience',
                            _selectedExperience,
                            _experienceLevels,
                            Icons.timeline_rounded,
                            (v) => setState(() {
                              _selectedExperience = v;
                              _hasChanges = true;
                            }),
                          ),
                          const SizedBox(height: 12),
                          _buildDropdownCard(
                            'Service Rate Range',
                            _selectedRate,
                            _rateRanges,
                            Icons.payments_outlined,
                            (v) => setState(() {
                              _selectedRate = v;
                              _hasChanges = true;
                            }),
                          ),
                          const SizedBox(height: 24),

                          // ── Professional Bio ─────────────────────────────
                          _sectionHeader(
                            'Professional Bio',
                            Icons.description_outlined,
                            const Color(0xFF8B5CF6),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'This appears on your public profile and helps homeowners decide to book you.',
                            style: TextStyle(
                              fontSize: 13,
                              color: _textMuted.withValues(alpha: 0.75),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 14),
                          _buildProBio(),
                          const SizedBox(height: 32),
                          _buildSaveButton(),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() => Container(
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
                    'Trade & Skills',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.4,
                    ),
                  ),
                  Text(
                    'Update your professional expertise',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (_hasChanges)
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

  Widget _sectionHeader(String title, IconData icon, Color color) => Row(
    children: [
      Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 18),
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

  Widget _buildTradeCards() {
    final trades = _tradeSpecializations.keys.toList();
    final icons = [
      Icons.plumbing_rounded,
      Icons.electrical_services_rounded,
      Icons.ac_unit_rounded,
      Icons.carpenter_rounded,
      Icons.kitchen_rounded,
    ];
    final colors = [
      const Color(0xFF3B82F6),
      const Color(0xFFF59E0B),
      const Color(0xFF06B6D4),
      const Color(0xFF8B5CF6),
      const Color(0xFFEC4899),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.4,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      itemCount: trades.length,
      itemBuilder: (_, i) {
        final trade = trades[i];
        final isSelected = _selectedTrade == trade;
        return GestureDetector(
          onTap: () => _onTradeChanged(trade),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? colors[i] : _cardWhite,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? colors[i] : Colors.grey.shade200,
                width: isSelected ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? colors[i].withValues(alpha: 0.25)
                      : Colors.black.withValues(alpha: 0.04),
                  blurRadius: isSelected ? 12 : 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  icons[i],
                  color: isSelected ? Colors.white : colors[i],
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    trade,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : _textDark,
                    ),
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSpecChips() {
    if (_selectedTrade == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _cardWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(
              Icons.touch_app_rounded,
              color: _textMuted.withValues(alpha: 0.4),
              size: 20,
            ),
            const SizedBox(width: 10),
            Text(
              'Select a trade category above',
              style: TextStyle(
                fontSize: 13,
                color: _textMuted.withValues(alpha: 0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _currentSpecs.map((spec) {
        final isSelected = _selectedSpecs.contains(spec);
        return GestureDetector(
          onTap: () => _toggleSpec(spec),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: isSelected ? _primaryBlue : _cardWhite,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? _primaryBlue : _borderGray,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSelected) ...[
                  const Icon(
                    Icons.check_rounded,
                    size: 13,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 5),
                ],
                Text(
                  spec,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : _textDark,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDropdownCard(
    String label,
    String? value,
    List<String> items,
    IconData icon,
    void Function(String?) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 4),
      decoration: BoxDecoration(
        color: _cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borderGray, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          onChanged: onChanged,
          isExpanded: true,
          dropdownColor: _cardWhite,
          icon: Icon(
            Icons.expand_more_rounded,
            color: _textMuted.withValues(alpha: 0.6),
          ),
          hint: Row(
            children: [
              Icon(icon, size: 18, color: _textMuted.withValues(alpha: 0.5)),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: _textMuted.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          selectedItemBuilder: (_) => items
              .map(
                (i) => Row(
                  children: [
                    Icon(icon, size: 18, color: _primaryBlue),
                    const SizedBox(width: 10),
                    Text(
                      i,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _textDark,
                      ),
                    ),
                  ],
                ),
              )
              .toList(),
          items: items
              .map(
                (i) => DropdownMenuItem(
                  value: i,
                  child: Text(
                    i,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _textDark,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildProBio() => TextFormField(
    controller: _proBioCtrl,
    maxLines: 5,
    maxLength: 300,
    keyboardType: TextInputType.multiline,
    style: const TextStyle(
      fontSize: 15,
      color: _textDark,
      fontWeight: FontWeight.w500,
      height: 1.5,
    ),
    decoration: InputDecoration(
      hintText:
          'Tell homeowners about your expertise, tools you use, and why they should choose you...',
      hintStyle: TextStyle(
        color: _textMuted.withValues(alpha: 0.5),
        fontSize: 13,
        fontWeight: FontWeight.w400,
      ),
      filled: true,
      fillColor: _cardWhite,
      alignLabelWithHint: true,
      counterStyle: TextStyle(
        fontSize: 11,
        color: _textMuted.withValues(alpha: 0.6),
      ),
      contentPadding: const EdgeInsets.all(16),
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
    ),
  );

  Widget _buildSaveButton() => SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: _isSaving ? null : _save,
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryBlue,
        disabledBackgroundColor: _primaryBlue.withValues(alpha: 0.5),
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: _isSaving
            ? const SizedBox(
                key: ValueKey('l'),
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : const Row(
                key: ValueKey('t'),
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.save_rounded, size: 20),
                  SizedBox(width: 10),
                  Text(
                    'Save Trade & Skills',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
      ),
    ),
  );
}
