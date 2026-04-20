import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'modal_base.dart';

/// Modal para solicitar días de vacaciones
class ModalSolicitarVacaciones extends StatefulWidget {
  const ModalSolicitarVacaciones({super.key});

  @override
  State<ModalSolicitarVacaciones> createState() => _ModalSolicitarVacacionesState();
}

class _ModalSolicitarVacacionesState extends State<ModalSolicitarVacaciones> {
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  final TextEditingController _observacionesController = TextEditingController();

  Future<void> _seleccionarFecha(BuildContext context, bool esInicio) async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.verdeNeon,
              onPrimary: AppTheme.textoSobreVerde,
              surface: AppTheme.fondoCard,
              onSurface: AppTheme.textoBlanco,
            ),
            dialogBackgroundColor: AppTheme.fondoCard,
          ),
          child: child!,
        );
      },
    );

    if (fecha != null) {
      setState(() {
        if (esInicio) {
          _fechaInicio = fecha;
        } else {
          _fechaFin = fecha;
        }
      });
    }
  }

  String _formatearFecha(DateTime? fecha) {
    if (fecha == null) return 'Seleccionar fecha';
    return '${fecha.day}/${fecha.month}/${fecha.year}';
  }

  @override
  void dispose() {
    _observacionesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ModalBase(
      titulo: 'Solicitar vacaciones',
      contenido: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Días disponibles
          Center(
            child: Column(
              children: [
                Text(
                  'Días disponibles',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textoSecundario,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '15',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.verdeNeon,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Fecha de inicio
          Text(
            'Fecha de inicio',
            style: Theme.of(context).textTheme.labelLarge,
          ),

          const SizedBox(height: 8),

          InkWell(
            onTap: () => _seleccionarFecha(context, true),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: AppTheme.fondoInput,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _formatearFecha(_fechaInicio),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: _fechaInicio == null
                            ? AppTheme.textoTerciario
                            : AppTheme.textoBlanco,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.calendar_today,
                    color: AppTheme.verdeNeon,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Fecha de fin
          Text(
            'Fecha de fin',
            style: Theme.of(context).textTheme.labelLarge,
          ),

          const SizedBox(height: 8),

          InkWell(
            onTap: () => _seleccionarFecha(context, false),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: AppTheme.fondoInput,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _formatearFecha(_fechaFin),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: _fechaFin == null
                            ? AppTheme.textoTerciario
                            : AppTheme.textoBlanco,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.calendar_today,
                    color: AppTheme.verdeNeon,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Observaciones
          Text(
            'Observaciones',
            style: Theme.of(context).textTheme.labelLarge,
          ),

          const SizedBox(height: 8),

          TextField(
            controller: _observacionesController,
            maxLines: 4,
            style: const TextStyle(color: AppTheme.textoBlanco),
            decoration: InputDecoration(
              hintText: 'Añade un comentario opcional',
              hintStyle: const TextStyle(color: AppTheme.textoTerciario),
              filled: true,
              fillColor: AppTheme.fondoInput,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
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
                  content: Text('Solicitud enviada correctamente'),
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
              'Enviar solicitud',
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