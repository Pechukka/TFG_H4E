import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hands4events/core/theme.dart';
import '../../models/notificacion.dart';
import '../../providers/idioma_provider.dart';
import '../../providers/notificaciones_provider.dart';
import '../../widgets/app_bar_custom.dart';

// Notificaciones del worker. Se abre desde la campanita del feed.
// Al tocar una, se marca como leída.
class NotificacionesScreen extends StatelessWidget {
  const NotificacionesScreen({super.key});

  // Icono según el tipo de notificación
  IconData _iconoDe(TipoNotificacion tipo) {
    switch (tipo) {
      case TipoNotificacion.confirmacion:
        return Icons.how_to_reg_outlined;
      case TipoNotificacion.nuevoEvento:
        return Icons.event_available_outlined;
      case TipoNotificacion.nuevoMensaje:
        return Icons.chat_bubble_outline;
      case TipoNotificacion.nominaPublicada:
        return Icons.receipt_long_outlined;
      case TipoNotificacion.cambioEvento:
        return Icons.edit_calendar_outlined;
      case TipoNotificacion.recordatorio:
        return Icons.alarm_outlined;
      case TipoNotificacion.eventoCancelado:
        return Icons.event_busy_outlined;
      case TipoNotificacion.documentoRequerido:
        return Icons.description_outlined;
      case TipoNotificacion.sistema:
        return Icons.info_outline;
    }
  }

  String _fecha(DateTime f) {
    return '${f.day.toString().padLeft(2, '0')}/${f.month.toString().padLeft(2, '0')} · '
        '${f.hour.toString().padLeft(2, '0')}:${f.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificacionesProvider>();
    final t = context.watch<IdiomaProvider>();
    final lista = provider.notificaciones;
    final noLeidas = provider.noLeidas;

    return Scaffold(
      backgroundColor: AppTheme.fondoPrincipal,
      appBar: AppBarCustom(
        showLogo: true,
        showBackButton: true,
        title: t.tr('feed_notificaciones'),
        actions: [
          if (noLeidas > 0)
            IconButton(
              icon: const Icon(Icons.done_all,
                  color: AppTheme.verdeNeon, size: 22),
              tooltip: t.tr('notif_marcar_todas'),
              onPressed: () {
                for (final n in lista.where((n) => !n.leida)) {
                  provider.marcarLeida(n.id);
                }
              },
            ),
        ],
      ),
      body: provider.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.verdeNeon))
          : lista.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.notifications_none,
                          color: AppTheme.textoSecundario, size: 48),
                      const SizedBox(height: 16),
                      Text(t.tr('notif_vacio'),
                          style: const TextStyle(color: AppTheme.textoSecundario)),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: lista.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) =>
                      _tarjeta(context, provider, lista[i]),
                ),
    );
  }

  Widget _tarjeta(BuildContext context, NotificacionesProvider provider,
      Notificacion n) {
    final sinLeer = !n.leida;

    return InkWell(
      onTap: sinLeer ? () => provider.marcarLeida(n.id) : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.fondoCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: sinLeer
                ? AppTheme.verdeNeon.withValues(alpha: 0.4)
                : AppTheme.bordeCard,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppTheme.verdeNeon.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(_iconoDe(n.tipo),
                  color: AppTheme.verdeNeon, size: 19),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          n.titulo,
                          style: TextStyle(
                            color: AppTheme.textoBlanco,
                            fontSize: 14,
                            fontWeight:
                                sinLeer ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ),
                      if (sinLeer)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppTheme.verdeNeon,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(n.mensaje,
                      style: const TextStyle(
                          color: AppTheme.textoSecundario, fontSize: 13)),
                  const SizedBox(height: 6),
                  Text(_fecha(n.timestamp),
                      style: const TextStyle(
                          color: AppTheme.textoTerciario, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
