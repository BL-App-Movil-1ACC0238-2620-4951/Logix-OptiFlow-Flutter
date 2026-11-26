import 'package:flutter/foundation.dart';

import 'package:logix_optiflow/features/searchbooking/domain/optical_store.dart';

class StoreSearchUiState {
  const StoreSearchUiState({
    this.query = '',
    this.address = '',
    this.minRating,
    this.results = const [],
    this.loading = false,
    this.message,
    this.error,
    this.stores = const [],
  });

  final String query;
  final String address;
  final double? minRating;
  final List<OpticalStore> results;
  final bool loading;
  final String? message;
  final String? error;

  /// Todas las ópticas, sin filtros (para citas, reservas y el nombre de la óptica del personal).
  final List<OpticalStore> stores;

  StoreSearchUiState copyWith({
    String? query,
    String? address,
    ValueGetter<double?>? minRating,
    List<OpticalStore>? results,
    bool? loading,
    ValueGetter<String?>? message,
    ValueGetter<String?>? error,
    List<OpticalStore>? stores,
  }) {
    return StoreSearchUiState(
      query: query ?? this.query,
      address: address ?? this.address,
      minRating: minRating != null ? minRating() : this.minRating,
      results: results ?? this.results,
      loading: loading ?? this.loading,
      message: message != null ? message() : this.message,
      error: error != null ? error() : this.error,
      stores: stores ?? this.stores,
    );
  }
}
