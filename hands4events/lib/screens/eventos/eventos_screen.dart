import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hands4events/core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/eventos_provider.dart';
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

class _EventosScreenState extends State<EventosScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().currentUserId;
      if (userId != null) {
        context.read<EventosProvider>().cargarEventos(userId);
      }
    });
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
    final eventosProvider = context.watch<EventosProvider>();
    final eventos = eventosProvider.eventos;

    return Scaffold(
      appBar: const AppBarCustom(
        showLogo: true,
        showBackButton: false,
        title: 'Eventos',
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),

          Expanded(
            child: eventosProvider.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.verdeNeon),
                  )
                : eventos.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.event_busy,
                              size: 64,
                              color: AppTheme.textoTerciario,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No tienes eventos asignados',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: AppTheme.textoSecundario),
                            ),
                          ],
                        ),
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
        ],
      ),
    );
  }

  Widget _buildEventoCard(BuildContext context, Evento evento) {
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
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    evento.titulo,
                    style: Theme.of(context).textTheme.titleSmall,
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
