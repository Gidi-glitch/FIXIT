import 'package:flutter/material.dart';

class TradespersonMyDocumentsScreen extends StatelessWidget {
  const TradespersonMyDocumentsScreen({super.key});

  static const Color _primaryBlue = Color(0xFF1E3A8A);
  static const Color _backgroundGray = Color(0xFFF9FAFB);
  static const Color _successGreen = Color(0xFF10B981);
  static const Color _warningYellow = Color(0xFFF59E0B);

  @override
  Widget build(BuildContext context) {
    final docs = const [
      ('Government ID', true),
      ('Professional License', true),
      ('Barangay Clearance', false),
      ('Insurance Policy', false),
    ];

    return Scaffold(
      backgroundColor: _backgroundGray,
      appBar: AppBar(
        title: const Text('My Documents'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: docs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final (name, isVerified) = docs[index];
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  isVerified ? Icons.verified_rounded : Icons.pending_rounded,
                  color: isVerified ? _successGreen : _warningYellow,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    foregroundColor: _primaryBlue,
                  ),
                  child: Text(isVerified ? 'View' : 'Upload'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
