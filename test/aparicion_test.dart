import 'dart:math';

import 'package:dolores_rally/dominio/aparicion.dart';
import 'package:dolores_rally/dominio/catalogo.dart';
import 'package:dolores_rally/dominio/geo.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ayudas.dart';

void main() {
  test('genera una aparición por personaje', () {
    final a = generarApariciones(centro: origen, personajes: personajes, random: Random(1));
    expect(a.length, personajes.length);
    expect(a.map((x) => x.personaje.id).toSet().length, personajes.length);
  });

  test('todas quedan entre el radio mínimo y el máximo', () {
    final a = generarApariciones(
        centro: origen, personajes: personajes, random: Random(7), radioMin: 60, radioMax: 500);
    for (final x in a) {
      final d = distanciaMetros(origen, x.coordenada);
      expect(d, inInclusiveRange(59.9, 500.1));
    }
  });

  test('con la misma semilla el "azar" se repite (pruebas confiables)', () {
    final a = generarApariciones(centro: origen, personajes: personajes, random: Random(42));
    final b = generarApariciones(centro: origen, personajes: personajes, random: Random(42));
    for (var i = 0; i < a.length; i++) {
      expect(a[i].coordenada.lat, b[i].coordenada.lat);
      expect(a[i].coordenada.lon, b[i].coordenada.lon);
    }
  });

  test('con semillas distintas los lugares son distintos', () {
    final a = generarApariciones(centro: origen, personajes: personajes, random: Random(1));
    final b = generarApariciones(centro: origen, personajes: personajes, random: Random(2));
    expect(a.first.coordenada.lat, isNot(b.first.coordenada.lat));
  });

  test('los puntos se reparten por TODAS las direcciones', () {
    final r = Random(5);
    final rumbos = [
      for (var i = 0; i < 400; i++) rumboGrados(origen, puntoAleatorio(origen, 60, 500, r))
    ];
    for (final cuadrante in [0, 90, 180, 270]) {
      expect(rumbos.where((g) => g >= cuadrante && g < cuadrante + 90).length, greaterThan(60),
          reason: 'cuadrante $cuadrante');
    }
  });
  test('dos personajes nunca quedan a menos de 30 m entre sí', () {
    for (final semilla in [1, 2, 3, 4, 5, 42, 99]) {
      final a = generarApariciones(
          centro: origen, personajes: personajes, random: Random(semilla));
      for (var i = 0; i < a.length; i++) {
        for (var j = i + 1; j < a.length; j++) {
          final d = distanciaMetros(a[i].coordenada, a[j].coordenada);
          expect(d, greaterThanOrEqualTo(30),
              reason: 'semilla $semilla: ${a[i].personaje.id} y ${a[j].personaje.id}');
        }
      }
    }
  });
    test('si la regla es imposible de cumplir, falla en vez de ciclarse', () {
    expect(
      () => generarApariciones(
        centro: origen,
        personajes: personajes,
        random: Random(1),
        radioMin: 60,
        radioMax: 61,
        separacionMin: 1000,
      ),
      throwsStateError,
    );
  });
  test('con separacionMin en 0 la regla se desactiva', () {
    final a = generarApariciones(
        centro: origen,
        personajes: personajes,
        random: Random(1),
        separacionMin: 0);
    expect(a.length, personajes.length);
  });
}
