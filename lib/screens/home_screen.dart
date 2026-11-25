import 'package:flutter/material.dart';

import '../data/materiales.dart';
import '../models/material_reciclable.dart';
import '../services/auth_service.dart';
import '../state/reciclaje_state.dart';
import '../theme/app_theme.dart';
import '../utils/dialogos.dart';
import '../utils/errores.dart';
import '../utils/formato.dart';
import '../utils/mensajes.dart';
import '../widgets/contenedor_info.dart';
import '../widgets/estado_sync.dart';
import '../widgets/stat_card.dart';

/// PANTALLA 1: inicio.
class HomeScreen extends StatelessWidget {
  final ValueChanged<int> onIrA;

  const HomeScreen({super.key, required this.onIrA});

  void _mostrarConsejo(BuildContext context, MaterialReciclable m) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(m.icono, color: m.color, size: 36),
        title: Text(m.nombre, textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(m.consejo),
            const SizedBox(height: 12),
            ContenedorInfo(tipo: m.contenedor),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  Future<void> _cerrarSesion(BuildContext context) async {
    final ok = await confirmarAccion(
      context,
      titulo: 'Cerrar sesión',
      mensaje: '¿Deseas cerrar tu sesión en Eco Barranquilla?',
      textoConfirmar: 'Cerrar sesión',
      icono: Icons.logout,
    );
    if (!ok) return;
    await servicioAuth.cerrarSesion();
  }

  Future<void> _cargarEjemplo(BuildContext context) async {
    try {
      await estadoApp.cargarEjemplo();
      if (!context.mounted) return;
      mostrarMensaje(context, 'Se guardaron datos de ejemplo en Firebase.',
          tipo: TipoMensaje.info);
    } catch (e) {
      if (!context.mounted) return;
      mostrarMensaje(context, mensajeError(e), tipo: TipoMensaje.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: estadoApp,
      builder: (context, _) {
        final nivel = estadoApp.nivel;
        final siguiente = estadoApp.siguienteNivel;
        final faltan = siguiente == null
            ? 0
            : siguiente.puntosMinimos - estadoApp.puntosTotales;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Eco Barranquilla'),
            backgroundColor: AppColors.verde,
            foregroundColor: Colors.white,
            actions: [
              const Center(child: EstadoSync(compacto: true)),
              IconButton(
                tooltip: 'Cerrar sesión',
                icon: const Icon(Icons.logout),
                onPressed: () => _cerrarSesion(context),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ---- Encabezado con nivel ----
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.verde, AppColors.verdeOscuro],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: AppTheme.sombra,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '¡Hola, ${servicioAuth.nombreUsuario}!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Recicla en Barranquilla, suma puntos y cuida tu ciudad.',
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(nivel.icono, color: AppColors.amarillo),
                        const SizedBox(width: 8),
                        Text(
                          'Nivel ${nivel.nombre}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: estadoApp.progresoNivel,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(8),
                      backgroundColor: Colors.white24,
                      color: AppColors.amarillo,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      siguiente == null
                          ? '¡Alcanzaste el nivel máximo!'
                          : 'Te faltan $faltan pts para ser ${siguiente.nombre}',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ---- Estadísticas ----
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      icono: Icons.star,
                      valor: '${estadoApp.puntosTotales}',
                      etiqueta: 'Puntos',
                      color: AppColors.amarillo,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: StatCard(
                      icono: Icons.scale,
                      valor: kgTexto(estadoApp.kgTotales),
                      etiqueta: 'Kg reciclados',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: StatCard(
                      icono: Icons.local_fire_department,
                      valor: '${estadoApp.racha}',
                      etiqueta: 'Días de racha',
                      color: Colors.deepOrange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ---- Acciones principales ----
              ElevatedButton.icon(
                onPressed: () => onIrA(1),
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Registrar reciclaje'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => onIrA(2),
                icon: const Icon(Icons.bar_chart),
                label: const Text('Ver mi historial e impacto'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  foregroundColor: AppColors.verde,
                  side: const BorderSide(color: AppColors.verde),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => onIrA(3),
                icon: const Icon(Icons.place),
                label: const Text('Dónde llevar mi reciclaje'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  foregroundColor: AppColors.verde,
                  side: const BorderSide(color: AppColors.verde),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ---- Guía rápida ----
              const Text(
                '¿Cómo separo mis residuos?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.texto,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Toca un material para ver su consejo.',
                style: TextStyle(color: AppColors.textoSuave),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: catalogoMateriales
                    .map(
                      (m) => ActionChip(
                        avatar: Icon(m.icono, size: 18, color: m.color),
                        label: Text(m.nombre.split(' (').first),
                        backgroundColor: Colors.white,
                        onPressed: () => _mostrarConsejo(context, m),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
              for (final tipo in TipoContenedor.values) ...[
                ContenedorInfo(tipo: tipo),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 8),
              Center(
                child: TextButton.icon(
                  onPressed: () => _cargarEjemplo(context),
                  icon: const Icon(Icons.science_outlined),
                  label: const Text('Cargar datos de ejemplo'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
