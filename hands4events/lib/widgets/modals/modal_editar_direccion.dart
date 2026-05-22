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
import '../../providers/auth_provider.dart';
import '../../providers/idioma_provider.dart';
import 'modal_base.dart';
import '../../utils/top_snackbar.dart';

class ModalEditarDireccion extends StatefulWidget {
  const ModalEditarDireccion({super.key});

  @override
  State<ModalEditarDireccion> createState() => _ModalEditarDireccionState();
}

class _ModalEditarDireccionState extends State<ModalEditarDireccion> {
  final TextEditingController _controller = TextEditingController();
  final MapController _mapController = MapController();
  List<Map<String, String>> _sugerencias = [];
  Timer? _debounce;
  double? _lat;
  double? _lng;
  String _direccionGuardar = '';
  bool _isLoading = false;
  bool _buscando = false;
  bool _geocodificandoTap = false;

  @override
  void initState() {
    super.initState();
    final usuario = Provider.of<AuthProvider>(context, listen: false).currentUser;
    final dir = usuario?.direccion ?? '';
    if (dir.isNotEmpty) {
      _controller.text = dir;
      _direccionGuardar = dir;
      _geocodificar(dir);
    } else {
      // Sin dirección guardada → usar GPS del dispositivo
      _usarUbicacionActual();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  // ── GPS ────────────────────────────────────────────────────────────────────

  Future<void> _usarUbicacionActual() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever ||
          perm == LocationPermission.denied) {
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      if (!mounted) return;
      await _geocodificarInverso(pos.latitude, pos.longitude, actualizarCampo: true);
    } catch (_) {}
  }

  // ── Geocodificación ────────────────────────────────────────────────────────

  Future<void> _geocodificar(String address) async {
    try {
      final uri = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json'
        '?address=${Uri.encodeComponent(address)}'
        '&key=${AppConstants.googleMapsApiKey}',
      );
      final res = await http.get(uri);
      if (res.statusCode == 200 && mounted) {
        final data = json.decode(res.body);
        if ((data['results'] as List).isNotEmpty) {
          final loc = data['results'][0]['geometry']['location'];
          final lat = (loc['lat'] as num).toDouble();
          final lng = (loc['lng'] as num).toDouble();
          setState(() {
            _lat = lat;
            _lng = lng;
          });
          _mapController.move(LatLng(lat, lng), 15);
        }
      }
    } catch (_) {}
  }

  Future<void> _geocodificarInverso(
    double lat,
    double lng, {
    bool actualizarCampo = false,
  }) async {
    setState(() => _geocodificandoTap = true);
    try {
      final uri = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json'
        '?latlng=$lat,$lng'
        '&key=${AppConstants.googleMapsApiKey}'
        '&language=es',
      );
      final res = await http.get(uri);
      if (res.statusCode == 200 && mounted) {
        final data = json.decode(res.body);
        final results = data['results'] as List;
        if (results.isNotEmpty) {
          final direccion = results[0]['formatted_address'] as String;
          setState(() {
            _lat = lat;
            _lng = lng;
            _direccionGuardar = direccion;
            if (actualizarCampo) _controller.text = direccion;
          });
          _mapController.move(LatLng(lat, lng), 15);
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _geocodificandoTap = false);
  }

  // ── Autocomplete ───────────────────────────────────────────────────────────

  void _onTextChanged(String value) {
    _debounce?.cancel();
    if (value.length < 3) {
      setState(() => _sugerencias = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () => _buscar(value));
  }

  Future<void> _buscar(String query) async {
    setState(() => _buscando = true);
    try {
      final uri = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json'
        '?input=${Uri.encodeComponent(query)}'
        '&key=${AppConstants.googleMapsApiKey}'
        '&language=es'
        '&types=address',
      );
      final res = await http.get(uri);
      if (res.statusCode == 200 && mounted) {
        final data = json.decode(res.body);
        final predictions = data['predictions'] as List;
        setState(() {
          _sugerencias = predictions
              .map((p) => {
                    'description': p['description'] as String,
                    'place_id': p['place_id'] as String,
                  })
              .toList();
          _buscando = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _buscando = false);
    }
  }

  Future<void> _seleccionar(Map<String, String> sugerencia) async {
    _debounce?.cancel();
    FocusScope.of(context).unfocus();
    final desc = sugerencia['description']!;
    setState(() {
      _sugerencias = [];
      _controller.text = desc;
      _direccionGuardar = desc;
    });

    try {
      final uri = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json'
        '?place_id=${sugerencia['place_id']}'
        '&key=${AppConstants.googleMapsApiKey}'
        '&fields=geometry',
      );
      final res = await http.get(uri);
      if (res.statusCode == 200 && mounted) {
        final loc = json.decode(res.body)['result']['geometry']['location'];
        final lat = (loc['lat'] as num).toDouble();
        final lng = (loc['lng'] as num).toDouble();
        setState(() {
          _lat = lat;
          _lng = lng;
        });
        _mapController.move(LatLng(lat, lng), 15);
      }
    } catch (_) {}
  }

  // ── Tap en el mapa ─────────────────────────────────────────────────────────

  void _onMapTap(TapPosition _, LatLng punto) {
    FocusScope.of(context).unfocus();
    _geocodificarInverso(punto.latitude, punto.longitude,
        actualizarCampo: true);
  }

  // ── Guardar ────────────────────────────────────────────────────────────────

  Future<void> _guardar() async {
    final t = context.read<IdiomaProvider>();
    final dir = _direccionGuardar.isNotEmpty
        ? _direccionGuardar
        : _controller.text.trim();
    if (dir.isEmpty) {
      showTopSnackBar(context, t.tr('direccion_invalida'),
          backgroundColor: AppTheme.rojoError, icon: Icons.error_outline);
      return;
    }

    setState(() => _isLoading = true);
    final exito = await Provider.of<AuthProvider>(context, listen: false)
        .updateProfile(direccion: dir);

    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.pop(context);
      showTopSnackBar(
        context,
        exito ? t.tr('direccion_actualizada') : t.tr('error_actualizar_direccion'),
        backgroundColor: exito ? AppTheme.verdeExito : AppTheme.rojoError,
        icon: exito ? Icons.check_circle_outline : Icons.error_outline,
      );
    }
  }

  // ── UI ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final t = context.watch<IdiomaProvider>();

    return ModalBase(
      titulo: t.tr('editar_direccion'),
      contenido: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Campo de búsqueda
          TextField(
            controller: _controller,
            style: const TextStyle(color: AppTheme.textoBlanco),
            onChanged: _onTextChanged,
            decoration: InputDecoration(
              hintText: t.tr('busca_direccion'),
              hintStyle: const TextStyle(color: AppTheme.textoTerciario),
              prefixIcon: const Icon(Icons.search, color: AppTheme.verdeNeon),
              suffixIcon: _buscando
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppTheme.verdeNeon),
                      ),
                    )
                  : null,
              filled: true,
              fillColor: AppTheme.fondoInput,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    const BorderSide(color: AppTheme.verdeNeon, width: 1),
              ),
            ),
          ),

          // Sugerencias autocomplete
          if (_sugerencias.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                color: AppTheme.fondoCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.bordeCampo),
              ),
              child: Column(
                children: _sugerencias
                    .map((s) => InkWell(
                          onTap: () => _seleccionar(s),
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
                        ))
                    .toList(),
              ),
            ),

          const SizedBox(height: 12),

          // Ayuda: tap en mapa
          Row(
            children: [
              const Icon(Icons.touch_app,
                  color: AppTheme.textoTerciario, size: 14),
              const SizedBox(width: 6),
              Text(
                t.tr('toca_mapa'),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textoTerciario,
                      fontSize: 11,
                    ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Mapa interactivo con OpenStreetMap
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 220,
              width: double.infinity,
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _lat != null && _lng != null
                          ? LatLng(_lat!, _lng!)
                          : const LatLng(40.416775, -3.703790), // Madrid por defecto
                      initialZoom: _lat != null ? 15.0 : 6.0,
                      onTap: _onMapTap,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.hands4events.app',
                      ),
                      if (_lat != null && _lng != null)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: LatLng(_lat!, _lng!),
                              child: const Icon(
                                Icons.location_on,
                                color: AppTheme.verdeNeon,
                                size: 36,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),

                  // Overlay de carga al geocodificar tap
                  if (_geocodificandoTap)
                    Container(
                      color: Colors.black45,
                      child: const Center(
                        child: CircularProgressIndicator(
                            color: AppTheme.verdeNeon),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      botonesAccion: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _guardar,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.verdeNeon,
              foregroundColor: AppTheme.textoSobreVerde,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppTheme.textoSobreVerde),
                  )
                : Text(
                    t.tr('guardar_cambios'),
                    style:
                        const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
      ],
    );
  }
}
