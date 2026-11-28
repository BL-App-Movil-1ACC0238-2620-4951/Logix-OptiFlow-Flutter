import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:logix_optiflow/core/errors/api_exception.dart';
import 'package:logix_optiflow/core/network/offline_cache.dart';

/// Cliente HTTP compartido por las APIs de cada contexto. Guarda el token de la sesión.
class ApiClient {
  ApiClient({http.Client? client, String? baseUrl, this.offline})
      : _client = client ?? http.Client(),
        baseUrl = _normalize(baseUrl ?? const String.fromEnvironment(
          'API_BASE_URL',
          defaultValue: 'https://logix-optiflow-back-end.onrender.com/api/v1/',
        ));

  final http.Client _client;
  final String baseUrl;
  String? token;
  /// Caché de lecturas para mostrar sin conexión; null en las pruebas.
  final OfflineCache? offline;
  void Function()? onUnauthorized;

  static const _timeout = Duration(seconds: 60);

  static String _normalize(String raw) {
    final trimmed = raw.trim().replaceAll(RegExp(r'/+$'), '');
    return trimmed.endsWith('/api/v1') ? '$trimmed/' : '$trimmed/api/v1/';
  }

  /// Convierte una respuesta en lista de objetos o lanza [error] si no lo es.
  List<Map<String, dynamic>> mapList(Object? json, String error) {
    if (json is! List || json.any((item) => item is! Map)) throw ApiException(error);
    return json.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<Object?> get(String path, [Map<String, String?>? query]) async {
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

  /// GET que guarda la respuesta con [key]; sin conexión devuelve la última guardada.
  Future<Object?> cachedGet(String key, String path, [Map<String, String?>? query]) async {
    final cache = offline;
    if (cache == null) return get(path, query);
    try {
      final json = await get(path, query);
      await cache.save(key, json);
      return json;
    } on ApiException catch (error) {
      if (!error.connection) rethrow;
      final saved = await cache.read(key);
      if (saved == null) rethrow;
      return saved.$1;
    }
  }

  /// GET que devuelve el cuerpo tal cual (por ejemplo un CSV con `accept: 'text/csv'`).
  Future<String> getText(String path, {Map<String, String?>? query, String accept = 'text/plain'}) async {
    final uri = Uri.parse('$baseUrl$path').replace(
      queryParameters: {
        for (final entry in (query ?? const {}).entries)
          if (entry.value != null && entry.value!.trim().isNotEmpty) entry.key: entry.value!.trim(),
      },
    );
    final requestToken = token;
    try {
      final response = await _client.get(uri, headers: {..._headers(requestToken), 'Accept': accept}).timeout(_timeout);
      if (response.statusCode >= 200 && response.statusCode < 300) return utf8.decode(response.bodyBytes);
      _decode(response, requestToken: requestToken);
      throw ApiException('No se pudo completar la solicitud (${response.statusCode}).', statusCode: response.statusCode);
    } catch (error) {
      throw _wrap(error);
    }
  }

  Future<Object?> send(String method, String path, Map<String, dynamic> body) async {
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
      return ApiException(ApiException.connectionMessage, connection: true);
    }
    // Tiempo agotado o fallo de red: el mensaje técnico puede incluir la dirección del servidor.
    if (error is TimeoutException || error is http.ClientException) {
      return ApiException(ApiException.connectionMessage, connection: true);
    }
    return ApiException(raw.isEmpty ? 'Error inesperado. Intenta de nuevo.' : raw);
  }
}
