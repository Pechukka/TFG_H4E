import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_bar_custom.dart';

/// Pantalla Perfil
/// Muestra información del usuario y opciones de configuración
class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppBarCustom(
        showLogo: true,
        showBackButton: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header "Perfil"
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              color: AppTheme.fondoPrincipal,
              child: Center(
                child: Text(
                  'Perfil',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Avatar
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.verdeNeon,
                  width: 3,
                ),
              ),
              child: const Icon(
                Icons.person,
                size: 50,
                color: AppTheme.verdeNeon,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Nombre
            Text(
              'Ricardo Gómez',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            
            const SizedBox(height: 4),
            
            // Rol
            Text(
              'Conductor',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.verdeNeon,
              ),
            ),
            
            const SizedBox(height: 4),
            
            // ID
            Text(
              'ID: 12345',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textoTerciario,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Sección Información personal
            _buildSeccionHeader(context, 'Información personal'),
            
            _buildOpcionPerfil(
              context,
              icono: Icons.phone,
              titulo: 'Teléfono',
              valor: '+34 666 777 888',
            ),
            
            _buildOpcionPerfil(
              context,
              icono: Icons.location_on,
              titulo: 'Dirección',
              valor: 'Calle Principal, 123, Madrid',
            ),
            
            const SizedBox(height: 24),
            
            // Sección Ajustes de la aplicación
            _buildSeccionHeader(context, 'Ajustes de la aplicación'),
            
            _buildOpcionPerfil(
              context,
              icono: Icons.language,
              titulo: 'Idioma',
              valor: 'Español',
            ),
            
            _buildOpcionPerfil(
              context,
              icono: Icons.notifications,
              titulo: 'Notificaciones',
              valor: 'Activadas',
            ),
            
            _buildOpcionPerfil(
              context,
              icono: Icons.description,
              titulo: 'Nóminas y vacaciones',
              valor: 'Consulta tus nóminas y días libres',
            ),
            
            const SizedBox(height: 24),
            
            // Sección Disponibilidad laboral
            _buildSeccionHeader(context, 'Disponibilidad laboral'),
            
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.fondoCard,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: AppTheme.verdeExito,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Disponible',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: AppTheme.verdeNeon,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Este estado se calcula automáticamente según tu calendario y tus vacaciones aprobadas.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textoSecundario,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Botón Cerrar sesión
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: () {
                    // TODO: Implementar logout
                    print('Cerrar sesión');
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.rojoSalir,
                    side: const BorderSide(color: AppTheme.rojoSalir, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.logout, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Cerrar sesión',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.rojoSalir,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSeccionHeader(BuildContext context, String titulo) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          titulo,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }

  Widget _buildOpcionPerfil(BuildContext context, {
    required IconData icono,
    required String titulo,
    required String valor,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: AppTheme.fondoCard,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () {
            print('Tap en $titulo');
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
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
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: AppTheme.textoTerciario,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        valor,
                        style: Theme.of(context).textTheme.bodyMedium,
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
        ),
      ),
    );
  }
}