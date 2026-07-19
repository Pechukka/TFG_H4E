import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hands4events/core/theme.dart';
import '../providers/idioma_provider.dart';
import '../providers/notificaciones_provider.dart';

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
    final t = context.watch<IdiomaProvider>();
    final noLeidas = context.watch<NotificacionesProvider>().noLeidas;

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
        items: [
          BottomNavigationBarItem(
            icon: Badge(
              isLabelVisible: noLeidas > 0,
              label: Text(noLeidas > 9 ? '9+' : '$noLeidas'),
              backgroundColor: AppTheme.rojoError,
              textStyle: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
              child: const Icon(Icons.home_outlined),
            ),
            activeIcon: Badge(
              isLabelVisible: noLeidas > 0,
              label: Text(noLeidas > 9 ? '9+' : '$noLeidas'),
              backgroundColor: AppTheme.rojoError,
              textStyle: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
              child: const Icon(Icons.home),
            ),
            label: t.tr('nav_escritorio'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.swipe_outlined),
            activeIcon: const Icon(Icons.swipe),
            label: t.tr('nav_ofertas'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.event_note_outlined),
            activeIcon: const Icon(Icons.event_note),
            label: t.tr('nav_eventos'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline),
            activeIcon: const Icon(Icons.person),
            label: t.tr('nav_perfil'),
          ),
        ],
      ),
    );
  }
}
