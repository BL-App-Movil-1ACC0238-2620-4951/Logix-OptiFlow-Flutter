import 'package:shared_preferences/shared_preferences.dart';

import 'package:logix_optiflow/features/inventory/domain/favorite_frame_repository.dart';

class FavoriteFrameRepositoryImpl implements FavoriteFrameRepository {
  const FavoriteFrameRepositoryImpl();

  String _key(String patientId) => 'favorite_frames_$patientId';

  @override
  Future<Set<String>> favorites(String patientId) async =>
      ((await SharedPreferences.getInstance()).getStringList(_key(patientId)) ?? const []).toSet();

  @override
  Future<Set<String>> toggle(String patientId, String sku) async {
    final prefs = await SharedPreferences.getInstance();
    final current = (prefs.getStringList(_key(patientId)) ?? const []).toSet();
    if (!current.remove(sku)) current.add(sku);
    await prefs.setStringList(_key(patientId), current.toList());
    return current;
  }
}
