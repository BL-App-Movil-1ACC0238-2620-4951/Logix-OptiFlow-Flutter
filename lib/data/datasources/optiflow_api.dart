import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/appointment_dto.dart';
import '../models/clinical_record_dto.dart';
import '../models/optical_store_dto.dart';
import '../models/patient_dto.dart';
import '../models/time_slot_dto.dart';
import '../models/work_order_dto.dart';
import '../../core/errors/api_exception.dart';

/// Cliente HTTP del backend. La app lo usa solo desde los repositorios.
class OptiFlowApi {
  OptiFlowApi({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        baseUrl = _normalize(baseUrl ?? const String.fromEnvironment(
          'API_BASE_URL',
          defaultValue: 'https://logix-optiflow-back-end.onrender.com/',
        ));

  final http.Client _client;
  final String baseUrl;

  static const _timeout = Duration(seconds: 60);

  static String _normalize(String raw) => raw.endsWith('/') ? raw : '$raw/';

  Future<List<OpticalStoreDto>> listStores({String? name, String? address}) async {
    final json = await _get('optical-stores', {'name': name, 'address': address});
    return _stores(json);
  }

  Future<StoreSearchDto> searchStores({
    String? name,
    String? address,
    double? minRating,
  }) async {
    final json = await _get('optical-stores/search', {
      'name': name,
      'address': address,
      'minRating': minRating?.toString(),
    });
    return StoreSearchDto(
      stores: _stores(json),
      message: json is Map ? json['message'] as String? : null,
    );
  }

  Future<List<TimeSlotDto>> availability(String storeId) async {
    final json = await _get('optical-stores/$storeId/availability');
    final list = json is Map ? (json['timeSlots'] as List?) ?? const [] : json as List? ?? const [];
    return list.whereType<Map>().map((e) => TimeSlotDto.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<PatientDto> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final json = await _send('POST', 'patients', {
      'name': name,
      'email': email,
      'phone': phone,
      'password': password,
    });
    return PatientDto.fromRegister(
      Map<String, dynamic>.from(json as Map),
      name: name,
      email: email,
      phone: phone,
    );
  }

  Future<PatientDto> login({required String email, required String password}) async {
    final json = await _send('POST', 'login', {'email': email, 'password': password});
    return PatientDto.fromLogin(Map<String, dynamic>.from(json as Map), email: email);
  }

  Future<AppointmentDto> book({
    required String patientId,
    required String opticalStoreId,
    required String timeSlotId,
  }) async {
    final json = await _send('POST', 'appointments', {
      'patientId': patientId,
      'opticalStoreId': opticalStoreId,
      'timeSlotId': timeSlotId,
    });
    return AppointmentDto.fromJson(Map<String, dynamic>.from(json as Map));
  }

  Future<List<AppointmentDto>> appointments(String patientId) async {
    final json = await _get('patients/$patientId/appointments');
    final list = json is List ? json : (json is Map ? json['value'] as List? : null) ?? const [];
    return list.whereType<Map>().map((e) => AppointmentDto.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<List<WorkOrderDto>> workOrders(String patientId) async {
    final json = await _get('patients/$patientId/work-orders');
    final list = json is List ? json : const [];
    return list.whereType<Map>().map((e) => WorkOrderDto.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<List<ClinicalRecordDto>> clinicalRecords(String patientId) async {
    final json = await _get('patients/$patientId/clinical-records');
    final list = json is List ? json : const [];
    return list.whereType<Map>().map((e) => ClinicalRecordDto.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  List<OpticalStoreDto> _stores(Object? json) {
    final list = json is Map ? (json['opticalStores'] as List?) ?? const [] : json is List ? json : const [];
    return list.whereType<Map>().map((e) => OpticalStoreDto.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<Object?> _get(String path, [Map<String, String?>? query]) async {
    final uri = Uri.parse('$baseUrl$path').replace(
      queryParameters: {
        for (final entry in (query ?? const {}).entries)
          if (entry.value != null && entry.value!.trim().isNotEmpty) entry.key: entry.value!.trim(),
      },
    );
    try {
      final response = await _client.get(uri).timeout(_timeout);
      return _decode(response);
    } catch (error) {
      throw _wrap(error);
    }
  }

  Future<Object?> _send(String method, String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('$baseUrl$path');
    try {
      final response = await _client
          .post(uri, headers: {'Content-Type': 'application/json'}, body: jsonEncode(body))
          .timeout(_timeout);
      if (method != 'POST') {
        throw ApiException('Método no soportado');
      }
      return _decode(response);
    } catch (error) {
      throw _wrap(error);
    }
  }

  Object? _decode(http.Response response) {
    final raw = utf8.decode(response.bodyBytes);
    Object? json;
    if (raw.isNotEmpty) {
      try {
        json = jsonDecode(raw);
      } catch (_) {
        json = null;
      }
    }
    if (response.statusCode >= 200 && response.statusCode < 300) return json;
    String? message;
    if (json is Map && json['message'] is String && (json['message'] as String).trim().isNotEmpty) {
      message = json['message'] as String;
    }
    throw ApiException(message ?? 'No se pudo completar la solicitud (${response.statusCode}).', statusCode: response.statusCode);
  }

  Exception _wrap(Object error) {
    if (error is ApiException) return error;
    final raw = error.toString();
    if (raw.contains('Failed host lookup') || raw.contains('Connection refused') || raw.contains('timed out') || raw.contains('SocketException')) {
      return ApiException(
        'No se pudo conectar al servidor. El backend en Render puede estar dormido: espera un minuto y vuelve a intentar, o abre Swagger para despertarlo.',
      );
    }
    return ApiException(raw.isEmpty ? 'Error inesperado. Intenta de nuevo.' : raw);
  }
}
