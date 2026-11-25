import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../utils/errores.dart';
import '../utils/mensajes.dart';

/// PANTALLA 0: inicio de sesión y creación de cuenta (Firebase Authentication).
/// Al autenticarse, el AuthGate de main.dart cambia solo a la app.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _correoCtrl = TextEditingController();
  final _claveCtrl = TextEditingController();

  bool _esRegistro = false;
  bool _ocultarClave = true;
  bool _cargando = false;
  String? _error;

  static final _formatoCorreo = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _correoCtrl.dispose();
    _claveCtrl.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      setState(() => _error = null);
      return;
    }
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      if (_esRegistro) {
        await servicioAuth.crearCuenta(
          _nombreCtrl.text,
          _correoCtrl.text,
          _claveCtrl.text,
        );
      } else {
        await servicioAuth.iniciarSesion(_correoCtrl.text, _claveCtrl.text);
      }
      // Éxito: AuthGate detecta la sesión y muestra la app.
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = mensajeError(e));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _recuperarClave() async {
    final correo = _correoCtrl.text.trim();
    if (!_formatoCorreo.hasMatch(correo)) {
      setState(() => _error = 'Escribe tu correo para enviarte el enlace de recuperación.');
      return;
    }
    try {
      await servicioAuth.recuperarClave(correo);
      if (!mounted) return;
      setState(() => _error = null);
      mostrarMensaje(
        context,
        'Si el correo está registrado, recibirás un enlace para restablecer la contraseña.',
        tipo: TipoMensaje.info,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = mensajeError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const CircleAvatar(
                      radius: 42,
                      backgroundColor: AppColors.verde,
                      child: Icon(Icons.recycling, size: 48, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Eco Barranquilla',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppColors.verdeOscuro,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _esRegistro
                          ? 'Crea tu cuenta para guardar tu reciclaje'
                          : 'Inicia sesión para continuar',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textoSuave),
                    ),
                    const SizedBox(height: 24),

                    if (_esRegistro) ...[
                      TextFormField(
                        controller: _nombreCtrl,
                        textCapitalization: TextCapitalization.words,
                        decoration: AppTheme.campo('Nombre', Icons.person),
                        validator: (v) => (v == null || v.trim().length < 2)
                            ? 'Escribe tu nombre'
                            : null,
                      ),
                      const SizedBox(height: 14),
                    ],

                    TextFormField(
                      controller: _correoCtrl,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      decoration:
                          AppTheme.campo('Correo electrónico', Icons.email),
                      validator: (v) {
                        final t = (v ?? '').trim();
                        if (t.isEmpty) return 'Ingresa tu correo';
                        if (!_formatoCorreo.hasMatch(t)) {
                          return 'Escribe un correo válido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    TextFormField(
                      controller: _claveCtrl,
                      obscureText: _ocultarClave,
                      decoration: AppTheme.campo('Contraseña', Icons.lock)
                          .copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(_ocultarClave
                              ? Icons.visibility
                              : Icons.visibility_off),
                          onPressed: () =>
                              setState(() => _ocultarClave = !_ocultarClave),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Ingresa tu contraseña';
                        if (_esRegistro && v.length < 6) {
                          return 'Mínimo 6 caracteres';
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) => _enviar(),
                    ),

                    if (_error != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.error),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error, color: AppColors.error),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _error!,
                                style: const TextStyle(color: AppColors.error),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _cargando ? null : _enviar,
                      child: _cargando
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Text(_esRegistro ? 'Crear cuenta' : 'Iniciar sesión'),
                    ),
                    const SizedBox(height: 8),
                    if (!_esRegistro)
                      TextButton(
                        onPressed: _cargando ? null : _recuperarClave,
                        child: const Text('¿Olvidaste tu contraseña?'),
                      ),
                    TextButton(
                      onPressed: _cargando
                          ? null
                          : () => setState(() {
                                _esRegistro = !_esRegistro;
                                _error = null;
                                _formKey.currentState?.reset();
                              }),
                      child: Text(_esRegistro
                          ? '¿Ya tienes cuenta? Inicia sesión'
                          : '¿No tienes cuenta? Regístrate'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
