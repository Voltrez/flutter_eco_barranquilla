import 'package:flutter/material.dart';

import '../services/escritura.dart';
import '../state/reciclaje_state.dart';
import '../theme/app_theme.dart';
import '../utils/errores.dart';
import '../utils/mensajes.dart';
import '../widgets/estado_sync.dart';
import '../widgets/formulario_registro.dart';

/// PANTALLA 3: registro de información (crea un documento en Firestore).
class RegistroScreen extends StatelessWidget {
  final ValueChanged<int> onIrA;

  const RegistroScreen({super.key, required this.onIrA});

  Future<bool> _guardar(BuildContext context, DatosFormulario d) async {
    try {
      final (registro, resultado) = await estadoApp.registrar(
        material: d.material,
        kg: d.kg,
        objetos: d.objetos,
        lugar: d.lugar,
        limpio: d.limpio,
        fecha: d.fecha,
        nota: d.nota,
      );
      if (!context.mounted) return true;
      mostrarMensaje(
        context,
        resultado == ResultadoEscritura.sincronizado
            ? '¡Guardado en Firebase! Ganaste ${registro.puntos} puntos.'
            : 'Sin conexión: se guardó en el dispositivo (+${registro.puntos} pts) y se enviará al reconectar.',
        tipo: resultado == ResultadoEscritura.sincronizado
            ? TipoMensaje.exito
            : TipoMensaje.advertencia,
        accion: 'Ver historial',
        onAccion: () => onIrA(2),
      );
      return true;
    } catch (e) {
      if (context.mounted) {
        mostrarMensaje(context, mensajeError(e), tipo: TipoMensaje.error);
      }
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar reciclaje'),
        backgroundColor: AppColors.verde,
        foregroundColor: Colors.white,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Center(child: EstadoSync(compacto: true)),
          ),
        ],
      ),
      body: FormularioRegistro(
        onGuardar: (datos) => _guardar(context, datos),
      ),
    );
  }
}
