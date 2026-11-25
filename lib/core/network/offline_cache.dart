import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:logix_optiflow/core/storage/app_database.dart';

/// Guarda la última respuesta de cada consulta y, si no hay conexión, la devuelve y avisa desde qué
/// fecha es (US20). Solo se usa para lecturas: lo que cambia datos va directo al backend.
class OfflineCache extends ChangeNotifier {
  OfflineCache(this._dao);

  final CachedResponseDao _dao;

  DateTime? _savedDataFrom;

  /// Fecha de los datos guardados que se muestran por falta de conexión, o null si están al día.
  DateTime? get savedDataFrom => _savedDataFrom;

  void _set(DateTime? value) {
    if (_savedDataFrom == value) return;
    _savedDataFrom = value;
    notifyListeners();
  }

  /// Guarda la respuesta descargada; si falla el guardado, la consulta sigue igual.
  Future<void> save(String key, Object? json) async {
    _set(null);
    try {
      await _dao.save(CachedResponse(key: key, json: jsonEncode(json), savedAtMillis: DateTime.now().millisecondsSinceEpoch));
    } catch (_) {}
  }

  /// La respuesta guardada con [key] (como si viniera del backend), o null si no hay.
  Future<(Object?,)?> read(String key) async {
    try {
      final saved = await _dao.get(key);
      if (saved == null) return null;
      final json = jsonDecode(saved.json);
      _set(DateTime.fromMillisecondsSinceEpoch(saved.savedAtMillis));
      return (json,);
    } catch (_) {
      return null;
    }
  }

  /// Borra lo guardado, por ejemplo al cerrar sesión.
  Future<void> clear() async {
    _set(null);
    try {
      await _dao.clear();
    } catch (_) {}
  }
}
