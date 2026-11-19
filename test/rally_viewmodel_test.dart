import 'dart:async';
import 'dart:math';
 
import 'package:dolores_rally/dominio/almacen.dart';
import 'package:dolores_rally/dominio/catalogo.dart';
import 'package:dolores_rally/dominio/excepciones.dart';
import 'package:dolores_rally/dominio/fuentes.dart';
import 'package:dolores_rally/dominio/geo.dart';
import 'package:dolores_rally/dominio/partida.dart';
import 'package:dolores_rally/dominio/radar.dart';
import 'package:dolores_rally/presentacion/rally_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ayudas.dart';

class PosicionFalsa implements FuentePosicion {
  final c = StreamController<Coordenada>.broadcast();
  @override
  Stream<Coordenada> get posiciones => c.stream;
}

class BrujulaFalsa implements FuenteBrujula {
  final c = StreamController<double>.broadcast();
  @override
  Stream<double> get rumbos => c.stream;
}

void main() {
  late PosicionFalsa gps;
  late BrujulaFalsa brujula;
  late AlmacenMemoria almacen;

  Future<RallyViewModel> crear() async {
    gps = PosicionFalsa();
    brujula = BrujulaFalsa();
    almacen = AlmacenMemoria();
    final vm = RallyViewModel(
      posicion: gps,
      brujula: brujula,
      almacen: almacen,
      personajes: personajes,
      centro: origen,
      random: Random(42), // semilla fija: el escenario es siempre el mismo
    );
    await vm.iniciar();
    return vm;
  }

  test('mientras falte GPS o brújula, está esperando', () async {
    final vm = await crear();
    expect(vm.esperando, true);
    gps.c.add(origen);
    await pumpEventQueue();
    expect(vm.esperando, true);
    vm.dispose();
  });

  test('con GPS y brújula calcula visibles, radar y temperatura', () async {
    final vm = await crear();
    gps.c.add(origen);
    brujula.c.add(0);
    await pumpEventQueue();
    expect(vm.esperando, false);
    expect(vm.temperatura, isNotNull);
    expect(vm.puntosRadar, isNotEmpty);
    vm.dispose();
  });

  test('el más cercano es el que marca la temperatura', () async {
    final vm = await crear();
    final objetivo = vm.partida.todas.first;
    gps.c.add(destino(objetivo.coordenada, 90, 8)); // a 8 m de ese personaje
    brujula.c.add(0);
    await pumpEventQueue();
    expect(vm.masCercano!.personaje.id, objetivo.personaje.id);
    expect(vm.temperatura, Temperatura.ardiente);
    vm.dispose();
  });

  test('capturar con respuesta correcta suma puntos y guarda el progreso', () async {
    final vm = await crear();
    final objetivo = vm.partida.todas.first;
    gps.c.add(destino(objetivo.coordenada, 0, 5));
    brujula.c.add(0);
    await pumpEventQueue();

    final correcta = objetivo.personaje.pregunta.correcta;
    final r = await vm.capturar(objetivo.personaje.id, correcta);
    expect(r, isA<Capturado>());
    expect(vm.partida.puntos, 100);
    expect(await almacen.cargarCapturados(), {objetivo.personaje.id});
    expect(await almacen.cargarMejorPuntaje(), 100);
    vm.dispose();
  });

  test('capturar estando lejos lanza LejosException y no guarda nada', () async {
    final vm = await crear();
    gps.c.add(origen);
    brujula.c.add(0);
    await pumpEventQueue();
    final objetivo = vm.partida.todas.first;
    expect(() => vm.capturar(objetivo.personaje.id, 0), throwsA(isA<LejosException>()));
    expect(await almacen.cargarCapturados(), isEmpty);
    vm.dispose();
  });

  test('al iniciar restaura el progreso guardado', () async {
    gps = PosicionFalsa();
    brujula = BrujulaFalsa();
    almacen = AlmacenMemoria();
    await almacen.guardarCapturados({'hidalgo'});
    final vm = RallyViewModel(
      posicion: gps, brujula: brujula, almacen: almacen,
      personajes: personajes, centro: origen, random: Random(1),
    );
    await vm.iniciar();
    expect(vm.partida.estaCapturado('hidalgo'), true);
    expect(vm.partida.pendientes.length, personajes.length - 1);
    vm.dispose();
  });

  test('lejosDeDolores avisa cuando estás a más de 3 km del centro', () async {
    final vm = await crear();
    gps.c.add(destino(origen, 0, 5000));
    brujula.c.add(0);
    await pumpEventQueue();
    expect(vm.lejosDeDolores, true);
    vm.dispose();
  });

  test('un error de permiso se muestra con mensaje amable', () async {
    final vm = await crear();
    gps.c.addError(const PermisoUbicacionException());
    await pumpEventQueue();
    expect(vm.error, contains('permiso'));
    vm.dispose();
  });

  test('un error desconocido NO filtra detalles internos', () async {
    final vm = await crear();
    brujula.c.addError(StateError('fallo en /sensores/mag.dart'));
    await pumpEventQueue();
    expect(vm.error, isNot(contains('/sensores')));
    expect(vm.error, contains('inesperado'));
    vm.dispose();
  });
}
