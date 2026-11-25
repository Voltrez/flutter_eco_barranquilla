import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/registro_reciclaje.dart';
import 'escritura.dart';

/// Acceso a la colección `registros` (CRUD contra Firestore).
class RegistroRepository {
  final CollectionReference<Map<String, dynamic>> _col =
      FirebaseFirestore.instance.collection('registros');

  String nuevoId() => _col.doc().id;

  /// BASE DE DATOS → APP. Escucha en tiempo real SOLO los registros del
  /// usuario (el filtro por uid es obligatorio para que pasen las reglas).
  Stream<QuerySnapshot<Map<String, dynamic>>> escuchar(String uid) => _col
      .where('uid', isEqualTo: uid)
      .snapshots(includeMetadataChanges: true);

  /// Fuerza una lectura directa del servidor (pull-to-refresh).
  Future<void> leerDelServidor(String uid) => _col
      .where('uid', isEqualTo: uid)
      .get(const GetOptions(source: Source.server));

  // ---------- APP → BASE DE DATOS ----------
  Future<ResultadoEscritura> crear(RegistroReciclaje r) =>
      esperarEscritura(_col.doc(r.id).set(r.aMapa()));

  Future<ResultadoEscritura> crearVarios(List<RegistroReciclaje> lista) {
    final batch = FirebaseFirestore.instance.batch();
    for (final r in lista) {
      batch.set(_col.doc(r.id), r.aMapa());
    }
    return esperarEscritura(batch.commit());
  }

  Future<ResultadoEscritura> actualizar(RegistroReciclaje r) =>
      esperarEscritura(_col.doc(r.id).update(r.aMapaActualizacion()));

  Future<ResultadoEscritura> eliminar(String id) =>
      esperarEscritura(_col.doc(id).delete());

  Future<ResultadoEscritura> eliminarTodos(String uid) async {
    final consulta = await _col.where('uid', isEqualTo: uid).get();
    if (consulta.docs.isEmpty) return ResultadoEscritura.sincronizado;
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in consulta.docs) {
      batch.delete(doc.reference);
    }
    return esperarEscritura(batch.commit());
  }
}
