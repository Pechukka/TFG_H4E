import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Barra de navegación inferior de la app
class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: const BoxDecoration(
        color: AppTheme.fondoInput,
        border: Border(
          top: BorderSide(color: AppTheme.bordeCard, width: 1),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        backgroundColor: Colors.transparent,
        selectedItemColor: AppTheme.verdeNeon,
        unselectedItemColor: AppTheme.textoTerciario,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Escritorio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            activeIcon: Icon(Icons.calendar_today),
            label: 'Calendario',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event_note_outlined),
            activeIcon: Icon(Icons.event_note),
            label: 'Eventos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}