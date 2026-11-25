import 'package:flutter/material.dart';

import '../data/materiales.dart';
import '../models/material_reciclable.dart';
import '../models/punto_reciclaje.dart';
import '../services/auth_service.dart';
import '../services/puntos_repository.dart';
import '../theme/app_theme.dart';
import '../utils/dialogos.dart';
import '../utils/errores.dart';
import '../utils/mensajes.dart';

/// PANTALLA 6: funcionalidad principal del proyecto.
/// Responde a "¿dónde llevo mi reciclaje?": puntos de acopio compartidos por la
/// comunidad (colección `puntos_reciclaje`). Todos los usuarios autenticados
/// pueden verlos y agregar nuevos; solo el autor puede eliminar el suyo.
class PuntosScreen extends StatelessWidget {
  const PuntosScreen({super.key});

  static final PuntosRepository _repo = PuntosRepository();

  Future<void> _agregar(BuildContext context) async {
    final nuevo = await showModalBottomSheet<PuntoReciclaje>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _FormularioPunto(),
    );
    if (nuevo == null || !context.mounted) return;
    try {
      await _repo.crear(nuevo);
      if (context.mounted) {
        mostrarMensaje(context, 'Punto agregado.', tipo: TipoMensaje.exito);
      }
    } catch (e) {
      if (context.mounted) {
        mostrarMensaje(context, mensajeError(e), tipo: TipoMensaje.error);
      }
    }
  }

  Future<void> _eliminar(BuildContext context, PuntoReciclaje p) async {
    final ok = await confirmarAccion(
      context,
      titulo: 'Eliminar punto',
      mensaje: '¿Eliminar "${p.nombre}" para todos los usuarios?',
    );
    if (!ok || !context.mounted) return;
    try {
      await _repo.eliminar(p.id);
      if (context.mounted) {
        mostrarMensaje(context, 'Punto eliminado.',
            tipo: TipoMensaje.advertencia);
      }
    } catch (e) {
      if (context.mounted) {
        mostrarMensaje(context, mensajeError(e), tipo: TipoMensaje.error);
      }
    }
  }

  Future<void> _ejemplos(BuildContext context) async {
    final uid = servicioAuth.usuario?.uid;
    if (uid == null) return;
    try {
      await _repo.crearEjemplos(uid);
    } catch (e) {
      if (context.mounted) {
        mostrarMensaje(context, mensajeError(e), tipo: TipoMensaje.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = servicioAuth.usuario?.uid;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Puntos de reciclaje'),
        backgroundColor: AppColors.verde,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _agregar(context),
        backgroundColor: AppColors.verde,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_location_alt),
        label: const Text('Agregar punto'),
      ),
      body: StreamBuilder<List<PuntoReciclaje>>(
        stream: _repo.escuchar(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(mensajeError(snap.error!),
                    textAlign: TextAlign.center),
              ),
            );
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final puntos = snap.data!;
          if (puntos.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.place_outlined,
                        size: 90, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    const Text(
                      'Aún no hay puntos registrados',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.texto,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Agrega el primero o carga algunos de ejemplo para probar.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textoSuave),
                    ),
                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                      onPressed: () => _ejemplos(context),
                      icon: const Icon(Icons.science_outlined),
                      label: const Text('Cargar puntos de ejemplo'),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
            itemCount: puntos.length,
            itemBuilder: (context, i) {
              final p = puntos[i];
              final esMio = p.creadoPor == uid;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppTheme.sombra,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.place, color: AppColors.verde),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            p.nombre,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppColors.texto,
                            ),
                          ),
                        ),
                        if (esMio)
                          IconButton(
                            tooltip: 'Eliminar',
                            icon: const Icon(Icons.delete_outline,
                                color: AppColors.error),
                            onPressed: () => _eliminar(context, p),
                          ),
                      ],
                    ),
                    if (p.direccion.isNotEmpty || p.barrio.isNotEmpty)
                      Text(
                        [p.direccion, p.barrio]
                            .where((t) => t.isNotEmpty)
                            .join(' · '),
                        style: const TextStyle(color: AppColors.textoSuave),
                      ),
                    if (p.horario.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          'Horario: ${p.horario}',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textoSuave),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: p.materiales
                          .map((id) => catalogoMateriales
                              .where((m) => m.id == id)
                              .firstOrNull)
                          .whereType<MaterialReciclable>()
                          .map<Widget>((m) => Chip(
                                avatar: Icon(m.icono, size: 16, color: m.color),
                                label: Text(
                                  m.nombre.split(' (').first,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                visualDensity: VisualDensity.compact,
                                backgroundColor: Colors.white,
                              ))
                          .toList(),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _FormularioPunto extends StatefulWidget {
  const _FormularioPunto();

  @override
  State<_FormularioPunto> createState() => _FormularioPuntoState();
}

class _FormularioPuntoState extends State<_FormularioPunto> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();
  final _barrioCtrl = TextEditingController();
  final _horarioCtrl = TextEditingController();
  final Set<String> _materiales = {};
  bool _errorMateriales = false;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _direccionCtrl.dispose();
    _barrioCtrl.dispose();
    _horarioCtrl.dispose();
    super.dispose();
  }

  void _guardar() {
    final valido = _formKey.currentState!.validate();
    setState(() => _errorMateriales = _materiales.isEmpty);
    if (!valido || _materiales.isEmpty) return;
    Navigator.pop(
      context,
      PuntoReciclaje(
        id: '',
        nombre: _nombreCtrl.text.trim(),
        direccion: _direccionCtrl.text.trim(),
        barrio: _barrioCtrl.text.trim(),
        horario: _horarioCtrl.text.trim(),
        materiales: _materiales.toList(),
        creadoPor: servicioAuth.usuario?.uid ?? '',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 0, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Nuevo punto de reciclaje',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _nombreCtrl,
                decoration: AppTheme.campo('Nombre del punto', Icons.place),
                validator: (v) {
                  final t = (v ?? '').trim();
                  if (t.length < 3) return 'Mínimo 3 caracteres';
                  if (t.length > 60) return 'Máximo 60 caracteres';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _direccionCtrl,
                decoration: AppTheme.campo('Dirección', Icons.map),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _barrioCtrl,
                decoration: AppTheme.campo('Barrio', Icons.location_city),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _horarioCtrl,
                decoration: AppTheme.campo('Horario', Icons.schedule),
              ),
              const SizedBox(height: 14),
              const Text('Materiales que reciben',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: catalogoMateriales
                    .map((m) => FilterChip(
                          label: Text(m.nombre.split(' (').first),
                          avatar: Icon(m.icono, size: 16, color: m.color),
                          selected: _materiales.contains(m.id),
                          selectedColor: AppColors.verdeClaro,
                          onSelected: (v) => setState(() {
                            v ? _materiales.add(m.id) : _materiales.remove(m.id);
                            _errorMateriales = false;
                          }),
                        ))
                    .toList(),
              ),
              if (_errorMateriales)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text('Selecciona al menos un material',
                      style: TextStyle(fontSize: 12, color: AppColors.error)),
                ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _guardar,
                icon: const Icon(Icons.save),
                label: const Text('Guardar punto'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
