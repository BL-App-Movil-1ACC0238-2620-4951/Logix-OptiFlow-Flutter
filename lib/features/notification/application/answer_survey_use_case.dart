import 'package:logix_optiflow/features/notification/domain/notification_repository.dart';

class AnswerSurveyUseCase {
  const AnswerSurveyUseCase({required this.repository});

  final NotificationRepository repository;

  Future<void> execute(String id, int rating, String? comment) => repository.answerSurvey(id, rating, comment);
}
