import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hands4events/core/theme.dart';
import '../../providers/eventos_provider.dart';
import '../../providers/idioma_provider.dart';
import '../../widgets/app_bar_custom.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/top_snackbar.dart';

class EquipoEventoScreen extends StatefulWidget {
  final String tituloEvento;
  final String eventoId;

  const EquipoEventoScreen({
    super.key,
    required this.tituloEvento,
    this.eventoId = '',
  });

  @override
  State<EquipoEventoScreen> createState() => _EquipoEventoScreenState();
}

class _EquipoEventoScreenState extends State<EquipoEventoScreen> {
  List<Map<String, dynamic>> _equipo = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarEquipo();
  }

  Future<void> _cargarEquipo() async {
    if (widget.eventoId.isEmpty) {
      setState(() => _cargando = false);
      return;
    }

    final equipo = await context.read<EventosProvider>().getEquipoEvento(widget.eventoId);

    if (mounted) {
      setState(() {
        _equipo = equipo;
        _cargando = false;
      });
    }
  }

  String _iniciales(String nombre) {
    final partes = nombre.trim().split(' ');
    if (partes.length >= 2) {
      return '${partes[0][0]}${partes[1][0]}'.toUpperCase();
    }
    return nombre.isNotEmpty ? nombre[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<IdiomaProvider>();
    final n = _equipo.length;
    final s = t.idioma == 'en' ? (n != 1 ? 's' : '') : (n != 1 ? 's' : '');
    final sinRol = t.tr('sin_rol');
    final sinTelefono = t.tr('sin_telefono');

    return Scaffold(
      backgroundColor: AppTheme.fondoPrincipal,
      appBar: AppBarCustom(
        showLogo: true,
        showBackButton: true,
        title: t.tr('equipo_evento_titulo'),
        subtitle: widget.tituloEvento,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          if (_cargando)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(color: AppTheme.verdeNeon),
              ),
            )
          else ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  t.idioma == 'en'
                      ? '$n member$s in the team'
                      : '$n miembro$s en el equipo',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppTheme.textoTerciario,
                      ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _equipo.isEmpty
                  ? Center(
                      child: Text(
                        t.tr('sin_equipo'),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textoSecundario,
                            ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _equipo.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final miembro = _equipo[index];
                        final nombre = miembro['nombre'] as String? ?? '';
                        final rol = miembro['rol'] as String? ?? '';
                        final telefono = miembro['telefono'] as String? ?? '';
                        return _buildMiembroCard(
                          context,
                          t: t,
                          nombre: nombre,
                          rol: rol.isNotEmpty ? rol : sinRol,
                          telefono: telefono.isNotEmpty ? telefono : sinTelefono,
                          avatar: _iniciales(nombre),
                          sinTelefono: sinTelefono,
                        );
                      },
                    ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMiembroCard(
    BuildContext context, {
    required IdiomaProvider t,
    required String nombre,
    required String rol,
    required String telefono,
    required String avatar,
    required String sinTelefono,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.fondoCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppTheme.verdeNeon.withValues(alpha: 0.2),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nombre, style: Theme.of(context).textTheme.titleSmall),
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
                    const Icon(Icons.phone, size: 14, color: AppTheme.textoTerciario),
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
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: AppTheme.verdeNeon,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.phone, color: AppTheme.textoSobreVerde, size: 24),
              onPressed: telefono != sinTelefono
                  ? () async {
                      final uri = Uri.parse('tel:$telefono');
                      try {
                        await launchUrl(uri);
                      } catch (_) {
                        if (context.mounted) {
                          showTopSnackBar(context, t.tr('error_llamada'),
                              backgroundColor: AppTheme.rojoError,
                              icon: Icons.error_outline);
                        }
                      }
                    }
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
