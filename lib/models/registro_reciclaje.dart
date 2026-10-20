import 'package:flutter/material.dart';

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

class RegistroReciclaje {
  final int id;
  final MaterialReciclable material;
  final double kg;
  final int objetos;
  final LugarEntrega lugar;
  final bool limpio;
  final DateTime fecha;
  final String nota;
  final int puntos;
  final double co2;

  const RegistroReciclaje({
    required this.id,
    required this.material,
    required this.kg,
    required this.objetos,
    required this.lugar,
    required this.limpio,
    required this.fecha,
    required this.nota,
    required this.puntos,
    required this.co2,
  });
}
