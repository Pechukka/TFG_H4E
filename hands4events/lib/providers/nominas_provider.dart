import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/nomina.dart';
import '../services/nominas_service.dart';

class NominasProvider with ChangeNotifier {
  final NominasService _nominasService = NominasService();

  StreamSubscription<List<Nomina>>? _subscription;
  List<Nomina> _nominas = [];
  bool _isLoading = false;
  bool _estaInicializado = false;
  String? _errorMessage;

  List<Nomina> get nominas => _nominas;
  bool get isLoading => _isLoading;
  bool get estaInicializado => _estaInicializado;
  String? get errorMessage => _errorMessage;

  /// Última nómina disponible (la más reciente)
  Nomina? get ultimaNomina => _nominas.isNotEmpty ? _nominas.first : null;

  void cargarNominas(String trabajadorId) {
    if (_estaInicializado) return;
    _estaInicializado = true;
    _isLoading = true;
    notifyListeners();
    _subscription = _nominasService.getNominasTrabajador(trabajadorId).listen(
      (nominas) {
        _nominas = nominas;
        _isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = 'Error al cargar nóminas: $error';
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  void refresh(String trabajadorId) {
    _estaInicializado = false;
    cargarNominas(trabajadorId);
  }

  void reset() {
    _subscription?.cancel();
    _subscription = null;
    _nominas = [];
    _isLoading = false;
    _estaInicializado = false;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> marcarRevisada(String nominaId) async {
    try {
      await _nominasService.marcarComoRevisada(nominaId);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error al marcar nómina: $e';
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
