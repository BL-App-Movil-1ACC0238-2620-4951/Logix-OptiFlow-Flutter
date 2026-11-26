import 'package:flutter/foundation.dart';

import 'package:logix_optiflow/core/errors/api_exception.dart';
import 'package:logix_optiflow/features/auth/presentation/session_view_model.dart';
import 'package:logix_optiflow/features/notification/application/answer_survey_use_case.dart';
import 'package:logix_optiflow/features/notification/application/get_notifications_use_case.dart';
import 'package:logix_optiflow/features/notification/application/mark_notification_read_use_case.dart';
import 'package:logix_optiflow/features/notification/domain/patient_notification.dart';
import 'package:logix_optiflow/features/notification/presentation/notifications_ui_state.dart';

/// Notificaciones del paciente: lista del backend, marcar leídas y encuesta de satisfacción.
class NotificationsViewModel extends ChangeNotifier {
  NotificationsViewModel({
    required this.session,
    required this.getNotificationsUseCase,
    required this.markNotificationReadUseCase,
    required this.answerSurveyUseCase,
  }) {
    session.addLogoutListener(_reset);
  }

  final SessionViewModel session;
  final GetNotificationsUseCase getNotificationsUseCase;
  final MarkNotificationReadUseCase markNotificationReadUseCase;
  final AnswerSurveyUseCase answerSurveyUseCase;

  NotificationsUiState _state = const NotificationsUiState();
  NotificationsUiState get state => _state;
  int _request = 0;

  void _emit(NotificationsUiState value) {
    _state = value;
    notifyListeners();
  }

  void _reset() {
    _request++;
    _emit(const NotificationsUiState());
  }

  int get unreadCount => _state.items.where((n) => !n.read).length;

  List<NotificationSection> get sections {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final groups = {'Hoy': <PatientNotification>[], 'Ayer': <PatientNotification>[], 'Anteriores': <PatientNotification>[]};
    for (final item in _state.items) {
      final day = DateTime(item.occurredAt.year, item.occurredAt.month, item.occurredAt.day);
      groups[day == today ? 'Hoy' : day == yesterday ? 'Ayer' : 'Anteriores']!.add(item);
    }
    return [
      for (final entry in groups.entries)
        if (entry.value.isNotEmpty) NotificationSection(entry.key, entry.value),
    ];
  }

  Future<void> refresh() async {
    final current = session.session;
    final request = ++_request;
    if (current?.isAuthenticated != true || !current!.isPatient) {
      _emit(_state.copyWith(loading: false, error: () => 'Inicia sesión para ver tus notificaciones.'));
      return;
    }
    _emit(_state.copyWith(loading: true, error: () => null));
    try {
      final items = await getNotificationsUseCase.execute(current.patientId);
      if (request != _request) return;
      items.sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
      _emit(_state.copyWith(items: items, loading: false));
    } catch (e) {
      if (request != _request) return;
      _emit(_state.copyWith(loading: false, error: () => _message(e, 'No se pudieron cargar tus notificaciones.')));
    }
  }

  /// El backend marca de una en una (`PATCH /notifications/{id}`), así que se envían todas las no leídas.
  Future<void> markAllRead() async {
    final unread = _state.items.where((n) => !n.read).map((n) => n.id).toList();
    if (unread.isEmpty) return;
    await Future.wait(unread.map((id) => markNotificationReadUseCase.execute(id).catchError((_) {})));
    await refresh();
  }

  Future<void> markRead(PatientNotification item) async {
    if (item.read) return;
    try {
      await markNotificationReadUseCase.execute(item.id);
      await refresh();
    } catch (_) {}
  }

  /// Responde la encuesta de satisfacción. Devuelve el error o `null`.
  Future<String?> answerSurvey(String id, int rating, String comment) async {
    try {
      await answerSurveyUseCase.execute(id, rating, comment);
      await refresh();
      return null;
    } catch (e) {
      return _message(e, 'No se pudo enviar tu respuesta.');
    }
  }

  String _message(Object e, String fallback) => e is ApiException ? e.message : fallback;
}
