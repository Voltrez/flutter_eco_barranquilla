import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/materiales.dart';
import '../models/material_reciclable.dart';
import '../models/registro_reciclaje.dart';
import '../services/escritura.dart';
import '../services/registro_repository.dart';
import '../utils/errores.dart';

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

/// Estado de la app sincronizado con Cloud Firestore.
/// - La LISTA se alimenta en tiempo real desde la base de datos remota.
/// - Cada acción (registrar, actualizar, eliminar) se escribe en Firestore.
/// - Contiene además la LÓGICA: cálculo de puntos, CO2, racha y niveles.
class ReciclajeState extends ChangeNotifier {
  final RegistroRepository _repo = RegistroRepository();
  StreamSubscription? _suscripcion;
  String? _uid;

  List<RegistroReciclaje> _registros = [];
  bool cargando = true;
  String? error;

  /// true mientras haya cambios locales que el servidor aún no confirma.
  bool pendiente = false;

  /// true si los datos vienen de la caché del dispositivo (sin servidor).
  bool desdeCache = false;

  List<RegistroReciclaje> get registros => List.unmodifiable(_registros);
  bool get estaVacio => _registros.isEmpty;

  RegistroReciclaje? porId(String id) {
    for (final r in _registros) {
      if (r.id == id) return r;
    }
    return null;
  }

  // ---------- Conexión con Firestore ----------
  /// Empieza a escuchar los registros del usuario autenticado.
  void iniciar(String uid) {
    if (_uid == uid && _suscripcion != null) return;
    _suscripcion?.cancel();
    _uid = uid;
    _registros = [];
    cargando = true;
    error = null;
    notifyListeners();

    _suscripcion = _repo.escuchar(uid).listen(
      (snap) {
        _registros = snap.docs
            .map(RegistroReciclaje.desdeDoc)
            .whereType<RegistroReciclaje>()
            .toList();
        _ordenar();
        cargando = false;
        error = null;
        pendiente = snap.metadata.hasPendingWrites;
        desdeCache = snap.metadata.isFromCache;
        notifyListeners();
      },
      onError: (Object e) {
        cargando = false;
        error = mensajeError(e);
        notifyListeners();
      },
    );
  }

  /// Deja de escuchar y limpia los datos (al cerrar sesión).
  void detener() {
    _suscripcion?.cancel();
    _suscripcion = null;
    _uid = null;
    _registros = [];
    cargando = true;
    error = null;
    pendiente = false;
    desdeCache = false;
    notifyListeners();
  }

  /// Lee directamente del servidor (deslizar para actualizar).
  Future<void> refrescar() async {
    final uid = _uid;
    if (uid == null) return;
    await _repo.leerDelServidor(uid);
  }

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

  // ---------- Acciones (escriben en Firestore) ----------
  RegistroReciclaje _construir({
    required String id,
    required String uid,
    required MaterialReciclable material,
    required double kg,
    required int objetos,
    required LugarEntrega lugar,
    required bool limpio,
    required DateTime fecha,
    String nota = '',
  }) {
    return RegistroReciclaje(
      id: id,
      uid: uid,
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
      if (porFecha != 0) return porFecha;
      final ca = a.creadoEn ?? DateTime.now();
      final cb = b.creadoEn ?? DateTime.now();
      return cb.compareTo(ca);
    });
  }

  String get _uidActivo {
    final uid = _uid;
    if (uid == null) throw StateError('No hay una sesión iniciada.');
    return uid;
  }

  /// CREAR: guarda un nuevo documento en `registros`.
  Future<(RegistroReciclaje, ResultadoEscritura)> registrar({
    required MaterialReciclable material,
    required double kg,
    required int objetos,
    required LugarEntrega lugar,
    required bool limpio,
    required DateTime fecha,
    String nota = '',
  }) async {
    final registro = _construir(
      id: _repo.nuevoId(),
      uid: _uidActivo,
      material: material,
      kg: kg,
      objetos: objetos,
      lugar: lugar,
      limpio: limpio,
      fecha: fecha,
      nota: nota,
    );
    final resultado = await _repo.crear(registro);
    return (registro, resultado);
  }

  /// ACTUALIZAR: modifica un documento existente (recalcula puntos y CO2).
  Future<ResultadoEscritura> actualizar(
    RegistroReciclaje original, {
    required MaterialReciclable material,
    required double kg,
    required int objetos,
    required LugarEntrega lugar,
    required bool limpio,
    required DateTime fecha,
    String nota = '',
  }) {
    final nuevo = _construir(
      id: original.id,
      uid: original.uid,
      material: material,
      kg: kg,
      objetos: objetos,
      lugar: lugar,
      limpio: limpio,
      fecha: fecha,
      nota: nota,
    );
    return _repo.actualizar(nuevo);
  }

  /// ELIMINAR: borra el documento de la base de datos remota.
  Future<ResultadoEscritura> eliminar(String id) => _repo.eliminar(id);

  /// Deshacer una eliminación: vuelve a crear el documento con el mismo ID.
  Future<ResultadoEscritura> restaurar(RegistroReciclaje registro) =>
      _repo.crear(registro);

  /// Borra TODOS los registros del usuario.
  Future<ResultadoEscritura> reiniciar() => _repo.eliminarTodos(_uidActivo);

  /// Escribe datos de ejemplo en Firestore para probar la app.
  Future<ResultadoEscritura> cargarEjemplo() {
    final uid = _uidActivo;
    final hoy = DateUtils.dateOnly(DateTime.now());
    DateTime hace(int dias) => hoy.subtract(Duration(days: dias));
    RegistroReciclaje r(String materialId, double kg, int objetos,
            LugarEntrega lugar, bool limpio, int dias, [String nota = '']) =>
        _construir(
          id: _repo.nuevoId(),
          uid: uid,
          material: materialPorId(materialId),
          kg: kg,
          objetos: objetos,
          lugar: lugar,
          limpio: limpio,
          fecha: hace(dias),
          nota: nota,
        );

    return _repo.crearVarios([
      r('plastico', 2.5, 18, LugarEntrega.reciclador, true, 0, 'Botellas del apartamento'),
      r('papel', 4.0, 12, LugarEntrega.puntoReciclaje, true, 1),
      r('metal', 1.2, 25, LugarEntrega.reciclador, false, 2),
      r('vidrio', 3.0, 6, LugarEntrega.institucion, true, 3, 'Campaña del colegio'),
      r('organico', 5.0, 1, LugarEntrega.puntoReciclaje, false, 4),
      r('tetrapak', 0.8, 9, LugarEntrega.puntoReciclaje, true, 5),
    ]);
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
