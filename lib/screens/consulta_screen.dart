import 'package:flutter/material.dart';

import '../data/materiales.dart';
import '../models/registro_reciclaje.dart';
import '../state/reciclaje_state.dart';
import '../theme/app_theme.dart';
import '../utils/dialogos.dart';
import '../utils/errores.dart';
import '../utils/formato.dart';
import '../utils/mensajes.dart';
import '../widgets/barras_semana.dart';
import '../widgets/estado_sync.dart';
import '../widgets/registro_tile.dart';
import '../widgets/stat_card.dart';
import 'detalle_screen.dart';

/// PANTALLA 2: consulta/listado (registros leídos desde Firestore) + impacto personal.
class ConsultaScreen extends StatefulWidget {
  final ValueChanged<int> onIrA;

  const ConsultaScreen({super.key, required this.onIrA});

  @override
  State<ConsultaScreen> createState() => _ConsultaScreenState();
}

class _ConsultaScreenState extends State<ConsultaScreen> {
  String? _filtroId; // null = todos

  Future<void> _confirmarReinicio() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.delete_forever, color: AppColors.error, size: 36),
        title: const Text('Borrar todo el historial'),
        content: const Text('Se eliminarán todos tus registros. ¿Deseas continuar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );
    if (confirmar == true) {
      try {
        await estadoApp.reiniciar();
        setState(() => _filtroId = null);
        if (!mounted) return;
        mostrarMensaje(context, 'Historial borrado.',
            tipo: TipoMensaje.advertencia);
      } catch (e) {
        if (!mounted) return;
        mostrarMensaje(context, mensajeError(e), tipo: TipoMensaje.error);
      }
    }
  }

  Future<void> _abrirDetalle(RegistroReciclaje r) async {
    final eliminado = await Navigator.push<RegistroReciclaje>(
      context,
      MaterialPageRoute(builder: (_) => DetalleScreen(registroId: r.id)),
    );
    if (eliminado != null && mounted) _avisoEliminado(eliminado);
  }

  void _avisoEliminado(RegistroReciclaje r) {
    mostrarMensaje(
      context,
      'Registro eliminado de Firebase.',
      tipo: TipoMensaje.advertencia,
      accion: 'Deshacer',
      onAccion: () async {
        try {
          await estadoApp.restaurar(r);
        } catch (e) {
          if (mounted) {
            mostrarMensaje(context, mensajeError(e), tipo: TipoMensaje.error);
          }
        }
      },
    );
  }

  /// Pide confirmación y elimina. Devuelve false siempre: la fila desaparece
  /// cuando Firestore notifica el cambio, no antes.
  Future<bool> _confirmarYEliminar(RegistroReciclaje r) async {
    final ok = await confirmarAccion(
      context,
      titulo: 'Eliminar registro',
      mensaje: 'Se eliminará de la base de datos remota. ¿Deseas continuar?',
    );
    if (!ok || !mounted) return false;
    try {
      await estadoApp.eliminar(r.id);
      if (mounted) _avisoEliminado(r);
    } catch (e) {
      if (mounted) {
        mostrarMensaje(context, mensajeError(e), tipo: TipoMensaje.error);
      }
    }
    return false;
  }

  Future<void> _refrescar() async {
    try {
      await estadoApp.refrescar();
    } catch (e) {
      if (mounted) {
        mostrarMensaje(context, mensajeError(e), tipo: TipoMensaje.error);
      }
    }
  }

  Widget _titulo(String texto) => Padding(
        padding: const EdgeInsets.only(top: 22, bottom: 10),
        child: Text(
          texto,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.texto,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: estadoApp,
      builder: (context, _) {
        final todos = estadoApp.registros;
        final lista = _filtroId == null
            ? todos
            : todos.where((r) => r.material.id == _filtroId).toList();

        final hoy = DateUtils.dateOnly(DateTime.now());
        final etiquetas = List.generate(
          7,
          (i) => diaCorto(hoy.subtract(Duration(days: 6 - i))),
        );
        final porMaterial = estadoApp.kgPorMaterial;
        final maximoMaterial =
            porMaterial.values.fold<double>(0, (a, b) => b > a ? b : a);
        final nivel = estadoApp.nivel;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Mi impacto'),
            backgroundColor: AppColors.verde,
            foregroundColor: Colors.white,
            actions: const [
              Padding(
                padding: EdgeInsets.only(right: 12),
                child: Center(child: EstadoSync()),
              ),
            ],
          ),
          body: estadoApp.cargando
              ? const Center(child: CircularProgressIndicator())
              : estadoApp.error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cloud_off,
                            size: 70, color: AppColors.error),
                        const SizedBox(height: 12),
                        Text(estadoApp.error!, textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                )
              : estadoApp.estaVacio
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.recycling,
                            size: 90, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        const Text(
                          'Aún no tienes registros',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.texto,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Registra tu primer reciclaje y aquí verás tus puntos, tu impacto y tu historial.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textoSuave),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => widget.onIrA(1),
                          icon: const Icon(Icons.add_circle_outline),
                          label: const Text('Registrar ahora'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _refrescar,
                  child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  children: [
                    // ---- Tarjeta de nivel ----
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AppTheme.sombra,
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: AppColors.verdeClaro,
                            child: Icon(nivel.icono,
                                color: AppColors.verde, size: 28),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Nivel ${nivel.nombre}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.texto,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                LinearProgressIndicator(
                                  value: estadoApp.progresoNivel,
                                  minHeight: 8,
                                  borderRadius: BorderRadius.circular(8),
                                  backgroundColor: AppColors.verdeClaro,
                                  color: AppColors.verde,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${estadoApp.puntosTotales} puntos · racha de ${estadoApp.racha} día(s)',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textoSuave,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ---- Impacto personal ----
                    Row(
                      children: [
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
                            icono: Icons.category,
                            valor: '${estadoApp.objetosTotales}',
                            etiqueta: 'Objetos',
                            color: AppColors.azul,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: StatCard(
                            icono: Icons.cloud_done,
                            valor: estadoApp.co2Total.toStringAsFixed(1),
                            etiqueta: 'kg CO₂ evitados*',
                            color: Colors.teal,
                          ),
                        ),
                      ],
                    ),

                    // ---- Actividad semanal ----
                    _titulo('Actividad de los últimos 7 días (kg)'),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AppTheme.sombra,
                      ),
                      child: BarrasSemana(
                        valores: estadoApp.kgUltimosDias(7),
                        etiquetas: etiquetas,
                      ),
                    ),

                    // ---- Por material ----
                    _titulo('Por tipo de material'),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AppTheme.sombra,
                      ),
                      child: Column(
                        children: catalogoMateriales
                            .where((m) => porMaterial.containsKey(m.id))
                            .map((m) {
                          final kg = porMaterial[m.id]!;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Icon(m.icono, color: m.color, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${m.nombre.split(' (').first} · ${kgTexto(kg)} kg',
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                      const SizedBox(height: 4),
                                      LinearProgressIndicator(
                                        value: maximoMaterial == 0
                                            ? 0
                                            : kg / maximoMaterial,
                                        minHeight: 6,
                                        borderRadius: BorderRadius.circular(6),
                                        backgroundColor: Colors.grey.shade200,
                                        color: m.color,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    // ---- Historial con filtro ----
                    _titulo('Historial'),
                    SizedBox(
                      height: 44,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: const Text('Todos'),
                              selected: _filtroId == null,
                              selectedColor: AppColors.verdeClaro,
                              onSelected: (_) => setState(() => _filtroId = null),
                            ),
                          ),
                          ...catalogoMateriales.map(
                            (m) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                avatar: Icon(m.icono, size: 16, color: m.color),
                                label: Text(m.nombre.split(' (').first),
                                selected: _filtroId == m.id,
                                selectedColor: AppColors.verdeClaro,
                                onSelected: (_) =>
                                    setState(() => _filtroId = m.id),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (lista.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            'No hay registros para este material.',
                            style: TextStyle(color: AppColors.textoSuave),
                          ),
                        ),
                      )
                    else
                      ...lista.map(
                        (r) => Dismissible(
                          key: ValueKey(r.id),
                          direction: DismissDirection.endToStart,
                          confirmDismiss: (_) => _confirmarYEliminar(r),
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          child: GestureDetector(
                            onTap: () => _abrirDetalle(r),
                            child: RegistroTile(registro: r),
                          ),
                        ),
                      ),
                    const SizedBox(height: 4),
                    const Text(
                      'Toca un registro para ver el detalle. Desliza a la izquierda para eliminarlo.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: AppColors.textoSuave),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '* Valores referenciales de CO₂ definidos para este proyecto académico.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: AppColors.textoSuave),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: TextButton.icon(
                        onPressed: _confirmarReinicio,
                        icon: const Icon(Icons.delete_sweep, color: AppColors.error),
                        label: const Text(
                          'Borrar todo el historial',
                          style: TextStyle(color: AppColors.error),
                        ),
                      ),
                    ),
                  ],
                ),
                ),
        );
      },
    );
  }
}
