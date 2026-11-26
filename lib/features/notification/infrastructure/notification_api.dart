import 'package:logix_optiflow/core/errors/api_exception.dart';
import 'package:logix_optiflow/core/network/api_client.dart';
import 'package:logix_optiflow/features/notification/domain/patient_notification.dart';

class NotificationApi {
  const NotificationApi(this._client);

  final ApiClient _client;

  Future<List<PatientNotification>> forPatient(String patientId) async {
    final json = await _client.get('patients/$patientId/notifications');
    if (json is! List) throw ApiException('El servidor devolvió notificaciones inválidas.');
    return [for (final item in json.whereType<Map>()) _fromJson(Map<String, dynamic>.from(item))];
  }

  /// Saldo de puntos OptiFlow del paciente.
  Future<int> loyaltyBalance(String patientId) async {
    final json = await _client.get('patients/$patientId/loyalty-account');
    final balance = json is Map ? json['balance'] : null;
    if (balance is! num) throw ApiException('El servidor devolvió un saldo de puntos inválido.');
    return balance.toInt();
  }

  Future<void> markRead(String id) async {
    try {
      await _client.send('PATCH', 'notifications/$id', {'read': true});
    } on ApiException catch (e) {
      // 409: ya estaba leída, que es lo que se quería.
      if (e.statusCode != 409) rethrow;
    }
  }

  Future<void> answerSurvey(String id, int rating, String? comment) async {
    final text = comment?.trim() ?? '';
    await _client.send('POST', 'notifications/$id/survey-response', {'rating': rating, 'comment': text.isEmpty ? null : text});
  }

  static PatientNotification _fromJson(Map<String, dynamic> json) {
    DateTime? date(Object? value) => value is String ? DateTime.tryParse(value)?.toLocal() : null;
    String? text(Object? value) => value?.toString();
    return PatientNotification(
      id: json['id'].toString(),
      kind: _kind(json['type']?.toString()),
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      // Un recordatorio aparece en su fecha programada; los demás, cuando se crearon.
      occurredAt: date(json['scheduledAt']) ?? date(json['createdAt']) ?? DateTime.now(),
      read: json['status'] == 'READ',
      appointmentId: text(json['appointmentId']),
      workOrderId: text(json['workOrderId']),
      surveyRating: (json['surveyRating'] as num?)?.toInt(),
    );
  }

  static NotificationKind _kind(String? raw) => switch (raw) {
        'APPOINTMENT_REMINDER' => NotificationKind.appointment,
        'LENS_ORDER_PROGRESS' || 'DELIVERY_DELAY' => NotificationKind.order,
        'BIRTHDAY_DISCOUNT' => NotificationKind.promo,
        'SATISFACTION_SURVEY' => NotificationKind.survey,
        _ => NotificationKind.health,
      };
}
