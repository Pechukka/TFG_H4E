import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/disponibilidad.dart';
import '../core/constants.dart';

class DisponibilidadService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> guardarDisponibilidad({
    required String trabajadorId,
    required DateTime fecha,
    required TimeOfDay horaInicio,
    required TimeOfDay horaFin,
    bool aplicarRecurrente = false,
    String? existingId,
  }) async {
    final disponibilidad = Disponibilidad(
      id: existingId ?? '',
      trabajadorId: trabajadorId,
      fecha: fecha,
      horaInicio: horaInicio,
      horaFin: horaFin,
      aplicarRecurrente: aplicarRecurrente,
      diaSemana: aplicarRecurrente ? fecha.weekday : null,
      createdAt: DateTime.now(),
    );

    if (existingId != null) {
      await _firestore
          .collection(AppConstants.colDisponibilidad)
          .doc(existingId)
          .update(disponibilidad.toFirestore());
    } else {
      await _firestore
          .collection(AppConstants.colDisponibilidad)
          .add(disponibilidad.toFirestore());
    }

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

  // Crea entradas para el mismo día de la semana durante los próximos 2 años
  Future<void> _crearDisponibilidadRecurrente({
    required String trabajadorId,
    required DateTime fecha,
    required TimeOfDay horaInicio,
    required TimeOfDay horaFin,
  }) async {
    final diaSemana = fecha.weekday;
    final fechaFin = DateTime(fecha.year + 2, fecha.month, fecha.day);

    final batch = _firestore.batch();
    var diaActual = fecha.add(const Duration(days: 1));

    while (diaActual.isBefore(fechaFin)) {
      if (diaActual.weekday == diaSemana) {
        final disp = Disponibilidad(
          id: '',
          trabajadorId: trabajadorId,
          fecha: DateTime(diaActual.year, diaActual.month, diaActual.day),
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

  Future<Disponibilidad?> getDisponibilidadDia(
    String trabajadorId,
    DateTime fecha,
  ) async {
    final inicio = DateTime(fecha.year, fecha.month, fecha.day);
    final fin = inicio.add(const Duration(days: 1));

    // Filtramos en Dart para evitar índice compuesto en Firestore
    final snapshot = await _firestore
        .collection(AppConstants.colDisponibilidad)
        .where('trabajadorId', isEqualTo: trabajadorId)
        .get();

    final coincidencias = snapshot.docs
        .map((doc) => Disponibilidad.fromFirestore(doc))
        .where((d) => !d.fecha.isBefore(inicio) && d.fecha.isBefore(fin))
        .toList();

    return coincidencias.isNotEmpty ? coincidencias.first : null;
  }

  Future<Map<int, bool>> getDisponibilidadesDelMes(
    String trabajadorId,
    int anio,
    int mes,
  ) async {
    final inicio = DateTime(anio, mes, 1);
    final fin = DateTime(anio, mes + 1, 1);

    // Filtramos en Dart para evitar índice compuesto en Firestore
    final snapshot = await _firestore
        .collection(AppConstants.colDisponibilidad)
        .where('trabajadorId', isEqualTo: trabajadorId)
        .get();

    final Map<int, bool> diasConDisponibilidad = {};
    for (var doc in snapshot.docs) {
      final disp = Disponibilidad.fromFirestore(doc);
      if (!disp.fecha.isBefore(inicio) && disp.fecha.isBefore(fin)) {
        diasConDisponibilidad[disp.fecha.day] = true;
      }
    }
    return diasConDisponibilidad;
  }

  Future<void> eliminarDisponibilidad(String disponibilidadId) async {
    await _firestore
        .collection(AppConstants.colDisponibilidad)
        .doc(disponibilidadId)
        .delete();
  }
}