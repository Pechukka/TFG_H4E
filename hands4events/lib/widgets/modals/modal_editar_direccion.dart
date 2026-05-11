import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hands4events/core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_text_field.dart';
import 'modal_base.dart';

/// Modal para editar dirección
class ModalEditarDireccion extends StatefulWidget {
  const ModalEditarDireccion({super.key});

  @override
  State<ModalEditarDireccion> createState() => _ModalEditarDireccionState();
}

class _ModalEditarDireccionState extends State<ModalEditarDireccion> {
  late final TextEditingController _direccionController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-cargar dirección actual
    final usuario = Provider.of<AuthProvider>(context, listen: false).currentUser;
    _direccionController = TextEditingController(text: usuario?.direccion ?? '');
  }

  @override
  void dispose() {
    _direccionController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final direccion = _direccionController.text.trim();
    if (direccion.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Introduce una dirección válida'),
          backgroundColor: AppTheme.rojoError,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final exito = await authProvider.updateProfile(direccion: direccion);

    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(exito
              ? 'Dirección actualizada correctamente'
              : 'Error al actualizar la dirección'),
          backgroundColor: exito ? AppTheme.verdeExito : AppTheme.rojoError,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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
                  const Icon(
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
            onPressed: _isLoading ? null : _guardar,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.verdeNeon,
              foregroundColor: AppTheme.textoSobreVerde,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.textoSobreVerde,
                    ),
                  )
                : const Text(
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