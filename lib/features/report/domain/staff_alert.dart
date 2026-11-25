class StaffAlert {
  const StaffAlert({
    required this.kind,
    required this.title,
    required this.message,
    required this.action,
    required this.route,
  });

  final String kind;
  final String title;
  final String message;
  final String action;

  /// Pantalla que abre la acción de la alerta.
  final String route;
}
