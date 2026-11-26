import 'package:shared_preferences/shared_preferences.dart';

import 'package:logix_optiflow/core/storage/token_storage.dart';
import 'package:logix_optiflow/features/auth/domain/app_settings.dart';
import 'package:logix_optiflow/features/auth/domain/patient_session.dart';
import 'package:logix_optiflow/features/auth/domain/user_role.dart';

/// Datos de la sesión en preferencias; el token va aparte en [TokenStorage].
class SessionLocalDataSource {
  SessionLocalDataSource({required this.tokens});

  final TokenStorage tokens;

  static const patientIdKey = 'patient_id';
  static const legacyTokenKey = 'token';
  static const nameKey = 'patient_name';
  static const emailKey = 'patient_email';
  static const phoneKey = 'patient_phone';
  static const roleKey = 'user_role';
  static const expiresAtKey = 'session_expires_at';
  static const opticalStoreIdKey = 'session_optical_store_id';
  static const controlRemindersKey = 'settings_control_reminders';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<PatientSession?> read() async {
    final prefs = await _prefs;
    final id = prefs.getString(patientIdKey);
    if (id == null || id.trim().isEmpty) return null;
    final role = UserRole.fromApi(prefs.getString(roleKey) ?? 'PATIENT');
    final rawExpiry = prefs.getString(expiresAtKey);
    final expiresAt = rawExpiry == null ? null : DateTime.tryParse(rawExpiry);
    if (role == null || (rawExpiry != null && expiresAt == null)) {
      await clear();
      return null;
    }
    final session = PatientSession(
      patientId: id,
      token: await tokens.readToken(),
      name: prefs.getString(nameKey) ?? '',
      email: prefs.getString(emailKey) ?? '',
      phone: prefs.getString(phoneKey) ?? '',
      role: role,
      expiresAt: expiresAt,
      opticalStoreId: prefs.getString(opticalStoreIdKey),
    );
    if (!session.isAuthenticated) {
      await clear();
      return null;
    }
    return session;
  }

  Future<void> save(PatientSession session) async {
    final prefs = await _prefs;
    await prefs.setString(patientIdKey, session.patientId);
    await prefs.setString(nameKey, session.name);
    await prefs.setString(emailKey, session.email);
    await prefs.setString(phoneKey, session.phone);
    await prefs.setString(roleKey, session.role.apiValue);
    if (session.expiresAt != null) {
      await prefs.setString(expiresAtKey, session.expiresAt!.toIso8601String());
    } else {
      await prefs.remove(expiresAtKey);
    }
    if (session.opticalStoreId != null) {
      await prefs.setString(opticalStoreIdKey, session.opticalStoreId!);
    } else {
      await prefs.remove(opticalStoreIdKey);
    }
    if (session.hasToken) {
      await tokens.saveToken(session.token!);
    } else {
      await tokens.deleteToken();
    }
    await prefs.remove(legacyTokenKey);
  }

  Future<void> clear() async {
    final prefs = await _prefs;
    await prefs.remove(patientIdKey);
    await prefs.remove(legacyTokenKey);
    await prefs.remove(nameKey);
    await prefs.remove(emailKey);
    await prefs.remove(phoneKey);
    await prefs.remove(roleKey);
    await prefs.remove(expiresAtKey);
    await prefs.remove(opticalStoreIdKey);
    await tokens.deleteToken();
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
