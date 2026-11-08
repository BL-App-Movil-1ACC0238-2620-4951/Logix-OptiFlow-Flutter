import '../../domain/entities/models.dart';

class AppointmentDto {
  const AppointmentDto({
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

  factory AppointmentDto.fromJson(Map<String, dynamic> json) {
    return AppointmentDto(
      id: '${json['id']}',
      patientId: '${json['patientId']}',
      opticalStoreId: '${json['opticalStoreId']}',
      timeSlotId: '${json['timeSlotId']}',
      status: '${json['status'] ?? 'PENDING'}',
      start: DateTime.parse('${json['startDateTime']}').toLocal(),
      end: DateTime.parse('${json['endDateTime']}').toLocal(),
    );
  }

  Appointment toEntity() {
    return Appointment(
      id: id,
      patientId: patientId,
      opticalStoreId: opticalStoreId,
      timeSlotId: timeSlotId,
      status: status,
      start: start,
      end: end,
    );
  }
}
