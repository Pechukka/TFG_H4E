import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hands4events/core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/idioma_provider.dart';
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

  String _sectionTitle(IdiomaProvider t) {
    switch (_section) {
      case AdminSection.dashboard:
        return t.tr('admin_inicio');
      case AdminSection.workers:
        return t.tr('admin_trabajadores');
      case AdminSection.eventos:
        return t.tr('admin_eventos');
      case AdminSection.nominas:
        return t.tr('admin_nominas');
    }
  }

  Future<void> _logout() async {
    final t = context.read<IdiomaProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.fondoCard,
        title: Text(t.tr('cerrar_sesion')),
        content: Text(t.tr('admin_logout_msg')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t.tr('cancelar'), style: const TextStyle(color: AppTheme.textoSecundario)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t.tr('cerrar_sesion'), style: const TextStyle(color: AppTheme.verdeNeon)),
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
    final t = context.watch<IdiomaProvider>();
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
                _AdminTopBar(title: _sectionTitle(t)),
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
