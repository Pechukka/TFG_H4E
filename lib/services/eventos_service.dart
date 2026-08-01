import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/evento.dart';
import '../core/constants.dart';

class EventosService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Evento>> getEventosTrabajador(String trabajadorId) {
    return _firestore
        .collection(AppConstants.colEventos)
        .where('trabajadoresIds', arrayContains: trabajadorId)
        .snapshots()
        .map((snapshot) {
          final eventos = snapshot.docs
              .map((doc) => Evento.fromFirestore(doc))
              .toList();
          // Ordenar por fechaInicio en Dart (evita índice compuesto en Firestore)
          eventos.sort((a, b) => a.fechaInicio.compareTo(b.fechaInicio));
          return eventos;
        });
  }

  // Fase 2 — feed del worker: eventos publicados y futuros.
  // where('estado') es un filtro de campo único (no requiere índice compuesto);
  // la fecha futura se filtra en Dart, según el patrón del proyecto.
  // Feed del worker en tiempo real: el stream re-emite cuando el admin crea/publica
  // (o despublica) un evento, así el feed se refresca solo sin recargar a mano.
  // Filtro de campo único (sin índice compuesto); la fecha futura se filtra en Dart.
  Stream<List<Evento>> getEventosPublicadosStream() {
    return _firestore
        .collection(AppConstants.colEventos)
        .where('estado', isEqualTo: 'publicado')
        .snapshots()
        .map(_procesarPublicados);
  }

  // Convierte el snapshot en la lista de eventos publicados y futuros, ordenada.
  List<Evento> _procesarPublicados(QuerySnapshot<Map<String, dynamic>> snapshot) {
    final ahora = DateTime.now();
    final eventos = snapshot.docs
        .map((doc) => Evento.fromFirestore(doc))
        .where((e) => e.fechaInicio.isAfter(ahora))
        .toList();
    eventos.sort((a, b) => a.fechaInicio.compareTo(b.fechaInicio));
    return eventos;
  }

  Future<Evento?> getEvento(String eventoId) async {
    final doc = await _firestore
        .collection(AppConstants.colEventos)
        .doc(eventoId)
        .get();

    if (doc.exists) {
      return Evento.fromFirestore(doc);
    }
    return null;
  }

  Future<List<Evento>> getEventosFuturos(String trabajadorId) async {
    final snapshot = await _firestore
        .collection(AppConstants.colEventos)
        .where('trabajadoresIds', arrayContains: trabajadorId)
        .get();

    final ahora = DateTime.now();
    final eventos = snapshot.docs
        .map((doc) => Evento.fromFirestore(doc))
        .where((e) => e.fechaInicio.isAfter(ahora))
        .toList();
    eventos.sort((a, b) => a.fechaInicio.compareTo(b.fechaInicio));
    return eventos.take(10).toList();
  }

  Future<List<Evento>> getEventosPorFecha(
    String trabajadorId,
    DateTime fecha,
  ) async {
    final inicio = DateTime(fecha.year, fecha.month, fecha.day);
    final fin = inicio.add(const Duration(days: 1));

    // Filtramos en Dart para evitar índice compuesto en Firestore
    final snapshot = await _firestore
        .collection(AppConstants.colEventos)
        .where('trabajadoresIds', arrayContains: trabajadorId)
        .get();

    return snapshot.docs
        .map((doc) => Evento.fromFirestore(doc))
        .where((e) => !e.fechaInicio.isBefore(inicio) && e.fechaInicio.isBefore(fin))
        .toList();
  }

  Future<Map<int, bool>> getEventosDelMes(
    String trabajadorId,
    int anio,
    int mes,
  ) async {
    final inicio = DateTime(anio, mes, 1);
    final fin = DateTime(anio, mes + 1, 1);

    // Filtramos en Dart para evitar índice compuesto en Firestore
    final snapshot = await _firestore
        .collection(AppConstants.colEventos)
        .where('trabajadoresIds', arrayContains: trabajadorId)
        .get();

    final Map<int, bool> diasConEventos = {};
    for (var doc in snapshot.docs) {
      final evento = Evento.fromFirestore(doc);
      if (!evento.fechaInicio.isBefore(inicio) && evento.fechaInicio.isBefore(fin)) {
        diasConEventos[evento.fechaInicio.day] = true;
      }
    }
    return diasConEventos;
  }

  Future<bool> estaTrabajadorAsignado(String eventoId, String trabajadorId) async {
    final evento = await getEvento(eventoId);
    return evento?.trabajadoresIds.contains(trabajadorId) ?? false;
  }

  // Teléfonos del equipo desde la subcolección eventos/{id}/equipo.
  // Si no hay permiso o el evento aún no está migrado, se devuelve vacío y el equipo
  // simplemente se muestra sin teléfono (no rompe la pantalla).
  Future<Map<String, String>> _telefonosEquipo(String eventoId) async {
    try {
      final snap = await _firestore
          .collection(AppConstants.colEventos)
          .doc(eventoId)
          .collection(AppConstants.subColEquipo)
          .get();
      return {
        for (final d in snap.docs) d.id: (d.data()['telefono'] as String?) ?? '',
      };
    } catch (_) {
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> getEquipoEvento(String eventoId) async {
    final evento = await getEvento(eventoId);
    if (evento == null) return [];

    // Camino normal: la info del equipo va denormalizada en el propio evento,
    // así el worker no necesita leer los docs de users (su regla se lo prohíbe).
    // El flag esAdmin lo pinta la pantalla como "Admin"; 'rol' es el rol real.
    if (evento.trabajadoresInfo.isNotEmpty) {
      // El teléfono NO está en trabajadoresInfo (se filtraría en el feed): vive en la
      // subcolección eventos/{id}/equipo, que solo pueden leer los miembros del evento.
      final telefonos = await _telefonosEquipo(eventoId);
      final equipo = <Map<String, dynamic>>[];
      for (var trabajadorId in evento.trabajadoresIds) {
        final info = evento.trabajadoresInfo[trabajadorId];
        if (info == null) continue;
        equipo.add({
          'id': trabajadorId,
          'nombre': info['nombre'] ?? '',
          'rol': info['rol'] ?? '',
          'esAdmin': info['esAdmin'] == true,
          'telefono': telefonos[trabajadorId] ?? '',
        });
      }
      return equipo;
    }

    // Fallback para eventos antiguos sin trabajadoresInfo: leer users uno a uno.
    // Con las reglas por rol, un worker solo puede leer su propio doc; si alguna
    // lectura es denegada, marcamos el fallo y lanzamos excepción para que la
    // pantalla avise ("No se pudo cargar el equipo") en vez de mostrar una lista
    // a medias. El admin sí puede leer todos, así que para él no falla.
    final equipo = <Map<String, dynamic>>[];
    bool huboFallo = false;
    for (var trabajadorId in evento.trabajadoresIds) {
      try {
        final userDoc = await _firestore
            .collection(AppConstants.colUsers)
            .doc(trabajadorId)
            .get();

        if (userDoc.exists) {
          final data = userDoc.data()!;
          final esAdmin = (data['rol'] as String?) == 'admin';
          equipo.add({
            'id': trabajadorId,
            'nombre': data['nombre'] ?? '',
            'rol': evento.trabajadoresRoles[trabajadorId] ?? '',
            'esAdmin': esAdmin,
            'telefono': data['telefono'] ?? '',
          });
        }
      } catch (_) {
        // Sin permiso para leer este doc (regla por rol).
        huboFallo = true;
      }
    }

    // Si no pudimos cargar el equipo completo, avisamos al llamante.
    if (huboFallo) {
      throw Exception('equipo_incompleto');
    }

    return equipo;
  }

  Future<String> crearEvento(Evento evento) async {
    final doc = await _firestore
        .collection(AppConstants.colEventos)
        .add(evento.toFirestore());
    return doc.id;
  }

  Future<void> actualizarEvento(String eventoId, Evento evento) async {
    await _firestore
        .collection(AppConstants.colEventos)
        .doc(eventoId)
        .update(evento.toFirestore());
  }

  Future<void> eliminarEvento(String eventoId) async {
    await _firestore
        .collection(AppConstants.colEventos)
        .doc(eventoId)
        .delete();
  }
}