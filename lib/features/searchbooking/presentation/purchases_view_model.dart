import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:logix_optiflow/core/errors/api_exception.dart';
import 'package:logix_optiflow/features/auth/presentation/session_view_model.dart';
import 'package:logix_optiflow/features/clinical/application/create_payment_link_use_case.dart';
import 'package:logix_optiflow/features/clinical/application/get_patient_sales_use_case.dart';
import 'package:logix_optiflow/features/clinical/application/get_quotation_use_case.dart';
import 'package:logix_optiflow/features/clinical/domain/commerce.dart';
import 'package:logix_optiflow/presentation/mappers/patient_view_mapper.dart';
import 'package:logix_optiflow/presentation/models/ui_models.dart';

class PurchasesUiState {
  const PurchasesUiState({
    this.purchases = const [],
    this.loading = true,
    this.error,
    this.payingSaleId,
    this.paymentError,
  });

  final List<PurchaseUi> purchases;
  final bool loading;
  final String? error;
  /// Venta cuyo link de pago se está pidiendo.
  final String? payingSaleId;
  final String? paymentError;

  PurchasesUiState copyWith({
    List<PurchaseUi>? purchases,
    bool? loading,
    ValueGetter<String?>? error,
    ValueGetter<String?>? payingSaleId,
    ValueGetter<String?>? paymentError,
  }) {
    return PurchasesUiState(
      purchases: purchases ?? this.purchases,
      loading: loading ?? this.loading,
      error: error != null ? error() : this.error,
      payingSaleId: payingSaleId != null ? payingSaleId() : this.payingSaleId,
      paymentError: paymentError != null ? paymentError() : this.paymentError,
    );
  }
}

/// Compras del paciente y pago de las pendientes con Mercado Pago.
class PurchasesViewModel extends ChangeNotifier {
  PurchasesViewModel({
    required this.session,
    required this.getPatientSalesUseCase,
    required this.getQuotationUseCase,
    required this.createPaymentLinkUseCase,
  }) {
    session.addSessionReadyListener(_onSessionReady);
    session.addLogoutListener(_reset);
  }

  final SessionViewModel session;
  final GetPatientSalesUseCase getPatientSalesUseCase;
  final GetQuotationUseCase getQuotationUseCase;
  final CreatePaymentLinkUseCase createPaymentLinkUseCase;

  PurchasesUiState _state = const PurchasesUiState();
  PurchasesUiState get state => _state;
  int _request = 0;

  void _emit(PurchasesUiState value) {
    _state = value;
    notifyListeners();
  }

  void _onSessionReady() {
    if (session.session?.isPatient == true) {
      unawaited(load());
    } else {
      _emit(_state.copyWith(loading: false));
    }
  }

  void _reset() {
    _request++;
    _emit(const PurchasesUiState(loading: false));
  }

  Future<void> load() async {
    final current = session.session;
    if (current?.isAuthenticated != true || !current!.isPatient) return;
    final request = ++_request;
    _emit(_state.copyWith(loading: true, error: () => null));
    try {
      final sales = await getPatientSalesUseCase.execute(current.patientId);
      // Una venta pendiente aún no tiene pago ni boleta: el monto sale del total de su cotización.
      final totals = await Future.wait(sales.map((sale) async {
        if (sale.status != SaleStatus.pendingPayment || sale.amount != null) return null;
        try {
          return (await getQuotationUseCase.execute(sale.quotationId)).total;
        } catch (_) {
          return null;
        }
      }));
      if (request != _request) return;
      _emit(_state.copyWith(
        purchases: [for (final (i, sale) in sales.indexed) PatientViewMapper.purchase(sale, totals[i])],
        loading: false,
      ));
    } catch (e) {
      if (request != _request) return;
      _emit(_state.copyWith(loading: false, error: () => e is ApiException ? e.message : 'No se pudieron cargar tus compras.'));
    }
  }

  /// Pide el link de Checkout Pro (`POST sales/{id}/payment-preference`); null si falló.
  Future<String?> paymentLink(String saleId) async {
    if (_state.payingSaleId != null) return null;
    _emit(_state.copyWith(payingSaleId: () => saleId, paymentError: () => null));
    try {
      final url = await createPaymentLinkUseCase.execute(saleId);
      _emit(_state.copyWith(payingSaleId: () => null));
      return url;
    } catch (e) {
      _emit(_state.copyWith(
        payingSaleId: () => null,
        paymentError: () => e is ApiException ? e.message : 'No se pudo abrir Mercado Pago. Intenta nuevamente.',
      ));
      return null;
    }
  }

  void showPaymentError(String message) => _emit(_state.copyWith(paymentError: () => message));
}
