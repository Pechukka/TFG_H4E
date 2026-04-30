import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hands4events/core/theme.dart';
import 'modal_base.dart';

/// Modal para editar número de teléfono
class ModalEditarTelefono extends StatefulWidget {
  const ModalEditarTelefono({super.key});

  @override
  State<ModalEditarTelefono> createState() => _ModalEditarTelefonoState();
}

class _ModalEditarTelefonoState extends State<ModalEditarTelefono> {
  final TextEditingController _telefonoController = TextEditingController(
    text: '612 345 678',
  );

  @override
  void dispose() {
    _telefonoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ModalBase(
      titulo: 'Editar teléfono',
      contenido: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Número de teléfono',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          
          // Campo con prefijo +34 fijo
          Container(
            decoration: BoxDecoration(
              color: AppTheme.fondoInput,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                // Prefijo fijo
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
                
                // Separador
                Container(
                  width: 1,
                  height: 24,
                  color: AppTheme.bordeCampo,
                ),
                
                // Campo editable
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
                      hintStyle: TextStyle(
                        color: AppTheme.textoTerciario,
                      ),
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
            'Este número se usará para contactarte en caso de emergencias o cambios de última hora en los eventos.',
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
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Teléfono actualizado correctamente'),
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

/// Formatter para dar formato al número con espacios
class _PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(' ', '');
    
    if (text.isEmpty) {
      return newValue;
    }
    
    String formatted = '';
    for (int i = 0; i < text.length; i++) {
      if (i == 3 || i == 6) {
        formatted += ' ';
      }
      formatted += text[i];
    }
    
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}