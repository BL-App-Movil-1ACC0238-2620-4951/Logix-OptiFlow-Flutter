import '../../domain/entities/models.dart';

class ClinicalRecordDto {
  const ClinicalRecordDto({
    this.examinationDate,
    this.observations,
    this.prescription,
  });

  final DateTime? examinationDate;
  final String? observations;
  final PrescriptionValues? prescription;

  factory ClinicalRecordDto.fromJson(Map<String, dynamic> json) {
    final raw = json['prescription'];
    PrescriptionValues? prescription;
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      prescription = PrescriptionValues(
        sphereOd: _num(map['sphereOD']),
        cylinderOd: _num(map['cylinderOD']),
        axisOd: _num(map['axisOD']),
        addition: _num(map['addition']),
        sphereOs: _num(map['sphereOS']),
        cylinderOs: _num(map['cylinderOS']),
        axisOs: _num(map['axisOS']),
        treatment: map['treatment']?.toString(),
      );
    }
    return ClinicalRecordDto(
      examinationDate: DateTime.tryParse('${json['examinationDate']}'),
      observations: json['observations']?.toString(),
      prescription: prescription,
    );
  }

  ClinicalRecord toEntity() {
    return ClinicalRecord(
      examinationDate: examinationDate,
      observations: observations,
      prescription: prescription,
    );
  }
}

num? _num(Object? value) {
  if (value is num) return value;
  if (value is String) return num.tryParse(value);
  return null;
}
