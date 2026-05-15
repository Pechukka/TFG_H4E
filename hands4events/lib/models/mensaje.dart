import 'package:cloud_firestore/cloud_firestore.dart';

class Mensaje {
  final String id;
  final String eventoId;
  final String remitenteId;
  final String remitenteNombre;
  final String texto;
  final DateTime timestamp;
  final bool leido;
  final String? imagenUrl;
  final String tipo; // 'texto', 'imagen', 'ubicacion'
  final bool editado;
  final String? replyToId;
  final String? replyToNombre;
  final String? replyToTexto;

  const Mensaje({
    required this.id,
    required this.eventoId,
    required this.remitenteId,
    required this.remitenteNombre,
    required this.texto,
    required this.timestamp,
    this.leido = false,
    this.imagenUrl,
    this.tipo = 'texto',
    this.editado = false,
    this.replyToId,
    this.replyToNombre,
    this.replyToTexto,
  });

  String get horaFormateada {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  bool tieneImagen() => imagenUrl != null && imagenUrl!.isNotEmpty;
  bool tieneReply() => replyToId != null && replyToId!.isNotEmpty;

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
      tipo: data['tipo'] as String? ?? 'texto',
      editado: data['editado'] as bool? ?? false,
      replyToId: data['replyToId'] as String?,
      replyToNombre: data['replyToNombre'] as String?,
      replyToTexto: data['replyToTexto'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'eventoId': eventoId,
      'remitenteId': remitenteId,
      'remitenteNombre': remitenteNombre,
      'texto': texto,
      'timestamp': Timestamp.fromDate(timestamp),
      'leido': leido,
      'imagenUrl': imagenUrl,
      'tipo': tipo,
      'editado': editado,
      if (replyToId != null) 'replyToId': replyToId,
      if (replyToNombre != null) 'replyToNombre': replyToNombre,
      if (replyToTexto != null) 'replyToTexto': replyToTexto,
    };
  }

  Mensaje copyWith({
    String? id,
    String? eventoId,
    String? remitenteId,
    String? remitenteNombre,
    String? texto,
    DateTime? timestamp,
    bool? leido,
    String? imagenUrl,
    String? tipo,
    bool? editado,
    String? replyToId,
    String? replyToNombre,
    String? replyToTexto,
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
      tipo: tipo ?? this.tipo,
      editado: editado ?? this.editado,
      replyToId: replyToId ?? this.replyToId,
      replyToNombre: replyToNombre ?? this.replyToNombre,
      replyToTexto: replyToTexto ?? this.replyToTexto,
    );
  }
}
