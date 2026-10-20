import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// COMPONENTE PERSONALIZADO 1: tarjeta de estadística (ícono + valor + etiqueta).
class StatCard extends StatelessWidget {
  final IconData icono;
  final String valor;
  final String etiqueta;
  final Color color;

  const StatCard({
    super.key,
    required this.icono,
    required this.valor,
    required this.etiqueta,
    this.color = AppColors.verde,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.sombra,
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withAlpha(30),
            child: Icon(icono, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          FittedBox(
            child: Text(
              valor,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.texto,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            etiqueta,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: AppColors.textoSuave),
          ),
        ],
      ),
    );
  }
}
