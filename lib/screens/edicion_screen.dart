import 'package:flutter/material.dart';

import '../models/registro_reciclaje.dart';
import '../state/reciclaje_state.dart';
import '../theme/app_theme.dart';
import '../utils/errores.dart';
import '../utils/mensajes.dart';
import '../widgets/formulario_registro.dart';

/// PANTALLA 5: edición. Actualiza el documento existente en Firestore.
/// Al terminar devuelve el [ResultadoEscritura] a la pantalla anterior.
class EdicionScreen extends StatelessWidget {
  final RegistroReciclaje registro;

  const EdicionScreen({super.key, required this.registro});

  Future<bool> _guardar(BuildContext context, DatosFormulario d) async {
    try {
      final resultado = await estadoApp.actualizar(
        registro,
        material: d.material,
        kg: d.kg,
        objetos: d.objetos,
        lugar: d.lugar,
        limpio: d.limpio,
        fecha: d.fecha,
        nota: d.nota,
      );
      if (context.mounted) Navigator.pop(context, resultado);
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
        title: const Text('Editar registro'),
        backgroundColor: AppColors.verde,
        foregroundColor: Colors.white,
      ),
      body: FormularioRegistro(
        inicial: registro,
        textoBoton: 'Guardar cambios',
        limpiarAlGuardar: false,
        onGuardar: (datos) => _guardar(context, datos),
      ),
    );
  }
}
