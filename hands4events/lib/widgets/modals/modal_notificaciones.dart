import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'modal_base.dart';

/// Modal para gestionar configuración de notificaciones
class ModalNotificaciones extends StatefulWidget {
  const ModalNotificaciones({super.key});

  @override
  State<ModalNotificaciones> createState() => _ModalNotificacionesState();
}

class _ModalNotificacionesState extends State<ModalNotificaciones> {
  String _estadoNotificaciones = 'activadas'; // 'activadas', 'desactivadas', 'silenciadas'
  String _tiempoSilencio = '1'; // '1', '8', '24', 'manana'

  @override
  Widget build(BuildContext context) {
    return ModalBase(
      titulo: 'Notificaciones',
      contenido: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Opción: Activadas
          _buildOpcionNotificacion(
            icono: Icons.notifications_active,
            titulo: 'Activadas',
            descripcion: 'Recibirás todas las notificaciones',
            valor: 'activadas',
          ),

          const SizedBox(height: 12),

          // Opción: Desactivadas
          _buildOpcionNotificacion(
            icono: Icons.notifications_off,
            titulo: 'Desactivadas',
            descripcion: 'No recibirás notificaciones',
            valor: 'desactivadas',
          ),

          const SizedBox(height: 12),

          // Opción: Silenciar notificaciones
          _buildOpcionNotificacion(
            icono: Icons.access_time,
            titulo: 'Silenciar notificaciones',
            descripcion: 'Silenciar temporalmente',
            valor: 'silenciadas',
          ),

          // Selector de tiempo (solo si está silenciado)
          if (_estadoNotificaciones == 'silenciadas') ...[
            const SizedBox(height: 16),
            Text(
              'Silenciar por:',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppTheme.textoSecundario,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTiempoButton('1 hora', '1'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTiempoButton('8 horas', '8'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildTiempoButton('24 horas', '24'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTiempoButton('Hasta mañana', 'manana'),
                ),
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
            onPressed: () {
              Navigator.pop(context);
              String mensaje = '';
              if (_estadoNotificaciones == 'activadas') {
                mensaje = 'Notificaciones activadas';
              } else if (_estadoNotificaciones == 'desactivadas') {
                mensaje = 'Notificaciones desactivadas';
              } else {
                final tiempos = {
                  '1': '1 hora',
                  '8': '8 horas',
                  '24': '24 horas',
                  'manana': 'hasta mañana',
                };
                mensaje = 'Notificaciones silenciadas ${tiempos[_tiempoSilencio]}';
              }
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(mensaje),
                  backgroundColor: AppTheme.verdeExito,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.verdeNeon,
              foregroundColor: AppTheme.textoSobreVerde,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Guardar',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOpcionNotificacion({
    required IconData icono,
    required String titulo,
    required String descripcion,
    required String valor,
  }) {
    final estaSeleccionado = _estadoNotificaciones == valor;

    return InkWell(
      onTap: () {
        setState(() {
          _estadoNotificaciones = valor;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: estaSeleccionado
              ? AppTheme.verdeNeon.withOpacity(0.1)
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
                    ? AppTheme.verdeNeon.withOpacity(0.2)
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
              const Icon(
                Icons.check_circle,
                color: AppTheme.verdeNeon,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTiempoButton(String texto, String valor) {
    final estaSeleccionado = _tiempoSilencio == valor;

    return InkWell(
      onTap: () {
        setState(() {
          _tiempoSilencio = valor;
        });
      },
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