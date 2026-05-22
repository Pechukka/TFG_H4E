import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hands4events/core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/idioma_provider.dart';
import 'modal_base.dart';
import '../../utils/top_snackbar.dart';

class ModalNotificaciones extends StatefulWidget {
  const ModalNotificaciones({super.key});

  @override
  State<ModalNotificaciones> createState() => _ModalNotificacionesState();
}

class _ModalNotificacionesState extends State<ModalNotificaciones> {
  bool _activadas = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    _activadas = !auth.notifDesactivadas;
  }

  Future<void> _guardar(IdiomaProvider t) async {
    setState(() => _isLoading = true);

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final exito = await auth.actualizarNotificaciones(_activadas);

    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.pop(context);
      showTopSnackBar(
        context,
        exito
            ? (_activadas ? t.tr('notif_msg_activadas') : t.tr('notif_msg_desactivadas'))
            : t.tr('error_guardar_config'),
        backgroundColor: exito ? AppTheme.verdeExito : AppTheme.rojoError,
        icon: exito ? Icons.notifications_outlined : Icons.error_outline,
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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.fondoInput,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _activadas ? AppTheme.verdeNeon : AppTheme.bordeCampo,
                width: _activadas ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _activadas
                        ? AppTheme.verdeNeon.withValues(alpha: 0.2)
                        : AppTheme.fondoCard,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _activadas ? Icons.notifications_active : Icons.notifications_off,
                    color: _activadas ? AppTheme.verdeNeon : AppTheme.textoSecundario,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _activadas ? t.tr('notif_activadas') : t.tr('notif_desactivadas'),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: _activadas ? AppTheme.verdeNeon : AppTheme.textoBlanco,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _activadas
                            ? t.tr('notif_activadas_desc')
                            : t.tr('notif_desactivadas_desc'),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textoSecundario,
                            ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _activadas,
                  onChanged: (v) => setState(() => _activadas = v),
                  activeThumbColor: AppTheme.verdeNeon,
                  activeTrackColor: AppTheme.verdeNeon.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
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
}
