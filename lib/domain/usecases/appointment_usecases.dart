import '../entities/models.dart';
import '../repositories/appointment_repository.dart';

class GetPatientAppointments {
  const GetPatientAppointments(this._appointments);

  final AppointmentRepository _appointments;

  Future<List<Appointment>> call(String patientId) => _appointments.forPatient(patientId);
}

class BookAppointment {
  const BookAppointment(this._appointments);

  final AppointmentRepository _appointments;

  Future<Appointment> call({
    required String patientId,
    required String opticalStoreId,
    required String timeSlotId,
  }) {
    return _appointments.book(
      patientId: patientId,
      opticalStoreId: opticalStoreId,
      timeSlotId: timeSlotId,
    );
  }
}

class GetPatientWorkOrders {
  const GetPatientWorkOrders(this._appointments);

  final AppointmentRepository _appointments;

  Future<List<WorkOrder>> call(String patientId) => _appointments.workOrders(patientId);
}

class GetPatientClinicalRecords {
  const GetPatientClinicalRecords(this._appointments);

  final AppointmentRepository _appointments;

  Future<List<ClinicalRecord>> call(String patientId) => _appointments.clinicalRecords(patientId);
}
