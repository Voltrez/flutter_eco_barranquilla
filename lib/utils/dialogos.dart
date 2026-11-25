import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Diálogo de confirmación. Devuelve true solo si el usuario acepta.
Future<bool> confirmarAccion(
  BuildContext context, {
  required String titulo,
  required String mensaje,
  String textoConfirmar = 'Eliminar',
  IconData icono = Icons.delete_forever,
}) async {
  final resultado = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: Icon(icono, color: AppColors.error, size: 36),
      title: Text(titulo, textAlign: TextAlign.center),
      content: Text(mensaje),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(
            textoConfirmar,
            style: const TextStyle(color: AppColors.error),
          ),
        ),
      ],
    ),
  );
  return resultado == true;
}
