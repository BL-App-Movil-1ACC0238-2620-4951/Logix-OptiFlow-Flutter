class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.connection = false});

  final String message;
  final int? statusCode;
  /// La solicitud no llegó al servidor (sin internet o sin respuesta).
  final bool connection;

  @override
  String toString() => message;
}
