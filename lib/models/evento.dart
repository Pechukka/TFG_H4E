import 'package:cloud_firestore/cloud_firestore.dart';

class Evento {
  final String id;
  final String titulo;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final String ubicacion;
  final String descripcion;
  final double cobroPorHora;
  final String rolAsignado;
  final List<String> trabajadoresIds;
  // Mapa que guarda el rol de cada trabajador: {uid: nombreRol}
  // Solo lo usa el panel de admin — la app worker lo ignora
  final Map<String, String> trabajadoresRoles;
  // Info denormalizada del equipo: {uid: {nombre, rol, esAdmin?}} — SIN teléfono
  // (un evento publicado es legible por cualquier worker en el feed; no se filtran
  // teléfonos ajenos). Se guarda aquí para que el worker vea el equipo sin leer la
  // colección users. Desde la Fase 2 significa los CONFIRMADOS por el admin.
  final Map<String, Map<String, dynamic>> trabajadoresInfo;
  // Fase 2: plazas objetivo por rol {rol: nº}. Ej. {'H4ndMontaje': 3, 'Coordinador': 1}
  final Map<String, int> plazasPorRol;
  // Fase 2: 'borrador' | 'publicado' | 'finalizado'. Vacío en eventos antiguos.
  final String estado;

  Evento({
    required this.id,
    required this.titulo,
    required this.fechaInicio,
    required this.fechaFin,
    required this.ubicacion,
    required this.descripcion,
    required this.cobroPorHora,
    required this.rolAsignado,
    this.trabajadoresIds = const [],
    this.trabajadoresRoles = const {},
    this.trabajadoresInfo = const {},
    this.plazasPorRol = const {},
    this.estado = '',
  });

  // Estado para la vista admin: los eventos antiguos sin estado se tratan como publicados.
  String get estadoVista => estado.isEmpty ? 'publicado' : estado;

  String get fechaFormateada {
    return '${fechaInicio.day}/${fechaInicio.month}/${fechaInicio.year}';
  }

  String get horaFormateada {
    return '${_formatHora(fechaInicio)} - ${_formatHora(fechaFin)}';
  }

  String _formatHora(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  int get duracionHoras {
    return fechaFin.difference(fechaInicio).inHours;
  }

  bool estaEnCurso() {
    final now = DateTime.now();
    return now.isAfter(fechaInicio) && now.isBefore(fechaFin);
  }

  // Firebase → Dart
  factory Evento.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Evento(
      id: doc.id,
      titulo: data['titulo'] ?? '',
      fechaInicio: (data['fechaInicio'] as Timestamp).toDate(),
      fechaFin: (data['fechaFin'] as Timestamp).toDate(),
      ubicacion: data['ubicacion'] ?? '',
      descripcion: data['descripcion'] ?? '',
      cobroPorHora: (data['cobroPorHora'] ?? 0).toDouble(),
      rolAsignado: data['rolAsignado'] ?? '',
      trabajadoresIds: List<String>.from(data['trabajadoresIds'] ?? []),
      trabajadoresRoles: Map<String, String>.from(data['trabajadoresRoles'] ?? {}),
      trabajadoresInfo: (data['trabajadoresInfo'] as Map<String, dynamic>? ?? {})
          .map((uid, info) => MapEntry(uid, Map<String, dynamic>.from(info as Map))),
      plazasPorRol: (data['plazasPorRol'] as Map<String, dynamic>? ?? {})
          .map((rol, n) => MapEntry(rol, (n as num).toInt())),
      estado: data['estado'] as String? ?? '',
    );
  }

  // Dart → Firebase
  Map<String, dynamic> toFirestore() {
    return {
      'titulo': titulo,
      'fechaInicio': Timestamp.fromDate(fechaInicio),
      'fechaFin': Timestamp.fromDate(fechaFin),
      'ubicacion': ubicacion,
      'descripcion': descripcion,
      'cobroPorHora': cobroPorHora,
      'rolAsignado': rolAsignado,
      'trabajadoresIds': trabajadoresIds,
      'trabajadoresRoles': trabajadoresRoles,
      'trabajadoresInfo': trabajadoresInfo,
      'plazasPorRol': plazasPorRol,
      'estado': estado,
    };
  }
}