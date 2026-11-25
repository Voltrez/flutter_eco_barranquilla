import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/app_shell.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';
import 'state/reciclaje_state.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  String? errorInicio;
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    errorInicio = e.toString();
  }
  runApp(EcoBarranquillaApp(errorInicio: errorInicio));
}

class EcoBarranquillaApp extends StatelessWidget {
  final String? errorInicio;

  const EcoBarranquillaApp({super.key, this.errorInicio});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eco Barranquilla',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: errorInicio != null
          ? _PantallaErrorFirebase(detalle: errorInicio!)
          : const AuthGate(),
    );
  }
}

/// Decide qué pantalla mostrar según el estado de la sesión.
/// Firebase guarda la sesión en el dispositivo, así que al volver a abrir
/// la app el usuario sigue autenticado hasta que cierre sesión.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  StreamSubscription<User?>? _sub;
  User? _usuario;
  bool _listo = false;

  @override
  void initState() {
    super.initState();
    _sub = servicioAuth.cambios.listen((user) {
      if (user != null) {
        estadoApp.iniciar(user.uid); // empieza la sincronización
      } else {
        estadoApp.detener(); // limpia los datos al cerrar sesión
      }
      if (mounted) {
        setState(() {
          _usuario = user;
          _listo = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_listo) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return _usuario == null ? const LoginScreen() : const AppShell();
  }
}

class _PantallaErrorFirebase extends StatelessWidget {
  final String detalle;
  const _PantallaErrorFirebase({required this.detalle});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off, size: 72, color: AppColors.error),
              const SizedBox(height: 16),
              const Text(
                'No se pudo iniciar Firebase',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(detalle, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
