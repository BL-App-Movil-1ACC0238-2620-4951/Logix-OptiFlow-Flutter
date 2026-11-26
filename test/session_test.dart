import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logix_optiflow/core/storage/secure_token_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logix_optiflow/features/auth/infrastructure/session_local_data_source.dart';
import 'package:logix_optiflow/features/auth/domain/patient_session.dart';
import 'package:logix_optiflow/features/auth/domain/user_role.dart';
import 'package:logix_optiflow/features/auth/domain/app_settings.dart';

SessionLocalDataSource source() =>
    SessionLocalDataSource(tokens: const SecureTokenStorage(storage: FlutterSecureStorage()));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('restaura identidad, rol, token, óptica y vencimiento de personal',
      () async {
    final local = source();
    final expiry = DateTime.now().add(const Duration(hours: 1)).toUtc();
    await local.save(PatientSession(
        patientId: 'staff-1',
        name: 'Camila',
        email: 'staff@optiflow.pe',
        token: 'token',
        role: UserRole.technician,
        opticalStoreId: 'store-1',
        expiresAt: expiry));
    final restored = (await local.read())!;
    expect(restored.role, UserRole.technician);
    expect(restored.isPatient, isFalse);
    expect(restored.token, 'token');
    expect(restored.opticalStoreId, 'store-1');
    expect(restored.expiresAt, expiry);
    expect(restored.copyWith(name: 'Nuevo nombre').role, UserRole.technician);
    expect(restored.copyWith(name: 'Nuevo nombre').expiresAt, expiry);
  });

  test('sesiones antiguas sin rol se restauran como pacientes', () async {
    SharedPreferences.setMockInitialValues({'patient_id': 'patient-1'});
    FlutterSecureStorage.setMockInitialValues({'token': 'token'});
    expect((await source().read())?.role, UserRole.patient);
  });

  test('descarta sesiones vencidas, tokens vacíos y roles desconocidos',
      () async {
    for (final overrides in [
      {'session_expires_at': '2000-01-01T00:00:00Z'},
      {'session_expires_at': 'invalid'},
      {'token': ''},
      {'user_role': 'SUPERADMIN'},
    ]) {
      final token = overrides.remove('token') ?? 'token';
      SharedPreferences.setMockInitialValues({'patient_id': 'user-1', ...overrides});
      FlutterSecureStorage.setMockInitialValues({'token': token});
      expect(await source().read(), isNull);
      expect(await const FlutterSecureStorage().read(key: 'token'), isNull);
    }
  });

  test('limpia toda la identidad al salir y conserva preferencias', () async {
    final local = source();
    await local.save(const PatientSession(
        patientId: 'staff-1',
        name: 'Camila',
        email: 'staff@optiflow.pe',
        token: 'token',
        role: UserRole.admin,
        opticalStoreId: 'store-1'));
    await local.saveSettings(const AppSettings(controlReminders: true));
    await local.clear();
    expect(await local.read(), isNull);
    final prefs = await SharedPreferences.getInstance();
    for (final key in [
      'patient_id',
      'patient_name',
      'patient_email',
      'patient_phone',
      'token',
      'user_role',
      'session_expires_at',
      'session_optical_store_id'
    ]) {
      expect(prefs.containsKey(key), isFalse);
    }
    expect(await const FlutterSecureStorage().read(key: 'token'), isNull);
    expect((await local.readSettings()).controlReminders, isTrue);
  });
}
