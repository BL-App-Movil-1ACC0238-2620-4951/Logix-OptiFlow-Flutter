class ApiException implements Exception {
  /// Mensaje neutro cuando no se puede llegar al servidor (sin nombrar el proveedor ni herramientas internas).
  static const connectionMessage = 'No hay conexión con el servidor. Intenta de nuevo en un momento.';

  ApiException(this.message, {this.statusCode, this.connection = false});

  final String message;
  final int? statusCode;
  /// La solicitud no llegó al servidor (sin internet o sin respuesta).
  final bool connection;

  @override
  String toString() => message;
}
