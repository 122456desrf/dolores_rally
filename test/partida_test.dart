import 'package:dolores_rally/dominio/aparicion.dart';
import 'package:dolores_rally/dominio/excepciones.dart';
import 'package:dolores_rally/dominio/geo.dart';
import 'package:dolores_rally/dominio/partida.dart';
import 'package:dolores_rally/dominio/personaje.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ayudas.dart';

const _p = Personaje(
  id: 'x',
  nombre: 'Personaje X',
  emoji: '🎯',
  bio: '',
  pregunta: Pregunta('¿2+2?', ['3', '4', '5'], 1),
);

const _escondite = Coordenada(21.2, -100.9);

Partida crear({List<Coordenada>? reubicaciones}) {
  final cola = [...?reubicaciones];
  return Partida(
    [Aparicion(_p, origen)],
    reubicar: () => cola.isEmpty ? _escondite : cola.removeAt(0),
  );
}

void main() {
  test('respuesta correcta y cerca: captura con 100 puntos', () {
    final partida = crear();
    final r = partida.capturar('x', 1, 10);
    expect(r, isA<Capturado>());
    expect((r as Capturado).puntos, 100);
    expect(partida.puntos, 100);
    expect(partida.estaCapturado('x'), true);
    expect(partida.terminada, true);
  });

  test('si estás lejos, ni siquiera se puede intentar', () {
    final partida = crear();
    expect(() => partida.capturar('x', 1, 80), throwsA(isA<LejosException>()));
    expect(partida.puntos, 0);
  });

  test('a exactamente 15 m todavía cuenta', () {
    expect(crear().capturar('x', 1, 15), isA<Capturado>());
  });

  test('una respuesta incorrecta da otra oportunidad', () {
    final partida = crear();
    final r = partida.capturar('x', 0, 5);
    expect(r, isA<Fallo>());
    expect((r as Fallo).intentosRestantes, 1);
    expect(partida.estaCapturado('x'), false);
  });

  test('acertar en el segundo intento vale solo 50 puntos', () {
    final partida = crear();
    partida.capturar('x', 0, 5);
    final r = partida.capturar('x', 1, 5) as Capturado;
    expect(r.puntos, 50);
  });

  test('dos fallos: el personaje se escapa y reaparece en otro lugar', () {
    final partida = crear(reubicaciones: [const Coordenada(21.3, -100.8)]);
    partida.capturar('x', 0, 5);
    final r = partida.capturar('x', 2, 5);
    expect(r, isA<SeEscapo>());
    final nueva = (r as SeEscapo).nuevaPosicion;
    expect(nueva.lat, 21.3);
    expect(partida.pendientes.single.coordenada.lat, 21.3);
  });

  test('tras escaparse, el contador de fallos se reinicia', () {
    final partida = crear();
    partida.capturar('x', 0, 5);
    partida.capturar('x', 0, 5); // se escapa
    final r = partida.capturar('x', 0, 5); // primer fallo del nuevo ciclo
    expect(r, isA<Fallo>());
  });

  test('no se puede capturar dos veces al mismo personaje', () {
    final partida = crear();
    partida.capturar('x', 1, 5);
    expect(() => partida.capturar('x', 1, 5), throwsA(isA<YaCapturadoException>()));
    expect(partida.puntos, 100);
  });

  test('un personaje que no existe lanza error con nombre propio', () {
    expect(() => crear().capturar('nadie', 0, 5), throwsA(isA<PersonajeDesconocidoException>()));
  });

  test('restaurar marca como capturados a los guardados e ignora ids raros', () {
    final partida = crear();
    partida.restaurar(['x', 'fantasma']);
    expect(partida.capturados, {'x'});
    expect(partida.pendientes, isEmpty);
  });
}
