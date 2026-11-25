import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/punto_reciclaje.dart';
import 'escritura.dart';

/// Acceso a la colección `puntos_reciclaje`.
class PuntosRepository {
  final CollectionReference<Map<String, dynamic>> _col =
      FirebaseFirestore.instance.collection('puntos_reciclaje');

  Stream<List<PuntoReciclaje>> escuchar() => _col.orderBy('nombre').snapshots().map(
        (snap) => snap.docs
            .map(PuntoReciclaje.desdeDoc)
            .whereType<PuntoReciclaje>()
            .toList(),
      );

  Future<ResultadoEscritura> crear(PuntoReciclaje p) =>
      esperarEscritura(_col.doc().set(p.aMapa()));

  Future<ResultadoEscritura> eliminar(String id) =>
      esperarEscritura(_col.doc(id).delete());

  /// Puntos de EJEMPLO para probar la app (no son ubicaciones verificadas).
  Future<ResultadoEscritura> crearEjemplos(String uid) {
    const ejemplos = [
      ('Punto de acopio El Prado (ejemplo)', 'Calle 70 con Carrera 54', 'El Prado',
          'Lun a Sáb 8:00 a.m. - 5:00 p.m.', ['plastico', 'vidrio', 'papel', 'metal']),
      ('Ecopunto Riomar (ejemplo)', 'Calle 98 con Carrera 51B', 'Riomar',
          'Lun a Vie 9:00 a.m. - 6:00 p.m.', ['plastico', 'papel', 'tetrapak']),
      ('Centro de acopio Centro (ejemplo)', 'Carrera 44 con Calle 38', 'Centro',
          'Lun a Sáb 7:00 a.m. - 4:00 p.m.', ['vidrio', 'metal', 'papel', 'organico']),
    ];
    final batch = FirebaseFirestore.instance.batch();
    for (final e in ejemplos) {
      batch.set(
        _col.doc(),
        PuntoReciclaje(
          id: '',
          nombre: e.$1,
          direccion: e.$2,
          barrio: e.$3,
          horario: e.$4,
          materiales: e.$5,
          creadoPor: uid,
        ).aMapa(),
      );
    }
    return esperarEscritura(batch.commit());
  }
}
