import 'package:flutter/material.dart';

enum TipoMensaje { exito, advertencia, error, info }

/// Muestra un SnackBar de confirmación, advertencia o error.
void mostrarMensaje(
  BuildContext context,
  String texto, {
  TipoMensaje tipo = TipoMensaje.info,
  String? accion,
  VoidCallback? onAccion,
}) {
  final (Color color, IconData icono) = switch (tipo) {
    TipoMensaje.exito => (const Color(0xFF2E7D32), Icons.check_circle),
    TipoMensaje.advertencia => (const Color(0xFFEF6C00), Icons.warning_amber),
    TipoMensaje.error => (const Color(0xFFC62828), Icons.error),
    TipoMensaje.info => (const Color(0xFF0277BD), Icons.info),
  };

  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      content: Row(
        children: [
          Icon(icono, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(child: Text(texto)),
        ],
      ),
      action: accion == null
          ? null
          : SnackBarAction(
              label: accion,
              textColor: Colors.white,
              onPressed: onAccion ?? () {},
            ),
    ),
  );
}
