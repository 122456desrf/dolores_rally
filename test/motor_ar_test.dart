import 'package:dolores_rally/dominio/aparicion.dart';
import 'package:dolores_rally/dominio/geo.dart';
import 'package:dolores_rally/dominio/motor_ar.dart';
import 'package:dolores_rally/dominio/personaje.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ayudas.dart';

Aparicion en(String id, double rumbo, double metros) => Aparicion(
      Personaje(
        id: id, nombre: id, emoji: '🎯', bio: '',
        pregunta: const Pregunta('?', ['a', 'b'], 0),
      ),
      destino(origen, rumbo, metros),
    );

void main() {
  test('un personaje justo adelante aparece en el centro de la pantalla', () {
    final v = calcularVisibles(usuario: origen, rumbo: 0, apariciones: [en('a', 0, 100)]);
    expect(v.single.x, closeTo(0.5, 0.01));
    expect(v.single.distancia, closeTo(100, 0.5));
  });

  test('uno a 90° de donde miras no aparece; al girar hacia él, sí', () {
    final a = en('a', 90, 100);
    expect(calcularVisibles(usuario: origen, rumbo: 0, apariciones: [a]), isEmpty);
    expect(calcularVisibles(usuario: origen, rumbo: 90, apariciones: [a]), hasLength(1));
  });

  test('funciona al cruzar el norte (miras a 350° y está a 5°)', () {
    final v = calcularVisibles(usuario: origen, rumbo: 350, apariciones: [en('a', 5, 100)]);
    expect(v, hasLength(1));
    expect(v.single.x, greaterThan(0.5));
  });

  test('los lejanos van primero y se ven más pequeños', () {
    final v = calcularVisibles(
        usuario: origen, rumbo: 0, apariciones: [en('cerca', 0, 40), en('lejos', 0, 450)]);
    expect(v.map((x) => x.aparicion.personaje.id), ['lejos', 'cerca']);
    expect(v.last.escala, greaterThan(v.first.escala));
  });

  test('más allá del radio máximo se descartan', () {
    final v = calcularVisibles(
        usuario: origen, rumbo: 0, apariciones: [en('a', 0, 900)], radioMax: 600);
    expect(v, isEmpty);
  });
}
