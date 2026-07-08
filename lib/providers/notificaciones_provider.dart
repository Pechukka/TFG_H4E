import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/notificacion.dart';
import '../services/notificaciones_service.dart';

class NotificacionesProvider with ChangeNotifier {
  final NotificacionesService _service = NotificacionesService();

  StreamSubscription<List<Notificacion>>? _subscription;
  List<Notificacion> _notificaciones = [];
  bool _isLoading = false;
  bool _estaInicializado = false;

  List<Notificacion> get notificaciones => _notificaciones;
  bool get isLoading => _isLoading;
  int get noLeidas => _notificaciones.where((n) => !n.leida).length;

  void cargarNotificaciones(String trabajadorId) {
    if (_estaInicializado) return;
    _estaInicializado = true;
    _isLoading = true;
    notifyListeners();
    _subscription = _service.getNotificaciones(trabajadorId).listen(
      (notificaciones) {
        _notificaciones = notificaciones;
        _isLoading = false;
        notifyListeners();
      },
      onError: (_) {
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> marcarLeida(String notificacionId) async {
    await _service.marcarLeida(notificacionId);
  }

  Future<void> eliminarNotificacion(String notificacionId) async {
    _notificaciones.removeWhere((n) => n.id == notificacionId);
    notifyListeners();
    await _service.eliminarNotificacion(notificacionId);
  }

  void reset() {
    _subscription?.cancel();
    _subscription = null;
    _notificaciones = [];
    _isLoading = false;
    _estaInicializado = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
