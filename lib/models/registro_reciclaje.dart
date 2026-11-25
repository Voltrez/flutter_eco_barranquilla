import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../data/materiales.dart';
import 'material_reciclable.dart';

enum LugarEntrega { puntoReciclaje, reciclador, institucion }

extension LugarEntregaInfo on LugarEntrega {
  String get etiqueta => switch (this) {
        LugarEntrega.puntoReciclaje => 'Punto de reciclaje',
        LugarEntrega.reciclador => 'Reciclador de oficio',
        LugarEntrega.institucion => 'Institución',
      };

  String get etiquetaCorta => switch (this) {
        LugarEntrega.puntoReciclaje => 'Punto',
        LugarEntrega.reciclador => 'Reciclador',
        LugarEntrega.institucion => 'Institución',
      };

  IconData get icono => switch (this) {
        LugarEntrega.puntoReciclaje => Icons.place,
        LugarEntrega.reciclador => Icons.pedal_bike,
        LugarEntrega.institucion => Icons.school,
      };
}

/// Entidad principal. Se guarda en la colección `registros` de Firestore.
class RegistroReciclaje {
  final String id; // ID del documento en Firestore
  final String uid; // dueño del registro (usuario autenticado)
  final MaterialReciclable material;
  final double kg;
  final int objetos;
  final LugarEntrega lugar;
  final bool limpio;
  final DateTime fecha;
  final String nota;
  final int puntos;
  final double co2;
  final DateTime? creadoEn;
  final DateTime? actualizadoEn;

  const RegistroReciclaje({
    required this.id,
    required this.uid,
    required this.material,
    required this.kg,
    required this.objetos,
    required this.lugar,
    required this.limpio,
    required this.fecha,
    required this.nota,
    required this.puntos,
    required this.co2,
    this.creadoEn,
    this.actualizadoEn,
  });

  /// Documento para CREAR en Firestore.
  Map<String, dynamic> aMapa() => {
        'uid': uid,
        'materialId': material.id,
        'kg': kg,
        'objetos': objetos,
        'lugar': lugar.name,
        'limpio': limpio,
        'fecha': Timestamp.fromDate(fecha),
        'nota': nota,
        'puntos': puntos,
        'co2': co2,
        'creadoEn': FieldValue.serverTimestamp(),
        'actualizadoEn': FieldValue.serverTimestamp(),
      };

  /// Campos que cambian al ACTUALIZAR (no se toca uid ni creadoEn).
  Map<String, dynamic> aMapaActualizacion() => {
        'materialId': material.id,
        'kg': kg,
        'objetos': objetos,
        'lugar': lugar.name,
        'limpio': limpio,
        'fecha': Timestamp.fromDate(fecha),
        'nota': nota,
        'puntos': puntos,
        'co2': co2,
        'actualizadoEn': FieldValue.serverTimestamp(),
      };

  /// Convierte un documento de Firestore en un registro.
  /// Devuelve null si el documento está incompleto o dañado.
  static RegistroReciclaje? desdeDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    if (d == null) return null;
    try {
      final material =
          catalogoMateriales.firstWhere((m) => m.id == d['materialId']);
      return RegistroReciclaje(
        id: doc.id,
        uid: d['uid'] as String,
        material: material,
        kg: (d['kg'] as num).toDouble(),
        objetos: (d['objetos'] as num).toInt(),
        lugar: LugarEntrega.values.byName(d['lugar'] as String),
        limpio: d['limpio'] as bool,
        fecha: DateUtils.dateOnly((d['fecha'] as Timestamp).toDate()),
        nota: (d['nota'] as String?) ?? '',
        puntos: (d['puntos'] as num).toInt(),
        co2: (d['co2'] as num).toDouble(),
        creadoEn: (d['creadoEn'] as Timestamp?)?.toDate(),
        actualizadoEn: (d['actualizadoEn'] as Timestamp?)?.toDate(),
      );
    } catch (_) {
      return null;
    }
  }
}
