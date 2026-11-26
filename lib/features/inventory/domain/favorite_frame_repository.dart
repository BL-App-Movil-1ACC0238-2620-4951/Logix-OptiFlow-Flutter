/// Monturas favoritas del paciente, guardadas en el teléfono por SKU.
abstract class FavoriteFrameRepository {
  Future<Set<String>> favorites(String patientId);

  /// Agrega o quita el SKU y devuelve los favoritos actualizados.
  Future<Set<String>> toggle(String patientId, String sku);
}
