import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hands4events/core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/idioma_provider.dart';
import 'modal_base.dart';

class ModalNotificaciones extends StatefulWidget {
  const ModalNotificaciones({super.key});

  @override
  State<ModalNotificaciones> createState() => _ModalNotificacionesState();
}

class _ModalNotificacionesState extends State<ModalNotificaciones> {
  String _estadoNotificaciones = 'activadas';
  String _tiempoSilencio = '1';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final mutadaHasta = authProvider.currentUser?.notifMutadaHasta;

    if (mutadaHasta == null) {
      _estadoNotificaciones = 'activadas';
    } else if (mutadaHasta.year >= 2100) {
      _estadoNotificaciones = 'desactivadas';
    } else if (mutadaHasta.isAfter(DateTime.now())) {
      _estadoNotificaciones = 'silenciadas';
    } else {
      _estadoNotificaciones = 'activadas';
    }
  }

  Future<void> _guardar(IdiomaProvider t) async {
    setState(() => _isLoading = true);

    DateTime? mutadaHasta;
    String mensaje = '';

    if (_estadoNotificaciones == 'activadas') {
      mutadaHasta = null;
      mensaje = t.tr('notif_msg_activadas');
    } else if (_estadoNotificaciones == 'desactivadas') {
      mutadaHasta = DateTime(2100, 1, 1);
      mensaje = t.tr('notif_msg_desactivadas');
    } else {
      final ahora = DateTime.now();
      final etiqueta = {
        '1': t.tr('1h'),
        '8': t.tr('8h'),
        '24': t.tr('24h'),
        'manana': t.tr('hasta_manana'),
      }[_tiempoSilencio] ?? '';
      switch (_tiempoSilencio) {
        case '1':
          mutadaHasta = ahora.add(const Duration(hours: 1));
          break;
        case '8':
          mutadaHasta = ahora.add(const Duration(hours: 8));
          break;
        case '24':
          mutadaHasta = ahora.add(const Duration(hours: 24));
          break;
        case 'manana':
          mutadaHasta = DateTime(ahora.year, ahora.month, ahora.day + 1);
          break;
      }
      mensaje = '${t.tr('notif_msg_silenciadas')} $etiqueta';
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final exito = await authProvider.actualizarNotificacionesMute(mutadaHasta);

    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(exito ? mensaje : t.tr('error_guardar_config')),
          backgroundColor: exito ? AppTheme.verdeExito : AppTheme.rojoError,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<IdiomaProvider>();

    return ModalBase(
      titulo: t.tr('notificaciones'),
      contenido: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOpcionNotificacion(
            context: context,
            icono: Icons.notifications_active,
            titulo: t.tr('notif_activadas'),
            descripcion: t.tr('notif_activadas_desc'),
            valor: 'activadas',
          ),
          const SizedBox(height: 12),
          _buildOpcionNotificacion(
            context: context,
            icono: Icons.notifications_off,
            titulo: t.tr('notif_desactivadas'),
            descripcion: t.tr('notif_desactivadas_desc'),
            valor: 'desactivadas',
          ),
          const SizedBox(height: 12),
          _buildOpcionNotificacion(
            context: context,
            icono: Icons.access_time,
            titulo: t.tr('notif_silenciar'),
            descripcion: t.tr('notif_silenciar_desc'),
            valor: 'silenciadas',
          ),
          if (_estadoNotificaciones == 'silenciadas') ...[
            const SizedBox(height: 16),
            Text(
              t.tr('notif_silenciar_por'),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppTheme.textoSecundario,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildTiempoButton(t.tr('1h'), '1')),
                const SizedBox(width: 8),
                Expanded(child: _buildTiempoButton(t.tr('8h'), '8')),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildTiempoButton(t.tr('24h'), '24')),
                const SizedBox(width: 8),
                Expanded(child: _buildTiempoButton(t.tr('hasta_manana'), 'manana')),
              ],
            ),
          ],
        ],
      ),
      botonesAccion: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : () => _guardar(t),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.verdeNeon,
              foregroundColor: AppTheme.textoSobreVerde,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.textoSobreVerde),
                  )
                : Text(
                    t.tr('guardar'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildOpcionNotificacion({
    required BuildContext context,
    required IconData icono,
    required String titulo,
    required String descripcion,
    required String valor,
  }) {
    final estaSeleccionado = _estadoNotificaciones == valor;

    return InkWell(
      onTap: () => setState(() => _estadoNotificaciones = valor),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: estaSeleccionado
              ? AppTheme.verdeNeon.withValues(alpha: 0.1)
              : AppTheme.fondoInput,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: estaSeleccionado ? AppTheme.verdeNeon : AppTheme.bordeCampo,
            width: estaSeleccionado ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: estaSeleccionado
                    ? AppTheme.verdeNeon.withValues(alpha: 0.2)
                    : AppTheme.fondoCard,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icono,
                color: estaSeleccionado ? AppTheme.verdeNeon : AppTheme.textoSecundario,
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
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: estaSeleccionado ? AppTheme.verdeNeon : AppTheme.textoBlanco,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    descripcion,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textoSecundario,
                        ),
                  ),
                ],
              ),
            ),
            if (estaSeleccionado)
              const Icon(Icons.check_circle, color: AppTheme.verdeNeon, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTiempoButton(String texto, String valor) {
    final estaSeleccionado = _tiempoSilencio == valor;

    return InkWell(
      onTap: () => setState(() => _tiempoSilencio = valor),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: estaSeleccionado ? AppTheme.verdeNeon : AppTheme.fondoCard,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            texto,
            style: TextStyle(
              color: estaSeleccionado ? AppTheme.textoSobreVerde : AppTheme.textoBlanco,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}
