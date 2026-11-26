import 'package:logix_optiflow/core/errors/api_exception.dart';
import 'package:logix_optiflow/core/network/api_client.dart';
import 'package:logix_optiflow/features/clinical/domain/clinical_record.dart';
import 'package:logix_optiflow/features/clinical/infrastructure/clinical_record_dto.dart';

/// Historias clínicas y recetas (contexto Clinical & Commercial).
class ClinicalApi {
  const ClinicalApi(this._client);

  final ApiClient _client;

  Future<List<ClinicalRecordDto>> clinicalRecords(String patientId) async {
    final json = await _client.get('patients/$patientId/clinical-records');
    final list = json is List ? json : const [];
    return list.whereType<Map>().map((e) => ClinicalRecordDto.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<ClinicalRecord> examine({required String patientId, required String appointmentId, required String observations}) async =>
      ClinicalRecordDto.fromJson(Map<String, dynamic>.from(await _client.send('POST', 'clinical-records', {
        'patientId': patientId, 'appointmentId': appointmentId, 'observations': observations.isEmpty ? null : observations,
      }) as Map)).toEntity();
  Future<ClinicalRecord> saveMedicalHistory(String recordId, MedicalHistory history) async =>
      ClinicalRecordDto.fromJson(Map<String, dynamic>.from(await _client.send('PUT', 'clinical-records/${Uri.encodeComponent(recordId)}/medical-history', {
        'allergies': history.allergies, 'previousConditions': history.previousConditions, 'familyOcularHistory': history.familyOcularHistory,
      }) as Map)).toEntity();
  Future<PrescriptionValues> generatePrescription(String recordId, PrescriptionValues values) async {
    final json = Map<String, dynamic>.from(await _client.send('POST', 'clinical-records/${Uri.encodeComponent(recordId)}/prescription', {
      'sphereOD': values.sphereOd, 'cylinderOD': values.cylinderOd, 'axisOD': values.axisOd,
      'sphereOS': values.sphereOs, 'cylinderOS': values.cylinderOs, 'axisOS': values.axisOs,
      'addition': values.addition, 'treatment': values.treatment, 'recommendedFrameType': values.recommendedFrameType,
    }) as Map);
    if (json['clinicalRecordId'] != recordId) throw ApiException('La receta recibida no corresponde a esta ficha.');
    final prescription = ClinicalRecordDto.parsePrescription(json);
    final requiredValues = [prescription.sphereOd, prescription.cylinderOd, prescription.axisOd, prescription.sphereOs, prescription.cylinderOs, prescription.axisOs];
    if (requiredValues.any((value) => value == null || !value.isFinite)) throw ApiException('El servidor devolvió una receta incompleta.');
    return prescription;
  }
  Future<PrescriptionValues> prescription(String recordId) async =>
      ClinicalRecordDto.parsePrescription(Map<String, dynamic>.from(await _client.get('clinical-records/${Uri.encodeComponent(recordId)}/prescription') as Map));
  Future<int> patientsWithRecords() async {
    final json = await _client.get('clinical-records/summary') as Map;
    return (json['patientsWithRecords'] as num).toInt();
  }
}
