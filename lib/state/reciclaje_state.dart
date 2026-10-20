import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/materiales.dart';
import '../models/material_reciclable.dart';
import '../models/registro_reciclaje.dart';

class NivelEco {
  final String nombre;
  final int puntosMinimos;
  final IconData icono;
  const NivelEco(this.nombre, this.puntosMinimos, this.icono);
}

const List<NivelEco> nivelesEco = [
  NivelEco('Semilla', 0, Icons.grass),
  NivelEco('Brote', 100, Icons.spa),
  NivelEco('Árbol', 300, Icons.park),
  NivelEco('Guardián', 600, Icons.shield),
];

/// Estado en memoria de toda la app (sin base de datos).
/// Contiene la LÓGICA: cálculo de puntos, CO2, racha y niveles.
class ReciclajeState extends ChangeNotifier {
  final List<RegistroReciclaje> _registros = [];
  int _siguienteId = 1;

  List<RegistroReciclaje> get registros => List.unmodifiable(_registros);
  bool get estaVacio => _registros.isEmpty;

  // ---------- Cálculos ----------
  /// Puntos = kg x puntos del material x multiplicador.
  /// +20 % si lo entregó un reciclador de oficio, +10 % si está limpio y seco.
  static int calcularPuntos(
    MaterialReciclable material,
    double kg, {
    required bool conReciclador,
    required bool limpio,
  }) {
    final multiplicador = 1 + (conReciclador ? 0.2 : 0) + (limpio ? 0.1 : 0);
    return math.max(1, (kg * material.puntosPorKg * multiplicador).round());
  }

  static double calcularCo2(MaterialReciclable material, double kg) =>
      kg * material.co2PorKg;

  // ---------- Acciones ----------
  RegistroReciclaje _crear({
    required MaterialReciclable material,
    required double kg,
    required int objetos,
    required LugarEntrega lugar,
    required bool limpio,
    required DateTime fecha,
    String nota = '',
  }) {
    return RegistroReciclaje(
      id: _siguienteId++,
      material: material,
      kg: kg,
      objetos: objetos,
      lugar: lugar,
      limpio: limpio,
      fecha: DateUtils.dateOnly(fecha),
      nota: nota.trim(),
      puntos: calcularPuntos(
        material,
        kg,
        conReciclador: lugar == LugarEntrega.reciclador,
        limpio: limpio,
      ),
      co2: calcularCo2(material, kg),
    );
  }

  void _ordenar() {
    _registros.sort((a, b) {
      final porFecha = b.fecha.compareTo(a.fecha);
      return porFecha != 0 ? porFecha : b.id.compareTo(a.id);
    });
  }

  RegistroReciclaje registrar({
    required MaterialReciclable material,
    required double kg,
    required int objetos,
    required LugarEntrega lugar,
    required bool limpio,
    required DateTime fecha,
    String nota = '',
  }) {
    final registro = _crear(
      material: material,
      kg: kg,
      objetos: objetos,
      lugar: lugar,
      limpio: limpio,
      fecha: fecha,
      nota: nota,
    );
    _registros.add(registro);
    _ordenar();
    notifyListeners();
    return registro;
  }

  void eliminar(int id) {
    _registros.removeWhere((r) => r.id == id);
    notifyListeners();
  }

  void restaurar(RegistroReciclaje registro) {
    _registros.add(registro);
    _ordenar();
    notifyListeners();
  }

  void reiniciar() {
    _registros.clear();
    notifyListeners();
  }

  /// Datos de ejemplo para probar la app y tomar capturas.
  void cargarEjemplo() {
    _registros.clear();
    final hoy = DateUtils.dateOnly(DateTime.now());
    DateTime hace(int dias) => hoy.subtract(Duration(days: dias));

    _registros.addAll([
      _crear(material: materialPorId('plastico'), kg: 2.5, objetos: 18,
          lugar: LugarEntrega.reciclador, limpio: true, fecha: hace(0),
          nota: 'Botellas del apartamento'),
      _crear(material: materialPorId('papel'), kg: 4.0, objetos: 12,
          lugar: LugarEntrega.puntoReciclaje, limpio: true, fecha: hace(1)),
      _crear(material: materialPorId('metal'), kg: 1.2, objetos: 25,
          lugar: LugarEntrega.reciclador, limpio: false, fecha: hace(2)),
      _crear(material: materialPorId('vidrio'), kg: 3.0, objetos: 6,
          lugar: LugarEntrega.institucion, limpio: true, fecha: hace(3),
          nota: 'Campaña del colegio'),
      _crear(material: materialPorId('organico'), kg: 5.0, objetos: 1,
          lugar: LugarEntrega.puntoReciclaje, limpio: false, fecha: hace(4)),
      _crear(material: materialPorId('tetrapak'), kg: 0.8, objetos: 9,
          lugar: LugarEntrega.puntoReciclaje, limpio: true, fecha: hace(5)),
    ]);
    _ordenar();
    notifyListeners();
  }

  // ---------- Estadísticas ----------
  int get puntosTotales => _registros.fold(0, (s, r) => s + r.puntos);
  double get kgTotales => _registros.fold(0.0, (s, r) => s + r.kg);
  int get objetosTotales => _registros.fold(0, (s, r) => s + r.objetos);
  double get co2Total => _registros.fold(0.0, (s, r) => s + r.co2);

  /// Días consecutivos (hasta hoy o ayer) con al menos un registro.
  int get racha {
    if (_registros.isEmpty) return 0;
    final dias = _registros.map((r) => DateUtils.dateOnly(r.fecha)).toSet();
    var cursor = DateUtils.dateOnly(DateTime.now());
    if (!dias.contains(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
    }
    var total = 0;
    while (dias.contains(cursor)) {
      total++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return total;
  }

  NivelEco get nivel =>
      nivelesEco.lastWhere((n) => puntosTotales >= n.puntosMinimos);

  NivelEco? get siguienteNivel {
    final i = nivelesEco.indexOf(nivel);
    return i + 1 < nivelesEco.length ? nivelesEco[i + 1] : null;
  }

  double get progresoNivel {
    final siguiente = siguienteNivel;
    if (siguiente == null) return 1;
    final base = nivel.puntosMinimos;
    return ((puntosTotales - base) / (siguiente.puntosMinimos - base))
        .clamp(0.0, 1.0)
        .toDouble();
  }

  Map<String, double> get kgPorMaterial {
    final mapa = <String, double>{};
    for (final r in _registros) {
      mapa[r.material.id] = (mapa[r.material.id] ?? 0) + r.kg;
    }
    return mapa;
  }

  /// kg reciclados por día: del más antiguo al de hoy.
  List<double> kgUltimosDias(int cantidad) {
    final hoy = DateUtils.dateOnly(DateTime.now());
    return List.generate(cantidad, (i) {
      final dia = hoy.subtract(Duration(days: cantidad - 1 - i));
      return _registros
          .where((r) => DateUtils.isSameDay(r.fecha, dia))
          .fold(0.0, (s, r) => s + r.kg);
    });
  }
}

/// Instancia única compartida por las tres pantallas.
final ReciclajeState estadoApp = ReciclajeState();
