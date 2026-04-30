import 'package:flutter/material.dart';
import 'package:hands4events/core/theme.dart';

/// Modal base reutilizable con estructura común
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
    return Container(
      height: MediaQuery.of(context).size.height * altura,
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

          // Contenido
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
    );
  }
}