/// El backend no guarda fotos de las monturas; cada SKU usa una de las fotos incluidas en la app.
const _photosBySku = {
  'OK-8156-BLK': 'assets/images/img_frame_pacific.jpg',
  'PR-17WV-TOR': 'assets/images/img_frame_verona.png',
  'RB-3025-GLD': 'assets/images/img_frame_havana.png',
  'RB-5154-BLK': 'assets/images/img_frame_sienna.jpg',
  'TF-5401-HAV': 'assets/images/img_frame_amber.jpg',
  'VO-5276-TRP': 'assets/images/img_frame_roma.jpg',
};

/// Foto de la montura; un SKU que no está en la lista siempre recibe la misma de las seis.
String framePhotoFor(String sku) {
  final photos = _photosBySku.values.toList();
  return _photosBySku[sku] ?? photos[sku.codeUnits.fold<int>(0, (hash, unit) => (hash * 31 + unit) & 0x7fffffff) % photos.length];
}
