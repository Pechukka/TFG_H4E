import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// AppBar personalizado de Hands4Events
class AppBarCustom extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final String? subtitle;
  final bool showBackButton;
  final bool showLogo;
  final List<Widget>? actions;
  final VoidCallback? onBackPressed;

  const AppBarCustom({
    super.key,
    this.title,
    this.subtitle,
    this.showBackButton = false,
    this.showLogo = true,
    this.actions,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    final hasSubtitle = subtitle != null && subtitle!.trim().isNotEmpty;
    final headerColor =
        Color.lerp(AppTheme.fondoCard, AppTheme.fondoPrincipal, 0.42)!;

    return Container(
      decoration: BoxDecoration(
        color: headerColor,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.bordeCard.withOpacity(0.8),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: hasSubtitle ? 92 : 76,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              if (showBackButton)
                Positioned(
                  left: 4,
                  top: 6,
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: AppTheme.textoBlanco,
                      size: 22,
                    ),
                    onPressed: onBackPressed ?? () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 40,
                      height: 40,
                    ),
                  ),
                ),
              if (actions != null && actions!.isNotEmpty)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: actions!,
                  ),
                ),
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: showBackButton || (actions != null && actions!.isNotEmpty)
                        ? 64
                        : 24,
                    vertical: 2,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (showLogo)
                        Image.asset(
                          'assets/images/banner_sinfondo.png',
                          width: 252,
                          height: 43,
                          fit: BoxFit.contain,
                        ),
                      if (showLogo && (title != null || hasSubtitle))
                        const SizedBox(height: 3),
                      if (title != null)
                        Text(
                          title!,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppTheme.textoBlanco,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            height: 1.1,
                          ),
                        ),
                      if (hasSubtitle) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppTheme.textoSecundario,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            height: 1.1,
                          ),
                        ),
                      ],
                      if (title != null || hasSubtitle)
                        const SizedBox(height: 4),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
      subtitle != null && subtitle!.trim().isNotEmpty ? 92 : 76,
      );
}