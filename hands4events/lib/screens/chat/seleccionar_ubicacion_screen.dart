import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:hands4events/core/theme.dart';
import 'package:hands4events/core/constants.dart';
import '../../providers/idioma_provider.dart';
import '../../widgets/app_bar_custom.dart';

class SeleccionarUbicacionScreen extends StatefulWidget {
  const SeleccionarUbicacionScreen({super.key});

  @override
  State<SeleccionarUbicacionScreen> createState() =>
      _SeleccionarUbicacionScreenState();
}

class _SeleccionarUbicacionScreenState
    extends State<SeleccionarUbicacionScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  static const LatLng _defaultCenter = LatLng(40.4168, -3.7038);

  bool _cargandoGPS = false;
  bool _buscando = false;
  List<Map<String, String>> _sugerencias = [];
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _irAUbicacionActual();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // ── GPS ─────────────────────────────────────────────────────────────────────

  Future<void> _irAUbicacionActual() async {
    setState(() => _cargandoGPS = true);
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm != LocationPermission.denied &&
          perm != LocationPermission.deniedForever) {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings:
              const LocationSettings(accuracy: LocationAccuracy.high),
        );
        if (mounted) _mapController.move(LatLng(pos.latitude, pos.longitude), 16.0);
      }
    } catch (_) {}
    if (mounted) setState(() => _cargandoGPS = false);
  }

  // ── Búsqueda Places ──────────────────────────────────────────────────────────

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    if (value.trim().length < 3) {
      setState(() => _sugerencias = []);
      return;
    }
    _debounce = Timer(
      const Duration(milliseconds: 400),
      () => _buscarLugar(value.trim()),
    );
  }

  Future<void> _buscarLugar(String query) async {
    setState(() => _buscando = true);
    try {
      final uri = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json'
        '?input=${Uri.encodeComponent(query)}'
        '&key=${AppConstants.googleMapsApiKey}'
        '&language=es',
      );
      final res = await http.get(uri);
      if (res.statusCode == 200 && mounted) {
        final data = json.decode(res.body);
        final predictions = data['predictions'] as List;
        setState(() {
          _sugerencias = predictions
              .take(5)
              .map((p) => {
                    'description': p['description'] as String,
                    'place_id': p['place_id'] as String,
                  })
              .toList();
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _buscando = false);
  }

  Future<void> _seleccionarLugar(Map<String, String> lugar) async {
    _debounce?.cancel();
    FocusScope.of(context).unfocus();
    setState(() {
      _sugerencias = [];
      _searchController.text = lugar['description']!;
    });
    try {
      final uri = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json'
        '?place_id=${lugar['place_id']}'
        '&key=${AppConstants.googleMapsApiKey}'
        '&fields=geometry',
      );
      final res = await http.get(uri);
      if (res.statusCode == 200 && mounted) {
        final loc =
            json.decode(res.body)['result']['geometry']['location'];
        final lat = (loc['lat'] as num).toDouble();
        final lng = (loc['lng'] as num).toDouble();
        _mapController.move(LatLng(lat, lng), 16.0);
      }
    } catch (_) {}
  }

  // ── Confirmar ────────────────────────────────────────────────────────────────

  void _confirmar() => Navigator.pop(context, _mapController.camera.center);

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final t = context.watch<IdiomaProvider>();

    return Scaffold(
      backgroundColor: AppTheme.fondoPrincipal,
      appBar: AppBarCustom(
        showBackButton: true,
        showLogo: false,
        title: t.tr('seleccionar_ubicacion'),
      ),
      body: Stack(
        children: [
          // Mapa
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: _defaultCenter,
              initialZoom: 15.0,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.hands4events.app',
              ),
            ],
          ),

          // Pin fijo en el centro
          IgnorePointer(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.location_pin,
                      color: AppTheme.rojoError,
                      size: 52,
                    ),
                  ),
                  Container(
                    width: 10,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Barra de búsqueda superior
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Column(
              children: [
                Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(12),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    style: const TextStyle(color: AppTheme.textoBlanco),
                    decoration: InputDecoration(
                      hintText: t.tr('busca_direccion'),
                      hintStyle:
                          const TextStyle(color: AppTheme.textoTerciario),
                      prefixIcon: const Icon(Icons.search,
                          color: AppTheme.verdeNeon),
                      suffixIcon: _buscando
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppTheme.verdeNeon),
                              ),
                            )
                          : _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear,
                                      color: AppTheme.textoTerciario),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _sugerencias = []);
                                  },
                                )
                              : null,
                      filled: true,
                      fillColor: AppTheme.fondoCard,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                  ),
                ),

                // Sugerencias
                if (_sugerencias.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.fondoCard,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Column(
                      children: _sugerencias
                          .map(
                            (s) => InkWell(
                              onTap: () => _seleccionarLugar(s),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                child: Row(
                                  children: [
                                    const Icon(Icons.location_on,
                                        color: AppTheme.verdeNeon, size: 18),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        s['description']!,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                                color: AppTheme.textoBlanco),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
              ],
            ),
          ),

          // Botón GPS
          Positioned(
            right: 16,
            bottom: 96,
            child: FloatingActionButton.small(
              heroTag: 'gps_btn',
              backgroundColor: AppTheme.fondoCard,
              elevation: 4,
              onPressed: _cargandoGPS ? null : _irAUbicacionActual,
              child: _cargandoGPS
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.verdeNeon,
                      ),
                    )
                  : const Icon(Icons.my_location, color: AppTheme.verdeNeon),
            ),
          ),

          // Botón confirmar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                decoration: BoxDecoration(
                  color: AppTheme.fondoPrincipal.withValues(alpha: 0.95),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: _confirmar,
                  icon: const Icon(Icons.send),
                  label: Text(
                    t.tr('confirmar_ubicacion'),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.verdeNeon,
                    foregroundColor: AppTheme.textoSobreVerde,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
