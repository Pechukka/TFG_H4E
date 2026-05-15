import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/fichaje.dart';
import '../services/fichajes_service.dart';

/// Provider de Fichaje
/// Gestiona el estado del fichaje activo y cronómetro
class FichajeProvider with ChangeNotifier {
  final FichajesService _fichajesService = FichajesService();

  Fichaje? _fichajeActivo;
  List<Fichaje> _historial = [];
  Timer? _cronometro;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  Fichaje? get fichajeActivo => _fichajeActivo;
  List<Fichaje> get historial => _historial;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get tieneFichajeActivo => _fichajeActivo != null;

  /// CARGAR FICHAJE ACTIVO
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

  /// FICHAR ENTRADA
  Future<bool> ficharEntrada(String trabajadorId, String eventoId) async {
    _setLoading(true);
    _clearError();

    try {
      // Obtener ubicación GPS
      Position? ubicacion;
      try {
        ubicacion = await _fichajesService.obtenerUbicacion();
      } catch (e) {
        // Continuar sin GPS si falla
        // GPS unavailable — continue without location
      }

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

  /// FICHAR SALIDA
  Future<bool> ficharSalida() async {
    if (_fichajeActivo == null) return false;

    _setLoading(true);
    _clearError();

    try {
      // Obtener ubicación GPS
      Position? ubicacion;
      try {
        ubicacion = await _fichajesService.obtenerUbicacion();
      } catch (e) {
        // GPS unavailable — continue without location
      }

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

  /// PAUSAR FICHAJE
  Future<bool> pausarFichaje() async {
    if (_fichajeActivo == null) return false;

    _setLoading(true);
    _clearError();

    try {
      await _fichajesService.pausarFichaje(_fichajeActivo!.id);
      
      // Actualizar estado local
      _fichajeActivo = _fichajeActivo!.copyWith(estado: FichajeEstado.pausado);
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

  /// REANUDAR FICHAJE
  Future<bool> reanudarFichaje() async {
    if (_fichajeActivo == null) return false;

    _setLoading(true);
    _clearError();

    try {
      await _fichajesService.reanudarFichaje(_fichajeActivo!.id);
      
      // Actualizar estado local
      _fichajeActivo = _fichajeActivo!.copyWith(estado: FichajeEstado.enCurso);
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

  /// CARGAR HISTORIAL DE FICHAJES FINALIZADOS
  Future<void> cargarHistorial(String trabajadorId, String eventoId) async {
    try {
      _historial = await _fichajesService.getFichajesEvento(trabajadorId, eventoId);
      notifyListeners();
    } catch (_) {}
  }

  /// CRONÓMETRO
  void _iniciarCronometro() {
    _detenerCronometro(); // Detener cronómetro anterior si existe
    
    _cronometro = Timer.periodic(const Duration(seconds: 1), (timer) {
      notifyListeners(); // Actualiza el tiempoTotal cada segundo
    });
  }

  void _detenerCronometro() {
    _cronometro?.cancel();
    _cronometro = null;
  }

  // Métodos auxiliares
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