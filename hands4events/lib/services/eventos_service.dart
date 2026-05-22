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

  Future<List<Map<String, dynamic>>> getEquipoEvento(String eventoId) async {
    final evento = await getEvento(eventoId);
    if (evento == null) return [];

    final equipo = <Map<String, dynamic>>[];
    
    for (var trabajadorId in evento.trabajadoresIds) {
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
          'telefono': data['telefono'] ?? '',
          'rol': esAdmin ? 'Admin' : (evento.trabajadoresRoles[trabajadorId] ?? ''),
        });
      }
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