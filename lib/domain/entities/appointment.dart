class Appointment {
  const Appointment({
    required this.id,
    required this.patientId,
    required this.opticalStoreId,
    required this.timeSlotId,
    required this.status,
    required this.start,
    required this.end,
  });

  final String id;
  final String patientId;
  final String opticalStoreId;
  final String timeSlotId;
  final String status;
  final DateTime start;
  final DateTime end;
}

enum AppointmentStatus { confirmed, pending, cancelled }

extension AppointmentStatusLabel on AppointmentStatus {
  String get label => switch (this) {
        AppointmentStatus.confirmed => 'Confirmada',
        AppointmentStatus.pending => 'Pendiente',
        AppointmentStatus.cancelled => 'Cancelada',
      };

  static AppointmentStatus fromApi(String raw) {
    switch (raw.toUpperCase()) {
      case 'CONFIRMED':
      case 'CONFIRMADA':
      case 'BOOKED':
      case 'SCHEDULED':
        return AppointmentStatus.confirmed;
      case 'CANCELLED':
      case 'CANCELED':
      case 'CANCELADA':
        return AppointmentStatus.cancelled;
      default:
        return AppointmentStatus.pending;
    }
  }
}
