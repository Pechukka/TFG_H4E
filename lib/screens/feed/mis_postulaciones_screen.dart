import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hands4events/core/theme.dart';
import '../../models/evento.dart';
import '../../models/postulacion.dart';
import '../../providers/auth_provider.dart';
import '../../services/eventos_service.dart';
import '../../services/postulaciones_service.dart';
import '../../widgets/app_bar_custom.dart';

// "Mis postulaciones": el worker ve sus postulaciones pendientes y confirmadas.
class MisPostulacionesScreen extends StatefulWidget {
  const MisPostulacionesScreen({super.key});

  @override
  State<MisPostulacionesScreen> createState() => _MisPostulacionesScreenState();
}

class _MisPostulacionesScreenState extends State<MisPostulacionesScreen> {
  final _eventosService = EventosService();

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthProvider>().currentUserId ?? '';

    return Scaffold(
      backgroundColor: AppTheme.fondoPrincipal,
      appBar: const AppBarCustom(
        showLogo: true,
        showBackButton: true,
        title: 'Mis postulaciones',
      ),
      body: StreamBuilder<List<Postulacion>>(
        stream: PostulacionesService.misPostulacionesStream(uid),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(
                child: CircularProgressIndicator(color: AppTheme.verdeNeon));
          }

          // Solo pendientes y confirmadas (las rechazadas/descartadas no se listan).
          final lista = snap.data!
              .where((p) =>
                  p.estado == Postulacion.pendiente ||
                  p.estado == Postulacion.confirmado)
              .toList();
          // Más recientes primero (createdAt puede ser null si aún no llegó del server)
          lista.sort((a, b) => (b.createdAt ?? DateTime(0))
              .compareTo(a.createdAt ?? DateTime(0)));

          if (lista.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.assignment_outlined,
                      color: AppTheme.textoSecundario, size: 48),
                  SizedBox(height: 16),
                  Text('Todavía no te has postulado a nada',
                      style: TextStyle(color: AppTheme.textoSecundario)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: lista.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) => _tarjeta(lista[i]),
          );
        },
      ),
    );
  }

  Widget _tarjeta(Postulacion p) {
    final confirmada = p.estado == Postulacion.confirmado;

    return FutureBuilder<Evento?>(
      future: _eventosService.getEvento(p.eventoId),
      builder: (context, snap) {
        final evento = snap.data;
        final titulo = evento?.titulo ?? 'Evento';
        final fecha = evento == null
            ? ''
            : '${evento.fechaInicio.day.toString().padLeft(2, '0')}/${evento.fechaInicio.month.toString().padLeft(2, '0')}/${evento.fechaInicio.year} · ${evento.horaFormateada}';

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.fondoCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.bordeCard),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo,
                        style: Theme.of(context).textTheme.titleSmall,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    if (fecha.isNotEmpty)
                      Text(fecha,
                          style: const TextStyle(
                              color: AppTheme.textoSecundario, fontSize: 12)),
                    const SizedBox(height: 4),
                    if (p.rol.isNotEmpty)
                      Text('Puesto: ${p.rol}',
                          style: const TextStyle(
                              color: AppTheme.textoTerciario, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _badgeEstado(confirmada),
            ],
          ),
        );
      },
    );
  }

  Widget _badgeEstado(bool confirmada) {
    final color =
        confirmada ? AppTheme.verdeNeon : AppTheme.amarilloAdvertencia;
    final texto = confirmada ? 'Confirmada' : 'Pendiente';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color),
      ),
      child: Text(texto,
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
