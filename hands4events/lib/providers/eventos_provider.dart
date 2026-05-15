import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/evento.dart';
import '../services/eventos_service.dart';

/// Provider de Eventos
/// Gestiona el estado de eventos del trabajador
class EventosProvider with ChangeNotifier {
  final EventosService _eventosService = EventosService();

  StreamSubscription<List<Evento>>? _subscription;
  List<Evento> _eventos = [];
  Map<int, bool> _diasConEventos = {};
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<Evento> get eventos => _eventos;
  Map<int, bool> get diasConEventos => _diasConEventos;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// CARGAR EVENTOS DEL TRABAJADOR
  void cargarEventos(String trabajadorId) {
    _subscription?.cancel();
    _isLoading = true;
    notifyListeners();
    _subscription = _eventosService.getEventosTrabajador(trabajadorId).listen(
      (eventos) {
        _eventos = eventos;
        _isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        _setError('Error al cargar eventos: $error');
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// OBTENER EVENTO POR ID
  Future<Evento?> fetchEvento(String eventoId) async {
    try {
      return await _eventosService.getEvento(eventoId);
    } catch (e) {
      _setError('Error al cargar evento: $e');
      return null;
    }
  }

  /// OBTENER EVENTOS FUTUROS
  Future<List<Evento>> getEventosFuturos(String trabajadorId) async {
    try {
      return await _eventosService.getEventosFuturos(trabajadorId);
    } catch (e) {
      _setError('Error al cargar eventos futuros: $e');
      return [];
    }
  }

  /// OBTENER EVENTOS POR FECHA
  Future<List<Evento>> getEventosPorFecha(
    String trabajadorId,
    DateTime fecha,
  ) async {
    try {
      return await _eventosService.getEventosPorFecha(trabajadorId, fecha);
    } catch (e) {
      _setError('Error al cargar eventos de la fecha: $e');
      return [];
    }
  }

  /// CARGAR EVENTOS DEL MES (para calendario)
  Future<void> cargarEventosDelMes(
    String trabajadorId,
    int anio,
    int mes,
  ) async {
    _diasConEventos = {};
    notifyListeners();
    try {
      _diasConEventos = await _eventosService.getEventosDelMes(
        trabajadorId,
        anio,
        mes,
      );
      notifyListeners();
    } catch (e) {
      _setError('Error al cargar eventos del mes: $e');
    }
  }

  /// VERIFICAR SI HAY EVENTO EN UN DÍA
  bool tieneEventoEnDia(int dia) {
    return _diasConEventos[dia] ?? false;
  }

  /// OBTENER EQUIPO DEL EVENTO
  Future<List<Map<String, dynamic>>> getEquipoEvento(String eventoId) async {
    try {
      return await _eventosService.getEquipoEvento(eventoId);
    } catch (e) {
      _setError('Error al cargar equipo: $e');
      return [];
    }
  }

  /// FILTRAR EVENTOS POR ESTADO
  List<Evento> get eventosFuturos {
    return _eventos.where((e) => e.fechaInicio.isAfter(DateTime.now())).toList();
  }

  List<Evento> get eventosEnCurso {
    return _eventos.where((e) => e.estaEnCurso()).toList();
  }

  List<Evento> get eventosPasados {
    return _eventos.where((e) => e.fechaFin.isBefore(DateTime.now())).toList();
  }

  // Métodos auxiliares
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
    _subscription?.cancel();
    _subscription = null;
    _eventos = [];
    _diasConEventos = {};
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
