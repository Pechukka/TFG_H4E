import 'package:flutter/material.dart';
import 'package:hands4events/core/theme.dart';
import '../../widgets/app_bar_custom.dart';

/// Pantalla del equipo del evento
/// Muestra todos los miembros asignados con sus roles y contactos
class EquipoEventoScreen extends StatelessWidget {
  final String tituloEvento;

  const EquipoEventoScreen({
    super.key,
    required this.tituloEvento,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.fondoPrincipal,
      appBar: AppBarCustom(
        showLogo: true,
        showBackButton: true,
        title: 'Equipo del Evento',
        subtitle: tituloEvento,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),

          // Contador de miembros
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '5 miembros en el equipo',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppTheme.textoTerciario,
                    ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Lista de miembros
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildMiembroCard(
                  context,
                  nombre: 'Carlos Martínez',
                  rol: 'Coordinador',
                  telefono: '+34 612 345 678',
                  avatar: 'CM',
                ),
                const SizedBox(height: 12),
                _buildMiembroCard(
                  context,
                  nombre: 'Ana López',
                  rol: 'Coordinador',
                  telefono: '+34 623 456 789',
                  avatar: 'AL',
                ),
                const SizedBox(height: 12),
                _buildMiembroCard(
                  context,
                  nombre: 'Miguel Torres',
                  rol: 'Hands (Montador/Desmontador)',
                  telefono: '+34 634 567 890',
                  avatar: 'MT',
                ),
                const SizedBox(height: 12),
                _buildMiembroCard(
                  context,
                  nombre: 'Laura García',
                  rol: 'Runner',
                  telefono: '+34 645 678 901',
                  avatar: 'LG',
                ),
                const SizedBox(height: 12),
                _buildMiembroCard(
                  context,
                  nombre: 'David Ruiz',
                  rol: 'Hands (Montador/Desmontador)',
                  telefono: '+34 656 789 012',
                  avatar: 'DR',
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiembroCard(
    BuildContext context, {
    required String nombre,
    required String rol,
    required String telefono,
    required String avatar,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.fondoCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppTheme.verdeNeon.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                avatar,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppTheme.verdeNeon,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Info del miembro
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombre,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  rol,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.verdeNeon,
                      ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.phone,
                      size: 14,
                      color: AppTheme.textoTerciario,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      telefono,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textoSecundario,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Botón llamar
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: AppTheme.verdeNeon,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(
                Icons.phone,
                color: AppTheme.textoSobreVerde,
                size: 24,
              ),
              onPressed: () {
                print('Llamar a $nombre');
                // TODO: Implementar llamada
              },
            ),
          ),
        ],
      ),
    );
  }
}
