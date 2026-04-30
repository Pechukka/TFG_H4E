import 'package:flutter/material.dart';
import 'package:hands4events/core/theme.dart';
import '../../widgets/app_bar_custom.dart';
import 'detalle_evento_screen.dart';

/// Pantalla Eventos
/// Lista todos los eventos asignados al trabajador
class EventosScreen extends StatelessWidget {
  const EventosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppBarCustom(
        showLogo: true,
        showBackButton: false,
        title: 'Eventos',
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),

          // Lista de eventos
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildEventoCard(
                  context,
                  titulo: 'Festival de Música Summer Vibes',
                  fecha: '28 Dic, 18:00 – 02:00',
                  ubicacion: 'Recinto Ferial',
                ),
                const SizedBox(height: 12),
                _buildEventoCard(
                  context,
                  titulo: 'Conferencia Tech Innovation',
                  fecha: '30 Dic, 09:00 – 18:00',
                  ubicacion: 'Centro de Convenciones',
                ),
                const SizedBox(height: 12),
                _buildEventoCard(
                  context,
                  titulo: 'Concierto Año Nuevo',
                  fecha: '31 Dic, 22:00 – 03:00',
                  ubicacion: 'Plaza Mayor',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventoCard(
    BuildContext context, {
    required String titulo,
    required String fecha,
    required String ubicacion,
  }) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetalleEventoScreen(
              tituloEvento: titulo,
              fecha: fecha.split(',')[0], // Solo la fecha sin hora
              ubicacion: ubicacion,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.fondoCard,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    fecha,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.verdeNeon,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ubicacion,
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
