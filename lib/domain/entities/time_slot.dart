class TimeSlot {
  const TimeSlot({
    required this.id,
    required this.opticalStoreId,
    required this.start,
    required this.end,
    required this.status,
  });

  final String id;
  final String opticalStoreId;
  final DateTime start;
  final DateTime end;
  final String status;
}
