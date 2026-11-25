import 'package:shared_preferences/shared_preferences.dart';

class NotificationLocalDataSource {
  static const readNotificationsKey = 'read_notifications';

  Future<Set<String>> readNotificationIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(readNotificationsKey)?.toSet() ?? {};
  }

  Future<void> saveNotificationIds(Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(readNotificationsKey, ids.toList());
  }
}
