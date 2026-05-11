import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/mensaje.dart';
import '../core/constants.dart';

/// Servicio de Chat
/// Mensajería en tiempo real por evento
class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// STREAM DE MENSAJES DE UN EVENTO
  Stream<List<Mensaje>> getMensajesEvento(String eventoId) {
    return _firestore
        .collection(AppConstants.colMensajes)
        .where('eventoId', isEqualTo: eventoId)
        .snapshots()
        .map((snapshot) {
          final mensajes = snapshot.docs
              .map((doc) => Mensaje.fromFirestore(doc))
              .toList();
          // Ordenar por timestamp en Dart (evita índice compuesto en Firestore)
          mensajes.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          return mensajes;
        });
  }

  /// ENVIAR MENSAJE
  Future<void> enviarMensaje({
    required String eventoId,
    required String remitenteId,
    required String remitenteNombre,
    required String texto,
  }) async {
    final mensaje = Mensaje(
      id: '',
      eventoId: eventoId,
      remitenteId: remitenteId,
      remitenteNombre: remitenteNombre,
      texto: texto.trim(),
      timestamp: DateTime.now(),
    );

    await _firestore
        .collection(AppConstants.colMensajes)
        .add(mensaje.toFirestore());
  }

  /// ENVIAR MENSAJE CON IMAGEN
  Future<void> enviarMensajeConImagen({
    required String eventoId,
    required String remitenteId,
    required String remitenteNombre,
    required String imagenUrl,
    String? texto,
  }) async {
    final mensaje = Mensaje(
      id: '',
      eventoId: eventoId,
      remitenteId: remitenteId,
      remitenteNombre: remitenteNombre,
      texto: texto?.trim() ?? '',
      imagenUrl: imagenUrl,
      timestamp: DateTime.now(),
    );

    await _firestore
        .collection(AppConstants.colMensajes)
        .add(mensaje.toFirestore());
  }

  /// MARCAR MENSAJES COMO LEÍDOS
  Future<void> marcarMensajesLeidos(String eventoId, String userId) async {
    final snapshot = await _firestore
        .collection(AppConstants.colMensajes)
        .where('eventoId', isEqualTo: eventoId)
        .where('remitenteId', isNotEqualTo: userId)
        .where('leido', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (var doc in snapshot.docs) {
      batch.update(doc.reference, {'leido': true});
    }
    await batch.commit();
  }

  /// CONTAR MENSAJES NO LEÍDOS
  Future<int> contarMensajesNoLeidos(String eventoId, String userId) async {
    final snapshot = await _firestore
        .collection(AppConstants.colMensajes)
        .where('eventoId', isEqualTo: eventoId)
        .where('remitenteId', isNotEqualTo: userId)
        .where('leido', isEqualTo: false)
        .get();

    return snapshot.docs.length;
  }

  /// ELIMINAR MENSAJE
  Future<void> eliminarMensaje(String mensajeId) async {
    await _firestore
        .collection(AppConstants.colMensajes)
        .doc(mensajeId)
        .delete();
  }
}