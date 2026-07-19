import 'package:flutter/material.dart';
import 'package:hands4events/core/theme.dart';

enum AdminSection { dashboard, workers, eventos, nominas }

class AdminSidebar extends StatelessWidget {
  final AdminSection selected;
  final ValueChanged<AdminSection> onSelect;
  final VoidCallback onLogout;

  const AdminSidebar({
    super.key,
    required this.selected,
    required this.onSelect,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      color: AppTheme.fondoCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Image.asset(
              'assets/images/banner_sinfondo.png',
              height: 36,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Panel Admin',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textoSecundario,
                  ),
            ),
          ),
          const SizedBox(height: 24),
          const Divider(color: AppTheme.bordeCard, height: 1),
          const SizedBox(height: 12),
          _SidebarItem(
            icon: Icons.dashboard_outlined,
            label: 'Inicio',
            selected: selected == AdminSection.dashboard,
            onTap: () => onSelect(AdminSection.dashboard),
          ),
          _SidebarItem(
            icon: Icons.people_outline,
            label: 'Trabajadores',
            selected: selected == AdminSection.workers,
            onTap: () => onSelect(AdminSection.workers),
          ),
          _SidebarItem(
            icon: Icons.event_outlined,
            label: 'Eventos',
            selected: selected == AdminSection.eventos,
            onTap: () => onSelect(AdminSection.eventos),
          ),
          _SidebarItem(
            icon: Icons.description_outlined,
            label: 'Nóminas',
            selected: selected == AdminSection.nominas,
            onTap: () => onSelect(AdminSection.nominas),
          ),
          const Spacer(),
          const Divider(color: AppTheme.bordeCard, height: 1),
          _SidebarItem(
            icon: Icons.logout,
            label: 'Cerrar sesión',
            selected: false,
            onTap: onLogout,
            textColor: AppTheme.textoSecundario,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? textColor;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.textColor,
  });

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.selected
        ? AppTheme.verdeNeon
        : (widget.textColor ?? AppTheme.textoBlanco);

    // Fondo: seleccionado (verde tenue) > hover (gris tenue) > nada
    final Color? fondo = widget.selected
        ? AppTheme.verdeNeon.withValues(alpha: 0.1)
        : (_hover ? AppTheme.fondoHover : null);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: fondo,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(widget.icon, color: color, size: 20),
              const SizedBox(width: 10),
              Text(
                widget.label,
                style: TextStyle(
                  color: color,
                  fontWeight:
                      widget.selected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
