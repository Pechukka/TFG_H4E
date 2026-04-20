import 'package:flutter/material.dart';
import 'package:hands4events/screens/eventos/chat_evento_screen.dart';
import 'package:hands4events/screens/fichaje/fichaje_screen.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_bar_custom.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/outline_button.dart';

/// Pantalla de detalle de un evento
/// Muestra toda la información del evento y acciones disponibles
class DetalleEventoScreen extends StatelessWidget {
  final String tituloEvento;
  final String fecha;
  final String hora;
  final String ubicacion;
  final String descripcion;
  final String cobroPorHora;
  final String rolAsignado;
  final String tiempoEstimado;

  const DetalleEventoScreen({
    super.key,
    this.tituloEvento = 'Festival de Música Summer Vibes',
    this.fecha = '28 Diciembre 2024',
    this.hora = '18:00 - 02:00',
    this.ubicacion = 'Recinto Ferial, Av. Principal 123, Madrid',
    this.descripcion = 'Concierto especial de Año Nuevo en la plaza principal de la ciudad. Se necesita personal para seguridad, atención al público y coordinación de emergencias.',
    this.cobroPorHora = '20€/hora',
    this.rolAsignado = 'Runner',
    this.tiempoEstimado = '5 horas',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.fondoPrincipal,
      appBar: AppBarCustom(
        showLogo: true,
        showBackButton: true,
        title: tituloEvento,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const SizedBox(height: 16),

            // Sección: Información del Evento
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Información del Evento',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),

            const SizedBox(height: 12),

            // Card con información
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.fondoCard,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildInfoRow(
                    context,
                    icono: Icons.calendar_today,
                    titulo: 'Fecha',
                    valor: fecha,
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    context,
                    icono: Icons.access_time,
                    titulo: 'Hora',
                    valor: hora,
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    context,
                    icono: Icons.location_on,
                    titulo: 'Ubicación',
                    valor: ubicacion,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Descripción
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Descripción',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppTheme.textoTerciario,
                ),
              ),
            ),

            const SizedBox(height: 8),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                descripcion,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.6,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Sección: Tu Asignación
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Tu Asignación',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),

            const SizedBox(height: 12),

            // Card asignación
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.fondoCard,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildInfoRow(
                    context,
                    icono: Icons.attach_money,
                    titulo: 'Cobro por Hora',
                    valor: cobroPorHora,
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    context,
                    icono: Icons.work_outline,
                    titulo: 'Rol Asignado',
                    valor: rolAsignado,
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    context,
                    icono: Icons.schedule,
                    titulo: 'Tiempo Estimado',
                    valor: tiempoEstimado,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Botones de acción
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // Botón CHAT
                  Expanded(
                    child: CustomOutlineButton(
                      text: 'CHAT',
                      icon: Icons.chat_bubble_outline,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatEventoScreen(
                              tituloEvento: tituloEvento,
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Botón CLOCK IT
                  Expanded(
                    child: PrimaryButton(
                      text: 'CLOCK IT',
                      icon: Icons.access_time,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FichajeScreen(
                              tituloEvento: tituloEvento,
                              fecha: fecha,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, {
    required IconData icono,
    required String titulo,
    required String valor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icono,
          color: AppTheme.verdeNeon,
          size: 24,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppTheme.textoTerciario,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                valor,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}