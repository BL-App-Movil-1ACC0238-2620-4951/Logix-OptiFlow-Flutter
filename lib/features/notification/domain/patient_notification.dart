enum NotificationKind { appointment, order, health, promo, survey }

/// Notificación del paciente guardada en el backend (`patients/{id}/notifications`).
class PatientNotification {
  const PatientNotification({
    required this.id,
    required this.kind,
    required this.title,
    required this.message,
    required this.occurredAt,
    required this.read,
    this.appointmentId,
    this.workOrderId,
    this.surveyRating,
  });

  final String id;
  final NotificationKind kind;
  final String title;
  final String message;
  final DateTime occurredAt;
  final bool read;
  final String? appointmentId;
  final String? workOrderId;

  /// Puntaje de la encuesta respondida; null si no es encuesta o falta responderla.
  final int? surveyRating;
}
