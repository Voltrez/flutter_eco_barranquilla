import 'package:flutter/material.dart';

import 'consulta_screen.dart';
import 'home_screen.dart';
import 'registro_screen.dart';

/// Contiene la barra de navegación inferior y las 3 pantallas.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _indice = 0;

  void _irA(int indice) => setState(() => _indice = indice);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _indice,
        children: [
          HomeScreen(onIrA: _irA),
          RegistroScreen(onIrA: _irA),
          ConsultaScreen(onIrA: _irA),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indice,
        onDestinationSelected: _irA,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            selectedIcon: Icon(Icons.add_circle),
            label: 'Registrar',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Mi impacto',
          ),
        ],
      ),
    );
  }
}
