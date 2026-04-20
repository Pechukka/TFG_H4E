import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_text_field.dart';
import 'modal_base.dart';

/// Modal para editar dirección
class ModalEditarDireccion extends StatefulWidget {
  const ModalEditarDireccion({super.key});

  @override
  State<ModalEditarDireccion> createState() => _ModalEditarDireccionState();
}

class _ModalEditarDireccionState extends State<ModalEditarDireccion> {
  final TextEditingController _direccionController = TextEditingController(
    text: 'Calle Mayor 123, 28013 Madrid',
  );

  @override
  void dispose() {
    _direccionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ModalBase(
      titulo: 'Editar dirección',
      contenido: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dirección',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          CustomTextField(
            hintText: 'Ingresa tu dirección completa',
            controller: _direccionController,
            keyboardType: TextInputType.streetAddress,
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 24),
          
          // Mapa placeholder
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: AppTheme.fondoInput,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.bordeCampo,
                width: 1,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.map,
                    size: 48,
                    color: AppTheme.textoTerciario,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Mapa interactivo',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textoSecundario,
                    ),
                  ),
                  Text(
                    '(Próximamente)',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textoTerciario,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      botonesAccion: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Dirección actualizada correctamente'),
                  backgroundColor: AppTheme.verdeExito,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.verdeNeon,
              foregroundColor: AppTheme.textoSobreVerde,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Guardar cambios',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}