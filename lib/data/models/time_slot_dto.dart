import '../../domain/entities/models.dart';

class TimeSlotDto {
  const TimeSlotDto({
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

  factory TimeSlotDto.fromJson(Map<String, dynamic> json) {
    return TimeSlotDto(
      id: '${json['id']}',
      opticalStoreId: '${json['opticalStoreId']}',
      start: DateTime.parse('${json['startDateTime']}').toLocal(),
      end: DateTime.parse('${json['endDateTime']}').toLocal(),
      status: '${json['status'] ?? ''}',
    );
  }

  TimeSlot toEntity() {
    return TimeSlot(
      id: id,
      opticalStoreId: opticalStoreId,
      start: start,
      end: end,
      status: status,
    );
  }
}
