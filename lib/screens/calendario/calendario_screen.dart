import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hands4events/core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/eventos_provider.dart';
import '../../providers/disponibilidad_provider.dart';
import '../../providers/idioma_provider.dart';
import '../../models/evento.dart';
import '../../widgets/app_bar_custom.dart';
import '../../widgets/modals/modal_disponibilidad.dart';
import '../eventos/detalle_evento_screen.dart';

class CalendarioScreen extends StatefulWidget {
  const CalendarioScreen({super.key});

  @override
  State<CalendarioScreen> createState() => _CalendarioScreenState();
}

class _CalendarioScreenState extends State<CalendarioScreen> {
  DateTime _mesActual = DateTime.now();
  int? _diaSeleccionado;
  List<Evento> _eventosDelDia = [];
  Map<int, bool> _diasConDisponibilidad = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargarMes());
  }

  Future<void> _cargarMes() async {
    final userId = context.read<AuthProvider>().currentUserId;
    if (userId == null) return;

    final eventosProvider = context.read<EventosProvider>();
    final disponibilidadProvider = context.read<DisponibilidadProvider>();

    await eventosProvider.cargarEventosDelMes(
      userId,
      _mesActual.year,
      _mesActual.month,
    );

    final disponibilidades = await disponibilidadProvider
        .getDisponibilidadesDelMes(userId, _mesActual.year, _mesActual.month);

    if (mounted) {
      setState(() => _diasConDisponibilidad = disponibilidades);
    }
  }

  void _cambiarMes(int incremento) {
    setState(() {
      _mesActual = DateTime(_mesActual.year, _mesActual.month + incremento);
      _diaSeleccionado = null;
      _eventosDelDia = [];
      _diasConDisponibilidad = {};
    });
    _cargarMes();
  }

  Future<void> _seleccionarDia(int dia) async {
    setState(() {
      _diaSeleccionado = dia;
      _eventosDelDia = [];
    });

    final userId = context.read<AuthProvider>().currentUserId;
    if (userId == null) return;

    final fecha = DateTime(_mesActual.year, _mesActual.month, dia);
    final eventos = await context.read<EventosProvider>().getEventosPorFecha(userId, fecha);

    if (mounted) {
      setState(() => _eventosDelDia = eventos);
    }
  }

  String _getNombreMes([String idioma = 'es']) {
    const mesesEs = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
    ];
    const mesesEn = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    final meses = idioma == 'en' ? mesesEn : mesesEs;
    return '${meses[_mesActual.month - 1]} ${_mesActual.year}';
  }

  List<DateTime> _getDiasDelMes() {
    final primerDia = DateTime(_mesActual.year, _mesActual.month, 1);
    final ultimoDia = DateTime(_mesActual.year, _mesActual.month + 1, 0);

    final dias = <DateTime>[];
    final offset = primerDia.weekday % 7;
    for (int i = 0; i < offset; i++) {
      dias.add(DateTime(1970));
    }
    for (int dia = 1; dia <= ultimoDia.day; dia++) {
      dias.add(DateTime(_mesActual.year, _mesActual.month, dia));
    }
    return dias;
  }

  Future<void> _mostrarModalDisponibilidad() async {
    if (_diaSeleccionado == null) return;

    final fechaSeleccionada = DateTime(
      _mesActual.year,
      _mesActual.month,
      _diaSeleccionado!,
    );

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ModalDisponibilidad(fechaSeleccionada: fechaSeleccionada),
    );

    if (mounted) _cargarMes();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<IdiomaProvider>();
    final dias = _getDiasDelMes();
    final hoy = DateTime.now();
    final diasHeader = t.idioma == 'en'
        ? ['S', 'M', 'T', 'W', 'T', 'F', 'S']
        : ['D', 'L', 'M', 'M', 'J', 'V', 'S'];

    return Scaffold(
      appBar: AppBarCustom(
        showLogo: true,
        showBackButton: false,
        title: t.tr('nav_calendario'),
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
                    icon: const Icon(Icons.chevron_left, color: AppTheme.textoBlanco),
                    onPressed: () => _cambiarMes(-1),
                  ),
                  Text(
                    _getNombreMes(t.idioma),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, color: AppTheme.textoBlanco),
                    onPressed: () => _cambiarMes(1),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.fondoCard,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: diasHeader
                        .map((dia) => SizedBox(
                              width: 40,
                              child: Center(
                                child: Text(
                                  dia,
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                        color: AppTheme.verdeNeon,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ),
                            ))
                        .toList(),
                  ),

                  const SizedBox(height: 12),

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

                      if (dia.year == 1970) return const SizedBox();

                      final esHoy = dia.day == hoy.day &&
                          dia.month == hoy.month &&
                          dia.year == hoy.year;

                      final estaSeleccionado = dia.day == _diaSeleccionado;
                      final eventosProvider = context.watch<EventosProvider>();
                      final tieneEvento = eventosProvider.tieneEventoEnDia(dia.day);
                      final tieneDisponibilidad = _diasConDisponibilidad[dia.day] == true;

                      final Color textColor;
                      if (estaSeleccionado) {
                        textColor = AppTheme.textoSobreVerde;
                      } else if (tieneDisponibilidad) {
                        textColor = AppTheme.verdeNeon;
                      } else {
                        textColor = AppTheme.textoBlanco;
                      }

                      return InkWell(
                        onTap: () => _seleccionarDia(dia.day),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          decoration: BoxDecoration(
                            color: estaSeleccionado
                                ? AppTheme.verdeNeon
                                : (esHoy ? AppTheme.fondoHover : Colors.transparent),
                            borderRadius: BorderRadius.circular(8),
                            border: esHoy && !estaSeleccionado
                                ? Border.all(color: AppTheme.verdeNeon, width: 1)
                                : null,
                          ),
                          child: Stack(
                            clipBehavior: Clip.hardEdge,
                            children: [
                              // Fondo verde — disponibilidad marcada
                              if (tieneDisponibilidad && !estaSeleccionado)
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: AppTheme.verdeNeon.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: AppTheme.verdeNeon.withValues(alpha: 0.4),
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                ),

                              Center(
                                child: Text(
                                  '${dia.day}',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: textColor,
                                        fontWeight: (esHoy || tieneDisponibilidad)
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                ),
                              ),

                              // Punto verde — tiene evento asignado
                              if (tieneEvento && !estaSeleccionado)
                                Positioned(
                                  bottom: 3,
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
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Leyenda
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _buildLegendItem(
                    context,
                    AppTheme.verdeNeon,
                    t.idioma == 'en' ? 'Availability' : 'Disponibilidad',
                  ),
                  const SizedBox(width: 16),
                  _buildLegendDot(
                    context,
                    AppTheme.verdeNeon,
                    t.idioma == 'en' ? 'Event' : 'Evento',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            if (_diaSeleccionado != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    t.idioma == 'en'
                        ? 'Events on ${_getNombreMes(t.idioma).split(' ')[0]} $_diaSeleccionado'
                        : 'Eventos del $_diaSeleccionado de ${_getNombreMes(t.idioma).split(' ')[0]}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              if (_eventosDelDia.isNotEmpty)
                ..._eventosDelDia.map((evento) {
                  final si = evento.fechaInicio;
                  final sf = evento.fechaFin;
                  final horaI =
                      '${si.hour.toString().padLeft(2, '0')}:${si.minute.toString().padLeft(2, '0')}';
                  final horaF =
                      '${sf.hour.toString().padLeft(2, '0')}:${sf.minute.toString().padLeft(2, '0')}';
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: InkWell(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetalleEventoScreen(evento: evento),
                        ),
                      ),
                      borderRadius: BorderRadius.circular(12),
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
                                color: AppTheme.verdeNeon.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.event, color: AppTheme.verdeNeon, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    evento.titulo,
                                    style: Theme.of(context).textTheme.titleSmall,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$horaI - $horaF',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: AppTheme.verdeNeon,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: AppTheme.textoSecundario),
                          ],
                        ),
                      ),
                    ),
                  );
                })
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
                          const Icon(Icons.event_busy, color: AppTheme.textoTerciario, size: 40),
                          const SizedBox(height: 12),
                          Text(
                            t.tr('sin_eventos_dia'),
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

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton.icon(
                    onPressed: _mostrarModalDisponibilidad,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.verdeNeon,
                      side: const BorderSide(color: AppTheme.verdeNeon, width: 2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.schedule),
                    label: Text(
                      t.tr('gestionar_disponibilidad'),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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

  Widget _buildLegendItem(BuildContext context, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: color.withValues(alpha: 0.6), width: 1),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.textoTerciario),
        ),
      ],
    );
  }

  Widget _buildLegendDot(BuildContext context, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.textoTerciario),
        ),
      ],
    );
  }
}
