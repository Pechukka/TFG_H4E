import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/fichaje.dart';
import '../services/fichajes_service.dart';

class FichajeProvider with ChangeNotifier {
  final FichajesService _fichajesService = FichajesService();

  Fichaje? _fichajeActivo;
  List<Fichaje> _historial = [];
  Timer? _cronometro;
  bool _isLoading = false;
  String? _errorMessage;

  Fichaje? get fichajeActivo => _fichajeActivo;
  List<Fichaje> get historial => _historial;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get tieneFichajeActivo => _fichajeActivo != null;

  Future<void> cargarFichajeActivo(String trabajadorId, String eventoId) async {
    // Limpiar estado del evento anterior antes de cargar el nuevo
    _fichajeActivo = null;
    _historial = [];
    _detenerCronometro();
    _setLoading(true);
    _clearError();

    try {
      _fichajeActivo = await _fichajesService.getFichajeActivo(trabajadorId, eventoId);
      
      // Iniciar cronómetro si el fichaje está en curso
      if (_fichajeActivo?.estado == FichajeEstado.enCurso) {
        _iniciarCronometro();
      }

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Error al cargar fichaje: $e');
      _setLoading(false);
    }
  }

  Future<Position?> _intentarObtenerUbicacion() async {
    try {
      return await _fichajesService.obtenerUbicacion();
    } catch (_) {
      return null;
    }
  }

  Future<bool> ficharEntrada(String trabajadorId, String eventoId) async {
    _setLoading(true);
    _clearError();

    try {
      final ubicacion = await _intentarObtenerUbicacion();

      _fichajeActivo = await _fichajesService.ficharEntrada(
        trabajadorId: trabajadorId,
        eventoId: eventoId,
        ubicacion: ubicacion,
      );

      _iniciarCronometro();
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<bool> ficharSalida() async {
    if (_fichajeActivo == null) return false;

    _setLoading(true);
    _clearError();

    try {
      final ubicacion = await _intentarObtenerUbicacion();

      await _fichajesService.ficharSalida(
        fichajeId: _fichajeActivo!.id,
        ubicacion: ubicacion,
      );

      _detenerCronometro();
      _fichajeActivo = null;
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Error al fichar salida: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> pausarFichaje() async {
    if (_fichajeActivo == null) return false;

    _setLoading(true);
    _clearError();

    try {
      await _fichajesService.pausarFichaje(_fichajeActivo!.id);

      // Recargar desde Firestore: el servicio ha añadido la pausa, y si aquí solo
      // cambiáramos el estado, la lista de pausas local quedaría vieja y el cronómetro
      // no descontaría nada.
      final actualizado = await _fichajesService.getFichajeActivo(
          _fichajeActivo!.trabajadorId, _fichajeActivo!.eventoId);
      _fichajeActivo =
          actualizado ?? _fichajeActivo!.copyWith(estado: FichajeEstado.pausado);
      _detenerCronometro();
      
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Error al pausar: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> reanudarFichaje() async {
    if (_fichajeActivo == null) return false;

    _setLoading(true);
    _clearError();

    try {
      await _fichajesService.reanudarFichaje(_fichajeActivo!.id);

      // Recargar desde Firestore para traer la pausa ya cerrada (con su fin).
      final actualizado = await _fichajesService.getFichajeActivo(
          _fichajeActivo!.trabajadorId, _fichajeActivo!.eventoId);
      _fichajeActivo =
          actualizado ?? _fichajeActivo!.copyWith(estado: FichajeEstado.enCurso);
      _iniciarCronometro();
      
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Error al reanudar: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<void> cargarHistorial(String trabajadorId, String eventoId) async {
    try {
      _historial = await _fichajesService.getFichajesEvento(trabajadorId, eventoId);
      notifyListeners();
    } catch (_) {}
  }

  void _iniciarCronometro() {
    _detenerCronometro();
    _cronometro = Timer.periodic(const Duration(seconds: 1), (_) => notifyListeners());
  }

  void _detenerCronometro() {
    _cronometro?.cancel();
    _cronometro = null;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void clearError() {
    _clearError();
    notifyListeners();
  }

  void reset() {
    _detenerCronometro();
    _fichajeActivo = null;
    _historial = [];
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _detenerCronometro();
    super.dispose();
  }
}