import 'package:flutter/material.dart';
import 'package:hands4events/core/theme.dart';

/// Botón con borde verde y fondo transparente
/// Usado para acciones secundarias (Cancelar, Pausar, etc.)
class CustomOutlineButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double? width;
  final IconData? icon;
  final Color? borderColor;
  final Color? textColor;

  const CustomOutlineButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.width,
    this.icon,
    this.borderColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final btnBorderColor = borderColor ?? AppTheme.verdeNeon;
    final btnTextColor = textColor ?? AppTheme.verdeNeon;

    return SizedBox(
      width: width ?? double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: btnTextColor,
          side: BorderSide(
            color: isLoading
                ? btnBorderColor.withOpacity(0.5)
                : btnBorderColor,
            width: 2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: isLoading
            ? SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(btnTextColor),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: btnTextColor,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}