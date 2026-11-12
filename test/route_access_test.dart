import 'package:flutter_test/flutter_test.dart';
import 'package:logix_optiflow/domain/entities/models.dart';
import 'package:logix_optiflow/presentation/navigation/route_access.dart';

PatientSession account(UserRole role) => PatientSession(
    patientId: 'user-1',
    name: 'Test',
    email: 'test@optiflow.pe',
    token: 'token',
    role: role);

void main() {
  test('enlaces privados sin sesión vuelven al acceso', () {
    for (final path in ['/s/inventory', '/p/book', '/']) {
      expect(routeRedirect(null, Uri.parse(path)), '/auth');
    }
    expect(routeRedirect(null, Uri.parse('/auth')), isNull);
  });

  test('cada rol inicia en su experiencia sin permitir cruzar rutas', () {
    for (final role in UserRole.values) {
      final session = account(role);
      final home = role == UserRole.patient ? '/p/home' : '/s/home';
      expect(routeRedirect(session, Uri.parse('/auth')), home);
      expect(routeRedirect(session, Uri.parse(home)), isNull);
      expect(
          routeRedirect(session,
              Uri.parse(role == UserRole.patient ? '/s/home' : '/p/home')),
          home);
    }
  });

  test('enlaces directos y navegación cumplen la matriz de roles de Android',
      () {
    final allowed = <String, Set<UserRole>>{
      '/s/agenda': {
        UserRole.optometrist,
        UserRole.salesAdvisor,
        UserRole.admin
      },
      '/s/patient/42': {
        UserRole.optometrist,
        UserRole.salesAdvisor,
        UserRole.admin
      },
      '/s/evaluation': {UserRole.optometrist, UserRole.admin},
      '/s/inventory': {UserRole.salesAdvisor, UserRole.admin},
      '/s/product/42': {UserRole.salesAdvisor, UserRole.admin},
      '/s/stock/42': {UserRole.admin},
      '/s/movement': {UserRole.admin},
      '/s/quote': {UserRole.salesAdvisor, UserRole.admin},
      '/s/sale/done': {UserRole.salesAdvisor, UserRole.admin},
      '/s/production': {UserRole.technician, UserRole.admin},
      '/s/alerts': {UserRole.admin},
      '/s/reports': {UserRole.admin},
    };
    for (final entry in allowed.entries) {
      for (final role in UserRole.values) {
        expect(
            canAccessPath(account(role), entry.key), entry.value.contains(role),
            reason: '${role.apiValue}: ${entry.key}');
      }
    }
    expect(canAccessPath(account(UserRole.admin), '/s/unknown'), isFalse);
  });

  test('sesión vencida regresa al acceso y settings antiguo de staff migra',
      () {
    final expired = PatientSession(
        patientId: 'staff',
        name: 'Test',
        email: 'test@optiflow.pe',
        token: 'token',
        role: UserRole.admin,
        expiresAt: DateTime.utc(2000));
    expect(routeRedirect(expired, Uri.parse('/s/home')), '/auth');
    expect(
        routeRedirect(
            account(UserRole.technician), Uri.parse('/p/settings?staff=true')),
        '/s/settings');
  });
}
