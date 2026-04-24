const List<String> kCalauanBarangays = [
  'Balayhangin',
  'Bangyas',
  'Dayap',
  'Hanggan',
  'Imok',
  'Kanluran (Poblacion)',
  'Lamot 1',
  'Lamot 2',
  'Limao',
  'Mabacan',
  'Masiit',
  'Paliparan',
  'Perez',
  'Prinza',
  'San Isidro',
  'Silangan (Poblacion)',
  'Santo Tomas',
];

String normalizeCalauanBarangay(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return '';

  const aliases = {
    'kanluran': 'Kanluran (Poblacion)',
    'silangan': 'Silangan (Poblacion)',
  };

  final lower = trimmed.toLowerCase();
  return aliases[lower] ?? trimmed;
}
