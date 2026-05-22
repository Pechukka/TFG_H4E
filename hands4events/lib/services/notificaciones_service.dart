import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notificacion.dart';

class NotificacionesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Notificacion>> getNotificaciones(String trabajadorId) {
    return _firestore
        .collection('notificaciones')
        .where('trabajadorId', isEqualTo: trabajadorId)
        .snapshots()
        .map((snapshot) {
          final lista = snapshot.docs
              .map((doc) => Notificacion.fromFirestore(doc))
              .toList();
          lista.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return lista.take(30).toList();
        });
  }

  Future<void> marcarLeida(String notificacionId) async {
    await _firestore
        .collection('notificaciones')
        .doc(notificacionId)
        .update({'leida': true});
  }

  Future<void> eliminarNotificacion(String notificacionId) async {
    await _firestore
        .collection('notificaciones')
        .doc(notificacionId)
        .delete();
  }

  static Future<void> enviarNotificacion({
    required String trabajadorId,
    required TipoNotificacion tipo,
    required String titulo,
    required String mensaje,
    Map<String, dynamic>? datos,
  }) async {
    await FirebaseFirestore.instance.collection('notificaciones').add({
      'trabajadorId': trabajadorId,
      'tipo': tipo.toString(),
      'titulo': titulo,
      'mensaje': mensaje,
      'timestamp': FieldValue.serverTimestamp(),
      'leida': false,
      'datos': datos,
    });
  }
}
