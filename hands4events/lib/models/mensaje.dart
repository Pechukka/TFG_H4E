import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo de Mensaje de Chat
/// Mensajes dentro del chat de un evento específico
class Mensaje {
  final String id;
  final String eventoId;
  final String remitenteId;
  final String remitenteNombre;
  final String texto;
  final DateTime timestamp;
  final bool leido;
  final String? imagenUrl; // URL si el mensaje contiene imagen

  const Mensaje({
    required this.id,
    required this.eventoId,
    required this.remitenteId,
    required this.remitenteNombre,
    required this.texto,
    required this.timestamp,
    this.leido = false,
    this.imagenUrl,
  });

  // Getters
  String get horaFormateada {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  String get fechaFormateada {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      return 'Hoy ${horaFormateada}';
    } else if (difference.inDays == 1) {
      return 'Ayer ${horaFormateada}';
    } else if (difference.inDays < 7) {
      const dias = ['', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
      return '${dias[timestamp.weekday]} ${horaFormateada}';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year} ${horaFormateada}';
    }
  }

  bool tieneImagen() => imagenUrl != null && imagenUrl!.isNotEmpty;

  // Firebase → Dart
  factory Mensaje.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return Mensaje(
      id: doc.id,
      eventoId: data['eventoId'] ?? '',
      remitenteId: data['remitenteId'] ?? '',
      remitenteNombre: data['remitenteNombre'] ?? '',
      texto: data['texto'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      leido: data['leido'] ?? false,
      imagenUrl: data['imagenUrl'] as String?,
    );
  }

  // Dart → Firebase
  Map<String, dynamic> toFirestore() {
    return {
      'eventoId': eventoId,
      'remitenteId': remitenteId,
      'remitenteNombre': remitenteNombre,
      'texto': texto,
      'timestamp': Timestamp.fromDate(timestamp),
      'leido': leido,
      'imagenUrl': imagenUrl,
    };
  }

  // CopyWith
  Mensaje copyWith({
    String? id,
    String? eventoId,
    String? remitenteId,
    String? remitenteNombre,
    String? texto,
    DateTime? timestamp,
    bool? leido,
    String? imagenUrl,
  }) {
    return Mensaje(
      id: id ?? this.id,
      eventoId: eventoId ?? this.eventoId,
      remitenteId: remitenteId ?? this.remitenteId,
      remitenteNombre: remitenteNombre ?? this.remitenteNombre,
      texto: texto ?? this.texto,
      timestamp: timestamp ?? this.timestamp,
      leido: leido ?? this.leido,
      imagenUrl: imagenUrl ?? this.imagenUrl,
    );
  }

  // Marcar como leído
  Mensaje marcarLeido() {
    return copyWith(leido: true);
  }
}