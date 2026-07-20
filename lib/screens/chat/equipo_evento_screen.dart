import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hands4events/core/theme.dart';
import '../../providers/eventos_provider.dart';
import '../../providers/idioma_provider.dart';
import '../../widgets/app_bar_custom.dart';

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
  // true si la carga falló (p.ej. permisos): mostramos aviso, no lista vacía.
  bool _errorCarga = false;

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
        // null = no se pudo cargar; lista (aunque vacía) = carga correcta.
        _errorCarga = equipo == null;
        _equipo = equipo ?? [];
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
          else if (_errorCarga)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    t.tr('equipo_no_cargado'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textoSecundario,
                        ),
                  ),
                ),
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
                        final esAdmin = miembro['esAdmin'] == true;
                        return _buildMiembroCard(
                          context,
                          nombre: nombre,
                          rol: esAdmin ? 'Admin' : (rol.isNotEmpty ? rol : sinRol),
                          avatar: _iniciales(nombre),
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
    required String nombre,
    required String rol,
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
