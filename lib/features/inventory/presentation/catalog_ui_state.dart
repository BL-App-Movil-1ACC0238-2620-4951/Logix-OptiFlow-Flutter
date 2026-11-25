import 'package:flutter/foundation.dart';

import 'package:logix_optiflow/features/inventory/domain/frame.dart';
import 'package:logix_optiflow/features/inventory/domain/frame_stock.dart';
import 'package:logix_optiflow/features/inventory/domain/inventory.dart';
import 'package:logix_optiflow/features/inventory/domain/product.dart';

class CatalogUiState {
  const CatalogUiState({
    this.frames = const [],
    this.framesBySku = const {},
    this.products = const [],
    this.productsBySku = const {},
    this.catalogLoading = false,
    this.catalogError,
    this.inventoryLoading = false,
    this.inventoryError,
    this.frameLoading = const {},
    this.frameErrors = const {},
    this.suppliers = const [],
    this.suppliersLoading = false,
    this.suppliersError,
    this.movements = const [],
    this.movementsLoading = false,
    this.movementsError,
    this.mutationBusy = false,
    this.mutationError,
    this.favorites = const {},
    this.stock,
  });

  final List<FrameItem> frames;
  final Map<String, FrameItem> framesBySku;
  final List<ProductItem> products;
  final Map<String, ProductItem> productsBySku;
  final bool catalogLoading;
  final String? catalogError;
  final bool inventoryLoading;
  final String? inventoryError;
  final Set<String> frameLoading;
  final Map<String, String> frameErrors;
  final List<Supplier> suppliers;
  final bool suppliersLoading;
  final String? suppliersError;
  final List<StockMovement> movements;
  final bool movementsLoading;
  final String? movementsError;
  final bool mutationBusy;
  final String? mutationError;
  /// SKUs favoritos del paciente.
  final Set<String> favorites;
  /// Stock por óptica de la montura abierta; null mientras se consulta.
  final List<FrameStock>? stock;

  /// Formas del catálogo, sin repetir, para los filtros.
  List<String> get shapes => frames.map((f) => f.shape).whereType<String>().toSet().toList();

  CatalogUiState copyWith({
    List<FrameItem>? frames,
    Map<String, FrameItem>? framesBySku,
    List<ProductItem>? products,
    Map<String, ProductItem>? productsBySku,
    bool? catalogLoading,
    ValueGetter<String?>? catalogError,
    bool? inventoryLoading,
    ValueGetter<String?>? inventoryError,
    Set<String>? frameLoading,
    Map<String, String>? frameErrors,
    List<Supplier>? suppliers,
    bool? suppliersLoading,
    ValueGetter<String?>? suppliersError,
    List<StockMovement>? movements,
    bool? movementsLoading,
    ValueGetter<String?>? movementsError,
    bool? mutationBusy,
    ValueGetter<String?>? mutationError,
    Set<String>? favorites,
    ValueGetter<List<FrameStock>?>? stock,
  }) {
    return CatalogUiState(
      frames: frames ?? this.frames,
      framesBySku: framesBySku ?? this.framesBySku,
      products: products ?? this.products,
      productsBySku: productsBySku ?? this.productsBySku,
      catalogLoading: catalogLoading ?? this.catalogLoading,
      catalogError: catalogError != null ? catalogError() : this.catalogError,
      inventoryLoading: inventoryLoading ?? this.inventoryLoading,
      inventoryError: inventoryError != null ? inventoryError() : this.inventoryError,
      frameLoading: frameLoading ?? this.frameLoading,
      frameErrors: frameErrors ?? this.frameErrors,
      suppliers: suppliers ?? this.suppliers,
      suppliersLoading: suppliersLoading ?? this.suppliersLoading,
      suppliersError: suppliersError != null ? suppliersError() : this.suppliersError,
      movements: movements ?? this.movements,
      movementsLoading: movementsLoading ?? this.movementsLoading,
      movementsError: movementsError != null ? movementsError() : this.movementsError,
      mutationBusy: mutationBusy ?? this.mutationBusy,
      mutationError: mutationError != null ? mutationError() : this.mutationError,
      favorites: favorites ?? this.favorites,
      stock: stock != null ? stock() : this.stock,
    );
  }
}
