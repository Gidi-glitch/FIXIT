import 'package:flutter/material.dart';

class TradespersonServiceAreaScreen extends StatefulWidget {
  const TradespersonServiceAreaScreen({super.key});

  @override
  State<TradespersonServiceAreaScreen> createState() =>
      _TradespersonServiceAreaScreenState();
}

class _TradespersonServiceAreaScreenState
    extends State<TradespersonServiceAreaScreen> {
  static const Color _primaryBlue = Color(0xFF1E3A8A);
  static const Color _backgroundGray = Color(0xFFF9FAFB);

  final Set<String> _selected = {'Dayap', 'Poblacion'};
  final List<String> _areas = const [
    'Dayap',
    'Poblacion',
    'Mabacan',
    'Bagong Kalsada',
    'Bangyas',
    'Prinza',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundGray,
      appBar: AppBar(
        title: const Text('Service Area'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select barangays where you accept jobs.',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _areas.map((area) {
                  final isSelected = _selected.contains(area);
                  return FilterChip(
                    label: Text(area),
                    selected: isSelected,
                    onSelected: (value) {
                      setState(() {
                        if (value) {
                          _selected.add(area);
                        } else {
                          _selected.remove(area);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Save Service Area'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
