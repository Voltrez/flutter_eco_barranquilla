import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Autenticación con correo y contraseña (Firebase Authentication).
/// Además guarda el perfil del usuario en la colección `usuarios`.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> get cambios => _auth.authStateChanges();
  User? get usuario => _auth.currentUser;

  String get nombreUsuario {
    final u = usuario;
    if (u == null) return 'eco-ciudadano';
    final nombre = u.displayName;
    if (nombre != null && nombre.trim().isNotEmpty) return nombre.trim();
    return (u.email ?? 'eco-ciudadano').split('@').first;
  }

  Future<void> iniciarSesion(String correo, String clave) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: correo.trim(),
      password: clave,
    );
    await _guardarPerfil(cred.user, ultimoAcceso: true);
  }

  Future<void> crearCuenta(String nombre, String correo, String clave) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: correo.trim(),
      password: clave,
    );
    await cred.user?.updateDisplayName(nombre.trim());
    await _guardarPerfil(cred.user, nombre: nombre.trim(), esNuevo: true);
  }

  Future<void> recuperarClave(String correo) =>
      _auth.sendPasswordResetEmail(email: correo.trim());

  Future<void> cerrarSesion() => _auth.signOut();

  /// Crea o actualiza el documento `usuarios/{uid}`.
  /// Si falla no bloquea el ingreso: el login ya fue exitoso.
  Future<void> _guardarPerfil(
    User? user, {
    String? nombre,
    bool esNuevo = false,
    bool ultimoAcceso = false,
  }) async {
    if (user == null) return;
    try {
      await _db.collection('usuarios').doc(user.uid).set({
        'uid': user.uid,
        'correo': user.email,
        if (nombre != null) 'nombre': nombre,
        if (esNuevo) 'creadoEn': FieldValue.serverTimestamp(),
        if (ultimoAcceso || esNuevo) 'ultimoAcceso': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      // El perfil es secundario; se ignora el error.
    }
  }
}

/// Instancia única usada por toda la app.
final AuthService servicioAuth = AuthService();
