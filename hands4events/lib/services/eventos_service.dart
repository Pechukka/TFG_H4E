import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/evento.dart';
import '../core/constants.dart';

/// Servicio de Eventos
/// CRUD de eventos y consultas relacionadas
class EventosService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// OBTENER EVENTOS DE UN TRABAJADOR
  Stream<List<Evento>> getEventosTrabajador(String trabajadorId) {
    return _firestore
        .collection(AppConstants.colEventos)
        .where('trabajadoresIds', arrayContains: trabajadorId)
        .orderBy('fechaInicio', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Evento.fromFirestore(doc))
            .toList());
  }

  /// OBTENER UN EVENTO POR ID
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

  /// OBTENER EVENTOS FUTUROS
  Future<List<Evento>> getEventosFuturos(String trabajadorId) async {
    final now = Timestamp.now();
    
    final snapshot = await _firestore
        .collection(AppConstants.colEventos)
        .where('trabajadoresIds', arrayContains: trabajadorId)
        .where('fechaInicio', isGreaterThan: now)
        .orderBy('fechaInicio', descending: false)
        .limit(10)
        .get();

    return snapshot.docs
        .map((doc) => Evento.fromFirestore(doc))
        .toList();
  }

  /// OBTENER EVENTOS POR FECHA
  Future<List<Evento>> getEventosPorFecha(
    String trabajadorId,
    DateTime fecha,
  ) async {
    final inicio = DateTime(fecha.year, fecha.month, fecha.day);
    final fin = inicio.add(const Duration(days: 1));

    final snapshot = await _firestore
        .collection(AppConstants.colEventos)
        .where('trabajadoresIds', arrayContains: trabajadorId)
        .where('fechaInicio', isGreaterThanOrEqualTo: Timestamp.fromDate(inicio))
        .where('fechaInicio', isLessThan: Timestamp.fromDate(fin))
        .get();

    return snapshot.docs
        .map((doc) => Evento.fromFirestore(doc))
        .toList();
  }

  /// OBTENER EVENTOS DEL MES
  Future<Map<int, bool>> getEventosDelMes(
    String trabajadorId,
    int anio,
    int mes,
  ) async {
    final inicio = DateTime(anio, mes, 1);
    final fin = DateTime(anio, mes + 1, 1);

    final snapshot = await _firestore
        .collection(AppConstants.colEventos)
        .where('trabajadoresIds', arrayContains: trabajadorId)
        .where('fechaInicio', isGreaterThanOrEqualTo: Timestamp.fromDate(inicio))
        .where('fechaInicio', isLessThan: Timestamp.fromDate(fin))
        .get();

    // Mapa de día -> tiene evento
    final Map<int, bool> diasConEventos = {};
    for (var doc in snapshot.docs) {
      final evento = Evento.fromFirestore(doc);
      diasConEventos[evento.fechaInicio.day] = true;
    }

    return diasConEventos;
  }

  /// VERIFICAR SI TRABAJADOR ESTÁ ASIGNADO
  Future<bool> estaTrabajadorAsignado(String eventoId, String trabajadorId) async {
    final evento = await getEvento(eventoId);
    return evento?.trabajadoresIds.contains(trabajadorId) ?? false;
  }

  /// OBTENER EQUIPO DEL EVENTO
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
        equipo.add({
          'id': trabajadorId,
          'nombre': data['nombre'] ?? '',
          'telefono': data['telefono'] ?? '',
          'rol': data['rolEvento'] ?? evento.rolAsignado,
        });
      }
    }

    return equipo;
  }

  /// CREAR EVENTO (solo para admin - futuro)
  Future<String> crearEvento(Evento evento) async {
    final doc = await _firestore
        .collection(AppConstants.colEventos)
        .add(evento.toFirestore());
    return doc.id;
  }

  /// ACTUALIZAR EVENTO (solo para admin - futuro)
  Future<void> actualizarEvento(String eventoId, Evento evento) async {
    await _firestore
        .collection(AppConstants.colEventos)
        .doc(eventoId)
        .update(evento.toFirestore());
  }

  /// ELIMINAR EVENTO (solo para admin - futuro)
  Future<void> eliminarEvento(String eventoId) async {
    await _firestore
        .collection(AppConstants.colEventos)
        .doc(eventoId)
        .delete();
  }
}