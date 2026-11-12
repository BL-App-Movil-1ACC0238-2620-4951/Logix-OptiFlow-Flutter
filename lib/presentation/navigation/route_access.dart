import '../../domain/entities/patient_session.dart';
import '../../domain/entities/user_role.dart';

String homePath(PatientSession? session) => session?.isAuthenticated != true
    ? '/auth'
    : session!.isPatient ? '/p/home' : '/s/home';

// Keep direct links and visible navigation under the same role policy.
bool canAccessPath(PatientSession? session, String path) {
  if (session?.isAuthenticated != true) return false;
  if (session!.isPatient) return path.startsWith('/p/');
  if (!path.startsWith('/s/')) return false;
  if (const {'/s/home', '/s/more', '/s/settings'}.contains(path)) return true;
  final feature = switch (path) {
    '/s/agenda' || '/s/appointments/new' => StaffFeature.agenda,
    '/s/patients' || '/s/patients/new' => StaffFeature.patients,
    '/s/clinical' || '/s/evaluation' || '/s/work-order' => StaffFeature.clinical,
    '/s/inventory' || '/s/scanner' => StaffFeature.stock,
    '/s/movement' => StaffFeature.inventory,
    '/s/production' => StaffFeature.production,
    '/s/quote' => StaffFeature.quotes,
    '/s/sale' || '/s/sale/done' => StaffFeature.sales,
    '/s/alerts' => StaffFeature.alerts,
    '/s/reports' => StaffFeature.reports,
    _ when path.startsWith('/s/patient/') => StaffFeature.patients,
    _ when path.startsWith('/s/product/') => StaffFeature.stock,
    _ when path.startsWith('/s/stock/') => StaffFeature.inventory,
    _ => null,
  };
  return feature != null && session.role.can(feature);
}

String? routeRedirect(PatientSession? session, Uri uri) {
  if (session?.isAuthenticated != true) return uri.path == '/auth' ? null : '/auth';
  if (uri.path == '/' || uri.path == '/auth') return homePath(session);
  // Preserve old staff settings links without exposing patient pages to staff.
  if (!session!.isPatient && uri.path == '/p/settings' && uri.queryParameters['staff'] == 'true') {
    return '/s/settings';
  }
  return canAccessPath(session, uri.path) ? null : homePath(session);
}
