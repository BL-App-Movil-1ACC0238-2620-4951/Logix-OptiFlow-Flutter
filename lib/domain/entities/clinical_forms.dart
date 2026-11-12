import 'clinical_record.dart';

enum CareStep { examination, history, prescription, done }

class PrescriptionForm {
  PrescriptionForm(
      {this.sphereOD = '',
      this.cylinderOD = '',
      this.axisOD = '',
      this.sphereOS = '',
      this.cylinderOS = '',
      this.axisOS = '',
      this.addition = '',
      this.treatment = '',
      this.recommendedFrameType = ''});
  String sphereOD,
      cylinderOD,
      axisOD,
      sphereOS,
      cylinderOS,
      axisOS,
      addition,
      treatment,
      recommendedFrameType;

  factory PrescriptionForm.fromValues(PrescriptionValues values) =>
      PrescriptionForm(
        sphereOD: values.sphereOd?.toStringAsFixed(2) ?? '',
        cylinderOD: values.cylinderOd?.toStringAsFixed(2) ?? '',
        axisOD: values.axisOd?.toInt().toString() ?? '',
        sphereOS: values.sphereOs?.toStringAsFixed(2) ?? '',
        cylinderOS: values.cylinderOs?.toStringAsFixed(2) ?? '',
        axisOS: values.axisOs?.toInt().toString() ?? '',
        addition: values.addition?.toStringAsFixed(2) ?? '',
        treatment: values.treatment ?? '',
        recommendedFrameType: values.recommendedFrameType ?? '',
      );

  PrescriptionValues validate() {
    num diopters(String value, String label, int limit) {
      final number = num.tryParse(
          value.trim().replaceAll(',', '.').replaceFirst(RegExp(r'^\+'), ''));
      if (number == null || !number.isFinite) {
        throw FormatException('Ingresa $label.');
      }
      if (number < -limit || number > limit) {
        throw FormatException('$label debe estar entre -$limit y $limit.');
      }
      return number;
    }

    int axis(String value, String label) {
      final number = int.tryParse(value.trim());
      if (number == null || number < 0 || number > 180) {
        throw FormatException('$label debe estar entre 0 y 180 grados.');
      }
      return number;
    }

    final add = addition.trim().isEmpty
        ? null
        : num.tryParse(addition
            .trim()
            .replaceAll(',', '.')
            .replaceFirst(RegExp(r'^\+'), ''));
    if (addition.trim().isNotEmpty &&
        (add == null || !add.isFinite || add < 0 || add > 4)) {
      throw const FormatException('La adición debe estar entre 0 y 4.');
    }
    if (treatment.length > 255 || recommendedFrameType.length > 255) {
      throw const FormatException(
          'El tratamiento y la montura pueden tener hasta 255 caracteres.');
    }
    return PrescriptionValues(
      sphereOd: diopters(sphereOD, 'La esfera del OD', 30),
      cylinderOd: diopters(cylinderOD, 'El cilindro del OD', 10),
      axisOd: axis(axisOD, 'El eje del OD'),
      sphereOs: diopters(sphereOS, 'La esfera del OI', 30),
      cylinderOs: diopters(cylinderOS, 'El cilindro del OI', 10),
      axisOs: axis(axisOS, 'El eje del OI'),
      addition: add,
      treatment: treatment.trim().isEmpty ? null : treatment.trim(),
      recommendedFrameType: recommendedFrameType.trim().isEmpty
          ? null
          : recommendedFrameType.trim(),
    );
  }
}

MedicalHistory validateMedicalHistory(
    String allergies, String conditions, String family) {
  List<String> items(String value) {
    final list = value
        .split(RegExp(r'[,;\n]'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList();
    if (list.length > 20) {
      throw const FormatException(
          'Ingresa como máximo 20 elementos por campo.');
    }
    if (list.any((s) => s.length > 100)) {
      throw const FormatException(
          'Cada elemento puede tener hasta 100 caracteres.');
    }
    return list;
  }

  if (family.length > 1000) {
    throw const FormatException(
        'Los antecedentes familiares pueden tener hasta 1000 caracteres.');
  }
  return MedicalHistory(
      allergies: items(allergies),
      previousConditions: items(conditions),
      familyOcularHistory: family.trim().isEmpty ? null : family.trim());
}
