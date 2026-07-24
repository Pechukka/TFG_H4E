import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hands4events/core/theme.dart';
import 'package:hands4events/core/roles.dart';
import 'package:hands4events/models/evento.dart';
import 'package:hands4events/screens/chat/chat_evento_screen.dart';
import 'package:hands4events/screens/fichaje/fichaje_screen.dart';
import '../../providers/auth_provider.dart';
import '../../providers/idioma_provider.dart';
import '../../widgets/app_bar_custom.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/outline_button.dart';
import '../../utils/top_snackbar.dart';

class DetalleEventoScreen extends StatelessWidget {
  final Evento evento;

  const DetalleEventoScreen({super.key, required this.evento});

  String _getFecha(String idioma) {
    const mesesEs = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
    ];
    const mesesEn = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    final meses = idioma == 'en' ? mesesEn : mesesEs;
    final f = evento.fechaInicio;
    return idioma == 'en'
        ? '${meses[f.month - 1]} ${f.day}, ${f.year}'
        : '${f.day} de ${meses[f.month - 1]} de ${f.year}';
  }

  String _getHora() {
    String fmt(DateTime dt) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return '${fmt(evento.fechaInicio)} - ${fmt(evento.fechaFin)}';
  }

  String _getTiempoEstimado(IdiomaProvider t) {
    final horas = evento.duracionHoras;
    final unidad = horas == 1 ? t.tr('hora_unidad') : t.tr('horas_unidad');
    return '$horas $unidad';
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<IdiomaProvider>();
    final fecha = _getFecha(t.idioma);

    // Calculamos el rol y tarifa reales del trabajador actual
    final uid = context.read<AuthProvider>().currentUserId ?? '';
    final rolReal = evento.trabajadoresRoles[uid] ?? evento.rolAsignado;
    final tarifaReal = RolesEvento.tarifaDe(rolReal);

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

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                t.tr('info_evento'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),

            const SizedBox(height: 12),

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
                    titulo: t.tr('fecha_label'),
                    valor: fecha,
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(context,
                    icono: Icons.access_time,
                    titulo: t.tr('hora_label'),
                    valor: _getHora(),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(context,
                    icono: Icons.location_on,
                    titulo: t.tr('ubicacion_label'),
                    valor: evento.ubicacion,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                t.tr('descripcion_label'),
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
                    : t.tr('sin_descripcion'),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.6,
                ),
              ),
            ),

            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                t.tr('tu_asignacion'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),

            const SizedBox(height: 12),

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
                    titulo: t.tr('cobro_hora'),
                    valor: tarifaReal > 0
                        ? '${tarifaReal.toStringAsFixed(1)}€/h'
                        : t.tr('sin_especificar'),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(context,
                    icono: Icons.work_outline,
                    titulo: t.tr('rol_asignado'),
                    valor: rolReal.isNotEmpty
                        ? rolReal
                        : t.tr('sin_especificar'),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(context,
                    icono: Icons.schedule,
                    titulo: t.tr('tiempo_estimado_label'),
                    valor: _getTiempoEstimado(t),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    // Chat según el estado del evento:
                    //  activo      → abierto y escribible
                    //  finalizado  → abierto en solo lectura (histórico)
                    //  resto       → cerrado, con aviso "grupo no creado"
                    child: evento.estado == 'activo'
                        ? CustomOutlineButton(
                            text: t.tr('ir_chat'),
                            icon: Icons.chat_bubble_outline,
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatEventoScreen(
                                  tituloEvento: evento.titulo,
                                  eventoId: evento.id,
                                ),
                              ),
                            ),
                          )
                        : evento.estado == 'finalizado'
                            ? CustomOutlineButton(
                                text: t.tr('ver_historico'),
                                icon: Icons.history,
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChatEventoScreen(
                                      tituloEvento: evento.titulo,
                                      eventoId: evento.id,
                                      soloLectura: true,
                                    ),
                                  ),
                                ),
                              )
                            : CustomOutlineButton(
                                text: t.tr('grupo_no_creado'),
                                icon: Icons.lock_outline,
                                borderColor: AppTheme.textoTerciario,
                                textColor: AppTheme.textoTerciario,
                                onPressed: () => showTopSnackBar(
                                  context,
                                  t.tr('grupo_aviso'),
                                  backgroundColor: AppTheme.amarilloAdvertencia,
                                  icon: Icons.info_outline,
                                ),
                              ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: PrimaryButton(
                      text: t.tr('fichaje'),
                      icon: Icons.access_time,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FichajeScreen(
                              tituloEvento: evento.titulo,
                              fecha: fecha,
                              eventoId: evento.id,
                              fechaInicio: evento.fechaInicio,
                              fechaFin: evento.fechaFin,
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
