import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

/// Convierte cualquier error de Firebase en un mensaje claro para el usuario.
String mensajeError(Object e) {
  if (e is FirebaseAuthException) {
    return switch (e.code) {
      'invalid-credential' ||
      'wrong-password' ||
      'user-not-found' ||
      'invalid-login-credentials' =>
        'Correo o contraseña incorrectos.',
      'invalid-email' => 'El correo no tiene un formato válido.',
      'user-disabled' => 'Esta cuenta fue deshabilitada.',
      'email-already-in-use' => 'Ya existe una cuenta con ese correo.',
      'weak-password' => 'La contraseña es muy débil (mínimo 6 caracteres).',
      'too-many-requests' =>
        'Demasiados intentos. Espera unos minutos e inténtalo de nuevo.',
      'network-request-failed' =>
        'Sin conexión a internet. Revisa tu red e inténtalo de nuevo.',
      'operation-not-allowed' =>
        'El inicio de sesión con correo no está habilitado en Firebase.',
      _ => 'No se pudo completar la autenticación (${e.code}).',
    };
  }
  if (e is FirebaseException) {
    return switch (e.code) {
      'permission-denied' =>
        'No tienes permiso para realizar esta acción (reglas de seguridad).',
      'unauthenticated' => 'Debes iniciar sesión para continuar.',
      'unavailable' => 'Sin conexión con el servidor. Inténtalo más tarde.',
      'not-found' => 'El registro ya no existe en la base de datos.',
      'deadline-exceeded' => 'El servidor tardó demasiado en responder.',
      _ => 'Error de Firebase (${e.code}).',
    };
  }
  if (e is TimeoutException) return 'La operación tardó demasiado.';
  if (e is StateError) return e.message;
  return 'Ocurrió un error inesperado. Inténtalo de nuevo.';
}
