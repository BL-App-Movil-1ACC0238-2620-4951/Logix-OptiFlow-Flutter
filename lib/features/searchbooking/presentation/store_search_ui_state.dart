import 'package:flutter/foundation.dart';

import 'package:logix_optiflow/features/searchbooking/domain/geo_point.dart';
import 'package:logix_optiflow/features/searchbooking/domain/optical_store.dart';

/// Chips de la búsqueda: todas, las cercanas (`lat`/`lng`/`radiusKm`) o por primer turno libre.
enum StoreFilter {
  all('Todas'),
  nearby('Cerca de mí'),
  firstSlot('Primera hora');

  const StoreFilter(this.label);

  final String label;
}

class StoreSearchUiState {
  const StoreSearchUiState({
    this.query = '',
    this.results = const [],
    this.loading = false,
    this.message,
    this.error,
    this.stores = const [],
    this.filter = StoreFilter.all,
    this.userLocation,
    this.firstSlots = const {},
    this.favoriteIds = const {},
  });

  final String query;
  final List<OpticalStore> results;
  final bool loading;
  final String? message;
  final String? error;

  /// Todas las ópticas, sin filtros (para citas, reservas y el nombre de la óptica del personal).
  final List<OpticalStore> stores;
  final StoreFilter filter;
  final GeoPoint? userLocation;

  /// Primer turno libre de cada óptica.
  final Map<String, DateTime> firstSlots;
  final Set<String> favoriteIds;

  double? distanceKm(OpticalStore store) {
    final user = userLocation;
    if (user == null || !store.hasLocation) return null;
    return user.distanceKmTo(GeoPoint(store.latitude!, store.longitude!));
  }

  /// Ópticas en el orden del chip elegido: por distancia si hay ubicación, o por primer turno.
  List<OpticalStore> get visibleStores {
    if (filter == StoreFilter.firstSlot) {
      final far = DateTime(9999);
      return [...results]..sort((a, b) => (firstSlots[a.id] ?? far).compareTo(firstSlots[b.id] ?? far));
    }
    if (userLocation == null) return results;
    return [...results]..sort((a, b) => (distanceKm(a) ?? double.maxFinite).compareTo(distanceKm(b) ?? double.maxFinite));
  }

  StoreSearchUiState copyWith({
    String? query,
    List<OpticalStore>? results,
    bool? loading,
    ValueGetter<String?>? message,
    ValueGetter<String?>? error,
    List<OpticalStore>? stores,
    StoreFilter? filter,
    ValueGetter<GeoPoint?>? userLocation,
    Map<String, DateTime>? firstSlots,
    Set<String>? favoriteIds,
  }) {
    return StoreSearchUiState(
      query: query ?? this.query,
      results: results ?? this.results,
      loading: loading ?? this.loading,
      message: message != null ? message() : this.message,
      error: error != null ? error() : this.error,
      stores: stores ?? this.stores,
      filter: filter ?? this.filter,
      userLocation: userLocation != null ? userLocation() : this.userLocation,
      firstSlots: firstSlots ?? this.firstSlots,
      favoriteIds: favoriteIds ?? this.favoriteIds,
    );
  }
}
