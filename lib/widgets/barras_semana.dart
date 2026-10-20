import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// COMPONENTE PERSONALIZADO 4: gráfico de barras simple (sin paquetes).
class BarrasSemana extends StatelessWidget {
  final List<double> valores;
  final List<String> etiquetas;

  const BarrasSemana({
    super.key,
    required this.valores,
    required this.etiquetas,
  });

  @override
  Widget build(BuildContext context) {
    final maximo = valores.fold<double>(0, (a, b) => b > a ? b : a);
    return SizedBox(
      height: 130,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(valores.length, (i) {
          final valor = valores[i];
          final altura = maximo == 0 ? 4.0 : 4 + (valor / maximo) * 80;
          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  valor > 0 ? valor.toStringAsFixed(1) : '',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textoSuave,
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  height: altura,
                  width: 18,
                  decoration: BoxDecoration(
                    color: valor > 0 ? AppColors.verde : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  etiquetas[i],
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textoSuave,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
