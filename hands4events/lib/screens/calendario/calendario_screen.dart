// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_bar_custom.dart';
import '../../widgets/modals/modal_disponibilidad.dart';

/// Pantalla de calendario mensual
/// Permite ver eventos asignados y gestionar disponibilidad horaria
class CalendarioScreen extends StatefulWidget {
  const CalendarioScreen({super.key});

  @override
  State<CalendarioScreen> createState() => _CalendarioScreenState();
}

class _CalendarioScreenState extends State<CalendarioScreen> {
  DateTime _mesActual = DateTime.now();
  int? _diaSeleccionado;

  // Mapa de días con eventos (simulación)
  final Map<int, bool> _diasConEventos = {
    5: true,
    12: true,
    18: true,
    23: true,
  };

  // Mapa de días con disponibilidad configurada (simulación)
  final Map<int, bool> _diasConDisponibilidad = {
    15: true,
    16: true,
    20: true,
    25: true,
    30: true,
  };

  void _cambiarMes(int incremento) {
    setState(() {
      _mesActual = DateTime(
        _mesActual.year,
        _mesActual.month + incremento,
      );
      _diaSeleccionado = null;
    });
  }

  void _seleccionarDia(int dia) {
    setState(() {
      _diaSeleccionado = dia;
    });
  }

  String _getNombreMes() {
    const meses = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre'
    ];
    return '${meses[_mesActual.month - 1]} ${_mesActual.year}';
  }

  List<DateTime> _getDiasDelMes() {
    final primerDia = DateTime(_mesActual.year, _mesActual.month, 1);
    final ultimoDia = DateTime(_mesActual.year, _mesActual.month + 1, 0);

    final dias = <DateTime>[];

    // Días vacíos al inicio (para alinear con el día de la semana)
    for (int i = 1; i < primerDia.weekday; i++) {
      dias.add(DateTime(1970)); // Día placeholder
    }

    // Días del mes
    for (int dia = 1; dia <= ultimoDia.day; dia++) {
      dias.add(DateTime(_mesActual.year, _mesActual.month, dia));
    }

    return dias;
  }

  void _mostrarModalDisponibilidad() {
    if (_diaSeleccionado == null) return;

    final fechaSeleccionada = DateTime(
      _mesActual.year,
      _mesActual.month,
      _diaSeleccionado!,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ModalDisponibilidad(
        fechaSeleccionada: fechaSeleccionada,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dias = _getDiasDelMes();
    final hoy = DateTime.now();

    return Scaffold(
      appBar: const AppBarCustom(
        showLogo: true,
        showBackButton: false,
        title: 'Calendario',
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Navegación de mes
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left,
                        color: AppTheme.textoBlanco),
                    onPressed: () => _cambiarMes(-1),
                  ),
                  Text(
                    _getNombreMes(),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right,
                        color: AppTheme.textoBlanco),
                    onPressed: () => _cambiarMes(1),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

          // Calendario
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.fondoCard,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                // Cabecera días de la semana
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: ['D', 'L', 'M', 'M', 'J', 'V', 'S']
                      .map((dia) => SizedBox(
                            width: 40,
                            child: Center(
                              child: Text(
                                dia,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: AppTheme.verdeNeon,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                          ))
                      .toList(),
                ),

                const SizedBox(height: 12),

                // Grid de días
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    childAspectRatio: 1,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                  ),
                  itemCount: dias.length,
                  itemBuilder: (context, index) {
                    final dia = dias[index];

                    if (dia.year == 1970) {
                      return const SizedBox();
                    }

                    final esHoy = dia.day == hoy.day &&
                        dia.month == hoy.month &&
                        dia.year == hoy.year;

                    final estaSeleccionado = dia.day == _diaSeleccionado;
                    final tieneEvento = _diasConEventos[dia.day] == true;
                    final tieneDisponibilidad =
                        _diasConDisponibilidad[dia.day] == true;

                    return InkWell(
                      onTap: () => _seleccionarDia(dia.day),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: estaSeleccionado
                              ? AppTheme.verdeNeon
                              : (esHoy
                                  ? AppTheme.fondoHover
                                  : Colors.transparent),
                          borderRadius: BorderRadius.circular(8),
                          border: esHoy && !estaSeleccionado
                              ? Border.all(
                                  color: AppTheme.verdeNeon,
                                  width: 1,
                                )
                              : null,
                        ),
                        child: Stack(
                          clipBehavior: Clip.hardEdge,
                          children: [
                            Center(
                              child: Text(
                                '${dia.day}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: estaSeleccionado
                                          ? AppTheme.textoSobreVerde
                                          : AppTheme.textoBlanco,
                                      fontWeight: esHoy
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                              ),
                            ),

                            // Punto indicador de evento (abajo)
                            if (tieneEvento && !estaSeleccionado)
                              Positioned(
                                bottom: 4,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: Container(
                                    width: 4,
                                    height: 4,
                                    decoration: const BoxDecoration(
                                      color: AppTheme.verdeNeon,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ),

                            // Indicador de disponibilidad (fondo verde sutil en el día completo)
                            if (tieneDisponibilidad && !estaSeleccionado)
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppTheme.verdeNeon.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color:
                                          AppTheme.verdeNeon.withOpacity(0.4),
                                      width: 1,
                                    ),
                                  ),
                                ),
                              ),

                            // Número del día (siempre arriba)
                            Center(
                              child: Text(
                                '${dia.day}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: estaSeleccionado
                                          ? AppTheme.textoSobreVerde
                                          : (tieneDisponibilidad
                                              ? AppTheme.verdeNeon
                                              : AppTheme.textoBlanco),
                                      fontWeight: (esHoy || tieneDisponibilidad)
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Sección eventos del día
          if (_diaSeleccionado != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Eventos del $_diaSeleccionado de ${_getNombreMes().split(' ')[0]}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Evento placeholder o mensaje vacío
            if (_diasConEventos[_diaSeleccionado] == true)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.fondoCard,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.verdeNeon.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.event,
                          color: AppTheme.verdeNeon,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Festival de Música',
                              style: Theme.of(context).textTheme.titleSmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '18:00 - 02:00',
                              style:
                                  Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: AppTheme.verdeNeon,
                                      ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.fondoCard,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.event_busy,
                          color: AppTheme.textoTerciario,
                          size: 40,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No hay eventos para este día',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.textoSecundario,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Botón gestionar disponibilidad
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: _mostrarModalDisponibilidad,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.verdeNeon,
                    side: const BorderSide(
                      color: AppTheme.verdeNeon,
                      width: 2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.schedule),
                  label: const Text(
                    'Gestionar disponibilidad',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),
        ],
        ),
      ),
    );
  }
}
