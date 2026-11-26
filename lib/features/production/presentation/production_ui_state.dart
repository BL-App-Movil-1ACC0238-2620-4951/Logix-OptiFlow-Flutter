import 'package:flutter/foundation.dart';

import 'package:logix_optiflow/features/production/domain/staff_order.dart';

class ProductionUiState {
  const ProductionUiState({
    this.orders = const [],
    this.loading = false,
    this.error,
    this.patientNames = const {},
  });

  final List<StaffOrder> orders;
  final bool loading;
  final String? error;

  /// Nombre de cada paciente con orden, por su id.
  final Map<String, String> patientNames;

  ProductionUiState copyWith({List<StaffOrder>? orders, bool? loading, ValueGetter<String?>? error, Map<String, String>? patientNames}) {
    return ProductionUiState(
      orders: orders ?? this.orders,
      loading: loading ?? this.loading,
      error: error != null ? error() : this.error,
      patientNames: patientNames ?? this.patientNames,
    );
  }
}
