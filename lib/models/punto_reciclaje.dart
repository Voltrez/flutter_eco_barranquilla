import 'package:cloud_firestore/cloud_firestore.dart';

/// Punto de acopio. Se guarda en la colección `puntos_reciclaje`.
/// Lo pueden leer todos los usuarios autenticados, pero solo lo puede
/// modificar o eliminar quien lo creó.
class PuntoReciclaje {
  final String id;
  final String nombre;
  final String direccion;
  final String barrio;
  final String horario;
  final List<String> materiales; // ids del catálogo
  final String creadoPor; // uid

  const PuntoReciclaje({
    required this.id,
    required this.nombre,
    required this.direccion,
    required this.barrio,
    required this.horario,
    required this.materiales,
    required this.creadoPor,
  });

  Map<String, dynamic> aMapa() => {
        'nombre': nombre,
        'direccion': direccion,
        'barrio': barrio,
        'horario': horario,
        'materiales': materiales,
        'creadoPor': creadoPor,
        'creadoEn': FieldValue.serverTimestamp(),
      };

  static PuntoReciclaje? desdeDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    if (d == null) return null;
    try {
      return PuntoReciclaje(
        id: doc.id,
        nombre: d['nombre'] as String,
        direccion: (d['direccion'] as String?) ?? '',
        barrio: (d['barrio'] as String?) ?? '',
        horario: (d['horario'] as String?) ?? '',
        materiales: List<String>.from(d['materiales'] as List),
        creadoPor: d['creadoPor'] as String,
      );
    } catch (_) {
      return null;
    }
  }
}
