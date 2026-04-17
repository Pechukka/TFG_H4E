import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// AppBar personalizado de Hands4Events
/// Muestra el logo central o un título personalizado
/// Opcionalmente muestra botón de retroceso
class AppBarCustom extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final bool showBackButton;
  final bool showLogo;
  final List<Widget>? actions;
  final VoidCallback? onBackPressed;

  const AppBarCustom({
    super.key,
    this.title,
    this.showBackButton = false,
    this.showLogo = true,
    this.actions,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppTheme.fondoPrincipal,
      elevation: 0,
      centerTitle: true,
      automaticallyImplyLeading: false,
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back, color: AppTheme.textoBlanco),
              onPressed: onBackPressed ?? () => Navigator.pop(context),
            )
          : null,
      title: showLogo
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo de la mano verde REAL
                Image.asset(
                  'assets/images/logo_hand.png',
                  width: 28,
                  height: 28,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 8),
                const Text(
                  'HANDS4EVENTS',
                  style: TextStyle(
                    color: AppTheme.textoBlanco,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            )
          : Text(
              title ?? '',
              style: const TextStyle(
                color: AppTheme.textoBlanco,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}