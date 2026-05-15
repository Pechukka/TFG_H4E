import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/mensaje.dart';
import '../core/constants.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Mensaje>> getMensajesEvento(String eventoId) {
    return _firestore
        .collection(AppConstants.colMensajes)
        .where('eventoId', isEqualTo: eventoId)
        .snapshots()
        .map((snapshot) {
      final mensajes =
          snapshot.docs.map((doc) => Mensaje.fromFirestore(doc)).toList();
      mensajes.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return mensajes;
    });
  }

  Future<void> enviarMensaje({
    required String eventoId,
    required String remitenteId,
    required String remitenteNombre,
    required String texto,
    String? replyToId,
    String? replyToNombre,
    String? replyToTexto,
  }) async {
    final mensaje = Mensaje(
      id: '',
      eventoId: eventoId,
      remitenteId: remitenteId,
      remitenteNombre: remitenteNombre,
      texto: texto.trim(),
      timestamp: DateTime.now(),
      replyToId: replyToId,
      replyToNombre: replyToNombre,
      replyToTexto: replyToTexto,
    );
    await _firestore
        .collection(AppConstants.colMensajes)
        .add(mensaje.toFirestore());
  }

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
      tipo: 'imagen',
      timestamp: DateTime.now(),
    );
    await _firestore
        .collection(AppConstants.colMensajes)
        .add(mensaje.toFirestore());
  }

  Future<void> enviarUbicacion({
    required String eventoId,
    required String remitenteId,
    required String remitenteNombre,
    required double lat,
    required double lng,
  }) async {
    final mapsUrl = 'https://www.google.com/maps?q=$lat,$lng';
    final mensaje = Mensaje(
      id: '',
      eventoId: eventoId,
      remitenteId: remitenteId,
      remitenteNombre: remitenteNombre,
      texto: mapsUrl,
      timestamp: DateTime.now(),
      tipo: 'ubicacion',
    );
    await _firestore
        .collection(AppConstants.colMensajes)
        .add(mensaje.toFirestore());
  }

  Future<void> editarMensaje(String mensajeId, String nuevoTexto) async {
    await _firestore
        .collection(AppConstants.colMensajes)
        .doc(mensajeId)
        .update({
      'texto': nuevoTexto.trim(),
      'editado': true,
    });
  }

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

  Future<int> contarMensajesNoLeidos(String eventoId, String userId) async {
    final snapshot = await _firestore
        .collection(AppConstants.colMensajes)
        .where('eventoId', isEqualTo: eventoId)
        .where('remitenteId', isNotEqualTo: userId)
        .where('leido', isEqualTo: false)
        .get();
    return snapshot.docs.length;
  }

  Future<void> eliminarMensaje(String mensajeId) async {
    await _firestore
        .collection(AppConstants.colMensajes)
        .doc(mensajeId)
        .delete();
  }
}
