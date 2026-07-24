// Script de migración ONE-OFF (se ejecuta una sola vez, a mano).
//
// Hace dos cosas para que la app worker pueda mostrar el equipo sin leer `users`
// (las reglas por rol se lo prohíben):
//
//   1. `trabajadoresInfo` en el doc del evento: {uid: {nombre, rol, esAdmin}}, SIN
//      teléfono (ese doc lo lee cualquier worker si el evento está publicado).
//      Solo se escribe en los eventos que aún no lo tienen.
//   2. Subcolección `eventos/{id}/equipo/{uid}`: {nombre, rol, telefono}. Aquí SÍ va
//      el teléfono, porque esa subcolección solo la pueden leer los miembros del
//      evento. Se rellena SIEMPRE, también en eventos ya migrados.
//
// Es IDEMPOTENTE: todo se escribe con set()/ids fijos, así que puedes ejecutarlo
// varias veces sin miedo.
//
// Cómo ejecutarlo:
//   1. cd scripts
//   2. npm install
//   3. node migrar-trabajadores-info.js
//
// Requiere una clave de cuenta de servicio de Firebase (NO se sube al repo):
//   Consola de Firebase → Configuración del proyecto → Cuentas de servicio →
//   "Generar nueva clave privada" → guarda el JSON y apunta la ruta abajo.

const admin = require('firebase-admin');

// 🔧 AJUSTAR: ruta al JSON de la cuenta de servicio (fuera del repo, no lo subas).
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

async function migrar() {
  const eventosSnap = await db.collection('eventos').get();

  let migrados = 0;
  let yaEstaban = 0;
  let sinTrabajadores = 0;

  for (const eventoDoc of eventosSnap.docs) {
    const data = eventoDoc.data();
    const titulo = data.titulo || '(sin título)';

    const ids = Array.isArray(data.trabajadoresIds) ? data.trabajadoresIds : [];
    const roles = data.trabajadoresRoles || {};

    if (ids.length === 0) {
      console.log(`- Sin trabajadores: "${titulo}" (${eventoDoc.id})`);
      sinTrabajadores++;
      continue;
    }

    // ¿Le falta trabajadoresInfo? (la subcolección equipo se rellena siempre)
    const infoActual = data.trabajadoresInfo;
    const necesitaInfo = !(infoActual && Object.keys(infoActual).length > 0);

    const trabajadoresInfo = {};
    let fichasEquipo = 0;

    for (const uid of ids) {
      const userDoc = await db.collection('users').doc(uid).get();
      if (!userDoc.exists) {
        console.log(`  ! user ${uid} no existe (evento "${titulo}") — se omite`);
        continue;
      }
      const u = userDoc.data();
      const nombre = `${u.nombre || ''} ${u.apellidos || ''}`.trim();
      const rol = roles[uid] || '';

      // En el doc del evento NO va telefono: lo lee cualquier worker si está publicado.
      trabajadoresInfo[uid] = {
        nombre: nombre,
        rol: rol,
        // El admin conserva su rol (Coordinador) en trabajadoresRoles, pero aquí
        // lo marcamos para que la pantalla de equipo lo pinte como "Admin".
        esAdmin: (u.rol === 'admin'),
      };

      // Subcolección eventos/{id}/equipo/{uid}: aquí SÍ va el teléfono, porque solo
      // la pueden leer los miembros del evento. Idempotente (doc id = uid).
      await eventoDoc.ref.collection('equipo').doc(uid).set({
        nombre: nombre,
        rol: rol,
        telefono: u.telefono || '',
      });
      fichasEquipo++;
    }

    if (necesitaInfo) {
      await eventoDoc.ref.update({ trabajadoresInfo: trabajadoresInfo });
      console.log(
        `+ Migrado: "${titulo}" (${eventoDoc.id}) — trabajadoresInfo + ${fichasEquipo} fichas de equipo`,
      );
      migrados++;
    } else {
      console.log(
        `= Ya tenía trabajadoresInfo: "${titulo}" (${eventoDoc.id}) — ${fichasEquipo} fichas de equipo al día`,
      );
      yaEstaban++;
    }
  }

  console.log('\n──────── Resumen ────────');
  console.log(`Migrados ahora:      ${migrados}`);
  console.log(`Ya estaban migrados: ${yaEstaban}`);
  console.log(`Sin trabajadores:    ${sinTrabajadores}`);
  console.log(`Total eventos:       ${eventosSnap.size}`);
}

migrar()
  .then(() => {
    console.log('\nMigración terminada.');
    process.exit(0);
  })
  .catch((err) => {
    console.error('\nError en la migración:', err);
    process.exit(1);
  });
