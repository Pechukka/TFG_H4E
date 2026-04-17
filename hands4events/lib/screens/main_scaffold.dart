import 'package:flutter/material.dart';
import '../widgets/bottom_nav_bar.dart';
import 'dashboard/dashboard_screen.dart';
import 'calendario/calendario_screen.dart';
import 'eventos/eventos_screen.dart';
import 'perfil/perfil_screen.dart';

/// Scaffold principal de la aplicación
/// Contiene el BottomNavigationBar y gestiona la navegación entre secciones
class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  // Lista de pantallas
  final List<Widget> _screens = const [
    DashboardScreen(),
    CalendarioScreen(),
    EventosScreen(),
    PerfilScreen(),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}