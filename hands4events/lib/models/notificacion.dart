import 'package:cloud_firestore/cloud_firestore.dart';

enum TipoNotificacion {
  nuevoEvento,
  nuevoMensaje,
  nominaPublicada,
  documentoRequerido,
  cambioEvento,
  recordatorio,
  eventoCancelado,
  sistema,
}

class Notificacion {
  final String id;
  final String trabajadorId;
  final TipoNotificacion tipo;
  final String titulo;
  final String mensaje;
  final DateTime timestamp;
  final bool leida;
  final Map<String, dynamic>? datos;

  Notificacion({
    required this.id,
    required this.trabajadorId,
    required this.tipo,
    required this.titulo,
    required this.mensaje,
    required this.timestamp,
    this.leida = false,
    this.datos,
  });

  factory Notificacion.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Notificacion(
      id: doc.id,
      trabajadorId: data['trabajadorId'] ?? '',
      tipo: TipoNotificacion.values.firstWhere(
        (e) => e.toString() == data['tipo'],
        orElse: () => TipoNotificacion.sistema,
      ),
      titulo: data['titulo'] ?? '',
      mensaje: data['mensaje'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      leida: data['leida'] ?? false,
      datos: data['datos'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'trabajadorId': trabajadorId,
      'tipo': tipo.toString(),
      'titulo': titulo,
      'mensaje': mensaje,
      'timestamp': Timestamp.fromDate(timestamp),
      'leida': leida,
      'datos': datos,
    };
  }
}
