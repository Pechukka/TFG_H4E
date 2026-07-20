import 'package:cloud_firestore/cloud_firestore.dart';

// Respuesta de un worker a un evento del feed (Fase 2).
// Colección `postulaciones`.
class Postulacion {
  final String id;
  final String eventoId;
  final String trabajadorId;
  final String rol; // el puesto al que se postula
  final String estado;
  final DateTime? createdAt;

  // Estados posibles (centralizados para no repetir strings sueltos)
  static const String pendiente = 'pendiente';
  static const String rechazadoPorWorker = 'rechazado_por_worker';
  static const String confirmado = 'confirmado';
  static const String descartado = 'descartado';

  const Postulacion({
    required this.id,
    required this.eventoId,
    required this.trabajadorId,
    required this.rol,
    required this.estado,
    this.createdAt,
  });

  factory Postulacion.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Postulacion(
      id: doc.id,
      eventoId: data['eventoId'] ?? '',
      trabajadorId: data['trabajadorId'] ?? '',
      rol: data['rol'] ?? '',
      estado: data['estado'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'eventoId': eventoId,
      'trabajadorId': trabajadorId,
      'rol': rol,
      'estado': estado,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }
}
