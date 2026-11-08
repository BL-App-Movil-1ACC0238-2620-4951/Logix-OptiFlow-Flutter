import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/models.dart';

class SessionLocalDataSource {
  static const patientIdKey = 'patient_id';
  static const tokenKey = 'token';
  static const nameKey = 'patient_name';
  static const emailKey = 'patient_email';
  static const phoneKey = 'patient_phone';
  static const readNotificationsKey = 'read_notifications';
  static const controlRemindersKey = 'settings_control_reminders';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<PatientSession?> read() async {
    final prefs = await _prefs;
    final id = prefs.getString(patientIdKey);
    if (id == null) return null;
    return PatientSession(
      patientId: id,
      token: prefs.getString(tokenKey),
      name: prefs.getString(nameKey) ?? '',
      email: prefs.getString(emailKey) ?? '',
      phone: prefs.getString(phoneKey) ?? '',
    );
  }

  Future<void> save(PatientSession session) async {
    final prefs = await _prefs;
    await prefs.setString(patientIdKey, session.patientId);
    await prefs.setString(nameKey, session.name);
    await prefs.setString(emailKey, session.email);
    await prefs.setString(phoneKey, session.phone);
    if (session.hasToken) {
      await prefs.setString(tokenKey, session.token!);
    } else {
      await prefs.remove(tokenKey);
    }
  }

  Future<void> clear() async {
    final prefs = await _prefs;
    await prefs.remove(patientIdKey);
    await prefs.remove(tokenKey);
    await prefs.remove(nameKey);
    await prefs.remove(emailKey);
    await prefs.remove(phoneKey);
  }

  Future<Set<String>> readNotificationIds() async {
    final prefs = await _prefs;
    return prefs.getStringList(readNotificationsKey)?.toSet() ?? {};
  }

  Future<void> saveNotificationIds(Set<String> ids) async {
    final prefs = await _prefs;
    await prefs.setStringList(readNotificationsKey, ids.toList());
  }

  Future<AppSettings> readSettings() async {
    final prefs = await _prefs;
    return AppSettings(controlReminders: prefs.getBool(controlRemindersKey) ?? false);
  }

  Future<void> saveSettings(AppSettings settings) async {
    final prefs = await _prefs;
    await prefs.setBool(controlRemindersKey, settings.controlReminders);
  }
}
