import 'package:logix_optiflow/features/inventory/domain/product.dart';

/// Productos de muestra del inventario del personal (se reemplazan por la API en la rama de datos demo).
class InventoryLocalDataSource {
  static const products = <ProductItem>[
    ProductItem(id: 'rb5154', name: 'Ray-Ban Clubmaster', sku: 'RB5154', code: 'RB-5154-51-21', detail: 'Carey / Dorado · Acetato', price: '\$189.000', tag: 'Alta demanda', available: 4, image: 'assets/images/img_inv_clubmaster.png', category: 'Armazones', size: '51-21-145', location: 'Vitrina Centro', supplier: 'EssilorLuxottica'),
    ProductItem(id: 'holbrook', name: 'Holbrook RX', sku: 'OX8156', code: 'OX-8156-54-18', detail: 'Negro mate · O-Matter', price: '\$165.000', tag: 'Deportivo', available: 2, image: 'assets/images/img_inv_holbrook.png', category: 'Armazones', size: '54-18-137', location: 'Vitrina Centro', supplier: 'Oakley'),
    ProductItem(id: 'titan', name: 'Titan Minimal', sku: 'TM1520', code: 'TM-1520-52-17', detail: 'Sin montura · Titanio', price: '\$290.000', tag: 'Titanio', available: 6, image: 'assets/images/img_inv_titan.png', category: 'Armazones', size: '52-17-140', location: 'Vitrina Norte', supplier: 'Silhouette'),
    ProductItem(id: 'vo5282', name: 'VO5282B Cat-Eye', sku: 'VO5282B', code: 'VO-5282-53-17', detail: 'Borgoña · Acetato fino', price: '\$138.000', tag: 'Última unidad', available: 1, image: 'assets/images/img_inv_vogue.png', category: 'Armazones', size: '53-17-140', location: 'Cajón Taller', supplier: 'Vogue Eyewear'),
  ];

  static ProductItem product(String id) => products.firstWhere((item) => item.id == id, orElse: () => products.first);
}
