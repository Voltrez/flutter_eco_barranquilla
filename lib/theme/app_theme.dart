import 'package:flutter/material.dart';

class AppColors {
  static const Color verde = Color(0xFF2E7D32);
  static const Color verdeOscuro = Color(0xFF1B5E20);
  static const Color verdeClaro = Color(0xFFE8F5E9);
  static const Color fondo = Color(0xFFF4F8F4);
  static const Color texto = Color(0xFF1B2B1E);
  static const Color textoSuave = Color(0xFF5F6F62);
  static const Color amarillo = Color(0xFFF9A825);
  static const Color azul = Color(0xFF0277BD);
  static const Color error = Color(0xFFC62828);
}

class AppTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.verde),
      scaffoldBackgroundColor: AppColors.fondo,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.verde,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  /// Decoración reutilizable para todos los campos de texto.
  static InputDecoration campo(String etiqueta, IconData icono,
      {String? ayuda}) {
    OutlineInputBorder borde(Color color, [double ancho = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: color, width: ancho),
        );
    return InputDecoration(
      labelText: etiqueta,
      helperText: ayuda,
      prefixIcon: Icon(icono, color: AppColors.verde),
      filled: true,
      fillColor: Colors.white,
      border: borde(Colors.grey.shade300),
      enabledBorder: borde(Colors.grey.shade300),
      focusedBorder: borde(AppColors.verde, 2),
      errorBorder: borde(AppColors.error),
      focusedErrorBorder: borde(AppColors.error, 2),
    );
  }

  static List<BoxShadow> get sombra => [
        BoxShadow(
          color: Colors.black.withAlpha(18),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ];
}
