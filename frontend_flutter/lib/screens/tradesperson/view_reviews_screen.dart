import 'package:flutter/material.dart';

class ViewReviewsScreen extends StatelessWidget {
  const ViewReviewsScreen({super.key});

  static const Color _backgroundGray = Color(0xFFF9FAFB);
  static const Color _textDark = Color(0xFF111827);
  static const Color _textMuted = Color(0xFF6B7280);
  static const Color _accentOrange = Color(0xFFF97316);

  @override
  Widget build(BuildContext context) {
    final reviews = const [
      ('Maria Santos', 'Fast response and clean work.', 5),
      ('Rico Mendoza', 'Solved the leak quickly.', 5),
      ('Ana Villanueva', 'Good service, arrived on time.', 4),
    ];

    return Scaffold(
      backgroundColor: _backgroundGray,
      appBar: AppBar(
        title: const Text('Customer Reviews'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: reviews.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final (name, comment, stars) = reviews[index];
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _textDark,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: List.generate(
                    stars,
                    (_) =>
                        const Icon(Icons.star_rounded, size: 16, color: _accentOrange),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  comment,
                  style: const TextStyle(
                    color: _textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
