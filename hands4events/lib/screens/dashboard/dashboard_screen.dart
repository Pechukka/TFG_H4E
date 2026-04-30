import 'package:flutter/material.dart';
import 'package:hands4events/core/theme.dart';
import '../../widgets/app_bar_custom.dart';

/// Pantalla Dashboard (Escritorio)
/// Muestra próximos eventos y notificaciones
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
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

            // Lista de eventos
            _buildEventoCard(
              context,
              titulo: 'Conferencia de Logística',
              fecha: 'Lunes 20 May • 10:00 AM',
            ),

            _buildEventoCard(
              context,
              titulo: 'Feria de Transporte',
              fecha: 'Domingo 26 May • 2:00 PM',
            ),

            _buildEventoCard(
              context,
              titulo: 'Reunión de la industria',
              fecha: 'Jueves 30 May • 9:00 AM',
            ),

            const SizedBox(height: 32),

            // Sección Notificaciones
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Notificaciones',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),

            const SizedBox(height: 12),

            // Subsección: MENSAJES SIN LEER
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'MENSAJES SIN LEER',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppTheme.textoTerciario,
                  letterSpacing: 1.2,
                ),
              ),
            ),

            const SizedBox(height: 8),

            _buildNotificacionCard(
              context,
              icono: Icons.chat_bubble_outline,
              texto: '3 mensajes sin leer en Conferencia de Logística',
            ),

            _buildNotificacionCard(
              context,
              icono: Icons.chat_bubble_outline,
              texto: '1 mensaje sin leer en Feria de Transporte',
            ),

            const SizedBox(height: 16),

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

            _buildNotificacionCard(
              context,
              icono: Icons.check_circle_outline,
              texto: 'Has sido asignado a un nuevo evento: Feria de Transporte',
            ),

            _buildNotificacionCard(
              context,
              icono: Icons.event_outlined,
              texto: 'Cambio de fecha en el evento Cumbre de Logística',
            ),

            _buildNotificacionCard(
              context,
              icono: Icons.access_time,
              texto: 'Cambio de horario en el evento Reunión de la industria',
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildEventoCard(
    BuildContext context, {
    required String titulo,
    required String fecha,
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