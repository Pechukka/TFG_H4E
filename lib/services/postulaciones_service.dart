import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants.dart';
import '../models/postulacion.dart';

// Servicio de la colección `postulaciones` (Fase 2).
// La parte admin (confirmar/descartar) vive aquí; la parte worker se añade en 2B.
class PostulacionesService {
  static final _firestore = FirebaseFirestore.instance;

  // Todas las postulaciones de un evento (el estado se filtra en Dart para no
  // necesitar índice compuesto). Solo el admin lo consulta.
  static Stream<List<Postulacion>> postulacionesDeEventoStream(String eventoId) {
    return _firestore
        .collection(AppConstants.colPostulaciones)
        .where('eventoId', isEqualTo: eventoId)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Postulacion.fromFirestore(d)).toList());
  }

  // El admin confirma a un worker: marca la postulación como confirmada y lo añade
  // a los confirmados del evento (trabajadoresIds / trabajadoresRoles / trabajadoresInfo).
  // Se usan rutas de campo con punto y arrayUnion para no pisar confirmaciones en paralelo.
  // Las dos escrituras van en un WriteBatch: o se aplican ambas o ninguna (atómico).
  static Future<void> confirmar({
    required String postulacionId,
    required String eventoId,
    required String trabajadorId,
    required String rol,
    required String nombre,
    required String telefono,
  }) async {
    final eventoRef =
        _firestore.collection(AppConstants.colEventos).doc(eventoId);
    final postulacionRef =
        _firestore.collection(AppConstants.colPostulaciones).doc(postulacionId);

    final batch = _firestore.batch();
    batch.update(eventoRef, {
      'trabajadoresIds': FieldValue.arrayUnion([trabajadorId]),
      'trabajadoresRoles.$trabajadorId': rol,
      'trabajadoresInfo.$trabajadorId': {
        'nombre': nombre,
        'telefono': telefono,
        'rol': rol,
      },
    });
    batch.update(postulacionRef, {'estado': Postulacion.confirmado});
    await batch.commit();
  }

  // El admin descarta una postulación (no añade al worker al evento).
  static Future<void> descartar(String postulacionId) async {
    await _firestore
        .collection(AppConstants.colPostulaciones)
        .doc(postulacionId)
        .update({'estado': Postulacion.descartado});
  }

  // ─── Lado worker (2B) ───────────────────────────────────────────────────────

  // Todas las postulaciones del worker (se filtra por estado en Dart).
  static Future<List<Postulacion>> misPostulaciones(String trabajadorId) async {
    final snap = await _firestore
        .collection(AppConstants.colPostulaciones)
        .where('trabajadorId', isEqualTo: trabajadorId)
        .get();
    return snap.docs.map((d) => Postulacion.fromFirestore(d)).toList();
  }

  // Stream de las postulaciones del worker (para "Mis postulaciones").
  static Stream<List<Postulacion>> misPostulacionesStream(String trabajadorId) {
    return _firestore
        .collection(AppConstants.colPostulaciones)
        .where('trabajadorId', isEqualTo: trabajadorId)
        .snapshots()
        .map((s) => s.docs.map((d) => Postulacion.fromFirestore(d)).toList());
  }

  // El worker responde a una carta del feed:
  //   swipe derecha → estado 'pendiente' (con el rol elegido)
  //   swipe izquierda → estado 'rechazado_por_worker' (rol vacío)
  static Future<void> responder({
    required String eventoId,
    required String trabajadorId,
    required String rol,
    required String estado,
  }) async {
    await _firestore.collection(AppConstants.colPostulaciones).add({
      'eventoId': eventoId,
      'trabajadorId': trabajadorId,
      'rol': rol,
      'estado': estado,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
