// Script de migración ONE-OFF (se ejecuta una sola vez, a mano).
//
// Prepara los eventos ANTIGUOS para la Fase 2 (feed tipo Tinder):
//   - Les pone estado: 'publicado' si no lo tienen (así entran en el feed del worker).
//   - Les pone un plazasPorRol por defecto si no lo tienen (AJÚSTALO abajo).
//   - Les pone creadoPor si falta (lo deduce del admin en trabajadoresInfo, o usa
//     un uid por defecto que debes rellenar).
//   - Borra trabajadoresInfo.*.telefono de los eventos que aún lo tengan (el código
//     ya no lo escribe, pero los docs antiguos podían tenerlo → fuga en el feed).
//
// Es IDEMPOTENTE: solo escribe si hay algo que cambiar. Se puede repetir sin miedo.
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

  let actualizados = 0;
  let sinCambios = 0;

  for (const eventoDoc of eventosSnap.docs) {
    const data = eventoDoc.data();
    const titulo = data.titulo || '(sin título)';

    const cambios = {};
    const notas = [];

    // 1. estado/plazasPorRol/creadoPor: solo si aún no tiene estado.
    if (!data.estado || String(data.estado).length === 0) {
      cambios.estado = 'publicado';
      notas.push("estado='publicado'");

      if (!data.plazasPorRol || Object.keys(data.plazasPorRol).length === 0) {
        cambios.plazasPorRol = PLAZAS_POR_DEFECTO;
        notas.push('plazasPorRol');
      }

      if (!data.creadoPor) {
        const adminUid = buscarAdminUid(data) || ADMIN_UID_POR_DEFECTO;
        if (adminUid) {
          cambios.creadoPor = adminUid;
          notas.push('creadoPor');
        }
      }
    }

    // 2. Limpiar telefono de trabajadoresInfo SIEMPRE (aunque el evento ya esté
    //    migrado): los docs antiguos podían tenerlo y no debe filtrarse en el feed.
    const info = data.trabajadoresInfo || {};
    let telefonos = 0;
    for (const [uid, datos] of Object.entries(info)) {
      if (datos && datos.telefono !== undefined) {
        cambios[`trabajadoresInfo.${uid}.telefono`] =
          admin.firestore.FieldValue.delete();
        telefonos++;
      }
    }
    if (telefonos > 0) notas.push(`quita ${telefonos} telefono(s)`);

    // Idempotencia: si no hay nada que cambiar, no se escribe.
    if (Object.keys(cambios).length === 0) {
      console.log(`= Nada que hacer: "${titulo}" (${eventoDoc.id})`);
      sinCambios++;
      continue;
    }

    await eventoDoc.ref.update(cambios);
    console.log(`+ Actualizado: "${titulo}" (${eventoDoc.id}) — ${notas.join(', ')}`);
    actualizados++;
  }

  console.log('\n──────── Resumen ────────');
  console.log(`Actualizados ahora:  ${actualizados}`);
  console.log(`Sin cambios:         ${sinCambios}`);
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
