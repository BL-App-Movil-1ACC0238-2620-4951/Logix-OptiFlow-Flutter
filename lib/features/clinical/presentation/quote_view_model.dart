import 'package:flutter/foundation.dart';

import 'package:logix_optiflow/features/auth/presentation/session_view_model.dart';
import 'package:logix_optiflow/features/clinical/domain/commerce_repository.dart';
import 'package:logix_optiflow/features/clinical/presentation/quote_flow.dart';

/// Cotización de un paciente a partir de su receta.
class QuoteViewModel extends ChangeNotifier {
  QuoteViewModel({required this.session, required this.repository}) {
    session.addLogoutListener(_reset);
  }

  final SessionViewModel session;
  final CommerceRepository repository;

  /// Cotización en curso; se reemplaza al abrir otro paciente.
  QuoteFlow? get flow => _flow;
  QuoteFlow? _flow;

  void _reset() {
    _flow?.dispose();
    _flow = null;
    notifyListeners();
  }

  Future<void> start(String patientId) async {
    if (!session.canOpen('/s/quote')) return;
    final current = session.session;
    _flow?.dispose();
    final flow = QuoteFlow(repository: repository, patientId: patientId, storeId: current?.opticalStoreId,
      isActive: () => identical(current, session.session) && session.canOpen('/s/quote'), onChanged: notifyListeners);
    _flow = flow;
    await flow.load();
  }

  @override
  void dispose() {
    _flow?.dispose();
    super.dispose();
  }
}
