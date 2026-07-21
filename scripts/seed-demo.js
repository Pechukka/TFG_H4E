// Script de SEED para la demo de Hands4Events.
//
// Puebla Firestore (y Firebase Auth para las cuentas con las que harás login) con
// datos realistas: trabajadores, eventos en distintos estados, postulaciones y avisos.
//
// Es IDEMPOTENTE: todos los documentos se crean con IDs fijos (prefijo `seed_`) y se
// escriben con set(), así que relanzarlo NO duplica nada, solo reescribe lo mismo.
// Las cuentas de Auth se reutilizan si ya existen (se buscan por email).
//
// Cómo ejecutarlo:
//   1. cd scripts
//   2. npm install
//   3. node seed-demo.js
//
// Requiere la clave de cuenta de servicio (NO se sube al repo): ver scripts/.gitignore.

const admin = require('firebase-admin');

// 🔧 AJUSTAR: ruta al JSON de la cuenta de servicio (fuera del repo, no lo subas).
const serviceAccount = require('./serviceAccountKey.json');

// 🔧 AJUSTAR: ponlo a true para BORRAR todo lo que creó este seed antes de volver a
// crearlo (borra los docs `seed_*`, y las cuentas de Auth de los workers de demo).
// Déjalo en false para un seed normal / repetible.
const BORRAR_Y_RESEMBRAR = false;

// 🔧 AJUSTAR: uid del admin. Si lo dejas vacío, el script busca el primer usuario con
// rol 'admin' en Firestore. Se usa como creador de los eventos y como Coordinador.
const ADMIN_UID_MANUAL = '';

// ───────────────────────────────────────────────────────────────────────────────
// 🔧 AJUSTAR — CREDENCIALES DE DEMO
// Estas 3 cuentas SÍ tienen usuario en Firebase Authentication: son con las que
// puedes hacer login en la app durante la demo. Cambia las contraseñas si quieres.
// (Se crean con debeReiniciarPassword: false para entrar directo, sin pantalla de
// "cambia tu contraseña".)
// ───────────────────────────────────────────────────────────────────────────────
const WORKERS_DEMO = [
  {
    clave: 'demo1',
    email: 'lucia.demo@hands4events.com',
    password: 'Demo2026!',
    nombre: 'Lucía',
    apellidos: 'Fernández Ruiz',
    telefono: '611223344',
    dni: '12345678Z',
  },
  {
    clave: 'demo2',
    email: 'marc.demo@hands4events.com',
    password: 'Demo2026!',
    nombre: 'Marc',
    apellidos: 'Soler Vidal',
    telefono: '622334455',
    dni: '23456789S',
  },
  {
    clave: 'demo3',
    email: 'aitor.demo@hands4events.com',
    password: 'Demo2026!',
    nombre: 'Aitor',
    apellidos: 'Etxeberria Lasa',
    telefono: '633445566',
    dni: '34567890T',
  },
];

// Workers de relleno: SOLO documento en `users`, sin cuenta de Authentication.
// Sirven para que las listas y las postulaciones no estén vacías.
const WORKERS_RELLENO = [
  { clave: 'r01', nombre: 'Paula', apellidos: 'Moreno Gil', telefono: '644556677', dni: '45678901R' },
  { clave: 'r02', nombre: 'Javier', apellidos: 'Ortega Peña', telefono: '655667788', dni: '56789012W' },
  { clave: 'r03', nombre: 'Nerea', apellidos: 'Campos Díaz', telefono: '666778899', dni: '67890123A' },
  { clave: 'r04', nombre: 'Sergio', apellidos: 'Ibáñez Molina', telefono: '677889900', dni: '78901234G' },
  { clave: 'r05', nombre: 'Carla', apellidos: 'Vega Santos', telefono: '688990011', dni: '89012345M' },
  { clave: 'r06', nombre: 'Iván', apellidos: 'Prieto Lara', telefono: '699001122', dni: '90123456Y' },
  { clave: 'r07', nombre: 'Marta', apellidos: 'Cano Herrera', telefono: '611334455', dni: '01234567F' },
  { clave: 'r08', nombre: 'Diego', apellidos: 'Ramos Bravo', telefono: '622445566', dni: '11234567P' },
  { clave: 'r09', nombre: 'Alba', apellidos: 'Serrano Nieto', telefono: '633556677', dni: '21234567D' },
  { clave: 'r10', nombre: 'Hugo', apellidos: 'Castro Beltrán', telefono: '644667788', dni: '31234567X' },
  { clave: 'r11', nombre: 'Elena', apellidos: 'Navarro Puig', telefono: '655778899', dni: '41234567B' },
  { clave: 'r12', nombre: 'Óscar', apellidos: 'Rubio Marín', telefono: '666889900', dni: '51234567N' },
];

// Roles válidos (deben coincidir con lib/core/roles.dart)
const ROL_MONTAJE = 'H4ndMontaje';
const ROL_DESMONTAJE = 'H4ndDesmontaje';
const ROL_COORDINADOR = 'Coordinador';
const ROL_RUNNER = 'Runner';

// Eventos de demo. `dias` es el desplazamiento respecto a hoy (negativo = pasado).
// `confirmados` son claves de worker que ya están dentro del evento.
const EVENTOS = [
  {
    id: 'seed_evento_01',
    titulo: 'Montaje Festival Primavera Sound',
    ubicacion: 'Parc del Fòrum, Barcelona',
    descripcion: 'Montaje de escenario principal y vallado perimetral. Se trabaja por equipos de 4.',
    dias: 6,
    hora: 8,
    duracion: 10,
    estado: 'publicado',
    plazasPorRol: { [ROL_MONTAJE]: 4, [ROL_COORDINADOR]: 1 },
    confirmados: [{ clave: 'demo1', rol: ROL_MONTAJE }, { clave: 'r01', rol: ROL_MONTAJE }],
  },
  {
    id: 'seed_evento_02',
    titulo: 'Congreso Médico — Acreditaciones',
    ubicacion: 'IFEMA, Madrid',
    descripcion: 'Atención en mostrador de acreditaciones y apoyo a organización.',
    dias: 3,
    hora: 7,
    duracion: 8,
    estado: 'publicado',
    plazasPorRol: { [ROL_RUNNER]: 3, [ROL_COORDINADOR]: 1 },
    confirmados: [{ clave: 'r02', rol: ROL_RUNNER }],
  },
  {
    id: 'seed_evento_03',
    titulo: 'Boda Finca Los Olivos — Servicio',
    ubicacion: 'Finca Los Olivos, Sevilla',
    descripcion: 'Montaje de carpa, mesas y servicio durante el evento.',
    dias: 12,
    hora: 16,
    duracion: 9,
    estado: 'publicado',
    plazasPorRol: { [ROL_MONTAJE]: 3, [ROL_RUNNER]: 2 },
    confirmados: [],
  },
  {
    id: 'seed_evento_04',
    titulo: 'Desmontaje Feria del Libro',
    ubicacion: 'Parque del Retiro, Madrid',
    descripcion: 'Desmontaje de casetas y carga de material. Imprescindible calzado de seguridad.',
    dias: 20,
    hora: 9,
    duracion: 7,
    estado: 'borrador',
    plazasPorRol: { [ROL_DESMONTAJE]: 5, [ROL_COORDINADOR]: 1 },
    confirmados: [],
  },
  {
    id: 'seed_evento_05',
    titulo: 'Concierto Sala Apolo — Producción',
    ubicacion: 'Sala Apolo, Barcelona',
    descripcion: 'Apoyo a producción y backstage durante el concierto.',
    dias: 30,
    hora: 18,
    duracion: 6,
    estado: 'borrador',
    plazasPorRol: { [ROL_RUNNER]: 2, [ROL_COORDINADOR]: 1 },
    confirmados: [],
  },
  {
    id: 'seed_evento_06',
    titulo: 'Maratón Ciudad — Avituallamiento',
    ubicacion: 'Paseo de la Castellana, Madrid',
    descripcion: 'Montaje de puestos de avituallamiento y reparto durante la carrera.',
    dias: -8,
    hora: 6,
    duracion: 8,
    estado: 'finalizado',
    plazasPorRol: { [ROL_MONTAJE]: 3, [ROL_RUNNER]: 2 },
    confirmados: [
      { clave: 'demo2', rol: ROL_RUNNER },
      { clave: 'r03', rol: ROL_MONTAJE },
      { clave: 'r04', rol: ROL_MONTAJE },
    ],
  },
  {
    id: 'seed_evento_07',
    titulo: 'Gala Benéfica — Montaje y servicio',
    ubicacion: 'Hotel Palace, Valencia',
    descripcion: 'Montaje de sala, photocall y servicio de sala durante la gala.',
    dias: -25,
    hora: 15,
    duracion: 10,
    estado: 'finalizado',
    plazasPorRol: { [ROL_MONTAJE]: 2, [ROL_COORDINADOR]: 1 },
    confirmados: [{ clave: 'demo3', rol: ROL_MONTAJE }, { clave: 'r05', rol: ROL_MONTAJE }],
  },
];

// Postulaciones pendientes sobre eventos PUBLICADOS (para que el admin tenga cola).
const POSTULACIONES_PENDIENTES = [
  { id: 'seed_post_01', evento: 'seed_evento_01', clave: 'r06', rol: ROL_MONTAJE },
  { id: 'seed_post_02', evento: 'seed_evento_01', clave: 'r07', rol: ROL_MONTAJE },
  { id: 'seed_post_03', evento: 'seed_evento_01', clave: 'r08', rol: ROL_COORDINADOR },
  { id: 'seed_post_04', evento: 'seed_evento_02', clave: 'r09', rol: ROL_RUNNER },
  { id: 'seed_post_05', evento: 'seed_evento_02', clave: 'demo2', rol: ROL_RUNNER },
  { id: 'seed_post_06', evento: 'seed_evento_03', clave: 'r10', rol: ROL_MONTAJE },
  { id: 'seed_post_07', evento: 'seed_evento_03', clave: 'r11', rol: ROL_RUNNER },
  { id: 'seed_post_08', evento: 'seed_evento_03', clave: 'demo3', rol: ROL_MONTAJE },
];

// Alguna rechazada por el worker, para que el feed no le vuelva a ofrecer esa carta.
const POSTULACIONES_RECHAZADAS = [
  { id: 'seed_post_09', evento: 'seed_evento_03', clave: 'demo2', rol: '' },
];

admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });

const db = admin.firestore();
const auth = admin.auth();

// Mapa clave de worker -> uid real (se rellena al crearlos)
const uids = {};

function fechaRelativa(dias, hora) {
  const f = new Date();
  f.setDate(f.getDate() + dias);
  f.setHours(hora, 0, 0, 0);
  return f;
}

// ── Busca el uid del admin ─────────────────────────────────────────────────────
async function resolverAdmin() {
  if (ADMIN_UID_MANUAL) {
    const doc = await db.collection('users').doc(ADMIN_UID_MANUAL).get();
    return { uid: ADMIN_UID_MANUAL, nombre: (doc.data() || {}).nombre || 'Admin' };
  }
  const snap = await db.collection('users').where('rol', '==', 'admin').limit(1).get();
  if (snap.empty) return null;
  return { uid: snap.docs[0].id, nombre: snap.docs[0].data().nombre || 'Admin' };
}

// ── Borrado (solo lo que crea este seed) ───────────────────────────────────────
async function borrarSeed() {
  console.log('\n── Borrando datos del seed ──');

  const ids = [
    ...EVENTOS.map((e) => ({ col: 'eventos', id: e.id })),
    ...POSTULACIONES_PENDIENTES.map((p) => ({ col: 'postulaciones', id: p.id })),
    ...POSTULACIONES_RECHAZADAS.map((p) => ({ col: 'postulaciones', id: p.id })),
    ...WORKERS_RELLENO.map((w) => ({ col: 'users', id: `seed_worker_${w.clave}` })),
    ...EVENTOS.flatMap((e) =>
      e.confirmados.map((c) => ({ col: 'notificaciones', id: `seed_notif_${e.id}_${c.clave}` })),
    ),
  ];

  for (const { col, id } of ids) {
    await db.collection(col).doc(id).delete();
  }
  console.log(`  - ${ids.length} documentos seed borrados`);

  // Cuentas de demo: se borra el doc de users y el usuario de Auth
  for (const w of WORKERS_DEMO) {
    try {
      const u = await auth.getUserByEmail(w.email);
      await db.collection('users').doc(u.uid).delete();
      await auth.deleteUser(u.uid);
      console.log(`  - cuenta de demo borrada: ${w.email}`);
    } catch (e) {
      if (e.code !== 'auth/user-not-found') throw e;
    }
  }
}

// ── Workers con cuenta de Auth ─────────────────────────────────────────────────
async function crearWorkersDemo() {
  console.log('\n── Workers de DEMO (con login) ──');
  for (const w of WORKERS_DEMO) {
    let uid;
    try {
      const existente = await auth.getUserByEmail(w.email);
      uid = existente.uid;
      // Reponemos la contraseña por si se cambió en una demo anterior
      await auth.updateUser(uid, { password: w.password });
      console.log(`  = Ya existía en Auth: ${w.email}`);
    } catch (e) {
      if (e.code !== 'auth/user-not-found') throw e;
      const creado = await auth.createUser({
        email: w.email,
        password: w.password,
        displayName: `${w.nombre} ${w.apellidos}`,
      });
      uid = creado.uid;
      console.log(`  + Creado en Auth: ${w.email}`);
    }

    uids[w.clave] = uid;
    await db.collection('users').doc(uid).set({
      uid: uid,
      nombre: w.nombre,
      apellidos: w.apellidos,
      email: w.email,
      telefono: w.telefono,
      dni: w.dni,
      rol: 'worker',
      activo: true,
      idioma: 'es',
      avatarUrl: '',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      notifActivadas: true,
      // false = entra directo, sin pantalla de "cambia tu contraseña"
      debeReiniciarPassword: false,
    });
    console.log(`    doc users/${uid} escrito  →  ${w.email} / ${w.password}`);
  }
}

// ── Workers de relleno (solo Firestore) ────────────────────────────────────────
async function crearWorkersRelleno() {
  console.log('\n── Workers de relleno (sin login) ──');
  for (const w of WORKERS_RELLENO) {
    const id = `seed_worker_${w.clave}`;
    uids[w.clave] = id;
    await db.collection('users').doc(id).set({
      uid: id,
      nombre: w.nombre,
      apellidos: w.apellidos,
      // Email ficticio: NO existe en Authentication, no puede iniciar sesión
      email: `${w.nombre.toLowerCase()}.${w.clave}@demo.hands4events.com`,
      telefono: w.telefono,
      dni: w.dni,
      rol: 'worker',
      activo: true,
      idioma: 'es',
      avatarUrl: '',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      notifActivadas: true,
      debeReiniciarPassword: false,
    });
  }
  console.log(`  + ${WORKERS_RELLENO.length} trabajadores de relleno escritos`);
}

// ── Eventos ────────────────────────────────────────────────────────────────────
async function crearEventos(adminInfo) {
  console.log('\n── Eventos ──');
  for (const e of EVENTOS) {
    const inicio = fechaRelativa(e.dias, e.hora);
    const fin = new Date(inicio.getTime() + e.duracion * 60 * 60 * 1000);

    // Confirmados = los que ya están dentro del evento. El admin entra siempre como
    // Coordinador con esAdmin: true (igual que hace crearEventoAdmin en la app).
    const trabajadoresIds = [];
    const trabajadoresRoles = {};
    const trabajadoresInfo = {};

    for (const c of e.confirmados) {
      const uid = uids[c.clave];
      if (!uid) continue;
      const datos = [...WORKERS_DEMO, ...WORKERS_RELLENO].find((w) => w.clave === c.clave);
      trabajadoresIds.push(uid);
      trabajadoresRoles[uid] = c.rol;
      // OJO: trabajadoresInfo NO guarda telefono (un evento publicado lo lee
      // cualquier worker desde el feed).
      trabajadoresInfo[uid] = {
        nombre: `${datos.nombre} ${datos.apellidos}`.trim(),
        rol: c.rol,
      };
    }

    if (adminInfo) {
      trabajadoresIds.push(adminInfo.uid);
      trabajadoresRoles[adminInfo.uid] = ROL_COORDINADOR;
      trabajadoresInfo[adminInfo.uid] = {
        nombre: adminInfo.nombre,
        rol: ROL_COORDINADOR,
        esAdmin: true,
      };
    }

    await db.collection('eventos').doc(e.id).set({
      titulo: e.titulo,
      descripcion: e.descripcion,
      ubicacion: e.ubicacion,
      fechaInicio: admin.firestore.Timestamp.fromDate(inicio),
      fechaFin: admin.firestore.Timestamp.fromDate(fin),
      plazasPorRol: e.plazasPorRol,
      estado: e.estado,
      trabajadoresIds: trabajadoresIds,
      trabajadoresRoles: trabajadoresRoles,
      trabajadoresInfo: trabajadoresInfo,
      // Campos heredados que la app sigue escribiendo
      rolAsignado: '',
      cobroPorHora: 0.0,
      creadoPor: adminInfo ? adminInfo.uid : '',
    });

    const cuando = e.dias < 0 ? `hace ${-e.dias}d` : `en ${e.dias}d`;
    console.log(
      `  + [${e.estado}] ${e.titulo} (${cuando}) — ${e.confirmados.length} confirmados`,
    );
  }
}

// ── Postulaciones ──────────────────────────────────────────────────────────────
async function crearPostulaciones() {
  console.log('\n── Postulaciones ──');

  for (const p of POSTULACIONES_PENDIENTES) {
    const uid = uids[p.clave];
    if (!uid) continue;
    await db.collection('postulaciones').doc(p.id).set({
      eventoId: p.evento,
      trabajadorId: uid,
      rol: p.rol,
      estado: 'pendiente',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }
  console.log(`  + ${POSTULACIONES_PENDIENTES.length} pendientes`);

  for (const p of POSTULACIONES_RECHAZADAS) {
    const uid = uids[p.clave];
    if (!uid) continue;
    await db.collection('postulaciones').doc(p.id).set({
      eventoId: p.evento,
      trabajadorId: uid,
      rol: p.rol,
      estado: 'rechazado_por_worker',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }
  console.log(`  + ${POSTULACIONES_RECHAZADAS.length} rechazadas por el worker`);

  // Los confirmados de cada evento tienen su postulación en estado 'confirmado',
  // que es como queda tras confirmarlos el admin desde el panel.
  let confirmadas = 0;
  for (const e of EVENTOS) {
    for (const c of e.confirmados) {
      const uid = uids[c.clave];
      if (!uid) continue;
      await db
        .collection('postulaciones')
        .doc(`seed_post_conf_${e.id}_${c.clave}`)
        .set({
          eventoId: e.id,
          trabajadorId: uid,
          rol: c.rol,
          estado: 'confirmado',
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      confirmadas++;
    }
  }
  console.log(`  + ${confirmadas} confirmadas`);
}

// ── Notificaciones de "te han confirmado" ──────────────────────────────────────
async function crearNotificaciones() {
  console.log('\n── Notificaciones ──');
  let n = 0;
  for (const e of EVENTOS) {
    for (const c of e.confirmados) {
      const uid = uids[c.clave];
      if (!uid) continue;
      await db
        .collection('notificaciones')
        .doc(`seed_notif_${e.id}_${c.clave}`)
        .set({
          trabajadorId: uid,
          // El modelo resuelve el enum por su toString()
          tipo: 'TipoNotificacion.confirmacion',
          titulo: 'Te han confirmado',
          mensaje: `Estás confirmado en ${e.titulo} como ${c.rol}`,
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
          leida: false,
          datos: { eventoId: e.id, tituloEvento: e.titulo },
        });
      n++;
    }
  }
  console.log(`  + ${n} notificaciones`);
}

async function main() {
  const adminInfo = await resolverAdmin();
  if (adminInfo) {
    console.log(`Admin detectado: ${adminInfo.nombre} (${adminInfo.uid})`);
  } else {
    console.log(
      '! No se encontró ningún usuario con rol "admin".\n' +
        '  Los eventos se crearán sin coordinador/creador. Rellena ADMIN_UID_MANUAL si lo necesitas.',
    );
  }

  if (BORRAR_Y_RESEMBRAR) await borrarSeed();

  await crearWorkersDemo();
  await crearWorkersRelleno();
  await crearEventos(adminInfo);
  await crearPostulaciones();
  await crearNotificaciones();

  console.log('\n════════ CREDENCIALES DE DEMO ════════');
  for (const w of WORKERS_DEMO) {
    console.log(`  ${w.nombre} ${w.apellidos}`);
    console.log(`     email:      ${w.email}`);
    console.log(`     contraseña: ${w.password}`);
  }
  console.log('══════════════════════════════════════');
}

main()
  .then(() => {
    console.log('\nSeed terminado.');
    process.exit(0);
  })
  .catch((err) => {
    console.error('\nError en el seed:', err);
    process.exit(1);
  });
