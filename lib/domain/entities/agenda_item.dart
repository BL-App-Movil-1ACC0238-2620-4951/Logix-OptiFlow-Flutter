enum AgendaStatus { waiting, confirmed, pending, pickup, done }

class AgendaItem {
  const AgendaItem({
    required this.time,
    required this.duration,
    required this.patientId,
    required this.name,
    required this.service,
    required this.status,
    this.appointmentId,
    this.startsAt,
    this.endsAt,
  });

  final String time;
  final String duration;
  final String patientId;
  final String name;
  final String service;
  final AgendaStatus status;
  final String? appointmentId;
  final DateTime? startsAt;
  final DateTime? endsAt;
}
