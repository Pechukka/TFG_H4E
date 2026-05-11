import 'package:flutter/material.dart';
import 'package:hands4events/core/theme.dart';
import 'package:hands4events/models/evento.dart';
import 'package:hands4events/screens/chat/chat_evento_screen.dart';
import 'package:hands4events/screens/fichaje/fichaje_screen.dart';
import '../../widgets/app_bar_custom.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/outline_button.dart';

/// Pantalla de detalle de un evento
/// Recibe el objeto Evento completo desde EventosScreen
class DetalleEventoScreen extends StatelessWidget {
  final Evento evento;

  const DetalleEventoScreen({super.key, required this.evento});

  String get _fecha {
    const meses = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    final f = evento.fechaInicio;
    return '${f.day} de ${meses[f.month - 1]} de ${f.year}';
  }

  String get _hora {
    String fmt(DateTime dt) =>
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '${fmt(evento.fechaInicio)} - ${fmt(evento.fechaFin)}';
  }

  String get _tiempoEstimado {
    final horas = evento.duracionHoras;
    return horas == 1 ? '1 hora' : '$horas horas';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.fondoPrincipal,
      appBar: AppBarCustom(
        showLogo: true,
        showBackButton: true,
        title: evento.titulo,
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
                  _buildInfoRow(context,
                    icono: Icons.calendar_today,
                    titulo: 'Fecha',
                    valor: _fecha,
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(context,
                    icono: Icons.access_time,
                    titulo: 'Hora',
                    valor: _hora,
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(context,
                    icono: Icons.location_on,
                    titulo: 'Ubicación',
                    valor: evento.ubicacion,
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
                evento.descripcion.isNotEmpty
                    ? evento.descripcion
                    : 'Sin descripción disponible.',
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
                  _buildInfoRow(context,
                    icono: Icons.attach_money,
                    titulo: 'Cobro por Hora',
                    valor: '${evento.cobroPorHora.toStringAsFixed(0)}€/hora',
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(context,
                    icono: Icons.work_outline,
                    titulo: 'Rol Asignado',
                    valor: evento.rolAsignado.isNotEmpty
                        ? evento.rolAsignado
                        : 'Sin especificar',
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(context,
                    icono: Icons.schedule,
                    titulo: 'Tiempo Estimado',
                    valor: _tiempoEstimado,
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
                              tituloEvento: evento.titulo,
                              eventoId: evento.id,
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
                              tituloEvento: evento.titulo,
                              fecha: _fecha,
                              eventoId: evento.id,
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
        Icon(icono, color: AppTheme.verdeNeon, size: 24),
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
              Text(valor, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}