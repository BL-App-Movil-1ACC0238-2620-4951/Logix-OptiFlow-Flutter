import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:logix_optiflow/core/errors/api_exception.dart';
import 'package:logix_optiflow/features/auth/presentation/session_view_model.dart';
import 'package:logix_optiflow/features/searchbooking/application/get_current_location_use_case.dart';
import 'package:logix_optiflow/features/searchbooking/application/get_first_available_slots_use_case.dart';
import 'package:logix_optiflow/features/searchbooking/application/get_nearby_optical_stores_use_case.dart';
import 'package:logix_optiflow/features/searchbooking/application/get_optical_stores_use_case.dart';
import 'package:logix_optiflow/features/searchbooking/application/save_favorite_store_use_case.dart';
import 'package:logix_optiflow/features/searchbooking/application/search_optical_stores_use_case.dart';
import 'package:logix_optiflow/features/searchbooking/domain/optical_store.dart';
import 'package:logix_optiflow/features/searchbooking/presentation/store_search_ui_state.dart';

/// Búsqueda de ópticas del paciente (filtros, ubicación y mapa) y lista completa de ópticas.
class StoreSearchViewModel extends ChangeNotifier {
  StoreSearchViewModel({
    required this.session,
    required this.getOpticalStoresUseCase,
    required this.searchOpticalStoresUseCase,
    required this.getNearbyOpticalStoresUseCase,
    required this.getFirstAvailableSlotsUseCase,
    required this.saveFavoriteStoreUseCase,
    required this.getCurrentLocationUseCase,
  }) {
    session.addLogoutListener(_reset);
  }

  final SessionViewModel session;
  final GetOpticalStoresUseCase getOpticalStoresUseCase;
  final SearchOpticalStoresUseCase searchOpticalStoresUseCase;
  final GetNearbyOpticalStoresUseCase getNearbyOpticalStoresUseCase;
  final GetFirstAvailableSlotsUseCase getFirstAvailableSlotsUseCase;
  final SaveFavoriteStoreUseCase saveFavoriteStoreUseCase;
  final GetCurrentLocationUseCase getCurrentLocationUseCase;

  StoreSearchUiState _state = const StoreSearchUiState();
  StoreSearchUiState get state => _state;
  int _searchRequest = 0;
  bool _askedLocation = false;

  void _emit(StoreSearchUiState value) {
    _state = value;
    notifyListeners();
  }

  void _reset() {
    _searchRequest++;
    _askedLocation = false;
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

  /// Se llama al abrir la búsqueda o el mapa. El permiso se pide una sola vez por sesión,
  /// salvo que [ask] lo fuerce (al tocar "Cerca de mí").
  Future<void> refreshLocation({bool ask = false}) async {
    final shouldAsk = ask || !_askedLocation;
    _askedLocation = true;
    final location = await getCurrentLocationUseCase.execute(ask: shouldAsk);
    if (location == null) return;
    final hadLocation = _state.userLocation != null;
    _emit(_state.copyWith(userLocation: () => location));
    if (!hadLocation && _state.filter == StoreFilter.nearby) unawaited(searchStores());
  }

  void setFilter(StoreFilter filter) {
    _emit(_state.copyWith(filter: filter, error: () => null));
    if (filter == StoreFilter.nearby && _state.userLocation == null) unawaited(refreshLocation(ask: true));
    unawaited(searchStores());
  }

  void setSearchQuery(String value) {
    _state = _state.copyWith(query: value, error: () => null);
    _searchRequest++; // Descarta respuestas anteriores durante la espera del debounce.
  }

  Future<void> searchStores() async {
    final request = ++_searchRequest;
    final name = _state.query.trim().isEmpty ? null : _state.query.trim();
    final location = _state.userLocation;
    _emit(_state.copyWith(loading: true, error: () => null, message: () => null));
    if (_state.filter == StoreFilter.nearby && location == null) {
      _emit(_state.copyWith(loading: false, results: const [], message: () => 'Activa la ubicación para ver las ópticas cercanas.'));
      return;
    }
    try {
      List<OpticalStore> found;
      String? message;
      if (_state.filter == StoreFilter.nearby && location != null) {
        final nearby = await getNearbyOpticalStoresUseCase.execute(location);
        found = nearby.where((s) => name == null || s.name.toLowerCase().contains(name.toLowerCase())).toList();
        if (found.isEmpty) message = 'No hay ópticas a menos de 5 km.';
      } else {
        final result = await searchOpticalStoresUseCase.execute(name: name);
        found = result.stores;
        message = result.message;
      }
      if (request != _searchRequest) return;
      _emit(_state.copyWith(results: found, loading: false, message: () => found.isEmpty ? message : null));
      unawaited(_loadFirstSlots(found));
    } catch (e) {
      if (request != _searchRequest) return;
      _emit(_state.copyWith(results: const [], loading: false, error: () => e is ApiException ? e.message : 'No se pudieron buscar las ópticas.'));
    }
  }

  /// Guarda la óptica como favorita con `POST /patients/{id}/favorites`. El backend no tiene
  /// listado ni borrado de favoritas; un 409 significa que ya estaba guardada.
  Future<void> saveFavorite(String storeId) async {
    final current = session.session;
    if (_state.favoriteIds.contains(storeId) || current == null) return;
    try {
      await saveFavoriteStoreUseCase.execute(current.patientId, storeId);
    } on ApiException catch (e) {
      if (e.statusCode != 409) {
        _emit(_state.copyWith(error: () => e.message));
        return;
      }
    } catch (_) {
      _emit(_state.copyWith(error: () => 'No se pudo guardar la óptica.'));
      return;
    }
    _emit(_state.copyWith(favoriteIds: {..._state.favoriteIds, storeId}, message: () => 'Óptica guardada en tus favoritas.'));
  }

  Future<void> _loadFirstSlots(List<OpticalStore> stores) async {
    final missing = stores.map((s) => s.id).where((id) => !_state.firstSlots.containsKey(id)).toList();
    if (missing.isEmpty) return;
    final slots = await getFirstAvailableSlotsUseCase.execute(missing);
    if (slots.isEmpty) return;
    _emit(_state.copyWith(firstSlots: {..._state.firstSlots, ...slots}));
  }
}
