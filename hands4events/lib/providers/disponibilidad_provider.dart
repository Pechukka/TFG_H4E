import 'package:flutter/material.dart';
import '../models/disponibilidad.dart';
import '../services/disponibilidad_service.dart';

class DisponibilidadProvider with ChangeNotifier {
  final DisponibilidadService _service = DisponibilidadService();

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<bool> guardarDisponibilidad({
    required String trabajadorId,
    required DateTime fecha,
    required TimeOfDay horaInicio,
    required TimeOfDay horaFin,
    bool aplicarRecurrente = false,
    String? existingId,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _service.guardarDisponibilidad(
        trabajadorId: trabajadorId,
        fecha: fecha,
        horaInicio: horaInicio,
        horaFin: horaFin,
        aplicarRecurrente: aplicarRecurrente,
        existingId: existingId,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<Disponibilidad?> getDisponibilidadDia(
    String trabajadorId,
    DateTime fecha,
  ) async {
    return await _service.getDisponibilidadDia(trabajadorId, fecha);
  }

  Future<Map<int, bool>> getDisponibilidadesDelMes(
    String trabajadorId,
    int anio,
    int mes,
  ) async {
    return await _service.getDisponibilidadesDelMes(trabajadorId, anio, mes);
  }

  Future<void> eliminarDisponibilidad(String id) async {
    await _service.eliminarDisponibilidad(id);
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}