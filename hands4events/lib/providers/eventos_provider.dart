import 'package:flutter/foundation.dart';
import '../models/evento.dart';
import '../services/eventos_service.dart';

/// Provider de Eventos
/// Gestiona el estado de eventos del trabajador
class EventosProvider with ChangeNotifier {
  final EventosService _eventosService = EventosService();

  List<Evento> _eventos = [];
  Evento? _eventoSeleccionado;
  Map<int, bool> _diasConEventos = {};
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<Evento> get eventos => _eventos;
  Evento? get eventoSeleccionado => _eventoSeleccionado;
  Map<int, bool> get diasConEventos => _diasConEventos;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// CARGAR EVENTOS DEL TRABAJADOR
  void cargarEventos(String trabajadorId) {
    _eventosService.getEventosTrabajador(trabajadorId).listen(
      (eventos) {
        _eventos = eventos;
        notifyListeners();
      },
      onError: (error) {
        _setError('Error al cargar eventos: $error');
      },
    );
  }

  /// OBTENER EVENTO POR ID
  Future<void> cargarEvento(String eventoId) async {
    _setLoading(true);
    _clearError();

    try {
      _eventoSeleccionado = await _eventosService.getEvento(eventoId);
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Error al cargar evento: $e');
      _setLoading(false);
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

  /// SELECCIONAR EVENTO
  void seleccionarEvento(Evento evento) {
    _eventoSeleccionado = evento;
    notifyListeners();
  }

  /// LIMPIAR SELECCIÓN
  void limpiarSeleccion() {
    _eventoSeleccionado = null;
    notifyListeners();
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
}