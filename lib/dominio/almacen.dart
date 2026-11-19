/// Contrato para guardar el progreso. Solo guardamos ids y puntaje:
/// NUNCA coordenadas del jugador (privacidad).
abstract class AlmacenColeccion {
  Future<Set<String>> cargarCapturados();
  Future<void> guardarCapturados(Set<String> ids);
  Future<int> cargarMejorPuntaje();
  Future<void> guardarMejorPuntaje(int puntos);
}

/// En memoria: para pruebas y para el modo demo (no ensucia el progreso real).
class AlmacenMemoria implements AlmacenColeccion {
  Set<String> _ids = {};
  int _mejor = 0;

  @override
  Future<Set<String>> cargarCapturados() async => {..._ids};
  @override
  Future<void> guardarCapturados(Set<String> ids) async => _ids = {...ids};
  @override
  Future<int> cargarMejorPuntaje() async => _mejor;
  @override
  Future<void> guardarMejorPuntaje(int puntos) async => _mejor = puntos;
}
