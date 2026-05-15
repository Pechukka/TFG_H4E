import 'package:flutter/material.dart';
import 'package:hands4events/core/theme.dart';

class ModalBase extends StatelessWidget {
  final String titulo;
  final Widget contenido;
  final List<Widget>? botonesAccion;
  final double altura;

  const ModalBase({
    super.key,
    required this.titulo,
    required this.contenido,
    this.botonesAccion,
    this.altura = 0.85,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final kb = MediaQuery.viewInsetsOf(context).bottom;
    // Shrink the modal height when keyboard appears so content stays visible
    final modalHeight = (size.height * altura - kb).clamp(200.0, size.height);

    return Padding(
      // Bottom padding fills the keyboard area, effectively pushing modal above it
      padding: EdgeInsets.only(bottom: kb),
      child: Container(
        height: modalHeight,
        decoration: const BoxDecoration(
          color: AppTheme.fondoCard,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textoTerciario,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      titulo,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppTheme.textoBlanco),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            const Divider(color: AppTheme.bordeCampo, height: 1),

            // Contenido scrollable
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: contenido,
              ),
            ),

            // Botones de acción
            if (botonesAccion != null)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: botonesAccion!,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
