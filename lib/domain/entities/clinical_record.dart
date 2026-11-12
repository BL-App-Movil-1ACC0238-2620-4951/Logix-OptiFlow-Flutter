class PrescriptionValues {
  const PrescriptionValues({
    this.sphereOd,
    this.cylinderOd,
    this.axisOd,
    this.addition,
    this.sphereOs,
    this.cylinderOs,
    this.axisOs,
    this.treatment,
    this.recommendedFrameType,
  });

  final num? sphereOd;
  final num? cylinderOd;
  final num? axisOd;
  final num? addition;
  final num? sphereOs;
  final num? cylinderOs;
  final num? axisOs;
  final String? treatment;
  final String? recommendedFrameType;
}

class ClinicalRecord {
  const ClinicalRecord({
    this.examinationDate,
    this.observations,
    this.prescription,
    this.id,
    this.appointmentId,
    this.status,
  });

  final DateTime? examinationDate;
  final String? observations;
  final PrescriptionValues? prescription;
  final String? id;
  final String? appointmentId;
  final String? status;
}
