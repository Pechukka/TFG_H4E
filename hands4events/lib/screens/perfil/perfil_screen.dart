import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hands4events/core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/idioma_provider.dart';
import '../../widgets/app_bar_custom.dart';
import '../../widgets/modals/modal_editar_telefono.dart';
import '../../widgets/modals/modal_editar_direccion.dart';
import '../../widgets/modals/modal_seleccionar_idioma.dart';
import '../../widgets/modals/modal_notificaciones.dart';
import '../nominas/nominas_screen.dart';

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

  void _mostrarDialogoCerrarSesion(BuildContext context, IdiomaProvider t) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.fondoCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          t.tr('cerrar_sesion_confirm'),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        content: Text(
          t.tr('cerrar_sesion_msg'),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textoSecundario,
              ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              t.tr('cancelar'),
              style: const TextStyle(color: AppTheme.textoSecundario),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final authProvider =
                  Provider.of<AuthProvider>(context, listen: false);
              await authProvider.logout();
            },
            child: Text(
              t.tr('cerrar_sesion'),
              style: const TextStyle(color: AppTheme.rojoSalir),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<IdiomaProvider>();
    final usuario = context.watch<AuthProvider>().currentUser;

    final iniciales = usuario?.iniciales ?? '??';
    final nombre = usuario?.nombre ?? 'Usuario';
    final email = usuario?.email ?? '';
    final telefono = usuario?.telefono ?? t.tr('no_configurado');
    final direccion = usuario?.direccion ?? t.tr('no_configurada');
    final idiomaNombre = usuario?.idioma == 'en' ? 'English' : 'Español';

    return Scaffold(
      appBar: AppBarCustom(
        showLogo: true,
        showBackButton: false,
        title: t.tr('perfil'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Avatar con iniciales
            Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: const BoxDecoration(shape: BoxShape.circle),
                  child: ClipOval(child: _buildIniciales(iniciales)),
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
                  t.tr('informacion_personal'),
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
              titulo: t.tr('telefono'),
              valor: telefono,
              onTap: () => _mostrarModalTelefono(context),
            ),

            _buildOpcionCard(
              context,
              icono: Icons.location_on,
              titulo: t.tr('direccion'),
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
                  t.tr('configuracion'),
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
              titulo: t.tr('idioma'),
              valor: idiomaNombre,
              onTap: () => _mostrarModalIdioma(context),
            ),

            _buildOpcionCard(
              context,
              icono: Icons.notifications,
              titulo: t.tr('notificaciones_config'),
              valor: t.tr('gestionar_preferencias'),
              onTap: () => _mostrarModalNotificaciones(context),
            ),

            const SizedBox(height: 24),

            // Sección: Otros
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  t.tr('otros'),
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
              titulo: t.tr('seccion_nominas'),
              valor: t.tr('ver_mis_nominas'),
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
                  onPressed: () => _mostrarDialogoCerrarSesion(context, t),
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
                  label: Text(
                    t.tr('cerrar_sesion'),
                    style: const TextStyle(
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

  Widget _buildIniciales(String iniciales) {
    return Container(
      color: AppTheme.verdeNeon.withValues(alpha: 0.2),
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
                color: AppTheme.verdeNeon.withValues(alpha: 0.1),
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
