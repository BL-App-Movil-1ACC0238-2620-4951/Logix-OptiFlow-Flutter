import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/models.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

/// Cliente del backend Search & Booking (el mismo que usa la app Android).
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

  Future<List<OpticalStore>> listStores({String? name, String? address}) async {
    final json = await _get('optical-stores', {'name': name, 'address': address});
    return _stores(json);
  }

  Future<({List<OpticalStore> stores, String? message})> searchStores({
    String? name,
    String? address,
    double? minRating,
  }) async {
    final json = await _get('optical-stores/search', {
      'name': name,
      'address': address,
      'minRating': minRating?.toString(),
    });
    if (json is Map) {
      return (stores: _stores(json), message: json['message'] as String?);
    }
    return (stores: _stores(json), message: null);
  }

  Future<List<TimeSlot>> availability(String storeId) async {
    final json = await _get('optical-stores/$storeId/availability');
    final list = json is Map ? (json['timeSlots'] as List?) ?? const [] : json as List? ?? const [];
    return list
        .whereType<Map>()
        .map((e) => TimeSlot.fromJson(Map<String, dynamic>.from(e)))
        .where((s) => s.status.toUpperCase() == 'AVAILABLE')
        .toList();
  }

  Future<PatientSession> register({
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
    final map = Map<String, dynamic>.from(json as Map);
    return PatientSession(
      patientId: '${map['id']}',
      name: '${map['name'] ?? name}',
      email: '${map['email'] ?? email}',
      phone: '${map['phone'] ?? phone}',
    );
  }

  Future<PatientSession> login({required String email, required String password}) async {
    final json = await _send('POST', 'login', {'email': email, 'password': password});
    final map = Map<String, dynamic>.from(json as Map);
    final patient = Map<String, dynamic>.from(map['patient'] as Map? ?? const {});
    return PatientSession(
      patientId: '${patient['id']}',
      token: '${map['token'] ?? ''}',
      name: '${patient['name'] ?? ''}',
      email: '${patient['email'] ?? email}',
      phone: '${patient['phone'] ?? ''}',
    );
  }

  Future<Appointment> book({
    required String patientId,
    required String opticalStoreId,
    required String timeSlotId,
  }) async {
    final json = await _send('POST', 'appointments', {
      'patientId': patientId,
      'opticalStoreId': opticalStoreId,
      'timeSlotId': timeSlotId,
    });
    return Appointment.fromJson(Map<String, dynamic>.from(json as Map));
  }

  Future<List<Appointment>> appointments(String patientId) async {
    final json = await _get('patients/$patientId/appointments');
    final list = json is List ? json : (json is Map ? json['value'] as List? : null) ?? const [];
    return list.whereType<Map>().map((e) => Appointment.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<List<Map<String, dynamic>>> workOrders(String patientId) async {
    final json = await _get('patients/$patientId/work-orders');
    final list = json is List ? json : const [];
    return list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<List<Map<String, dynamic>>> clinicalRecords(String patientId) async {
    final json = await _get('patients/$patientId/clinical-records');
    final list = json is List ? json : const [];
    return list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  List<OpticalStore> _stores(Object? json) {
    final list = json is Map ? (json['opticalStores'] as List?) ?? const [] : json is List ? json : const [];
    return list.whereType<Map>().map((e) => OpticalStore.fromJson(Map<String, dynamic>.from(e))).toList();
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
