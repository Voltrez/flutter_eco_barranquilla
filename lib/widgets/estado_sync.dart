import 'package:flutter/material.dart';

import '../state/reciclaje_state.dart';

/// Indicador del estado de sincronización con Firebase.
class EstadoSync extends StatelessWidget {
  /// Si es true, se dibuja con colores claros (para fondos oscuros).
  final bool compacto;

  const EstadoSync({super.key, this.compacto = false});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: estadoApp,
      builder: (context, _) {
        final (IconData icono, String texto, Color color) = estadoApp.error != null
            ? (Icons.error_outline, 'Error de sincronización', const Color(0xFFC62828))
            : estadoApp.pendiente
                ? (Icons.cloud_upload, 'Pendiente de enviar', const Color(0xFFEF6C00))
                : estadoApp.desdeCache
                    ? (Icons.cloud_off, 'Datos locales (sin servidor)', Colors.blueGrey)
                    : (Icons.cloud_done, 'Sincronizado con Firebase', const Color(0xFF2E7D32));

        return Tooltip(
          message: texto,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: color.withAlpha(28),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withAlpha(90)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icono, size: 16, color: color),
                if (!compacto) ...[
                  const SizedBox(width: 6),
                  Text(
                    texto,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
