import 'package:flutter/material.dart';

import '../models/registro_reciclaje.dart';
import '../services/escritura.dart';
import '../state/reciclaje_state.dart';
import '../theme/app_theme.dart';
import '../utils/dialogos.dart';
import '../utils/errores.dart';
import '../utils/formato.dart';
import '../utils/mensajes.dart';
import '../widgets/contenedor_info.dart';
import 'edicion_screen.dart';

/// PANTALLA 4: detalle completo de un registro.
/// Si el registro se elimina, devuelve el registro eliminado a quien la abrió.
class DetalleScreen extends StatelessWidget {
  final String registroId;

  const DetalleScreen({super.key, required this.registroId});

  Future<void> _editar(BuildContext context, RegistroReciclaje r) async {
    final resultado = await Navigator.push<ResultadoEscritura>(
      context,
      MaterialPageRoute(builder: (_) => EdicionScreen(registro: r)),
    );
    if (resultado == null || !context.mounted) return;
    mostrarMensaje(
      context,
      resultado == ResultadoEscritura.sincronizado
          ? 'Registro actualizado en Firebase.'
          : 'Sin conexión: el cambio se enviará al reconectar.',
      tipo: resultado == ResultadoEscritura.sincronizado
          ? TipoMensaje.exito
          : TipoMensaje.advertencia,
    );
  }

  Future<void> _eliminar(BuildContext context, RegistroReciclaje r) async {
    final ok = await confirmarAccion(
      context,
      titulo: 'Eliminar registro',
      mensaje: 'Se eliminará este registro de la base de datos remota. ¿Deseas continuar?',
    );
    if (!ok || !context.mounted) return;
    try {
      await estadoApp.eliminar(r.id);
      if (context.mounted) Navigator.pop(context, r);
    } catch (e) {
      if (context.mounted) {
        mostrarMensaje(context, mensajeError(e), tipo: TipoMensaje.error);
      }
    }
  }

  Widget _fila(IconData icono, String titulo, String valor) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icono, size: 20, color: AppColors.verde),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textoSuave,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    valor,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.texto,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: estadoApp,
      builder: (context, _) {
        final r = estadoApp.porId(registroId);

        if (r == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Detalle'),
              backgroundColor: AppColors.verde,
              foregroundColor: Colors.white,
            ),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Este registro ya no existe.'),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Volver'),
                  ),
                ],
              ),
            ),
          );
        }

        final m = r.material;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Detalle del registro'),
            backgroundColor: AppColors.verde,
            foregroundColor: Colors.white,
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: AppTheme.sombra,
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 34,
                      backgroundColor: m.color.withAlpha(35),
                      child: Icon(m.icono, color: m.color, size: 36),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      m.nombre,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.texto,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.verdeClaro,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '+${r.puntos} puntos',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.verdeOscuro,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Divider(),
                    _fila(Icons.scale, 'Peso', '${kgTexto(r.kg)} kg'),
                    _fila(Icons.category, 'Objetos', '${r.objetos}'),
                    _fila(r.lugar.icono, 'Entregado a', r.lugar.etiqueta),
                    _fila(
                      r.limpio ? Icons.check_circle : Icons.cancel,
                      'Limpio y seco',
                      r.limpio ? 'Sí (+10 %)' : 'No',
                    ),
                    _fila(Icons.calendar_month, 'Fecha', fechaCorta(r.fecha)),
                    _fila(Icons.cloud_done, 'CO₂ evitado (referencial)',
                        '${r.co2.toStringAsFixed(2)} kg'),
                    if (r.nota.isNotEmpty)
                      _fila(Icons.edit_note, 'Nota', r.nota),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              ContenedorInfo(tipo: m.contenedor),
              const SizedBox(height: 8),
              Text(
                'Consejo: ${m.consejo}',
                style: const TextStyle(color: AppColors.textoSuave),
              ),
              const SizedBox(height: 14),

              // Datos técnicos (útiles para comprobar en la consola de Firebase)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Datos en Firebase',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.texto,
                      ),
                    ),
                    const SizedBox(height: 6),
                    SelectableText(
                      'ID del documento: ${r.id}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    if (r.creadoEn != null)
                      Text('Creado: ${fechaHora(r.creadoEn!)}',
                          style: const TextStyle(fontSize: 12)),
                    if (r.actualizadoEn != null)
                      Text('Actualizado: ${fechaHora(r.actualizadoEn!)}',
                          style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: () => _editar(context, r),
                icon: const Icon(Icons.edit),
                label: const Text('Editar registro'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => _eliminar(context, r),
                icon: const Icon(Icons.delete, color: AppColors.error),
                label: const Text(
                  'Eliminar registro',
                  style: TextStyle(color: AppColors.error),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  side: const BorderSide(color: AppColors.error),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }
}
