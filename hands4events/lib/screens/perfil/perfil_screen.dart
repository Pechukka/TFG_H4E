import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hands4events/core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_bar_custom.dart';
import '../../widgets/modals/modal_editar_telefono.dart';
import '../../widgets/modals/modal_editar_direccion.dart';
import '../../widgets/modals/modal_seleccionar_idioma.dart';
import '../../widgets/modals/modal_notificaciones.dart';
import '../nominas/nominas_screen.dart';

/// Pantalla de perfil del usuario
/// Muestra datos reales del usuario autenticado desde AuthProvider
class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

  void _mostrarModalTelefono(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ModalEditarTelefono(),
    );
  }

  void _mostrarModalDireccion(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ModalEditarDireccion(),
    );
  }

  void _mostrarModalIdioma(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ModalSeleccionarIdioma(),
    );
  }

  void _mostrarModalNotificaciones(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ModalNotificaciones(),
    );
  }

  void _navegarANominas(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NominasScreen(),
      ),
    );
  }

  void _mostrarDialogoCerrarSesion(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.fondoCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          '¿Cerrar sesión?',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        content: Text(
          'Se cerrará tu sesión y volverás a la pantalla de inicio.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textoSecundario,
              ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppTheme.textoSecundario),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // cerrar diálogo
              final authProvider =
                  Provider.of<AuthProvider>(context, listen: false);
              await authProvider.logout();
              // AuthWrapper detecta isAuthenticated=false y navega al Login
            },
            child: const Text(
              'Cerrar sesión',
              style: TextStyle(color: AppTheme.rojoSalir),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Escuchamos AuthProvider para mostrar datos reales
    final usuario = context.watch<AuthProvider>().currentUser;

    // Valores a mostrar (con fallback si aún no cargó)
    final iniciales = usuario?.iniciales ?? '??';
    final nombre = usuario?.nombre ?? 'Usuario';
    final email = usuario?.email ?? '';
    final telefono = usuario?.telefono ?? 'No configurado';
    final direccion = usuario?.direccion ?? 'No configurada';

    return Scaffold(
      appBar: const AppBarCustom(
        showLogo: true,
        showBackButton: false,
        title: 'Perfil',
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Avatar con iniciales reales
            Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppTheme.verdeNeon.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      iniciales,
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.verdeNeon,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  nombre,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textoSecundario,
                      ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Sección: Información Personal
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'INFORMACIÓN PERSONAL',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.textoTerciario,
                        letterSpacing: 1.2,
                      ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            _buildOpcionCard(
              context,
              icono: Icons.phone,
              titulo: 'Teléfono',
              valor: telefono,
              onTap: () => _mostrarModalTelefono(context),
            ),

            _buildOpcionCard(
              context,
              icono: Icons.location_on,
              titulo: 'Dirección',
              valor: direccion,
              onTap: () => _mostrarModalDireccion(context),
            ),

            const SizedBox(height: 24),

            // Sección: Configuración
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'CONFIGURACIÓN',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.textoTerciario,
                        letterSpacing: 1.2,
                      ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            _buildOpcionCard(
              context,
              icono: Icons.language,
              titulo: 'Idioma',
              valor: usuario?.idioma == 'es' ? 'Español' : (usuario?.idioma ?? 'Español'),
              onTap: () => _mostrarModalIdioma(context),
            ),

            _buildOpcionCard(
              context,
              icono: Icons.notifications,
              titulo: 'Notificaciones',
              valor: 'Gestionar preferencias',
              onTap: () => _mostrarModalNotificaciones(context),
            ),

            const SizedBox(height: 24),

            // Sección: Otros
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'OTROS',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.textoTerciario,
                        letterSpacing: 1.2,
                      ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            _buildOpcionCard(
              context,
              icono: Icons.description,
              titulo: 'Nóminas y vacaciones',
              valor: 'Ver nóminas y solicitar vacaciones',
              onTap: () => _navegarANominas(context),
            ),

            const SizedBox(height: 32),

            // Botón cerrar sesión
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: () => _mostrarDialogoCerrarSesion(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.rojoSalir,
                    side: const BorderSide(
                      color: AppTheme.rojoSalir,
                      width: 2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.logout),
                  label: const Text(
                    'Cerrar sesión',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
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

  Widget _buildOpcionCard(
    BuildContext context, {
    required IconData icono,
    required String titulo,
    required String valor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
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
              child: Icon(
                icono,
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
                  const SizedBox(height: 2),
                  Text(
                    valor,
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
