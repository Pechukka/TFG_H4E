import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hands4events/core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/disponibilidad_provider.dart';
import '../../providers/idioma_provider.dart';
import 'modal_base.dart';
import '../../utils/top_snackbar.dart';

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
  bool _isLoading = false;
  String? _disponibilidadId;

  @override
  void initState() {
    super.initState();
    _cargarDisponibilidad();
  }

  Future<void> _cargarDisponibilidad() async {
    final userId = context.read<AuthProvider>().currentUserId;
    if (userId == null) return;

    final disponibilidad = await context
        .read<DisponibilidadProvider>()
        .getDisponibilidadDia(userId, widget.fechaSeleccionada);

    if (disponibilidad != null && mounted) {
      setState(() {
        _horaInicio = disponibilidad.horaInicio;
        _horaFin = disponibilidad.horaFin;
        _aplicarATodosLosDias = disponibilidad.aplicarRecurrente;
        _disponibilidadId = disponibilidad.id;
      });
    }
  }

  String _getNombreDia(IdiomaProvider t) {
    const keysEs = [
      'dia_lunes', 'dia_martes', 'dia_miercoles',
      'dia_jueves', 'dia_viernes', 'dia_sabado', 'dia_domingo'
    ];
    return t.tr(keysEs[widget.fechaSeleccionada.weekday - 1]);
  }

  Future<void> _seleccionarHora(BuildContext context, bool esInicio) async {
    final TimeOfDay? seleccionada = await showTimePicker(
      context: context,
      initialTime: esInicio ? _horaInicio : _horaFin,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: Theme(
            data: ThemeData.dark().copyWith(
              colorScheme: const ColorScheme.dark(
                primary: AppTheme.verdeNeon,
                onPrimary: AppTheme.textoSobreVerde,
                surface: AppTheme.fondoCard,
                onSurface: AppTheme.textoBlanco,
              ),
              dialogTheme: const DialogThemeData(backgroundColor: AppTheme.fondoCard),
            ),
            child: child!,
          ),
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

  Future<void> _eliminar(IdiomaProvider t) async {
    if (_disponibilidadId == null) return;

    setState(() => _isLoading = true);

    await context
        .read<DisponibilidadProvider>()
        .eliminarDisponibilidad(_disponibilidadId!);

    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.pop(context);
      showTopSnackBar(context, t.tr('disponibilidad_eliminada'),
          backgroundColor: AppTheme.rojoError, icon: Icons.delete_outline);
    }
  }

  Future<void> _guardar(IdiomaProvider t) async {
    final userId = context.read<AuthProvider>().currentUserId;
    if (userId == null) return;

    final inicioMin = _horaInicio.hour * 60 + _horaInicio.minute;
    // 00:00 como hora de fin = medianoche = 24:00 = 1440 min
    final finMin = (_horaFin.hour == 0 && _horaFin.minute == 0)
        ? 1440
        : _horaFin.hour * 60 + _horaFin.minute;
    if (finMin <= inicioMin) {
      showTopSnackBar(context, t.tr('error_hora_fin_menor'),
          backgroundColor: AppTheme.rojoError, icon: Icons.error_outline);
      return;
    }

    setState(() => _isLoading = true);

    final exito = await context.read<DisponibilidadProvider>().guardarDisponibilidad(
          trabajadorId: userId,
          fecha: widget.fechaSeleccionada,
          horaInicio: _horaInicio,
          horaFin: _horaFin,
          aplicarRecurrente: _aplicarATodosLosDias,
          existingId: _disponibilidadId,
        );

    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.pop(context);
      final nombreDia = _getNombreDia(t);
      final msg = exito
          ? (_aplicarATodosLosDias
              ? '${t.tr('disponibilidad_guardada')} – ${t.tr('aplicar_recurrente_prefijo')}$nombreDia${t.tr('aplicar_recurrente_sufijo')}'
              : t.tr('disponibilidad_guardada'))
          : 'Error';
      showTopSnackBar(context, msg,
          backgroundColor: exito ? AppTheme.verdeExito : AppTheme.rojoError,
          icon: exito ? Icons.check_circle_outline : Icons.error_outline);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<IdiomaProvider>();
    final nombreDia = _getNombreDia(t);

    return ModalBase(
      titulo: t.tr('disponibilidad_horaria'),
      contenido: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.fondoInput,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, color: AppTheme.verdeNeon, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nombreDia,
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

          Text(t.tr('horario_disponible'), style: Theme.of(context).textTheme.titleMedium),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.tr('desde'),
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
                          border: Border.all(color: AppTheme.bordeCampo, width: 1),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_formatearHora(_horaInicio),
                                style: Theme.of(context).textTheme.titleMedium),
                            const Icon(Icons.access_time, color: AppTheme.verdeNeon, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.tr('hasta_hora'),
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
                          border: Border.all(color: AppTheme.bordeCampo, width: 1),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              (_horaFin.hour == 0 && _horaFin.minute == 0)
                                  ? '24:00'
                                  : _formatearHora(_horaFin),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const Icon(Icons.access_time, color: AppTheme.verdeNeon, size: 20),
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
                        '${t.tr('aplicar_recurrente_prefijo')}$nombreDia${t.tr('aplicar_recurrente_sufijo')}',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: _aplicarATodosLosDias
                                  ? AppTheme.verdeNeon
                                  : AppTheme.textoBlanco,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${t.tr('recurrente_desc')}${nombreDia.toLowerCase()}${t.tr('recurrente_desc2')}',
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
                  onChanged: (value) => setState(() => _aplicarATodosLosDias = value),
                  activeThumbColor: AppTheme.verdeNeon,
                  activeTrackColor: AppTheme.verdeNeon.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.verdeNeon.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.verdeNeon.withValues(alpha: 0.3), width: 1),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppTheme.verdeNeon, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    t.tr('disponibilidad_info'),
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
            onPressed: _isLoading ? null : () => _guardar(t),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.verdeNeon,
              foregroundColor: AppTheme.textoSobreVerde,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.textoSobreVerde),
                  )
                : Text(
                    t.tr('guardar_disponibilidad'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
        if (_disponibilidadId != null) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton.icon(
              onPressed: _isLoading ? null : () => _eliminar(t),
              icon: const Icon(Icons.delete_outline, color: AppTheme.rojoError),
              label: Text(
                t.tr('eliminar_disponibilidad'),
                style: const TextStyle(
                  color: AppTheme.rojoError,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.rojoError),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
