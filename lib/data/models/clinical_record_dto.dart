import '../../domain/entities/models.dart';

class ClinicalRecordDto {
  const ClinicalRecordDto({
    this.examinationDate,
    this.observations,
    this.prescription,
    this.id,
    this.appointmentId,
    this.status,
    this.patientId,
    this.medicalHistory,
  });

  final DateTime? examinationDate;
  final String? observations;
  final PrescriptionValues? prescription;
  final String? id;
  final String? appointmentId;
  final String? status;
  final String? patientId;
  final MedicalHistory? medicalHistory;

  factory ClinicalRecordDto.fromJson(Map<String, dynamic> json) {
    final raw = json['prescription'];
    final history = json['medicalHistory'];
    final prescription = raw is Map ? parsePrescription(Map<String, dynamic>.from(raw)) : null;
    return ClinicalRecordDto(
      id: json['id'] as String?, appointmentId: json['appointmentId'] as String?, status: json['status'] as String?,
      patientId: json['patientId'] as String?,
      medicalHistory: history is Map ? MedicalHistory(
        allergies: List<String>.from(history['allergies'] as List? ?? []),
        previousConditions: List<String>.from(history['previousConditions'] as List? ?? []),
        familyOcularHistory: history['familyOcularHistory'] as String?,
      ) : null,
      examinationDate: DateTime.tryParse('${json['examinationDate']}'),
      observations: json['observations']?.toString(),
      prescription: prescription,
    );
  }

  static PrescriptionValues parsePrescription(Map<String, dynamic> map) => PrescriptionValues(
        sphereOd: _num(map['sphereOD']),
        cylinderOd: _num(map['cylinderOD']),
        axisOd: _num(map['axisOD']),
        addition: _num(map['addition']),
        sphereOs: _num(map['sphereOS']),
        cylinderOs: _num(map['cylinderOS']),
        axisOs: _num(map['axisOS']),
        treatment: map['treatment']?.toString(),
        recommendedFrameType: map['recommendedFrameType']?.toString(),
      );

  ClinicalRecord toEntity() {
    return ClinicalRecord(
      id: id, appointmentId: appointmentId, status: status,
      patientId: patientId, medicalHistory: medicalHistory,
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
