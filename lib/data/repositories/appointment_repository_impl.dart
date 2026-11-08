import '../../core/network/optiflow_api.dart';
import '../../domain/entities/models.dart';
import '../../domain/repositories/appointment_repository.dart';

class AppointmentRepositoryImpl implements AppointmentRepository {
  AppointmentRepositoryImpl(this._api);

  final OptiFlowApi _api;

  @override
  Future<List<Appointment>> forPatient(String patientId) => _api.appointments(patientId);

  @override
  Future<Appointment> book({
    required String patientId,
    required String opticalStoreId,
    required String timeSlotId,
  }) {
    return _api.book(patientId: patientId, opticalStoreId: opticalStoreId, timeSlotId: timeSlotId);
  }

  @override
  Future<List<Map<String, dynamic>>> workOrders(String patientId) => _api.workOrders(patientId);

  @override
  Future<List<Map<String, dynamic>>> clinicalRecords(String patientId) => _api.clinicalRecords(patientId);
}
