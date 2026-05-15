import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hands4events/core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/eventos_provider.dart';
import '../../providers/idioma_provider.dart';
import '../../models/evento.dart';
import '../../widgets/app_bar_custom.dart';
import 'detalle_evento_screen.dart';

/// Pantalla Eventos
/// Lista todos los eventos asignados al trabajador desde Firestore
class EventosScreen extends StatefulWidget {
  const EventosScreen({super.key});

  @override
  State<EventosScreen> createState() => _EventosScreenState();
}

enum _FiltroEvento { todos, enCurso, proximos, pasados }

class _EventosScreenState extends State<EventosScreen> {
  _FiltroEvento _filtro = _FiltroEvento.todos;
  String? _userId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _userId = context.read<AuthProvider>().currentUserId;
      if (_userId != null) {
        context.read<EventosProvider>().cargarEventos(_userId!);
      }
    });
  }

  Future<void> _refrescar() async {
    if (_userId == null) return;
    context.read<EventosProvider>().cargarEventos(_userId!);
    await Future.delayed(const Duration(milliseconds: 600));
  }

  List<Evento> _eventosFiltrados(EventosProvider provider) {
    switch (_filtro) {
      case _FiltroEvento.enCurso:
        return provider.eventosEnCurso;
      case _FiltroEvento.proximos:
        return provider.eventosFuturos;
      case _FiltroEvento.pasados:
        return provider.eventosPasados;
      case _FiltroEvento.todos:
        return provider.eventos;
    }
  }

  String _formatearFecha(Evento evento) {
    const meses = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    final f = evento.fechaInicio;
    final horaI = '${f.hour.toString().padLeft(2, '0')}:${f.minute.toString().padLeft(2, '0')}';
    final horaF = '${evento.fechaFin.hour.toString().padLeft(2, '0')}:${evento.fechaFin.minute.toString().padLeft(2, '0')}';
    return '${f.day} ${meses[f.month - 1]}, $horaI – $horaF';
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<IdiomaProvider>();
    final eventosProvider = context.watch<EventosProvider>();
    final eventos = _eventosFiltrados(eventosProvider);

    return Scaffold(
      appBar: AppBarCustom(
        showLogo: true,
        showBackButton: false,
        title: t.tr('nav_eventos'),
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),

          // Filtro de pestañas
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildFiltroChip(_FiltroEvento.todos, t.tr('todos'), eventosProvider.eventos.length),
                _buildFiltroChip(_FiltroEvento.enCurso, t.tr('filtro_en_curso'), eventosProvider.eventosEnCurso.length),
                _buildFiltroChip(_FiltroEvento.proximos, t.tr('filtro_proximos'), eventosProvider.eventosFuturos.length),
                _buildFiltroChip(_FiltroEvento.pasados, t.tr('filtro_pasados'), eventosProvider.eventosPasados.length),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Expanded(
            child: RefreshIndicator(
              color: AppTheme.verdeNeon,
              onRefresh: _refrescar,
              child: eventosProvider.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppTheme.verdeNeon),
                    )
                  : eventosProvider.errorMessage != null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.cloud_off, size: 48, color: AppTheme.textoTerciario),
                              const SizedBox(height: 12),
                              Text(
                                t.tr('error_cargar_eventos'),
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: AppTheme.textoSecundario,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: _refrescar,
                                child: Text(t.tr('reintentar'), style: const TextStyle(color: AppTheme.verdeNeon)),
                              ),
                            ],
                          ),
                        )
                      : eventos.isEmpty
                          ? ListView(
                              children: [
                                SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.event_busy, size: 64, color: AppTheme.textoTerciario),
                                    const SizedBox(height: 16),
                                    Text(
                                      t.tr('sin_eventos_categoria'),
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: AppTheme.textoSecundario,
                                          ),
                                    ),
                                  ],
                                ),
                              ],
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: eventos.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final evento = eventos[index];
                                return _buildEventoCard(context, evento);
                              },
                            ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltroChip(_FiltroEvento filtro, String label, int count) {
    final seleccionado = _filtro == filtro;
    return GestureDetector(
      onTap: () => setState(() => _filtro = filtro),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: seleccionado ? AppTheme.verdeNeon : AppTheme.fondoCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: seleccionado ? AppTheme.verdeNeon : AppTheme.bordeCampo,
          ),
        ),
        child: Text(
          count > 0 ? '$label ($count)' : label,
          style: TextStyle(
            color: seleccionado ? AppTheme.textoSobreVerde : AppTheme.textoBlanco,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildEventoCard(BuildContext context, Evento evento) {
    final enCurso = evento.estaEnCurso();
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetalleEventoScreen(evento: evento),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.fondoCard,
          borderRadius: BorderRadius.circular(12),
          border: enCurso
              ? Border.all(color: AppTheme.verdeNeon.withValues(alpha: 0.4), width: 1)
              : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          evento.titulo,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      if (enCurso)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.verdeNeon.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppTheme.verdeNeon, width: 1),
                          ),
                          child: Text(
                            'EN CURSO',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: AppTheme.verdeNeon,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatearFecha(evento),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.verdeNeon,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    evento.ubicacion,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textoSecundario,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right,
              color: AppTheme.textoSecundario,
            ),
          ],
        ),
      ),
    );
  }
}
