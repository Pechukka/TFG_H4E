// Script de migración ONE-OFF (se ejecuta una sola vez, a mano).
//
// Rellena el campo `trabajadoresInfo` en los eventos ANTIGUOS que no lo tienen,
// para que la app worker pueda mostrar el equipo sin leer la colección `users`
// (las reglas por rol se lo prohíben). Copia nombre, teléfono y rol de cada
// asignado dentro del propio doc del evento, y marca al admin con esAdmin: true.
//
// Es IDEMPOTENTE: los eventos que ya tienen trabajadoresInfo se saltan.
// Puedes ejecutarlo varias veces sin miedo.
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

    // Idempotencia: si ya tiene trabajadoresInfo con contenido, no tocar.
    const infoActual = data.trabajadoresInfo;
    if (infoActual && Object.keys(infoActual).length > 0) {
      console.log(`= Ya migrado: "${titulo}" (${eventoDoc.id})`);
      yaEstaban++;
      continue;
    }

    const ids = Array.isArray(data.trabajadoresIds) ? data.trabajadoresIds : [];
    const roles = data.trabajadoresRoles || {};

    if (ids.length === 0) {
      console.log(`- Sin trabajadores: "${titulo}" (${eventoDoc.id})`);
      sinTrabajadores++;
      continue;
    }

    // Construimos trabajadoresInfo leyendo cada user (aquí sí podemos: admin).
    const trabajadoresInfo = {};
    for (const uid of ids) {
      const userDoc = await db.collection('users').doc(uid).get();
      if (!userDoc.exists) {
        console.log(`  ! user ${uid} no existe (evento "${titulo}") — se omite`);
        continue;
      }
      const u = userDoc.data();
      const nombre = `${u.nombre || ''} ${u.apellidos || ''}`.trim();
      // NO se guarda telefono: un evento publicado es legible por cualquier worker.
      trabajadoresInfo[uid] = {
        nombre: nombre,
        rol: roles[uid] || '',
        // El admin conserva su rol (Coordinador) en trabajadoresRoles, pero aquí
        // lo marcamos para que la pantalla de equipo lo pinte como "Admin".
        esAdmin: (u.rol === 'admin'),
      };
    }

    await eventoDoc.ref.update({ trabajadoresInfo: trabajadoresInfo });
    console.log(`+ Migrado: "${titulo}" (${eventoDoc.id}) — ${Object.keys(trabajadoresInfo).length} miembros`);
    migrados++;
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
