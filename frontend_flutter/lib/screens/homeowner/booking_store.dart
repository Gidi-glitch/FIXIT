/// Simple static store that acts as the shared in-memory booking list.
/// BookingFormScreen writes here; BookingsScreen reads from here.
/// Replace with a proper state-management solution (Riverpod/Provider)
/// once you wire up the Go backend.
library;

class BookingModel {
  final String id;
  final String tradespersonName;
  final String tradespersonAvatar;
  final String trade;
  final String specialization;
  final String problemDescription;
  final String address;
  final String date;
  final String time;
  final double offeredBudget;
  final String
  status; // 'Pending' | 'Accepted' | 'In Progress' | 'Completed' | 'Cancelled'
  final DateTime createdAt;

  const BookingModel({
    required this.id,
    required this.tradespersonName,
    required this.tradespersonAvatar,
    required this.trade,
    required this.specialization,
    required this.problemDescription,
    required this.address,
    required this.date,
    required this.time,
    required this.offeredBudget,
    required this.status,
    required this.createdAt,
  });

  BookingModel copyWith({String? status}) {
    return BookingModel(
      id: id,
      tradespersonName: tradespersonName,
      tradespersonAvatar: tradespersonAvatar,
      trade: trade,
      specialization: specialization,
      problemDescription: problemDescription,
      address: address,
      date: date,
      time: time,
      offeredBudget: offeredBudget,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }
}

class BookingStore {
  BookingStore._();

  static final List<BookingModel> _bookings = [
    // Pre-loaded sample data (mirrors dashboard mock data)
    BookingModel(
      id: 'BK-001',
      tradespersonName: 'Juan Dela Cruz',
      tradespersonAvatar: 'JD',
      trade: 'Plumbing',
      specialization: 'Pipe Repair & Installation',
      problemDescription: 'Pipe leak under the kitchen sink.',
      address: 'Blk 4 Lot 12, Dayap, Calauan',
      date: 'Today',
      time: '2:00 PM',
      offeredBudget: 500,
      status: 'In Progress',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    BookingModel(
      id: 'BK-002',
      tradespersonName: 'Maria Santos',
      tradespersonAvatar: 'MS',
      trade: 'Electrical',
      specialization: 'Wiring & Panel Upgrades',
      problemDescription: 'Electrical wiring check for the living room.',
      address: 'Blk 2 Lot 5, Hanggan, Calauan',
      date: 'Tomorrow',
      time: '9:00 AM',
      offeredBudget: 800,
      status: 'Accepted',
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    BookingModel(
      id: 'BK-003',
      tradespersonName: 'Pedro Reyes',
      tradespersonAvatar: 'PR',
      trade: 'HVAC',
      specialization: 'AC Maintenance & Repair',
      problemDescription: 'AC unit not cooling properly.',
      address: 'Blk 7 Lot 3, Imok, Calauan',
      date: 'Mar 25',
      time: '10:00 AM',
      offeredBudget: 1200,
      status: 'Pending',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  static List<BookingModel> get all => List.unmodifiable(_bookings);

  static void add(BookingModel booking) {
    _bookings.insert(0, booking);
  }

  static void updateStatus(String id, String status) {
    final index = _bookings.indexWhere((b) => b.id == id);
    if (index != -1) {
      _bookings[index] = _bookings[index].copyWith(status: status);
    }
  }
}
