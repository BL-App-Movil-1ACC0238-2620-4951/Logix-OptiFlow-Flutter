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
  });

  final num? sphereOd;
  final num? cylinderOd;
  final num? axisOd;
  final num? addition;
  final num? sphereOs;
  final num? cylinderOs;
  final num? axisOs;
  final String? treatment;
}

class ClinicalRecord {
  const ClinicalRecord({
    this.examinationDate,
    this.observations,
    this.prescription,
  });

  final DateTime? examinationDate;
  final String? observations;
  final PrescriptionValues? prescription;
}
