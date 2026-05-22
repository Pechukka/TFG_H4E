import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Disponibilidad {
  final String id;
  final String trabajadorId;
  final DateTime fecha;
  final TimeOfDay horaInicio;
  final TimeOfDay horaFin;
  final bool aplicarRecurrente;
  final int? diaSemana;
  final DateTime? createdAt;

  const Disponibilidad({
    required this.id,
    required this.trabajadorId,
    required this.fecha,
    required this.horaInicio,
    required this.horaFin,
    this.aplicarRecurrente = false,
    this.diaSemana,
    this.createdAt,
  });

  String get horaInicioFormateada {
    return '${horaInicio.hour.toString().padLeft(2, '0')}:${horaInicio.minute.toString().padLeft(2, '0')}';
  }

  String get horaFinFormateada {
    return '${horaFin.hour.toString().padLeft(2, '0')}:${horaFin.minute.toString().padLeft(2, '0')}';
  }

  String get rangoHorario {
    return '$horaInicioFormateada - $horaFinFormateada';
  }

  String get nombreDiaSemana {
    if (diaSemana == null) return '';
    const dias = ['', 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    return dias[diaSemana!];
  }

  // Firebase → Dart
  factory Disponibilidad.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return Disponibilidad(
      id: doc.id,
      trabajadorId: data['trabajadorId'] ?? '',
      fecha: (data['fecha'] as Timestamp).toDate(),
      horaInicio: TimeOfDay(
        hour: data['horaInicio']['hour'] as int,
        minute: data['horaInicio']['minute'] as int,
      ),
      horaFin: TimeOfDay(
        hour: data['horaFin']['hour'] as int,
        minute: data['horaFin']['minute'] as int,
      ),
      aplicarRecurrente: data['aplicarRecurrente'] ?? false,
      diaSemana: data['diaSemana'] as int?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  // Dart → Firebase
  Map<String, dynamic> toFirestore() {
    return {
      'trabajadorId': trabajadorId,
      'fecha': Timestamp.fromDate(fecha),
      'horaInicio': {
        'hour': horaInicio.hour,
        'minute': horaInicio.minute,
      },
      'horaFin': {
        'hour': horaFin.hour,
        'minute': horaFin.minute,
      },
      'aplicarRecurrente': aplicarRecurrente,
      'diaSemana': diaSemana,
      'createdAt': createdAt != null 
          ? Timestamp.fromDate(createdAt!) 
          : FieldValue.serverTimestamp(),
    };
  }

  Disponibilidad copyWith({
    String? id,
    String? trabajadorId,
    DateTime? fecha,
    TimeOfDay? horaInicio,
    TimeOfDay? horaFin,
    bool? aplicarRecurrente,
    int? diaSemana,
    DateTime? createdAt,
  }) {
    return Disponibilidad(
      id: id ?? this.id,
      trabajadorId: trabajadorId ?? this.trabajadorId,
      fecha: fecha ?? this.fecha,
      horaInicio: horaInicio ?? this.horaInicio,
      horaFin: horaFin ?? this.horaFin,
      aplicarRecurrente: aplicarRecurrente ?? this.aplicarRecurrente,
      diaSemana: diaSemana ?? this.diaSemana,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}