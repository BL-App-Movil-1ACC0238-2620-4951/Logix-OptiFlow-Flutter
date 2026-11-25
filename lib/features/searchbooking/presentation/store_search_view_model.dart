import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:logix_optiflow/core/errors/api_exception.dart';
import 'package:logix_optiflow/features/auth/presentation/session_view_model.dart';
import 'package:logix_optiflow/features/searchbooking/application/get_optical_stores_use_case.dart';
import 'package:logix_optiflow/features/searchbooking/application/search_optical_stores_use_case.dart';
import 'package:logix_optiflow/features/searchbooking/domain/optical_store.dart';
import 'package:logix_optiflow/features/searchbooking/presentation/store_search_ui_state.dart';

/// Búsqueda de ópticas del paciente y lista completa de ópticas.
class StoreSearchViewModel extends ChangeNotifier {
  StoreSearchViewModel({required this.session, required this.getOpticalStoresUseCase, required this.searchOpticalStoresUseCase}) {
    session.addLogoutListener(_reset);
  }

  final SessionViewModel session;
  final GetOpticalStoresUseCase getOpticalStoresUseCase;
  final SearchOpticalStoresUseCase searchOpticalStoresUseCase;

  StoreSearchUiState _state = const StoreSearchUiState();
  StoreSearchUiState get state => _state;
  int _searchRequest = 0;

  void _emit(StoreSearchUiState value) {
    _state = value;
    notifyListeners();
  }

  void _reset() {
    _searchRequest++;
    _emit(StoreSearchUiState(stores: _state.stores));
  }

  /// Nombre de la óptica asignada al personal, o su rol si aún no se conoce.
  String get staffStoreName =>
      _state.stores.where((s) => s.id == session.session?.opticalStoreId).firstOrNull?.name ?? session.session?.role.label ?? '';

  /// Carga todas las ópticas y las guarda en [StoreSearchUiState.stores].
  Future<List<OpticalStore>> loadStores() async {
    final loaded = await getOpticalStoresUseCase.execute();
    _emit(_state.copyWith(stores: loaded));
    return loaded;
  }

  Future<void> searchStores() async {
    final request = ++_searchRequest;
    _emit(_state.copyWith(loading: true, error: () => null, message: () => null));
    try {
      final result = await searchOpticalStoresUseCase.execute(
        name: _state.query.trim().isEmpty ? null : _state.query.trim(),
        address: _state.address.trim().isEmpty ? null : _state.address.trim(),
        minRating: _state.minRating,
      );
      if (request != _searchRequest) return;
      _state = _state.copyWith(results: result.stores, message: () => result.message);
    } catch (e) {
      if (request != _searchRequest) return;
      _state = _state.copyWith(results: const [], error: () => e is ApiException ? e.message : 'No se pudieron buscar las ópticas.');
    } finally {
      if (request == _searchRequest) _emit(_state.copyWith(loading: false));
    }
  }

  void setSearchQuery(String value) {
    _state = _state.copyWith(query: value);
    _searchRequest++; // Invalidate earlier responses during the debounce interval.
  }

  void setSearchAddress(String value) {
    _state = _state.copyWith(address: value);
    _searchRequest++;
  }

  void setMinRating(double? value) {
    _state = _state.copyWith(minRating: () => value);
    unawaited(searchStores());
  }
}
