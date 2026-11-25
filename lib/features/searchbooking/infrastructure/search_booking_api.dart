import 'package:logix_optiflow/core/network/api_client.dart';
import 'package:logix_optiflow/core/errors/api_exception.dart';
import 'package:logix_optiflow/core/time/store_time.dart';
import 'package:logix_optiflow/features/searchbooking/domain/staff_patient.dart';
import 'package:logix_optiflow/features/searchbooking/infrastructure/appointment_dto.dart';
import 'package:logix_optiflow/features/searchbooking/infrastructure/optical_store_dto.dart';
import 'package:logix_optiflow/features/searchbooking/infrastructure/staff_patient_dto.dart';
import 'package:logix_optiflow/features/searchbooking/infrastructure/time_slot_dto.dart';

/// Ópticas, horarios, citas y pacientes (contexto Search & Booking).
class SearchBookingApi {
  const SearchBookingApi(this._client);

  final ApiClient _client;

  Future<List<OpticalStoreDto>> listStores({String? name, String? address}) async {
    final json = await _client.get('optical-stores', {'name': name, 'address': address});
    return _stores(json);
  }

  Future<StoreSearchDto> searchStores({
    String? name,
    String? address,
    double? minRating,
  }) async {
    final json = await _client.get('optical-stores', {
      'name': name,
      'address': address,
      'minRating': minRating?.toString(),
    });
    return StoreSearchDto(
      stores: _stores(json),
      message: json is Map ? json['message'] as String? : null,
    );
  }

  /// Ópticas a menos de [radiusKm] del punto (`lat`, `lng`, `radiusKm`).
  Future<List<OpticalStoreDto>> nearbyStores(double latitude, double longitude, double radiusKm) async {
    final json = await _client.get('optical-stores', {
      'lat': latitude.toString(),
      'lng': longitude.toString(),
      'radiusKm': radiusKm.toString(),
    });
    return _stores(json);
  }

  Future<void> saveFavoriteStore(String patientId, String opticalStoreId) async {
    await _client.send('POST', 'patients/$patientId/favorites', {'opticalStoreId': opticalStoreId});
  }

  Future<void> rateOpticalStore(String storeId, String patientId, int score, String? comment) async {
    await _client.send('POST', 'optical-stores/$storeId/ratings', {'patientId': patientId, 'score': score, 'comment': comment});
  }

  Future<List<TimeSlotDto>> availability(String storeId) async {
    final json = await _client.get('optical-stores/$storeId/time-slots');
    final list = json is Map ? (json['timeSlots'] as List?) ?? const [] : json as List? ?? const [];
    return list.whereType<Map>().map((e) => TimeSlotDto.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<AppointmentDto> book({
    required String patientId,
    required String opticalStoreId,
    required String timeSlotId,
  }) async {
    final json = await _client.send('POST', 'appointments', {
      'patientId': patientId,
      'opticalStoreId': opticalStoreId,
      'timeSlotId': timeSlotId,
    });
    return AppointmentDto.fromJson(Map<String, dynamic>.from(json as Map));
  }

  Future<List<AppointmentDto>> appointments(String patientId) async {
    final json = await _client.get('patients/$patientId/appointments');
    final list = json is List ? json : (json is Map ? json['value'] as List? : null) ?? const [];
    return list.whereType<Map>().map((e) => AppointmentDto.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<AppointmentDto> cancelAppointment(String appointmentId) async {
    final json = await _client.send('PATCH', 'appointments/$appointmentId/status', {'status': 'CANCELLED'});
    return AppointmentDto.fromJson(Map<String, dynamic>.from(json as Map));
  }

  Future<AppointmentDto> completeAppointment(String id) async => AppointmentDto.fromJson(Map<String, dynamic>.from(
      await _client.send('PATCH', 'appointments/${Uri.encodeComponent(id)}/status', {'status': 'COMPLETED'}) as Map));

  Future<List<StaffPatient>> staffPatients() async => _list(await _client.get('patients')).map(StaffPatientDto.fromJson).toList();
  Future<StaffPatient> staffPatient(String id) async {
    final patient = StaffPatientDto.fromJson(Map<String, dynamic>.from(await _client.get('patients/${Uri.encodeComponent(id)}') as Map));
    if (patient.id != id) throw ApiException('El paciente recibido no coincide con la ficha solicitada.');
    return patient;
  }
  Future<StaffPatient> registerPatientByStaff({required String name, required String email, required String phone, required String dni, DateTime? birthDate}) async =>
      StaffPatientDto.fromJson(Map<String, dynamic>.from(await _client.send('POST', 'patients', {
        'name': name, 'email': email, 'phone': phone, 'password': dni,
        if (birthDate != null) 'birthDate': StoreTime.isoDay(birthDate),
      }) as Map));
  Future<List<AppointmentDto>> storeAgenda(String opticalStoreId, DateTime date) async => _list(await _client.get('appointments', {
    'opticalStoreId': opticalStoreId, 'date': StoreTime.isoDay(date),
  })).map(AppointmentDto.fromJson).toList();

  List<OpticalStoreDto> _stores(Object? json) {
    final list = json is Map ? (json['opticalStores'] as List?) ?? const [] : json is List ? json : const [];
    return list.whereType<Map>().map((e) => OpticalStoreDto.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  List<Map<String, dynamic>> _list(Object? json) => _client.mapList(json, 'El servidor devolvió una lista del personal inválida.');
}
