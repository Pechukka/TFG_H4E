const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

const db = admin.firestore();

// Al borrar un usuario de Firestore, se elimina también de Firebase Auth
// para que no pueda volver a iniciar sesión
exports.onWorkerDeleted = functions.firestore
  .document('users/{uid}')
  .onDelete(async (snap, context) => {
    const uid = context.params.uid;

    try {
      await admin.auth().deleteUser(uid);
      console.log('Usuario Auth eliminado:', uid);
    } catch (e) {
      console.error('Error al eliminar usuario Auth', uid, ':', e.message);
    }

    // Quitar al trabajador de los eventos en los que estaba asignado. Se limpian TODAS
    // las denormalizaciones para no dejar huérfanos: trabajadoresIds, trabajadoresRoles,
    // trabajadoresInfo (equipo que ve el worker) y su ficha en la subcolección `equipo`
    // (que contiene el teléfono).
    const eventosSnap = await db.collection('eventos')
      .where('trabajadoresIds', 'array-contains', uid)
      .get();

    if (!eventosSnap.empty) {
      const batch = db.batch();
      for (const eventoDoc of eventosSnap.docs) {
        const data = eventoDoc.data();
        const ids = (data.trabajadoresIds || []).filter(id => id !== uid);
        const roles = Object.assign({}, data.trabajadoresRoles || {});
        delete roles[uid];
        const info = Object.assign({}, data.trabajadoresInfo || {});
        delete info[uid];
        batch.update(eventoDoc.ref, {
          trabajadoresIds: ids,
          trabajadoresRoles: roles,
          trabajadoresInfo: info,
        });
        batch.delete(eventoDoc.ref.collection('equipo').doc(uid));
      }
      await batch.commit();
      console.log('Trabajador', uid, 'eliminado de', eventosSnap.size, 'eventos');
    }

    // Borrar sus postulaciones (pendientes/confirmadas/rechazadas) para que no queden
    // colgando en el panel del admin ni en el feed.
    const postSnap = await db.collection('postulaciones')
      .where('trabajadorId', '==', uid)
      .get();
    if (!postSnap.empty) {
      const batch = db.batch();
      postSnap.docs.forEach((d) => batch.delete(d.ref));
      await batch.commit();
      console.log('Borradas', postSnap.size, 'postulaciones de', uid);
    }

    return null;
  });

// Manda la notificación push (FCM) cuando se crea un doc en 'notificaciones'
// Funciona aunque la app esté cerrada
exports.onNotificacionCreada = functions.firestore
  .document('notificaciones/{notifId}')
  .onCreate(async (snap) => {
    const data = snap.data();
    const trabajadorId = data.trabajadorId;
    if (!trabajadorId) return null;

    const userDoc = await db.collection('users').doc(trabajadorId).get();
    if (!userDoc.exists) return null;

    const userData = userDoc.data();
    const fcmToken = userData.fcmToken;
    if (!fcmToken) return null;

    // Respetar preferencia del usuario: no enviar si desactivadas
    if (userData.notifActivadas === false) return null;

    try {
      await admin.messaging().send({
        token: fcmToken,
        notification: {
          title: data.titulo || '',
          body: data.mensaje || '',
        },
        data: {
          tipo: data.tipo || '',
          eventoId: (data.datos && data.datos.eventoId) || '',
          tituloEvento: (data.datos && data.datos.tituloEvento) || '',
        },
        android: {
          notification: {
            channelId: 'hands4events_notificaciones',
            priority: 'high',
            sound: 'default',
          },
        },
        apns: {
          payload: {
            aps: { sound: 'default', badge: 1 },
          },
        },
      });
    } catch (e) {
      console.error('Error al enviar FCM a', trabajadorId, ':', e.message);
    }
    return null;
  });

// Crea una notificación en Firestore para cada miembro del evento
// cuando alguien envía un mensaje al chat (excepto el propio autor).
// El chat NO es una subcolección: vive en la colección top-level 'mensajes',
// con los campos `eventoId` y `remitenteId` (ver lib/models/mensaje.dart).
exports.onMensajeCreado = functions.firestore
  .document('mensajes/{mensajeId}')
  .onCreate(async (snap) => {
    const mensaje = snap.data();
    const eventoId = mensaje.eventoId;
    const autorId = mensaje.remitenteId;
    if (!autorId || !eventoId) return null;

    const eventoDoc = await db.collection('eventos').doc(eventoId).get();
    if (!eventoDoc.exists) return null;

    const evento = eventoDoc.data();
    const trabajadoresIds = evento.trabajadoresIds || [];
    const destinatarios = trabajadoresIds.filter((uid) => uid !== autorId);

    const texto = mensaje.texto || '';
    const preview = texto.length > 70 ? texto.substring(0, 70) + '...' : texto;

    const batch = db.batch();
    for (const uid of destinatarios) {
      const userDoc = await db.collection('users').doc(uid).get();
      if (!userDoc.exists || userDoc.data().rol !== 'worker') continue;

      const ref = db.collection('notificaciones').doc();
      batch.set(ref, {
        trabajadorId: uid,
        tipo: 'TipoNotificacion.nuevoMensaje',
        titulo: `Mensaje en ${evento.titulo}`,
        mensaje: preview,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        leida: false,
        datos: { eventoId, tituloEvento: evento.titulo },
      });
    }
    await batch.commit();
    return null;
  });

// Recordatorio automático: avisa 24 h antes del evento, a las 9:00 hora Madrid
exports.recordatoriosEventos = functions.pubsub
  .schedule('every day 09:00')
  .timeZone('Europe/Madrid')
  .onRun(async () => {
    const ahora = new Date();
    const en24h = new Date(ahora.getTime() + 24 * 60 * 60 * 1000);
    const en25h = new Date(ahora.getTime() + 25 * 60 * 60 * 1000);

    const eventosSnap = await db.collection('eventos')
      .where('fechaInicio', '>=', en24h)
      .where('fechaInicio', '<', en25h)
      .get();

    for (const eventoDoc of eventosSnap.docs) {
      const evento = eventoDoc.data();
      const trabajadoresIds = evento.trabajadoresIds || [];

      for (const uid of trabajadoresIds) {
        const userDoc = await db.collection('users').doc(uid).get();
        if (!userDoc.exists || userDoc.data().rol !== 'worker') continue;

        await db.collection('notificaciones').add({
          trabajadorId: uid,
          tipo: 'TipoNotificacion.recordatorio',
          titulo: 'Recordatorio de evento',
          mensaje: `${evento.titulo} es mañana`,
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
          leida: false,
          datos: { eventoId: eventoDoc.id, tituloEvento: evento.titulo },
        });
      }
    }
    return null;
  });

// Limpia mensajes de chats de eventos terminados hace más de 45 días
exports.limpiarMensajesAntiguos = functions.pubsub
  .schedule('every 24 hours')
  .onRun(async () => {
    const hace45dias = new Date();
    hace45dias.setDate(hace45dias.getDate() - 45);

    const eventosSnap = await db.collection('eventos')
      .where('fechaFin', '<', hace45dias)
      .get();

    for (const eventoDoc of eventosSnap.docs) {
      // El chat vive en la colección top-level 'mensajes' (campo eventoId),
      // no en una subcolección del evento.
      const mensajesSnap = await db
        .collection('mensajes')
        .where('eventoId', '==', eventoDoc.id)
        .get();
      if (mensajesSnap.empty) continue;

      // Firestore batch tiene límite de 500 ops; se divide en bloques de 450
      const chunks = [];
      for (let i = 0; i < mensajesSnap.docs.length; i += 450) {
        chunks.push(mensajesSnap.docs.slice(i, i + 450));
      }
      for (const chunk of chunks) {
        const batch = db.batch();
        chunk.forEach((doc) => batch.delete(doc.ref));
        await batch.commit();
      }
    }
    return null;
  });
