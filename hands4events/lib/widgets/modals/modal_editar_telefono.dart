import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:hands4events/core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/idioma_provider.dart';
import 'modal_base.dart';
import '../../utils/top_snackbar.dart';

class ModalEditarTelefono extends StatefulWidget {
  const ModalEditarTelefono({super.key});

  @override
  State<ModalEditarTelefono> createState() => _ModalEditarTelefonoState();
}

class _ModalEditarTelefonoState extends State<ModalEditarTelefono> {
  late final TextEditingController _telefonoController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final usuario = Provider.of<AuthProvider>(context, listen: false).currentUser;
    final telActual = usuario?.telefono?.replaceAll('+34', '').trim() ?? '';
    _telefonoController = TextEditingController(text: telActual);
  }

  @override
  void dispose() {
    _telefonoController.dispose();
    super.dispose();
  }

  Future<void> _guardar(IdiomaProvider t) async {
    final numero = _telefonoController.text.replaceAll(' ', '');
    if (numero.length != 9) {
      showTopSnackBar(context, t.tr('telefono_digitos_error'),
          backgroundColor: AppTheme.rojoError, icon: Icons.error_outline);
      return;
    }

    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final exito = await authProvider.updateProfile(telefono: '+34 $numero');

    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.pop(context);
      showTopSnackBar(
        context,
        exito ? t.tr('telefono_actualizado') : t.tr('error_actualizar_telefono'),
        backgroundColor: exito ? AppTheme.verdeExito : AppTheme.rojoError,
        icon: exito ? Icons.check_circle_outline : Icons.error_outline,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<IdiomaProvider>();

    return ModalBase(
      titulo: t.tr('editar_telefono'),
      contenido: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.tr('numero_telefono'),
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),

          Container(
            decoration: BoxDecoration(
              color: AppTheme.fondoInput,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    '+34',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textoBlanco,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                Container(
                  width: 1,
                  height: 24,
                  color: AppTheme.bordeCampo,
                ),
                Expanded(
                  child: TextField(
                    controller: _telefonoController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(
                      color: AppTheme.textoBlanco,
                      fontSize: 16,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(9),
                      _PhoneNumberFormatter(),
                    ],
                    decoration: const InputDecoration(
                      hintText: '612 345 678',
                      hintStyle: TextStyle(color: AppTheme.textoTerciario),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          Text(
            t.tr('telefono_info'),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textoSecundario,
                ),
          ),
        ],
      ),
      botonesAccion: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : () => _guardar(t),
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
                : Text(
                    t.tr('guardar_cambios'),
                    style: const TextStyle(
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

class _PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(' ', '');

    if (text.isEmpty) return newValue;

    String formatted = '';
    for (int i = 0; i < text.length; i++) {
      if (i == 3 || i == 6) formatted += ' ';
      formatted += text[i];
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
