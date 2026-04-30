import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/disponibilidad.dart';
import '../core/constants.dart';

/// Servicio de Disponibilidad
/// Gestiona los horarios de disponibilidad del trabajador
class DisponibilidadService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// GUARDAR DISPONIBILIDAD
  Future<void> guardarDisponibilidad({
    required String trabajadorId,
    required DateTime fecha,
    required TimeOfDay horaInicio,
    required TimeOfDay horaFin,
    bool aplicarRecurrente = false,
  }) async {
    final disponibilidad = Disponibilidad(
      id: '',
      trabajadorId: trabajadorId,
      fecha: fecha,
      horaInicio: horaInicio,
      horaFin: horaFin,
      aplicarRecurrente: aplicarRecurrente,
      diaSemana: aplicarRecurrente ? fecha.weekday : null,
      createdAt: DateTime.now(),
    );

    await _firestore
        .collection(AppConstants.colDisponibilidad)
        .add(disponibilidad.toFirestore());

    // Si es recurrente, crear para todos los días de ese tipo en el mes
    if (aplicarRecurrente) {
      await _crearDisponibilidadRecurrente(
        trabajadorId: trabajadorId,
        fecha: fecha,
        horaInicio: horaInicio,
        horaFin: horaFin,
      );
    }
  }

  /// CREAR DISPONIBILIDAD RECURRENTE
  Future<void> _crearDisponibilidadRecurrente({
    required String trabajadorId,
    required DateTime fecha,
    required TimeOfDay horaInicio,
    required TimeOfDay horaFin,
  }) async {
    final diaSemana = fecha.weekday;
    final primerDia = DateTime(fecha.year, fecha.month, 1);
    final ultimoDia = DateTime(fecha.year, fecha.month + 1, 0);

    final batch = _firestore.batch();
    var diaActual = primerDia;

    while (diaActual.isBefore(ultimoDia) || diaActual.isAtSameMomentAs(ultimoDia)) {
      if (diaActual.weekday == diaSemana && diaActual != fecha) {
        final disp = Disponibilidad(
          id: '',
          trabajadorId: trabajadorId,
          fecha: diaActual,
          horaInicio: horaInicio,
          horaFin: horaFin,
          aplicarRecurrente: true,
          diaSemana: diaSemana,
          createdAt: DateTime.now(),
        );

        final ref = _firestore.collection(AppConstants.colDisponibilidad).doc();
        batch.set(ref, disp.toFirestore());
      }
      diaActual = diaActual.add(const Duration(days: 1));
    }

    await batch.commit();
  }

  /// OBTENER DISPONIBILIDAD DE UN DÍA
  Future<Disponibilidad?> getDisponibilidadDia(
    String trabajadorId,
    DateTime fecha,
  ) async {
    final inicio = DateTime(fecha.year, fecha.month, fecha.day);
    final fin = inicio.add(const Duration(days: 1));

    final snapshot = await _firestore
        .collection(AppConstants.colDisponibilidad)
        .where('trabajadorId', isEqualTo: trabajadorId)
        .where('fecha', isGreaterThanOrEqualTo: Timestamp.fromDate(inicio))
        .where('fecha', isLessThan: Timestamp.fromDate(fin))
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return Disponibilidad.fromFirestore(snapshot.docs.first);
    }
    return null;
  }

  /// OBTENER DISPONIBILIDADES DEL MES
  Future<Map<int, bool>> getDisponibilidadesDelMes(
    String trabajadorId,
    int anio,
    int mes,
  ) async {
    final inicio = DateTime(anio, mes, 1);
    final fin = DateTime(anio, mes + 1, 1);

    final snapshot = await _firestore
        .collection(AppConstants.colDisponibilidad)
        .where('trabajadorId', isEqualTo: trabajadorId)
        .where('fecha', isGreaterThanOrEqualTo: Timestamp.fromDate(inicio))
        .where('fecha', isLessThan: Timestamp.fromDate(fin))
        .get();

    final Map<int, bool> diasConDisponibilidad = {};
    for (var doc in snapshot.docs) {
      final disp = Disponibilidad.fromFirestore(doc);
      diasConDisponibilidad[disp.fecha.day] = true;
    }

    return diasConDisponibilidad;
  }

  /// ELIMINAR DISPONIBILIDAD
  Future<void> eliminarDisponibilidad(String disponibilidadId) async {
    await _firestore
        .collection(AppConstants.colDisponibilidad)
        .doc(disponibilidadId)
        .delete();
  }
}