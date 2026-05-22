import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hands4events/core/theme.dart';
import '../../../services/admin_service.dart';

// Pantalla que muestra los fichajes de todos los trabajadores en un evento.
// El admin ve: hora de entrada, hora de salida, ubicación GPS de cada uno.
class AdminFichajesEventoScreen extends StatefulWidget {
  final String eventoId;
  final String tituloEvento;
  // UIDs de los trabajadores asignados al evento
  final List<String> trabajadoresIds;

  const AdminFichajesEventoScreen({
    super.key,
    required this.eventoId,
    required this.tituloEvento,
    required this.trabajadoresIds,
  });

  @override
  State<AdminFichajesEventoScreen> createState() =>
      _AdminFichajesEventoScreenState();
}

class _AdminFichajesEventoScreenState
    extends State<AdminFichajesEventoScreen> {
  List<Map<String, dynamic>> _fichajes = [];
  // Mapa {uid: nombre} que cargamos desde Firestore
  Map<String, String> _nombresWorkers = {};
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarTodo();
  }

  Future<void> _cargarTodo() async {
    // Cargamos fichajes y nombres de trabajadores en paralelo
    final futures = await Future.wait([
      AdminService.getFichajesDeEvento(widget.eventoId),
      _cargarNombres(),
    ]);

    final fichajes = futures[0] as List<Map<String, dynamic>>;
    fichajes.sort((a, b) {
      final tA = a['entrada'];
      final tB = b['entrada'];
      if (tA == null) return 1;
      if (tB == null) return -1;
      return 0;
    });

    if (!mounted) return;
    setState(() {
      _fichajes = fichajes;
      _cargando = false;
    });
  }

  Future<Map<String, String>> _cargarNombres() async {
    final nombres = <String, String>{};
    for (final uid in widget.trabajadoresIds) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        nombres[uid] =
            '${data['nombre'] ?? ''} ${data['apellidos'] ?? ''}'.trim();
      }
    }
    _nombresWorkers = nombres;
    return nombres;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.fondoPrincipal,
      appBar: AppBar(
        backgroundColor: AppTheme.fondoCard,
        foregroundColor: AppTheme.textoBlanco,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.tituloEvento,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const Text('Registro de fichajes',
                style: TextStyle(fontSize: 12, color: AppTheme.textoSecundario)),
          ],
        ),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppTheme.bordeCard),
        ),
      ),
      body: _cargando
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.verdeNeon))
          : _fichajes.isEmpty
              ? _buildSinFichajes()
              : _buildTabla(),
    );
  }

  Widget _buildSinFichajes() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.fingerprint, color: AppTheme.textoSecundario, size: 48),
          SizedBox(height: 16),
          Text('Ningún trabajador ha fichado todavía',
              style: TextStyle(color: AppTheme.textoSecundario)),
        ],
      ),
    );
  }

  Widget _buildTabla() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${_fichajes.length} registro(s) encontrado(s)',
              style: const TextStyle(color: AppTheme.textoSecundario, fontSize: 12)),
          const SizedBox(height: 16),
          // Cabecera de la tabla
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: AppTheme.fondoPrincipal,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              border: Border(
                top: BorderSide(color: AppTheme.bordeCard),
                left: BorderSide(color: AppTheme.bordeCard),
                right: BorderSide(color: AppTheme.bordeCard),
              ),
            ),
            child: Row(
              children: [
                _cab('TRABAJADOR', flex: 3),
                _cab('ENTRADA', flex: 2),
                _cab('UBIC. ENTRADA', flex: 2),
                _cab('SALIDA', flex: 2),
                _cab('UBIC. SALIDA', flex: 2),
                _cab('HORAS', flex: 1),
              ],
            ),
          ),
          // Filas
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.fondoCard,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                border: Border.all(color: AppTheme.bordeCard),
              ),
              clipBehavior: Clip.antiAlias,
              child: ListView.separated(
                itemCount: _fichajes.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: AppTheme.bordeCard),
                itemBuilder: (context, i) => _buildFila(_fichajes[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFila(Map<String, dynamic> f) {
    final uid = f['trabajadorId'] as String? ?? '';
    final nombre = _nombresWorkers[uid] ?? uid;
    final entrada = f['entrada'];
    final salida = f['salida'];
    final ubicEntrada = f['ubicacionEntrada'] as Map<String, dynamic>?;
    final ubicSalida = f['ubicacionSalida'] as Map<String, dynamic>?;

    String horaEntrada = '—';
    String horaSalida = '—';
    double? horasTotales;

    if (entrada != null) {
      final dt = (entrada as dynamic).toDate() as DateTime;
      horaEntrada = _hora(dt);
      if (salida != null) {
        final dtSalida = (salida as dynamic).toDate() as DateTime;
        horaSalida = _hora(dtSalida);
        horasTotales = dtSalida.difference(dt).inMinutes / 60.0;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(nombre,
                style: const TextStyle(color: AppTheme.textoBlanco, fontSize: 13)),
          ),
          Expanded(
            flex: 2,
            child: Text(horaEntrada,
                style: const TextStyle(color: AppTheme.verdeNeon, fontSize: 13)),
          ),
          Expanded(
            flex: 2,
            child: _botonUbicacion(context, ubicEntrada, 'Entrada'),
          ),
          Expanded(
            flex: 2,
            child: Text(
              horaSalida,
              style: TextStyle(
                color: salida != null ? AppTheme.textoBlanco : AppTheme.textoTerciario,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: _botonUbicacion(context, ubicSalida, 'Salida'),
          ),
          Expanded(
            flex: 1,
            child: Text(
              horasTotales != null
                  ? '${horasTotales.toStringAsFixed(1)}h'
                  : '—',
              style: const TextStyle(
                  color: AppTheme.textoBlanco, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // Botón que abre un mapa en un diálogo con la ubicación del fichaje
  Widget _botonUbicacion(BuildContext context, Map<String, dynamic>? ubic, String tipo) {
    if (ubic == null) {
      return const Text('—',
          style: TextStyle(color: AppTheme.textoTerciario, fontSize: 12));
    }

    final lat = (ubic['lat'] as num).toDouble();
    final lng = (ubic['lng'] as num).toDouble();

    return TextButton.icon(
      onPressed: () => _mostrarMapa(context, lat, lng, tipo),
      icon: const Icon(Icons.location_on_outlined,
          color: AppTheme.verdeNeon, size: 14),
      label: const Text('Ver', style: TextStyle(color: AppTheme.verdeNeon, fontSize: 12)),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  // Abre un diálogo con un mapa centrado en las coordenadas del fichaje
  void _mostrarMapa(BuildContext context, double lat, double lng, String tipo) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppTheme.fondoCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SizedBox(
          width: 420,
          height: 380,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 8, 12),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: AppTheme.verdeNeon, size: 18),
                    const SizedBox(width: 8),
                    Text('Ubicación de $tipo',
                        style: Theme.of(context).textTheme.titleSmall),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close,
                          color: AppTheme.textoSecundario, size: 18),
                      onPressed: () => Navigator.pop(ctx),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Lat: ${lat.toStringAsFixed(6)}  Lng: ${lng.toStringAsFixed(6)}',
                  style: const TextStyle(
                      color: AppTheme.textoSecundario, fontSize: 11),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    // Mapa con la ubicación del fichaje usando OpenStreetMap
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: LatLng(lat, lng),
                        initialZoom: 15,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.hands4event.app',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: LatLng(lat, lng),
                              width: 32,
                              height: 32,
                              child: const Icon(
                                Icons.location_pin,
                                color: AppTheme.verdeNeon,
                                size: 32,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cab(String texto, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Text(
        texto,
        style: const TextStyle(
          color: AppTheme.textoTerciario,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  String _hora(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}
