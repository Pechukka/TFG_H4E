import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants.dart';
import '../models/notificacion.dart';
import '../models/postulacion.dart';

// Fase 5: se lanza al intentar confirmar/añadir a un rol que ya está lleno.
class RolCompletoException implements Exception {
  final String rol;
  RolCompletoException(this.rol);
}

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
  //
  // Fase 5:
  //  - CUPO DURO: si el rol ya está lleno (confirmados == plazas), NO confirma y lanza
  //    RolCompletoException. Para meter uno más hay que editar el evento y subir plazas.
  //  - AUTO-ACTIVACIÓN: si al añadir a este worker el equipo queda completo (todos los
  //    roles cubiertos) y el evento estaba 'publicado', pasa a 'activo' en el MISMO batch.
  //
  // Todo va en un WriteBatch: confirmación + notificación + (posible) activación son
  // atómicas (o se aplican todas o ninguna). Se lee el evento antes para calcular cupo
  // y cobertura (sin la lectura no se puede validar el cupo en servidor de forma segura).
  static Future<void> confirmar({
    required String postulacionId,
    required String eventoId,
    required String trabajadorId,
    required String rol,
    required String nombre,
    required String telefono,
    required String tituloEvento,
  }) async {
    final eventoRef =
        _firestore.collection(AppConstants.colEventos).doc(eventoId);
    final postulacionRef =
        _firestore.collection(AppConstants.colPostulaciones).doc(postulacionId);

    final snap = await eventoRef.get();
    final data = snap.data() ?? {};
    final plazas = (data['plazasPorRol'] as Map<String, dynamic>? ?? {})
        .map((k, v) => MapEntry(k, (v as num).toInt()));
    final roles = Map<String, String>.from(data['trabajadoresRoles'] ?? {});
    final creadoPor = data['creadoPor'] as String?;
    final estadoActual = data['estado'] as String? ?? '';

    // Confirmados por rol actuales (sin contar al admin creador).
    final confirmadosPorRol = <String, int>{};
    roles.forEach((uid, r) {
      if (uid == creadoPor) return;
      confirmadosPorRol[r] = (confirmadosPorRol[r] ?? 0) + 1;
    });

    // CUPO DURO: no se puede confirmar a un rol lleno (o sin plaza definida).
    if ((confirmadosPorRol[rol] ?? 0) >= (plazas[rol] ?? 0)) {
      throw RolCompletoException(rol);
    }

    // Cobertura tras añadir a este worker: ¿queda el equipo completo?
    confirmadosPorRol[rol] = (confirmadosPorRol[rol] ?? 0) + 1;
    final completo = plazas.isNotEmpty &&
        plazas.entries.every((e) => (confirmadosPorRol[e.key] ?? 0) >= e.value);

    final batch = _firestore.batch();

    final eventoUpdates = <String, dynamic>{
      'trabajadoresIds': FieldValue.arrayUnion([trabajadorId]),
      'trabajadoresRoles.$trabajadorId': rol,
      // trabajadoresInfo NO guarda teléfono (evita filtrarlo en el feed).
      'trabajadoresInfo.$trabajadorId': {
        'nombre': nombre,
        'rol': rol,
      },
    };
    // Auto-activación: equipo completo y el evento estaba publicado → grupo creado.
    if (completo && estadoActual == 'publicado') {
      eventoUpdates['estado'] = 'activo';
    }
    batch.update(eventoRef, eventoUpdates);
    batch.update(postulacionRef, {'estado': Postulacion.confirmado});

    // Subcolección equipo: el teléfono vive aquí (solo lo leen los miembros del evento).
    batch.set(eventoRef.collection(AppConstants.subColEquipo).doc(trabajadorId), {
      'nombre': nombre,
      'rol': rol,
      'telefono': telefono,
    });

    // Notificación al worker, en el MISMO batch. La Cloud Function onNotificacionCreada
    // la convierte en push. Campos del esquema existente (tipo enum + `timestamp`).
    final titulo = tituloEvento.isEmpty ? 'el evento' : tituloEvento;
    final notificacionRef =
        _firestore.collection(AppConstants.colNotificaciones).doc();
    batch.set(notificacionRef, {
      'trabajadorId': trabajadorId,
      'tipo': TipoNotificacion.confirmacion.toString(),
      'titulo': 'Te han confirmado',
      'mensaje': 'Estás confirmado en $titulo como $rol',
      'timestamp': FieldValue.serverTimestamp(),
      'leida': false,
      'datos': {'eventoId': eventoId, 'tituloEvento': titulo},
    });

    await batch.commit();
  }

  // Fase 5C: el admin añade a un worker directamente al evento (estilo grupo de
  // WhatsApp), respetando el cupo. NO crea postulación. Lanza RolCompletoException si
  // el rol ya está lleno.
  //
  // Igual que confirmar(): si al añadir el equipo queda completo y el evento estaba
  // 'publicado', auto-activa en la misma escritura (el disparador es "el equipo se
  // completó", no la vía por la que se completó).
  static Future<void> anadirIntegrante({
    required String eventoId,
    required String trabajadorId,
    required String rol,
    required String nombre,
    required String telefono,
  }) async {
    final eventoRef =
        _firestore.collection(AppConstants.colEventos).doc(eventoId);
    final snap = await eventoRef.get();
    final data = snap.data() ?? {};
    final plazas = (data['plazasPorRol'] as Map<String, dynamic>? ?? {})
        .map((k, v) => MapEntry(k, (v as num).toInt()));
    final roles = Map<String, String>.from(data['trabajadoresRoles'] ?? {});
    final creadoPor = data['creadoPor'] as String?;
    final estadoActual = data['estado'] as String? ?? '';

    if (roles.containsKey(trabajadorId)) return; // ya es miembro: nada que hacer

    // Confirmados por rol actuales (sin el admin creador).
    final confirmadosPorRol = <String, int>{};
    roles.forEach((uid, r) {
      if (uid == creadoPor) return;
      confirmadosPorRol[r] = (confirmadosPorRol[r] ?? 0) + 1;
    });

    // CUPO DURO.
    if ((confirmadosPorRol[rol] ?? 0) >= (plazas[rol] ?? 0)) {
      throw RolCompletoException(rol);
    }

    // Cobertura tras añadir a este worker: ¿queda el equipo completo?
    confirmadosPorRol[rol] = (confirmadosPorRol[rol] ?? 0) + 1;
    final completo = plazas.isNotEmpty &&
        plazas.entries.every((e) => (confirmadosPorRol[e.key] ?? 0) >= e.value);

    final updates = <String, dynamic>{
      'trabajadoresIds': FieldValue.arrayUnion([trabajadorId]),
      'trabajadoresRoles.$trabajadorId': rol,
      'trabajadoresInfo.$trabajadorId': {'nombre': nombre, 'rol': rol},
    };
    if (completo && estadoActual == 'publicado') {
      updates['estado'] = 'activo';
    }

    // Evento + subcolección equipo (con teléfono) en un batch.
    final batch = _firestore.batch();
    batch.update(eventoRef, updates);
    batch.set(eventoRef.collection(AppConstants.subColEquipo).doc(trabajadorId), {
      'nombre': nombre,
      'rol': rol,
      'telefono': telefono,
    });
    await batch.commit();
  }

  // Fase 5C: el admin quita a un integrante del evento. Lo saca de
  // trabajadoresIds/Roles/Info y, si tenía postulación en este evento, la pasa a
  // 'descartado'. Libera la plaza. Avisa al worker con una notificación (que la Cloud
  // Function convierte en push). Todo en un batch (atómico).
  static Future<void> quitarIntegrante({
    required String eventoId,
    required String trabajadorId,
    required String tituloEvento,
  }) async {
    final eventoRef =
        _firestore.collection(AppConstants.colEventos).doc(eventoId);

    // Postulaciones del worker en este evento (query de campo único + filtro en Dart).
    final postSnap = await _firestore
        .collection(AppConstants.colPostulaciones)
        .where('trabajadorId', isEqualTo: trabajadorId)
        .get();
    final delEvento =
        postSnap.docs.where((d) => d.data()['eventoId'] == eventoId).toList();

    final batch = _firestore.batch();
    batch.update(eventoRef, {
      'trabajadoresIds': FieldValue.arrayRemove([trabajadorId]),
      'trabajadoresRoles.$trabajadorId': FieldValue.delete(),
      'trabajadoresInfo.$trabajadorId': FieldValue.delete(),
    });
    // Y su ficha de la subcolección equipo (con el teléfono).
    batch.delete(
        eventoRef.collection(AppConstants.subColEquipo).doc(trabajadorId));
    for (final d in delEvento) {
      batch.update(d.reference, {'estado': Postulacion.descartado});
    }

    // Aviso al worker de que ya no está en el evento (mismo batch → atómico).
    final titulo = tituloEvento.isEmpty ? 'el evento' : tituloEvento;
    final notificacionRef =
        _firestore.collection(AppConstants.colNotificaciones).doc();
    batch.set(notificacionRef, {
      'trabajadorId': trabajadorId,
      'tipo': TipoNotificacion.cambioEvento.toString(),
      'titulo': 'Ya no estás en el evento',
      'mensaje': titulo,
      'timestamp': FieldValue.serverTimestamp(),
      'leida': false,
      'datos': {'eventoId': eventoId, 'tituloEvento': titulo},
    });

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
