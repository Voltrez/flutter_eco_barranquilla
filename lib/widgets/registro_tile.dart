import 'package:flutter/material.dart';

import '../models/registro_reciclaje.dart';
import '../theme/app_theme.dart';
import '../utils/formato.dart';

/// COMPONENTE PERSONALIZADO 2: fila del historial de reciclaje.
class RegistroTile extends StatelessWidget {
  final RegistroReciclaje registro;

  const RegistroTile({super.key, required this.registro});

  @override
  Widget build(BuildContext context) {
    final m = registro.material;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppTheme.sombra,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: m.color.withAlpha(35),
            child: Icon(m.icono, color: m.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${m.nombre} · ${kgTexto(registro.kg)} kg',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.texto,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${registro.objetos} objetos · ${registro.lugar.etiquetaCorta} · ${fechaCorta(registro.fecha)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textoSuave,
                  ),
                ),
                if (registro.nota.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '“${registro.nota}”',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: AppColors.textoSuave,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.verdeClaro,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '+${registro.puntos} pts',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.verdeOscuro,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
