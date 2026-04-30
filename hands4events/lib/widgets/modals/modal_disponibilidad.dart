import 'package:flutter/material.dart';
import 'package:hands4events/core/theme.dart';
import 'modal_base.dart';

/// Modal para gestionar disponibilidad horaria
class ModalDisponibilidad extends StatefulWidget {
  final DateTime fechaSeleccionada;

  const ModalDisponibilidad({
    super.key,
    required this.fechaSeleccionada,
  });

  @override
  State<ModalDisponibilidad> createState() => _ModalDisponibilidadState();
}

class _ModalDisponibilidadState extends State<ModalDisponibilidad> {
  TimeOfDay _horaInicio = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _horaFin = const TimeOfDay(hour: 18, minute: 0);
  bool _aplicarATodosLosDias = false;

  String _getNombreDia() {
    const dias = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    return dias[widget.fechaSeleccionada.weekday - 1];
  }

  Future<void> _seleccionarHora(BuildContext context, bool esInicio) async {
    final TimeOfDay? seleccionada = await showTimePicker(
      context: context,
      initialTime: esInicio ? _horaInicio : _horaFin,
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

    if (seleccionada != null) {
      setState(() {
        if (esInicio) {
          _horaInicio = seleccionada;
        } else {
          _horaFin = seleccionada;
        }
      });
    }
  }

  String _formatearHora(TimeOfDay hora) {
    return '${hora.hour.toString().padLeft(2, '0')}:${hora.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return ModalBase(
      titulo: 'Disponibilidad horaria',
      contenido: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info del día
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.fondoInput,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  color: AppTheme.verdeNeon,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getNombreDia(),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppTheme.verdeNeon,
                        ),
                      ),
                      Text(
                        '${widget.fechaSeleccionada.day}/${widget.fechaSeleccionada.month}/${widget.fechaSeleccionada.year}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textoSecundario,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Selección de horario
          Text(
            'Horario disponible',
            style: Theme.of(context).textTheme.titleMedium,
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              // Hora inicio
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Desde',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.textoTerciario,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _seleccionarHora(context, true),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.fondoInput,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppTheme.bordeCampo,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatearHora(_horaInicio),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const Icon(
                              Icons.access_time,
                              color: AppTheme.verdeNeon,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // Hora fin
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hasta',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.textoTerciario,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _seleccionarHora(context, false),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.fondoInput,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppTheme.bordeCampo,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatearHora(_horaFin),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const Icon(
                              Icons.access_time,
                              color: AppTheme.verdeNeon,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Switch aplicar a todos los días de la semana
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.fondoInput,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _aplicarATodosLosDias ? AppTheme.verdeNeon : AppTheme.bordeCampo,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Aplicar a todos los ${_getNombreDia()}s',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: _aplicarATodosLosDias ? AppTheme.verdeNeon : AppTheme.textoBlanco,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Este horario se aplicará automáticamente a todos los ${_getNombreDia().toLowerCase()}s',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textoSecundario,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Switch(
                  value: _aplicarATodosLosDias,
                  onChanged: (value) {
                    setState(() {
                      _aplicarATodosLosDias = value;
                    });
                  },
                  activeColor: AppTheme.verdeNeon,
                  activeTrackColor: AppTheme.verdeNeon.withOpacity(0.5),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Info adicional
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.verdeNeon.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.verdeNeon.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: AppTheme.verdeNeon,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Solo estarás disponible para eventos dentro de este horario',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textoSecundario,
                    ),
                  ),
                ),
              ],
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
                SnackBar(
                  content: Text(
                    _aplicarATodosLosDias
                        ? 'Disponibilidad guardada para todos los ${_getNombreDia()}s'
                        : 'Disponibilidad guardada',
                  ),
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
              'Guardar disponibilidad',
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