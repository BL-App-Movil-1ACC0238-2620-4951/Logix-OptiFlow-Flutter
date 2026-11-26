import 'package:flutter/foundation.dart';

import 'package:logix_optiflow/features/auth/presentation/session_view_model.dart';
import 'package:logix_optiflow/features/clinical/domain/clinical_repository.dart';
import 'package:logix_optiflow/features/clinical/presentation/clinical_care_flow.dart';
import 'package:logix_optiflow/features/searchbooking/presentation/agenda_view_model.dart';
import 'package:logix_optiflow/features/searchbooking/presentation/staff_patients_view_model.dart';

/// Atención clínica de una cita: examen, antecedentes y receta.
class ClinicalCareViewModel extends ChangeNotifier {
  ClinicalCareViewModel({required this.session, required this.repository, required this.agenda, required this.patients}) {
    session.addLogoutListener(_reset);
  }

  final SessionViewModel session;
  final ClinicalRepository repository;
  final AgendaViewModel agenda;
  final StaffPatientsViewModel patients;

  /// Atención en curso; se reemplaza al abrir otra cita.
  ClinicalCareFlow? get flow => _flow;
  ClinicalCareFlow? _flow;

  void _reset() {
    _flow?.dispose();
    _flow = null;
    notifyListeners();
  }

  Future<void> start(String patientId, String appointmentId) async {
    if (!session.canOpen('/s/clinical')) return;
    final current = session.session;
    _flow?.dispose();
    final flow = ClinicalCareFlow(
      repository: repository, patientId: patientId, appointmentId: appointmentId,
      isActive: () => identical(current, session.session) && session.canOpen('/s/clinical'),
      onChanged: notifyListeners,
      onCompleted: () async { await Future.wait([agenda.refreshStaffAgenda(), patients.loadStaffRecord(patientId)]); },
    );
    _flow = flow;
    await flow.load();
  }

  @override
  void dispose() {
    _flow?.dispose();
    super.dispose();
  }
}
