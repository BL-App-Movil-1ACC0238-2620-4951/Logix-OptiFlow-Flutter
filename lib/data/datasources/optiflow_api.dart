import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/appointment_dto.dart';
import '../models/clinical_record_dto.dart';
import '../models/optical_store_dto.dart';
import '../models/patient_dto.dart';
import '../models/time_slot_dto.dart';
import '../models/work_order_dto.dart';
import '../models/inventory_dto.dart';
import '../../domain/entities/inventory.dart';
import '../../domain/entities/staff_patient.dart';
import '../../domain/entities/staff_order.dart';
import '../../domain/entities/store_time.dart';
import '../models/staff_dto.dart';
import '../../core/errors/api_exception.dart';

/// Cliente HTTP del backend. La app lo usa solo desde los repositorios.
class OptiFlowApi {
  OptiFlowApi({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        baseUrl = _normalize(baseUrl ?? const String.fromEnvironment(
          'API_BASE_URL',
          defaultValue: 'https://logix-optiflow-back-end.onrender.com/api/v1/',
        ));

  final http.Client _client;
  final String baseUrl;
  String? token;
  void Function()? onUnauthorized;

  static const _timeout = Duration(seconds: 60);

  static String _normalize(String raw) {
    final trimmed = raw.trim().replaceAll(RegExp(r'/+$'), '');
    return trimmed.endsWith('/api/v1') ? '$trimmed/' : '$trimmed/api/v1/';
  }

  Future<List<StaffPatient>> staffPatients() async => _staffList(await _get('patients')).map(StaffDto.patient).toList();
  Future<StaffPatient> staffPatient(String id) async {
    final patient = StaffDto.patient(Map<String, dynamic>.from(await _get('patients/${Uri.encodeComponent(id)}') as Map));
    if (patient.id != id) throw ApiException('El paciente recibido no coincide con la ficha solicitada.');
    return patient;
  }
  Future<StaffPatient> registerPatientByStaff({required String name, required String email, required String phone, required String dni, DateTime? birthDate}) async =>
      StaffDto.patient(Map<String, dynamic>.from(await _send('POST', 'patients', {
        'name': name, 'email': email, 'phone': phone, 'password': dni,
        if (birthDate != null) 'birthDate': StoreTime.isoDay(birthDate),
      }) as Map));
  Future<List<AppointmentDto>> storeAgenda(String opticalStoreId, DateTime date) async => _staffList(await _get('appointments', {
    'opticalStoreId': opticalStoreId, 'date': StoreTime.isoDay(date),
  })).map(AppointmentDto.fromJson).toList();
  Future<int> patientsWithRecords() async {
    final json = await _get('clinical-records/summary') as Map;
    return (json['patientsWithRecords'] as num).toInt();
  }
  Future<List<StaffOrder>> staffOrders() async => _staffList(await _get('work-orders')).map(StaffDto.order).toList();
  List<Map<String, dynamic>> _staffList(Object? json) {
    if (json is! List || json.any((item) => item is! Map)) throw ApiException('El servidor devolvió una lista del personal inválida.');
    return json.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<List<FrameModelDto>> frameCatalog() async => _inventoryList(await _get('inventory/frames'))
      .map(FrameModelDto.new).toList();

  Future<FrameModelDto> frameModel(String sku, {String? opticalStoreId}) async => FrameModelDto(
      Map<String, dynamic>.from(await _get('inventory/frames/${Uri.encodeComponent(sku)}', {'opticalStoreId': opticalStoreId}) as Map));

  Future<FrameModelDto> updateFramePrice(String sku, num price) async => FrameModelDto(
      Map<String, dynamic>.from(await _send('PATCH', 'inventory/frames/${Uri.encodeComponent(sku)}/price', {'price': price}) as Map));

  Future<StoreInventory> inventoryStock(String opticalStoreId) async => InventoryDto.stock(
      Map<String, dynamic>.from(await _get('inventory/stock', {'opticalStoreId': opticalStoreId}) as Map));

  Future<List<Supplier>> suppliers() async => _inventoryList(await _get('suppliers')).map(InventoryDto.supplier).toList();

  Future<List<StockMovement>> stockMovements({required String opticalStoreId, required DateTime from, required DateTime to, String? sku}) async =>
      _inventoryList(await _get('inventory/movements', {
        'opticalStoreId': opticalStoreId, 'from': from.toIso8601String().substring(0, 10),
        'to': to.toIso8601String().substring(0, 10), 'sku': sku,
      })).map(InventoryDto.movement).toList();

  Future<StockMovement> replenishStock({required String opticalStoreId, required String sku, required String supplierId, required int quantity, int? minimumStock}) async =>
      InventoryDto.movement(Map<String, dynamic>.from(await _send('POST', 'inventory/replenishments', {
        'opticalStoreId': opticalStoreId, 'sku': sku, 'supplierId': supplierId, 'quantity': quantity,
        if (minimumStock != null) 'minimumStock': minimumStock,
      }) as Map));

  List<Map<String, dynamic>> _inventoryList(Object? json) {
    if (json is! List || json.any((item) => item is! Map)) throw ApiException('El servidor devolvió una lista de inventario inválida.');
    return json.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<List<OpticalStoreDto>> listStores({String? name, String? address}) async {
    final json = await _get('optical-stores', {'name': name, 'address': address});
    return _stores(json);
  }

  Future<StoreSearchDto> searchStores({
    String? name,
    String? address,
    double? minRating,
  }) async {
    final json = await _get('optical-stores', {
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
    final json = await _get('optical-stores/$storeId/time-slots');
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
    // Public requests must not carry a token from a previous account.
    token = null;
    final json = await _send('POST', 'auth/tokens', {'email': email, 'password': password});
    try {
      final response = Map<String, dynamic>.from(json as Map);
      final account = PatientDto.fromLogin(response, email: email);
      if (!account.toEntity().isAuthenticated) {
        throw ApiException('La sesión recibida ya venció. Vuelve a iniciar sesión.');
      }
      token = account.token;
      final path = account.toEntity().isPatient ? 'patients' : 'staff-members';
      final profile = await _get('$path/${account.id}');
      return PatientDto.fromLogin(response, email: email, profile: Map<String, dynamic>.from(profile as Map));
    } catch (error) {
      token = null;
      if (error is ApiException) rethrow;
      throw ApiException('El servidor devolvió una respuesta de autenticación inválida.');
    }
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

  Future<AppointmentDto> cancelAppointment(String appointmentId) async {
    final json = await _send('PATCH', 'appointments/$appointmentId/status', {'status': 'CANCELLED'});
    return AppointmentDto.fromJson(Map<String, dynamic>.from(json as Map));
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
    final requestToken = token;
    try {
      final response = await _client.get(uri, headers: _headers(requestToken)).timeout(_timeout);
      return _decode(response, requestToken: requestToken);
    } catch (error) {
      throw _wrap(error);
    }
  }

  Future<Object?> _send(String method, String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('$baseUrl$path');
    final requestToken = path == 'auth/tokens' || path == 'patients' ? null : token;
    try {
      final request = http.Request(method, uri)
        ..headers.addAll(_headers(requestToken))
        ..body = jsonEncode(body);
      final response = await _client.send(request).then(http.Response.fromStream).timeout(_timeout);
      return _decode(response, requestToken: requestToken);
    } catch (error) {
      throw _wrap(error);
    }
  }

  Map<String, String> _headers(String? requestToken) => {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    if (requestToken != null && requestToken.trim().isNotEmpty)
      'Authorization': 'Bearer $requestToken',
  };

  Object? _decode(http.Response response, {String? requestToken}) {
    final raw = utf8.decode(response.bodyBytes);
    Object? json;
    if (raw.isNotEmpty) {
      try {
        json = jsonDecode(raw);
      } catch (_) {
        json = null;
      }
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (raw.trim().isNotEmpty && json == null) {
        throw ApiException('El servidor devolvió una respuesta inválida.');
      }
      return json;
    }
    if (response.statusCode == 401 && requestToken != null && requestToken == token) {
      token = null;
      onUnauthorized?.call();
    }
    String? message;
    if (json is Map && json['message'] is String && (json['message'] as String).trim().isNotEmpty) {
      message = json['message'] as String;
    }
    if (message == null && json is Map && json['detail'] is String) message = json['detail'] as String;
    message ??= switch (response.statusCode) {
      401 => requestToken == null ? 'Correo o contraseña incorrectos.' : 'Tu sesión venció. Vuelve a iniciar sesión.',
      403 => 'Tu cuenta no tiene permiso para realizar esta acción.',
      _ => null,
    };
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
