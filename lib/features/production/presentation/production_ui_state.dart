import 'package:flutter/foundation.dart';

import 'package:logix_optiflow/features/production/domain/production_order.dart';
import 'package:logix_optiflow/features/production/domain/staff_order.dart';

class ProductionUiState {
  const ProductionUiState({
    this.orders = const [],
    this.loading = false,
    this.error,
    this.productionOrders = const [],
  });

  final List<StaffOrder> orders;
  final bool loading;
  final String? error;

  /// Tablero de producción de muestra (se reemplaza por la API en la rama de datos demo).
  final List<ProductionOrder> productionOrders;

  ProductionUiState copyWith({List<StaffOrder>? orders, bool? loading, ValueGetter<String?>? error, List<ProductionOrder>? productionOrders}) {
    return ProductionUiState(
      orders: orders ?? this.orders,
      loading: loading ?? this.loading,
      error: error != null ? error() : this.error,
      productionOrders: productionOrders ?? this.productionOrders,
    );
  }
}
