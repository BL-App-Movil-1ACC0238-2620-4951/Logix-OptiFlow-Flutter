import '../datasources/optiflow_api.dart';
import '../../domain/entities/models.dart';
import '../../domain/repositories/appointment_repository.dart';

class AppointmentRepositoryImpl implements AppointmentRepository {
  AppointmentRepositoryImpl(this._api);

  final OptiFlowApi _api;

  @override
  Future<Appointment> cancel(String appointmentId) async {
    return (await _api.cancelAppointment(appointmentId)).toEntity();
  }

  @override
  Future<List<Appointment>> forPatient(String patientId) async {
    final items = await _api.appointments(patientId);
    return items.map((item) => item.toEntity()).toList();
  }

  @override
  Future<Appointment> book({
    required String patientId,
    required String opticalStoreId,
    required String timeSlotId,
  }) async {
    final created = await _api.book(patientId: patientId, opticalStoreId: opticalStoreId, timeSlotId: timeSlotId);
    return created.toEntity();
  }

  @override
  Future<List<WorkOrder>> workOrders(String patientId) async {
    final items = await _api.workOrders(patientId);
    return items.map((item) => item.toEntity()).toList();
  }

  @override
  Future<List<ClinicalRecord>> clinicalRecords(String patientId) async {
    final items = await _api.clinicalRecords(patientId);
    return items.map((item) => item.toEntity()).toList();
  }
}
