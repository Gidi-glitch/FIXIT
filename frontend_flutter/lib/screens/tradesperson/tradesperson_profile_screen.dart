import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../login_screen.dart';
import 'settings/tradesperson_edit_profile_screen.dart';
import 'settings/tradesperson_my_documents_screen.dart';
import 'settings/tradesperson_service_area_screen.dart';
import 'view_reviews_screen.dart';

class TradespersonProfileScreen extends StatelessWidget {
  const TradespersonProfileScreen({required this.onDutyNotifier, super.key});

  final ValueNotifier<bool> onDutyNotifier;

  static const Color _primaryBlue = Color(0xFF1E3A8A);
  static const Color _backgroundGray = Color(0xFFF9FAFB);
  static const Color _textDark = Color(0xFF111827);
  static const Color _textMuted = Color(0xFF6B7280);
  static const Color _cardWhite = Color(0xFFFFFFFF);
  static const Color _dangerRed = Color(0xFFEF4444);
  static const Color _successGreen = Color(0xFF10B981);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundGray,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Profile',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: _textDark,
              ),
            ),
            const SizedBox(height: 16),
            _buildIdentityCard(),
            const SizedBox(height: 14),
            _buildOnDutyCard(),
            const SizedBox(height: 14),
            _buildMenuTile(
              context: context,
              icon: Icons.edit_rounded,
              title: 'Edit Profile',
              subtitle: 'Update name, phone, and trade information',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const TradespersonEditProfileScreen(),
                ),
              ),
            ),
            _buildMenuTile(
              context: context,
              icon: Icons.map_rounded,
              title: 'Service Area',
              subtitle: 'Manage covered barangays',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const TradespersonServiceAreaScreen(),
                ),
              ),
            ),
            _buildMenuTile(
              context: context,
              icon: Icons.description_rounded,
              title: 'My Documents',
              subtitle: 'Review submitted files and verification status',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const TradespersonMyDocumentsScreen(),
                ),
              ),
            ),
            _buildMenuTile(
              context: context,
              icon: Icons.star_rounded,
              title: 'View Reviews',
              subtitle: 'See customer feedback and ratings',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ViewReviewsScreen()),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _logout(context),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Logout'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _dangerRed,
                  side: BorderSide(color: _dangerRed.withValues(alpha: 0.35)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIdentityCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _cardWhite,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: _primaryBlue,
            child: Text(
              'TP',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Verified Tradesperson',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _textDark,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Plumbing and home repair services',
                  style: TextStyle(
                    color: _textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOnDutyCard() {
    return ValueListenableBuilder<bool>(
      valueListenable: onDutyNotifier,
      builder: (context, isOnDuty, _) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _cardWhite,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(
                isOnDuty ? Icons.work_rounded : Icons.work_off_rounded,
                color: isOnDuty ? _successGreen : _textMuted,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isOnDuty ? 'You are On-Duty' : 'You are Off-Duty',
                  style: const TextStyle(
                    color: _textDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Switch(
                value: isOnDuty,
                onChanged: (value) => onDutyNotifier.value = value,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        tileColor: _cardWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        leading: CircleAvatar(
          backgroundColor: _primaryBlue.withValues(alpha: 0.1),
          child: Icon(icon, color: _primaryBlue),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(subtitle, style: const TextStyle(color: _textMuted)),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const UserLoginScreen()),
      (route) => false,
    );
  }
}
