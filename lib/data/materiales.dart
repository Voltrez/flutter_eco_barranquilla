import 'package:flutter/material.dart';

import '../models/material_reciclable.dart';

/// Catálogo en memoria. Los factores de puntos y CO2 son valores
/// referenciales definidos para este proyecto académico.
const List<MaterialReciclable> catalogoMateriales = [
  MaterialReciclable(
    id: 'plastico',
    nombre: 'Plástico (botellas, envases)',
    icono: Icons.local_drink,
    color: Color(0xFF0288D1),
    puntosPorKg: 10,
    co2PorKg: 1.5,
    contenedor: TipoContenedor.blanco,
    consejo:
        'Enjuaga las botellas, aplástalas y ponles la tapa antes de entregarlas.',
  ),
  MaterialReciclable(
    id: 'vidrio',
    nombre: 'Vidrio',
    icono: Icons.wine_bar,
    color: Color(0xFF00897B),
    puntosPorKg: 6,
    co2PorKg: 0.3,
    contenedor: TipoContenedor.blanco,
    consejo:
        'Entrega frascos y botellas sin tapa. No los mezcles con cerámica ni espejos.',
  ),
  MaterialReciclable(
    id: 'papel',
    nombre: 'Papel y cartón',
    icono: Icons.description,
    color: Color(0xFF8D6E63),
    puntosPorKg: 5,
    co2PorKg: 1.0,
    contenedor: TipoContenedor.blanco,
    consejo: 'Mantenlos secos y sin grasa. Aplana las cajas para ahorrar espacio.',
  ),
  MaterialReciclable(
    id: 'metal',
    nombre: 'Metal y latas',
    icono: Icons.hardware,
    color: Color(0xFF78909C),
    puntosPorKg: 12,
    co2PorKg: 4.0,
    contenedor: TipoContenedor.blanco,
    consejo:
        'Enjuaga las latas y aplástalas. El aluminio se puede reciclar muchas veces.',
  ),
  MaterialReciclable(
    id: 'tetrapak',
    nombre: 'Cartón multicapa (Tetra Pak)',
    icono: Icons.inventory_2,
    color: Color(0xFFF9A825),
    puntosPorKg: 8,
    co2PorKg: 0.9,
    contenedor: TipoContenedor.blanco,
    consejo: 'Vacía, enjuaga y aplana las cajas de leche y jugo.',
  ),
  MaterialReciclable(
    id: 'organico',
    nombre: 'Residuos orgánicos',
    icono: Icons.eco,
    color: Color(0xFF43A047),
    puntosPorKg: 3,
    co2PorKg: 0.5,
    contenedor: TipoContenedor.verde,
    consejo:
        'Sepáralos en una bolsa aparte; sirven para hacer compostaje casero.',
  ),
];

MaterialReciclable materialPorId(String id) =>
    catalogoMateriales.firstWhere((m) => m.id == id);
