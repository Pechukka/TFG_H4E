import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hands4events/core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/eventos_provider.dart';
import '../../providers/nominas_provider.dart';
import '../../providers/notificaciones_provider.dart';
import '../../providers/idioma_provider.dart';
import '../../models/evento.dart';
import '../../models/notificacion.dart';
import '../../widgets/app_bar_custom.dart';
import '../eventos/detalle_evento_screen.dart';
import '../chat/chat_evento_screen.dart';
import '../nominas/nominas_screen.dart';
import '../perfil/perfil_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().currentUserId;
      if (userId != null) {
        context.read<EventosProvider>().cargarEventos(userId);
        context.read<NotificacionesProvider>().cargarNotificaciones(userId);
        context.read<NominasProvider>().cargarNominas(userId);
      }
    });
  }

  String _formatearFechaEvento(Evento evento, String idioma) {
    const diasEs = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    const diasEn = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const mesesEs = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    const mesesEn = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final dias = idioma == 'en' ? diasEn : diasEs;
    final meses = idioma == 'en' ? mesesEn : mesesEs;
    final fecha = evento.fechaInicio;
    final diaSemana = dias[fecha.weekday - 1];
    final mes = meses[fecha.month - 1];
    final hora = '${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';
    return '$diaSemana ${fecha.day} $mes • $hora';
  }

  void _navegarNotificacion(Notificacion notif) async {
    await context.read<NotificacionesProvider>().marcarLeida(notif.id);

    if (!mounted) return;

    switch (notif.tipo) {
      case TipoNotificacion.nuevoEvento:
        final eventoId = notif.datos?['eventoId'];
        if (eventoId != null) {
          final evento = await context.read<EventosProvider>().fetchEvento(eventoId);
          if (mounted && evento != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetalleEventoScreen(evento: evento),
              ),
            );
          }
        }
        break;

      case TipoNotificacion.nuevoMensaje:
        final eventoId = notif.datos?['eventoId'];
        final tituloEvento = notif.datos?['tituloEvento'] ?? 'Evento';
        if (eventoId != null && mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatEventoScreen(
                tituloEvento: tituloEvento,
                eventoId: eventoId,
              ),
            ),
          );
        }
        break;

      case TipoNotificacion.nominaPublicada:
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NominasScreen()),
          );
        }
        break;

      case TipoNotificacion.cambioEvento:
        final eventoIdCambio = notif.datos?['eventoId'];
        if (eventoIdCambio != null) {
          final evento = await context.read<EventosProvider>().fetchEvento(eventoIdCambio);
          if (mounted && evento != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetalleEventoScreen(evento: evento),
              ),
            );
          }
        }
        break;

      case TipoNotificacion.documentoRequerido:
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PerfilScreen()),
          );
        }
        break;

      case TipoNotificacion.recordatorio:
        final eventoIdRecordatorio = notif.datos?['eventoId'];
        if (eventoIdRecordatorio != null) {
          final evento = await context.read<EventosProvider>().fetchEvento(eventoIdRecordatorio);
          if (mounted && evento != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetalleEventoScreen(evento: evento),
              ),
            );
          }
        }
        break;

      case TipoNotificacion.confirmacion:
        // Te han confirmado en un evento — abrir su detalle
        final eventoIdConfirmacion = notif.datos?['eventoId'];
        if (eventoIdConfirmacion != null) {
          final evento =
              await context.read<EventosProvider>().fetchEvento(eventoIdConfirmacion);
          if (mounted && evento != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetalleEventoScreen(evento: evento),
              ),
            );
          }
        }
        break;

      case TipoNotificacion.eventoCancelado:
        // El evento ya no existe — solo marcar como leída
        break;

      case TipoNotificacion.sistema:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<IdiomaProvider>();
    final eventosProvider = context.watch<EventosProvider>();
    final notificacionesProvider = context.watch<NotificacionesProvider>();
    final nominasProvider = context.watch<NominasProvider>();

    final eventosFuturos = eventosProvider.eventosFuturos;
    final eventosEnCurso = eventosProvider.eventosEnCurso;
    final eventosAMostrar =
        [...eventosEnCurso, ...eventosFuturos].take(5).toList();
    final notificaciones =
        notificacionesProvider.notificaciones.take(5).toList();
    final ultimaNomina = nominasProvider.ultimaNomina;

    return Scaffold(
      appBar: AppBarCustom(
        showLogo: true,
        showBackButton: false,
        title: t.tr('escritorio'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            // Resumen última nómina
            if (ultimaNomina != null)
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NominasScreen(),
                  ),
                ),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.fondoCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.verdeNeon.withValues(alpha: 0.25),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppTheme.verdeNeon.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.description_outlined,
                          color: AppTheme.verdeNeon,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.tr('ultima_nomina'),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.textoSecundario,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              ultimaNomina.nombreCompleto,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ],
                        ),
                      ),
                      Text(
                        ultimaNomina.sueldoNetoFormateado,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.verdeNeon,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                t.tr('proximos_eventos'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 12),
            if (eventosProvider.isLoading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: CircularProgressIndicator(color: AppTheme.verdeNeon),
                ),
              )
            else if (eventosAMostrar.isEmpty)
              _buildSinEventos(context, t)
            else
              ...eventosAMostrar.map(
                (evento) => _buildEventoCard(
                  context,
                  t: t,
                  titulo: evento.titulo,
                  fecha: _formatearFechaEvento(evento, t.idioma),
                  enCurso: evento.estaEnCurso(),
                ),
              ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                t.tr('notificaciones'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 12),
            if (notificacionesProvider.isLoading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: CircularProgressIndicator(color: AppTheme.verdeNeon),
                ),
              )
            else if (notificaciones.isEmpty)
              _buildSinNotificaciones(context, t)
            else
              ...notificaciones.map((notif) => _buildNotificacionCard(
                    context,
                    notificacion: notif,
                    onTap: () => _navegarNotificacion(notif),
                    onDismiss: () => context
                        .read<NotificacionesProvider>()
                        .eliminarNotificacion(notif.id),
                  )),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSinEventos(BuildContext context, IdiomaProvider t) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.fondoCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          t.tr('sin_eventos'),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textoSecundario,
              ),
        ),
      ),
    );
  }

  Widget _buildSinNotificaciones(BuildContext context, IdiomaProvider t) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.fondoCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          t.tr('sin_notificaciones'),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textoSecundario,
              ),
        ),
      ),
    );
  }

  Widget _buildEventoCard(
    BuildContext context, {
    required IdiomaProvider t,
    required String titulo,
    required String fecha,
    bool enCurso = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
            child: const Icon(
              Icons.calendar_today,
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
                  titulo,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  fecha,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.verdeNeon,
                      ),
                ),
              ],
            ),
          ),
          if (enCurso)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.verdeNeon.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.verdeNeon, width: 1),
              ),
              child: Text(
                t.tr('en_curso'),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppTheme.verdeNeon,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNotificacionCard(
    BuildContext context, {
    required Notificacion notificacion,
    required VoidCallback onTap,
    required VoidCallback onDismiss,
  }) {
    IconData icono;
    switch (notificacion.tipo) {
      case TipoNotificacion.nuevoEvento:
        icono = Icons.event;
        break;
      case TipoNotificacion.nuevoMensaje:
        icono = Icons.chat_bubble;
        break;
      case TipoNotificacion.nominaPublicada:
        icono = Icons.description;
        break;
      case TipoNotificacion.recordatorio:
        icono = Icons.alarm;
        break;
      case TipoNotificacion.eventoCancelado:
        icono = Icons.event_busy;
        break;
      case TipoNotificacion.cambioEvento:
        icono = Icons.edit_calendar;
        break;
      default:
        icono = Icons.notifications;
    }

    final dismissBackground = Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      alignment: Alignment.centerLeft,
      child: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
    );

    return Dismissible(
      key: Key(notificacion.id),
      direction: DismissDirection.horizontal,
      background: dismissBackground,
      secondaryBackground: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.centerRight,
        child: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
      ),
      onDismissed: (_) => onDismiss(),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.fondoCard,
            borderRadius: BorderRadius.circular(12),
            border: notificacion.leida
                ? null
                : Border.all(
                    color: AppTheme.verdeNeon.withValues(alpha: 0.3), width: 1),
          ),
          child: Row(
            children: [
              Icon(icono, color: AppTheme.verdeNeon, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notificacion.titulo,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: notificacion.leida
                                ? FontWeight.normal
                                : FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notificacion.mensaje,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textoSecundario,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (!notificacion.leida)
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
        ),
      ),
    );
  }
}
