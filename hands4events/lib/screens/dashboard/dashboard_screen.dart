import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hands4events/core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/eventos_provider.dart';
import '../../models/evento.dart';
import '../../widgets/app_bar_custom.dart';

/// Pantalla Dashboard (Escritorio)
/// Muestra próximos eventos reales desde Firestore
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Cargar eventos al entrar en el dashboard
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().currentUserId;
      if (userId != null) {
        context.read<EventosProvider>().cargarEventos(userId);
      }
    });
  }

  /// Formatea la fecha del evento para mostrarla como en el diseño original
  String _formatearFechaEvento(Evento evento) {
    const diasSemana = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    const meses = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    final fecha = evento.fechaInicio;
    final diaSemana = diasSemana[fecha.weekday - 1];
    final mes = meses[fecha.month - 1];
    final hora = '${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';
    return '$diaSemana ${fecha.day} $mes • $hora';
  }

  @override
  Widget build(BuildContext context) {
    final eventosProvider = context.watch<EventosProvider>();
    final eventosFuturos = eventosProvider.eventosFuturos;
    final eventosEnCurso = eventosProvider.eventosEnCurso;

    // Los que mostrar en dashboard: en curso primero, luego futuros (máx 5 en total)
    final eventosAMostrar = [...eventosEnCurso, ...eventosFuturos].take(5).toList();

    return Scaffold(
      appBar: const AppBarCustom(
        showLogo: true,
        showBackButton: false,
        title: 'Escritorio',
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            // Sección Próximos eventos
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Próximos eventos',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),

            const SizedBox(height: 12),

            // Lista de eventos desde Firestore
            if (eventosProvider.isLoading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: CircularProgressIndicator(color: AppTheme.verdeNeon),
                ),
              )
            else if (eventosAMostrar.isEmpty)
              _buildSinEventos(context)
            else
              ...eventosAMostrar.map(
                (evento) => _buildEventoCard(
                  context,
                  titulo: evento.titulo,
                  fecha: _formatearFechaEvento(evento),
                  enCurso: evento.estaEnCurso(),
                ),
              ),

            const SizedBox(height: 32),

            // Sección Notificaciones (diseño original mantenido)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Notificaciones',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),

            const SizedBox(height: 12),

            // Subsección: SISTEMA
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'SISTEMA',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppTheme.textoTerciario,
                  letterSpacing: 1.2,
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Notificaciones dinámicas según eventos cargados
            if (eventosEnCurso.isNotEmpty)
              _buildNotificacionCard(
                context,
                icono: Icons.access_time,
                texto: 'Tienes ${eventosEnCurso.length} evento${eventosEnCurso.length > 1 ? 's' : ''} en curso ahora mismo',
              ),

            if (eventosFuturos.isNotEmpty)
              _buildNotificacionCard(
                context,
                icono: Icons.event_outlined,
                texto: 'Tienes ${eventosFuturos.length} evento${eventosFuturos.length > 1 ? 's' : ''} próximo${eventosFuturos.length > 1 ? 's' : ''} asignado${eventosFuturos.length > 1 ? 's' : ''}',
              ),

            if (eventosAMostrar.isEmpty && !eventosProvider.isLoading)
              _buildNotificacionCard(
                context,
                icono: Icons.check_circle_outline,
                texto: 'No tienes eventos asignados por el momento',
              ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSinEventos(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.fondoCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          'No tienes eventos próximos asignados',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.textoSecundario,
          ),
        ),
      ),
    );
  }

  Widget _buildEventoCard(
    BuildContext context, {
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
              color: AppTheme.verdeNeon.withOpacity(0.1),
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
          // Badge "En curso" si el evento está activo ahora
          if (enCurso)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.verdeNeon.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.verdeNeon, width: 1),
              ),
              child: Text(
                'EN CURSO',
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
    required IconData icono,
    required String texto,
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
          Icon(
            icono,
            color: AppTheme.verdeNeon,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              texto,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}