import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hands4events/core/theme.dart';
import '../../providers/auth_provider.dart';
import 'widgets/admin_sidebar.dart';
import 'dashboard/admin_dashboard_screen.dart';
import 'workers/admin_workers_screen.dart';
import 'eventos/admin_eventos_screen.dart';
import 'nominas/admin_nominas_screen.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  AdminSection _section = AdminSection.dashboard;

  Widget _buildContent() {
    switch (_section) {
      case AdminSection.dashboard:
        return const AdminDashboardScreen();
      case AdminSection.workers:
        return const AdminWorkersScreen();
      case AdminSection.eventos:
        return const AdminEventosScreen();
      case AdminSection.nominas:
        return const AdminNominasScreen();
    }
  }

  String _sectionTitle() {
    switch (_section) {
      case AdminSection.dashboard:
        return 'Inicio';
      case AdminSection.workers:
        return 'Trabajadores';
      case AdminSection.eventos:
        return 'Eventos';
      case AdminSection.nominas:
        return 'Nóminas';
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.fondoCard,
        title: const Text('Cerrar sesión'),
        content: const Text('¿Seguro que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(color: AppTheme.textoSecundario)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cerrar sesión', style: TextStyle(color: AppTheme.verdeNeon)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<AuthProvider>().logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.fondoPrincipal,
      body: Row(
        children: [
          AdminSidebar(
            selected: _section,
            onSelect: (s) => setState(() => _section = s),
            onLogout: _logout,
          ),
          Container(width: 1, color: AppTheme.bordeCard),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AdminTopBar(title: _sectionTitle()),
                Expanded(child: _buildContent()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminTopBar extends StatelessWidget {
  final String title;
  const _AdminTopBar({required this.title});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: AppTheme.fondoCard,
        border: Border(bottom: BorderSide(color: AppTheme.bordeCard, width: 1)),
      ),
      child: Row(
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const Spacer(),
          if (user != null) ...[
            const Icon(Icons.person_outline, color: AppTheme.textoSecundario, size: 18),
            const SizedBox(width: 8),
            Text(
              user.nombre,
              style: const TextStyle(color: AppTheme.textoSecundario, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }
}
