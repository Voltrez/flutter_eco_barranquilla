import 'package:flutter/material.dart';

/// Contenedores según el código de colores de Colombia.
enum TipoContenedor { blanco, verde, negro }

extension TipoContenedorInfo on TipoContenedor {
  String get nombre => switch (this) {
        TipoContenedor.blanco => 'Contenedor blanco',
        TipoContenedor.verde => 'Contenedor verde',
        TipoContenedor.negro => 'Contenedor negro',
      };

  String get descripcion => switch (this) {
        TipoContenedor.blanco =>
          'Aprovechables: plástico, vidrio, metal, papel y cartón limpios y secos.',
        TipoContenedor.verde =>
          'Orgánicos: restos de comida, cáscaras y residuos de jardín.',
        TipoContenedor.negro =>
          'No aprovechables: papel higiénico, servilletas usadas y residuos sanitarios.',
      };

  Color get color => switch (this) {
        TipoContenedor.blanco => Colors.white,
        TipoContenedor.verde => const Color(0xFF43A047),
        TipoContenedor.negro => const Color(0xFF37474F),
      };
}

class MaterialReciclable {
  final String id;
  final String nombre;
  final IconData icono;
  final Color color;
  final int puntosPorKg;
  final double co2PorKg; // kg de CO2 evitado por kg (valor referencial)
  final TipoContenedor contenedor;
  final String consejo;

  const MaterialReciclable({
    required this.id,
    required this.nombre,
    required this.icono,
    required this.color,
    required this.puntosPorKg,
    required this.co2PorKg,
    required this.contenedor,
    required this.consejo,
  });
}
