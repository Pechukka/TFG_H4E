// Script de migración ONE-OFF (se ejecuta una sola vez, a mano).
//
// Prepara los eventos ANTIGUOS para la Fase 2 (feed tipo Tinder):
//   - Les pone estado: 'publicado' si no lo tienen (así entran en el feed del worker).
//   - Les pone un plazasPorRol por defecto si no lo tienen (AJÚSTALO abajo).
//   - Les pone creadoPor si falta (lo deduce del admin en trabajadoresInfo, o usa
//     un uid por defecto que debes rellenar).
//
// Es IDEMPOTENTE: un evento que ya tenga estado NO se toca. Se puede repetir sin miedo.
//
// Cómo ejecutarlo:
//   1. cd scripts
//   2. npm install
//   3. node migrar-estado-eventos.js
//
// Requiere la clave de cuenta de servicio (NO se sube al repo): ver scripts/.gitignore.

const admin = require('firebase-admin');

// 🔧 AJUSTAR: ruta al JSON de la cuenta de servicio (fuera del repo, no lo subas).
const serviceAccount = require('./serviceAccountKey.json');

// 🔧 AJUSTAR: plazas por defecto para los eventos antiguos sin plazasPorRol.
// Cámbialo a lo que tenga sentido para tus datos de demo.
const PLAZAS_POR_DEFECTO = {
  H4ndMontaje: 3,
  Coordinador: 1,
};

// 🔧 AJUSTAR: uid del admin, por si algún evento no tiene creadoPor ni admin en
// trabajadoresInfo. Déjalo vacío si prefieres no forzar ninguno.
const ADMIN_UID_POR_DEFECTO = '';

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

// Busca el uid del admin dentro de trabajadoresInfo (entrada con esAdmin: true).
function buscarAdminUid(data) {
  const info = data.trabajadoresInfo || {};
  for (const [uid, datos] of Object.entries(info)) {
    if (datos && datos.esAdmin === true) return uid;
  }
  return '';
}

async function migrar() {
  const eventosSnap = await db.collection('eventos').get();

  let migrados = 0;
  let yaEstaban = 0;

  for (const eventoDoc of eventosSnap.docs) {
    const data = eventoDoc.data();
    const titulo = data.titulo || '(sin título)';

    // Idempotencia: si ya tiene estado, no tocar.
    if (data.estado && String(data.estado).length > 0) {
      console.log(`= Ya tiene estado ("${data.estado}"): "${titulo}" (${eventoDoc.id})`);
      yaEstaban++;
      continue;
    }

    const cambios = { estado: 'publicado' };

    // plazasPorRol por defecto si no lo tiene
    if (!data.plazasPorRol || Object.keys(data.plazasPorRol).length === 0) {
      cambios.plazasPorRol = PLAZAS_POR_DEFECTO;
    }

    // creadoPor si falta
    if (!data.creadoPor) {
      const adminUid = buscarAdminUid(data) || ADMIN_UID_POR_DEFECTO;
      if (adminUid) cambios.creadoPor = adminUid;
    }

    await eventoDoc.ref.update(cambios);
    console.log(
      `+ Migrado: "${titulo}" (${eventoDoc.id}) — ${JSON.stringify(cambios)}`,
    );
    migrados++;
  }

  console.log('\n──────── Resumen ────────');
  console.log(`Migrados ahora:      ${migrados}`);
  console.log(`Ya tenían estado:    ${yaEstaban}`);
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
