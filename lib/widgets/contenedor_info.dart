import 'package:flutter/material.dart';

import '../models/material_reciclable.dart';
import '../theme/app_theme.dart';

/// COMPONENTE PERSONALIZADO 3: guía del contenedor donde va cada residuo.
class ContenedorInfo extends StatelessWidget {
  final TipoContenedor tipo;

  const ContenedorInfo({super.key, required this.tipo});

  @override
  Widget build(BuildContext context) {
    final esBlanco = tipo == TipoContenedor.blanco;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: tipo.color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade400),
            ),
            child: Icon(
              Icons.delete_outline,
              color: esBlanco ? Colors.grey.shade700 : Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tipo.nombre,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.texto,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  tipo.descripcion,
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
    );
  }
}
