import 'dart:math' as math;

import 'geo.dart';
import 'personaje.dart';

/// Un personaje escondido en un punto del mapa.
class Aparicion {
  final Personaje personaje;
  final Coordenada coordenada;
  const Aparicion(this.personaje, this.coordenada);
}

/// Punto al azar entre [min] y [max] metros del [centro].
/// Se usa raíz cuadrada para que los puntos queden repartidos de forma PAREJA
/// por el área (sin ella, se amontonarían cerca del centro).
Coordenada puntoAleatorio(Coordenada centro, double min, double max, math.Random random) {
  final distancia = math.sqrt(min * min + random.nextDouble() * (max * max - min * min));
  return destino(centro, random.nextDouble() * 360, distancia);
}

/// El [random] se inyecta: con una semilla fija (Random(42)) el "azar" es repetible
/// y las pruebas son confiables; en el juego real se usa Random() sin semilla.
///
/// Dos personajes no quedan a menos de [separacionMin] metros. Por cada
/// personaje se prueban hasta [maxIntentos] puntos; si ninguno cumple la regla,
/// lanza StateError (así una regla imposible no se cicla para siempre).
List<Aparicion> generarApariciones({
  required Coordenada centro,
  required List<Personaje> personajes,
  required math.Random random,
  double radioMin = 60,
  double radioMax = 500,
  double separacionMin = 30,
  int maxIntentos = 100,
}) {
  final resultado = <Aparicion>[];
  for (final p in personajes) {
    Coordenada? elegido;
    for (var i = 0; i < maxIntentos && elegido == null; i++) {
      final candidato = puntoAleatorio(centro, radioMin, radioMax, random);
      final libre = resultado.every(
          (a) => distanciaMetros(a.coordenada, candidato) >= separacionMin);
      if (libre) elegido = candidato;
    }
    if (elegido == null) {
      throw StateError(
          'No hay lugar para ${p.nombre} con separación de $separacionMin m');
    }
    resultado.add(Aparicion(p, elegido));
  }
  return resultado;
}