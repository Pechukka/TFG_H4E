import 'package:flutter/material.dart';
import '../services/fcm_service.dart';
import '../widgets/bottom_nav_bar.dart';
import 'dashboard/dashboard_screen.dart';
import 'feed/feed_ofertas_screen.dart';
import 'eventos/eventos_screen.dart';
import 'perfil/perfil_screen.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    FeedOfertasScreen(),
    EventosScreen(),
    PerfilScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Listen for tab switches triggered by notification taps
    pendingNavTab.addListener(_onPendingNavTab);
  }

  @override
  void dispose() {
    pendingNavTab.removeListener(_onPendingNavTab);
    super.dispose();
  }

  void _onPendingNavTab() {
    final tab = pendingNavTab.value;
    if (tab != null && mounted) {
      setState(() => _currentIndex = tab);
      pendingNavTab.value = null;
    }
  }

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
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
