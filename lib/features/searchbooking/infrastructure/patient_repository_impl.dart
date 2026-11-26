import 'package:logix_optiflow/features/searchbooking/domain/patient_repository.dart';
import 'package:logix_optiflow/features/searchbooking/domain/staff_patient.dart';
import 'package:logix_optiflow/features/searchbooking/infrastructure/search_booking_api.dart';

class PatientRepositoryImpl implements PatientRepository {
  const PatientRepositoryImpl({required this.api});

  final SearchBookingApi api;

  @override
  Future<List<StaffPatient>> patients() => api.staffPatients();
  @override
  Future<StaffPatient> patient(String id) => api.staffPatient(id);
  @override
  Future<StaffPatient> updateProfile(String id, {required String name, required String phone, DateTime? birthDate}) =>
      api.updatePatientProfile(id, name: name, phone: phone, birthDate: birthDate);
  @override
  Future<StaffPatient> registerPatient({required String name, required String email, required String phone, required String dni, DateTime? birthDate}) =>
      api.registerPatientByStaff(name: name, email: email, phone: phone, dni: dni, birthDate: birthDate);
}
