import 'package:shared_preferences/shared_preferences.dart';

import '../dominio/almacen.dart';

/// Guarda el progreso en el teléfono (sin internet, sin servidores).
class AlmacenPrefs implements AlmacenColeccion {
  static const _claveIds = 'capturados';
  static const _claveMejor = 'mejor_puntaje';

  @override
  Future<Set<String>> cargarCapturados() async {
    final p = await SharedPreferences.getInstance();
    return (p.getStringList(_claveIds) ?? const <String>[]).toSet();
  }

  @override
  Future<void> guardarCapturados(Set<String> ids) async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList(_claveIds, ids.toList());
  }

  @override
  Future<int> cargarMejorPuntaje() async =>
      (await SharedPreferences.getInstance()).getInt(_claveMejor) ?? 0;

  @override
  Future<void> guardarMejorPuntaje(int puntos) async =>
      (await SharedPreferences.getInstance()).setInt(_claveMejor, puntos);
}
