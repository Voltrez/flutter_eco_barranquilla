import 'dart:async';

/// Resultado de una escritura en Firestore.
/// - sincronizado: el servidor confirmó el cambio.
/// - pendiente: no hubo conexión; el cambio quedó guardado en el dispositivo
///   y Firestore lo enviará solo cuando regrese el internet.
enum ResultadoEscritura { sincronizado, pendiente }

/// Espera la confirmación del servidor, pero no deja la pantalla bloqueada
/// si no hay conexión (Firestore nunca falla por falta de internet: encola).
Future<ResultadoEscritura> esperarEscritura(Future<void> escritura) async {
  try {
    await escritura.timeout(const Duration(seconds: 6));
    return ResultadoEscritura.sincronizado;
  } on TimeoutException {
    return ResultadoEscritura.pendiente;
  }
}
