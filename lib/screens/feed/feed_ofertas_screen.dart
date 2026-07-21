import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hands4events/core/theme.dart';
import '../../core/roles.dart';
import '../../models/evento.dart';
import '../../models/postulacion.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notificaciones_provider.dart';
import '../../services/eventos_service.dart';
import '../../services/postulaciones_service.dart';
import '../../widgets/app_bar_custom.dart';
import '../../utils/top_snackbar.dart';
import '../notificaciones/notificaciones_screen.dart';
import 'mis_postulaciones_screen.dart';

// Feed de ofertas (tipo Tinder): el worker se postula (derecha) o rechaza (izquierda).
class FeedOfertasScreen extends StatefulWidget {
  const FeedOfertasScreen({super.key});

  @override
  State<FeedOfertasScreen> createState() => _FeedOfertasScreenState();
}

class _FeedOfertasScreenState extends State<FeedOfertasScreen> {
  final _eventosService = EventosService();

  List<Evento> _cartas = [];
  bool _cargando = true;
  // Rol elegido en confirmDismiss para usarlo en onDismissed (swipe derecha).
  String? _rolPendiente;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    final uid = context.read<AuthProvider>().currentUserId ?? '';

    // La campanita necesita el stream de notificaciones (el provider ignora
    // llamadas repetidas, así que es seguro pedirlo también desde aquí).
    if (uid.isNotEmpty) {
      context.read<NotificacionesProvider>().cargarNotificaciones(uid);
    }

    final eventos = await _eventosService.getEventosPublicados();
    final misPost = await PostulacionesService.misPostulaciones(uid);
    final respondidos = misPost.map((p) => p.eventoId).toSet();

    // Se muestran los publicados/futuros que el worker NO haya respondido ya
    // y en los que no sea ya confirmado. (Cruce en Dart, sin índices compuestos.)
    final cartas = eventos
        .where((e) =>
            !respondidos.contains(e.id) && !e.trabajadoresIds.contains(uid))
        .toList();

    if (!mounted) return;
    setState(() {
      _cartas = cartas;
      _cargando = false;
    });
  }

  // Plazas libres por rol = plazas objetivo - confirmados de ese rol (sin el admin).
  Map<String, int> _libresPorRol(Evento e) {
    final confirmadosPorRol = <String, int>{};
    e.trabajadoresRoles.forEach((uid, rol) {
      final info = e.trabajadoresInfo[uid];
      if (info != null && info['esAdmin'] == true) return; // el admin no cuenta
      confirmadosPorRol[rol] = (confirmadosPorRol[rol] ?? 0) + 1;
    });
    final libres = <String, int>{};
    e.plazasPorRol.forEach((rol, plaza) {
      final c = confirmadosPorRol[rol] ?? 0;
      libres[rol] = (plaza - c) < 0 ? 0 : (plaza - c);
    });
    return libres;
  }

  // Quita la carta de la pila y registra la respuesta del worker.
  Future<void> _responder(Evento e,
      {required String rol, required String estado}) async {
    setState(() => _cartas.removeWhere((c) => c.id == e.id));
    final uid = context.read<AuthProvider>().currentUserId ?? '';
    try {
      await PostulacionesService.responder(
        eventoId: e.id,
        trabajadorId: uid,
        rol: rol,
        estado: estado,
      );
      if (mounted && estado == Postulacion.pendiente) {
        showTopSnackBar(context, 'Te has postulado a "${e.titulo}"',
            backgroundColor: AppTheme.verdeNeon,
            icon: Icons.check_circle_outline);
      }
    } catch (_) {
      // Si falla, devolvemos la carta a la pila y avisamos.
      if (mounted) {
        setState(() => _cartas.insert(0, e));
        showTopSnackBar(context, 'No se pudo registrar. Inténtalo de nuevo.',
            backgroundColor: AppTheme.rojoError, icon: Icons.error_outline);
      }
    }
  }

  // Devuelve el rol elegido para postularse, o null si se cancela.
  Future<String?> _elegirRol(Evento e) async {
    final libres = _libresPorRol(e);
    final conHueco = libres.entries
        .where((x) => x.value > 0)
        .map((x) => x.key)
        .toList();
    // Si no queda hueco, se permite postularse igualmente entre los roles definidos.
    final opciones = conHueco.isNotEmpty
        ? conHueco
        : (e.plazasPorRol.isNotEmpty
            ? e.plazasPorRol.keys.toList()
            : RolesEvento.todos);

    if (opciones.length == 1) return opciones.first;

    return showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        backgroundColor: AppTheme.fondoCard,
        title: const Text('¿Para qué puesto?',
            style: TextStyle(color: AppTheme.textoBlanco, fontSize: 16)),
        children: opciones.map((rol) {
          final n = libres[rol] ?? 0;
          return SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, rol),
            child: Row(
              children: [
                Expanded(
                  child: Text(rol,
                      style: const TextStyle(
                          color: AppTheme.textoBlanco, fontSize: 14)),
                ),
                Text(
                  n > 0 ? '$n libre${n == 1 ? '' : 's'}' : 'sin hueco',
                  style: TextStyle(
                      color:
                          n > 0 ? AppTheme.verdeNeon : AppTheme.textoTerciario,
                      fontSize: 12),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // Botón "postularme": elige rol y responde.
  Future<void> _postularBoton(Evento e) async {
    final rol = await _elegirRol(e);
    if (rol == null) return;
    await _responder(e, rol: rol, estado: Postulacion.pendiente);
  }

  @override
  Widget build(BuildContext context) {
    final noLeidas = context.watch<NotificacionesProvider>().noLeidas;

    return Scaffold(
      backgroundColor: AppTheme.fondoPrincipal,
      appBar: AppBarCustom(
        showLogo: true,
        title: 'Ofertas',
        actions: [
          // Campanita con el nº de notificaciones sin leer
          IconButton(
            icon: Badge(
              isLabelVisible: noLeidas > 0,
              label: Text(noLeidas > 9 ? '9+' : '$noLeidas'),
              backgroundColor: AppTheme.rojoError,
              textStyle:
                  const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
              child: const Icon(Icons.notifications_none,
                  color: AppTheme.textoBlanco, size: 22),
            ),
            tooltip: 'Notificaciones',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificacionesScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.assignment_outlined,
                color: AppTheme.textoBlanco, size: 22),
            tooltip: 'Mis postulaciones',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const MisPostulacionesScreen()),
            ),
          ),
        ],
      ),
      body: _cargando
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.verdeNeon))
          : _cartas.isEmpty
              ? _buildVacio()
              : _buildPila(),
    );
  }

  Widget _buildVacio() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.done_all, color: AppTheme.textoSecundario, size: 52),
          const SizedBox(height: 16),
          const Text('No hay ofertas nuevas por ahora',
              style: TextStyle(color: AppTheme.textoSecundario)),
          const SizedBox(height: 6),
          const Text('Vuelve más tarde o actualiza',
              style: TextStyle(color: AppTheme.textoTerciario, fontSize: 12)),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: _cargar,
            icon: const Icon(Icons.refresh, color: AppTheme.verdeNeon),
            label: const Text('Actualizar',
                style: TextStyle(color: AppTheme.verdeNeon)),
          ),
        ],
      ),
    );
  }

  Widget _buildPila() {
    // La carta de arriba (índice 0) va la última en el Stack para pintarse encima.
    final visibles = math.min(3, _cartas.length);
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Stack(
              alignment: Alignment.center,
              children: [
                for (int i = visibles - 1; i >= 0; i--) _buildCarta(i),
              ],
            ),
          ),
        ),
        _buildBotones(),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildCarta(int i) {
    final e = _cartas[i];
    // Cartas de fondo: algo más pequeñas y desplazadas hacia arriba.
    if (i > 0) {
      return Transform.translate(
        offset: Offset(0, -12.0 * i),
        child: Transform.scale(
          scale: 1 - 0.04 * i,
          child: Opacity(opacity: 0.6, child: _contenidoCarta(e)),
        ),
      );
    }
    // Carta superior: deslizable.
    return Dismissible(
      key: ValueKey(e.id),
      direction: DismissDirection.horizontal,
      confirmDismiss: (dir) async {
        if (dir == DismissDirection.startToEnd) {
          // Derecha = postularse → elegir rol primero
          final rol = await _elegirRol(e);
          if (rol == null) return false;
          _rolPendiente = rol;
          return true;
        }
        return true; // izquierda = rechazar
      },
      onDismissed: (dir) {
        if (dir == DismissDirection.startToEnd) {
          _responder(e,
              rol: _rolPendiente ?? '', estado: Postulacion.pendiente);
          _rolPendiente = null;
        } else {
          _responder(e, rol: '', estado: Postulacion.rechazadoPorWorker);
        }
      },
      background: _overlaySwipe(
          Alignment.centerLeft, 'POSTULARME', AppTheme.verdeNeon, Icons.check),
      secondaryBackground: _overlaySwipe(
          Alignment.centerRight, 'RECHAZAR', AppTheme.rojoError, Icons.close),
      child: _contenidoCarta(e),
    );
  }

  Widget _overlaySwipe(
      Alignment align, String texto, Color color, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: 2),
      ),
      alignment: align,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 8),
          Text(texto,
              style: TextStyle(
                  color: color, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _contenidoCarta(Evento e) {
    final libres = _libresPorRol(e);
    final fecha =
        '${e.fechaInicio.day.toString().padLeft(2, '0')}/${e.fechaInicio.month.toString().padLeft(2, '0')}/${e.fechaInicio.year}';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.fondoCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.bordeCard),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(e.titulo,
                  style: Theme.of(context).textTheme.headlineSmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 16),
              _filaInfo(Icons.calendar_today_outlined,
                  '$fecha · ${e.horaFormateada}'),
              const SizedBox(height: 10),
              if (e.ubicacion.isNotEmpty) ...[
                _filaInfo(Icons.location_on_outlined, e.ubicacion),
                const SizedBox(height: 10),
              ],
              _filaInfo(Icons.timelapse_outlined, '${e.duracionHoras} h'),
              if (e.descripcion.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(e.descripcion,
                    style: const TextStyle(
                        color: AppTheme.textoSecundario, fontSize: 13,
                        height: 1.4)),
              ],
              const SizedBox(height: 20),
              const Text('PLAZAS LIBRES',
                  style: TextStyle(
                      color: AppTheme.textoTerciario,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: e.plazasPorRol.keys.map((rol) {
                  final n = libres[rol] ?? 0;
                  final tarifa = RolesEvento.tarifaDe(rol);
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.fondoInput,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: n > 0
                              ? AppTheme.verdeNeon.withValues(alpha: 0.4)
                              : AppTheme.bordeCard),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(rol,
                            style: const TextStyle(
                                color: AppTheme.textoBlanco, fontSize: 13)),
                        const SizedBox(height: 2),
                        Text(
                          '${n > 0 ? '$n libre${n == 1 ? '' : 's'}' : 'completo'} · ${tarifa.toStringAsFixed(1)} €/h',
                          style: TextStyle(
                              color: n > 0
                                  ? AppTheme.verdeNeon
                                  : AppTheme.textoTerciario,
                              fontSize: 11),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filaInfo(IconData icon, String texto) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.verdeNeon),
        const SizedBox(width: 8),
        Expanded(
          child: Text(texto,
              style: const TextStyle(
                  color: AppTheme.textoBlanco, fontSize: 14)),
        ),
      ],
    );
  }

  Widget _buildBotones() {
    if (_cartas.isEmpty) return const SizedBox.shrink();
    final top = _cartas.first;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Rechazar
        _botonRedondo(
          icon: Icons.close,
          color: AppTheme.rojoError,
          onTap: () =>
              _responder(top, rol: '', estado: Postulacion.rechazadoPorWorker),
        ),
        const SizedBox(width: 40),
        // Postularse
        _botonRedondo(
          icon: Icons.check,
          color: AppTheme.verdeNeon,
          onTap: () => _postularBoton(top),
        ),
      ],
    );
  }

  Widget _botonRedondo({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: AppTheme.fondoCard,
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 2),
        ),
        child: Icon(icon, color: color, size: 28),
      ),
    );
  }
}
