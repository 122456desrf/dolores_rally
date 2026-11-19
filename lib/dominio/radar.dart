import 'dart:math' as math;

import 'geo.dart';

/// Posición de [objetivo] en un radar circular centrado en el jugador.
/// Devuelve (x, y) entre -1 y 1. Arriba (y negativo) = hacia donde miras.
/// Null si queda más lejos que [alcance] metros.
(double, double)? puntoEnRadar({
  required Coordenada usuario,
  required double rumbo,
  required Coordenada objetivo,
  double alcance = 500,
}) {
  final d = distanciaMetros(usuario, objetivo);
  if (d > alcance) return null;
  final dif = diferenciaAngular(rumboGrados(usuario, objetivo), rumbo) * math.pi / 180;
  final f = d / alcance;
  return (f * math.sin(dif), -f * math.cos(dif));
}

enum Temperatura { ardiente, caliente, tibio, frio, helado }


/// El juego de "frío o caliente": qué tan cerca estás de tu objetivo.
Temperatura temperaturaPorDistancia(double metros) {
  if (metros <= 15) return Temperatura.ardiente;
  if (metros <= 50) return Temperatura.caliente;
  if (metros <= 150) return Temperatura.tibio;
  if (metros <= 400) return Temperatura.frio;
  return Temperatura.helado;
}

extension TextoTemperatura on Temperatura {
  String get texto => switch (this) {
        Temperatura.helado => '🥶 Helado',
        Temperatura.frio => '❄️ Frío',
        Temperatura.tibio => '🙂 Tibio',
        Temperatura.caliente => '🔥 Caliente',
        Temperatura.ardiente => '🌋 ¡Ardiendo! Atrápalo',
      };
}
