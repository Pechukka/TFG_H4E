import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/nomina.dart';
import '../models/notificacion.dart';
import '../core/roles.dart';
import '../core/constants.dart';

// Servicio con las funciones que solo usa el administrador
class AdminService {
  static final _firestore = FirebaseFirestore.instance;

  // Genera una contraseña aleatoria con el prefijo H4E_
  // Usamos letras y números fáciles de leer (sin 0, O, l, 1 que se confunden)
  static String generarPassword() {
    const chars = 'ABCDEFGHJKMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789';
    final random = Random.secure();
    String resultado = 'H4E_';
    for (int i = 0; i < 8; i++) {
      resultado += chars[random.nextInt(chars.length)];
    }
    return resultado;
  }

  // Crea un trabajador nuevo en Firebase Auth y en Firestore.
  //
  // Problema: si usamos FirebaseAuth.instance.createUserWithEmailAndPassword()
  // directamente, Firebase cierra la sesión del admin y la reemplaza por la del
  // nuevo trabajador. Para evitar eso, conectamos una segunda instancia de Firebase
  // solo para crear el usuario, y al terminar la borramos. El admin sigue con
  // su sesión intacta en la instancia principal.
  static Future<Map<String, String>> crearWorker({
    required String nombre,
    required String apellidos,
    required String email,
    required String password,
    String? telefono,
    String? dni,
  }) async {
    // Nombre único para la conexión temporal (por si se llama varias veces seguidas)
    final nombreConexionTemporal = 'crear_worker_${DateTime.now().millisecondsSinceEpoch}';
    FirebaseApp? conexionTemporal;

    try {
      // Abrimos una segunda conexión a Firebase con la misma configuración
      conexionTemporal = await Firebase.initializeApp(
        name: nombreConexionTemporal,
        options: Firebase.app().options,
      );

      // Creamos el usuario en Firebase Auth usando la conexión temporal
      final authTemporal = FirebaseAuth.instanceFor(app: conexionTemporal);
      final resultado = await authTemporal.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = resultado.user!.uid;

      // Guardamos los datos del trabajador en Firestore
      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'nombre': nombre,
        'apellidos': apellidos,
        'email': email,
        'telefono': telefono ?? '',
        'dni': dni ?? '',
        'rol': 'worker',
        'activo': true,
        'idioma': 'es',
        'avatarUrl': '',
        'createdAt': FieldValue.serverTimestamp(),
        'debeReiniciarPassword': true,
      });

      return {'uid': uid, 'email': email};
    } finally {
      // Cerramos y eliminamos la conexión temporal siempre, haya error o no
      await conexionTemporal?.delete();
    }
  }

  // Devuelve un stream con todos los trabajadores ordenados por nombre.
  // StreamBuilder se actualiza automáticamente cuando hay cambios en Firestore.
  static Stream<QuerySnapshot<Map<String, dynamic>>> workersStream() {
    // Sin orderBy para evitar índice compuesto — se ordena en la pantalla
    return _firestore
        .collection('users')
        .where('rol', isEqualTo: 'worker')
        .snapshots();
  }

  // Obtiene una sola vez la lista de todos los trabajadores.
  // Se usa en el formulario de crear evento para mostrar a quién asignar.
  static Future<List<Map<String, dynamic>>> getWorkers() async {
    final snapshot = await _firestore
        .collection('users')
        .where('rol', isEqualTo: 'worker')
        .get();

    final lista = snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'uid': doc.id,
        'nombre': '${data['nombre'] ?? ''} ${data['apellidos'] ?? ''}'.trim(),
        'email': data['email'] ?? '',
        'telefono': data['telefono'] ?? '',
      };
    }).toList();

    // Ordenamos por nombre en Dart
    lista.sort((a, b) => (a['nombre'] as String).compareTo(b['nombre'] as String));
    return lista;
  }

  // Devuelve un stream con todos los eventos (sin filtrar por trabajador).
  // El admin ve todos los eventos del sistema.
  static Stream<QuerySnapshot<Map<String, dynamic>>> todosLosEventosStream() {
    return _firestore
        .collection('eventos')
        .orderBy('fechaInicio', descending: true)
        .snapshots();
  }

  // Stream de un evento concreto (para ver la cobertura en vivo, Fase 2).
  static Stream<DocumentSnapshot<Map<String, dynamic>>> eventoStream(
      String eventoId) {
    return _firestore.collection('eventos').doc(eventoId).snapshots();
  }

  // Comprueba si un trabajador cubre completamente el rango horario del evento.
  // Si eventoInicio/eventoFin son null, solo comprueba que haya disponibilidad ese día.
  // Ejemplo: worker disponible 09:00–14:00, evento 07:00–10:00 → false
  // porque el evento empieza antes de que el worker esté disponible.
  static Future<bool> tieneDisponibilidad(
    String uid,
    DateTime fecha, [
    DateTime? eventoInicio,
    DateTime? eventoFin,
  ]) async {
    final inicioDia = DateTime(fecha.year, fecha.month, fecha.day);
    final finDia = inicioDia.add(const Duration(days: 1));

    final snapshot = await _firestore
        .collection('disponibilidad')
        .where('trabajadorId', isEqualTo: uid)
        .get();

    // Filtramos los registros que corresponden a ese día
    final dispDia = snapshot.docs.where((doc) {
      final fechaDisp = (doc.data()['fecha'] as Timestamp).toDate();
      return !fechaDisp.isBefore(inicioDia) && fechaDisp.isBefore(finDia);
    }).toList();

    if (dispDia.isEmpty) return false;

    // Si no se proporcionó rango horario, basta con que haya disponibilidad ese día
    if (eventoInicio == null || eventoFin == null) return true;

    final eventoInicioMin = eventoInicio.hour * 60 + eventoInicio.minute;
    // Si el evento cruza medianoche, el fin se representa como minutos > 1440
    final eventoFinMin = eventoFin.day != eventoInicio.day
        ? 1440 + eventoFin.hour * 60 + eventoFin.minute
        : eventoFin.hour * 60 + eventoFin.minute;

    // Comprobamos que algún registro cubra el rango completo del evento
    return dispDia.any((doc) {
      final data = doc.data();
      final hi = data['horaInicio'] as Map<String, dynamic>?;
      final hf = data['horaFin'] as Map<String, dynamic>?;
      if (hi == null || hf == null) return false;
      final dispInicioMin = (hi['hour'] as int) * 60 + (hi['minute'] as int);
      final hfHour = hf['hour'] as int;
      final hfMinute = hf['minute'] as int;
      // 00:00 como horaFin = medianoche = 24:00 = 1440 min
      final dispFinMin = (hfHour == 0 && hfMinute == 0) ? 1440 : hfHour * 60 + hfMinute;
      return dispInicioMin <= eventoInicioMin && dispFinMin >= eventoFinMin;
    });
  }

  // ─── FASE 5: Fichajes por evento ───────────────────────────────────────────

  // Devuelve todos los fichajes de un evento (de todos los trabajadores).
  // Incluye los campos de ubicación GPS si el trabajador los registró.
  static Future<List<Map<String, dynamic>>> getFichajesDeEvento(
      String eventoId) async {
    final snapshot = await _firestore
        .collection('fichajes')
        .where('eventoId', isEqualTo: eventoId)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {...data, 'id': doc.id};
    }).toList();
  }

  // ─── FASE 6: Nóminas ────────────────────────────────────────────────────────

  // Calcula el resumen de horas y sueldo de todos los workers para un mes dado.
  // Devuelve una lista donde cada elemento es un worker con sus horas y total.
  static Future<List<Map<String, dynamic>>> calcularResumenMes(
      int anio, int mes) async {
    final inicio = DateTime(anio, mes, 1);
    final fin = DateTime(anio, mes + 1, 1);

    // 1. Cargar todos los workers (sin orderBy para evitar índice compuesto)
    final workersSnap = await _firestore
        .collection('users')
        .where('rol', isEqualTo: 'worker')
        .get();

    final resumen = <Map<String, dynamic>>[];

    for (final workerDoc in workersSnap.docs) {
      final uid = workerDoc.id;
      final data = workerDoc.data();
      final nombre =
          '${data['nombre'] ?? ''} ${data['apellidos'] ?? ''}'.trim();

      // 2. Cargar los fichajes de ese worker (filtramos estado en Dart para evitar índice compuesto)
      final fichajesSnap = await _firestore
          .collection('fichajes')
          .where('trabajadorId', isEqualTo: uid)
          .get();

      // Filtrar por estado y fecha en Dart para no necesitar índices compuestos
      final fichajesMes = fichajesSnap.docs.where((doc) {
        final data = doc.data();
        final estado = data['estado'] as String? ?? '';
        if (!estado.contains('finalizado')) return false;
        final entrada = (data['entrada'] as Timestamp?)?.toDate();
        if (entrada == null) return false;
        return !entrada.isBefore(inicio) && entrada.isBefore(fin);
      }).toList();

      if (fichajesMes.isEmpty) continue;

      // 3. Calcular horas y sueldo por evento
      final eventosTrabajados = <Map<String, dynamic>>[];
      double totalHoras = 0;
      double totalBruto = 0;

      for (final fichajeDoc in fichajesMes) {
        final f = fichajeDoc.data();
        final eventoId = f['eventoId'] as String? ?? '';
        final entrada = (f['entrada'] as Timestamp?)?.toDate();
        final salida = (f['salida'] as Timestamp?)?.toDate();
        if (entrada == null || salida == null) continue;

        final horas = salida.difference(entrada).inMinutes / 60.0;

        // Preferir los snapshots grabados al eliminar el evento;
        // si el evento sigue activo, leerlo de Firestore como antes.
        String rol = f['rolSnapshot'] as String? ?? '';
        double tarifa = f['tarifaSnapshot'] != null
            ? (f['tarifaSnapshot'] as num).toDouble()
            : 0.0;
        String tituloEvento = f['tituloEventoSnapshot'] as String? ?? 'Evento';

        if (rol.isEmpty && eventoId.isNotEmpty) {
          final eventoDoc =
              await _firestore.collection('eventos').doc(eventoId).get();
          if (eventoDoc.exists) {
            tituloEvento = eventoDoc.data()?['titulo'] ?? 'Evento';
            final roles = Map<String, String>.from(
                eventoDoc.data()?['trabajadoresRoles'] ?? {});
            rol = roles[uid] ?? RolesEvento.todos.first;
            tarifa = RolesEvento.tarifaDe(rol);
          } else {
            rol = RolesEvento.todos.first;
            tarifa = RolesEvento.tarifaDe(rol);
          }
        } else if (rol.isEmpty) {
          rol = RolesEvento.todos.first;
          tarifa = RolesEvento.tarifaDe(rol);
        }

        final subtotal = horas * tarifa;
        totalHoras += horas;
        totalBruto += subtotal;

        eventosTrabajados.add({
          'titulo': tituloEvento,
          'horas': horas,
          'rol': rol,
          'tarifa': tarifa,
          'subtotal': subtotal,
        });
      }

      resumen.add({
        'uid': uid,
        'nombre': nombre,
        'totalHoras': totalHoras,
        'sueldoBruto': totalBruto,
        'sueldoNeto': totalBruto * (1 - 0.15 - 0.0635), // IRPF 15% + SS 6.35%
        'eventos': eventosTrabajados,
      });
    }

    return resumen;
  }

  // Guarda la nómina de un trabajador en Firestore.
  // El PDF se genera y descarga en el cliente, no se sube a Storage.
  static Future<void> guardarNomina({
    required String trabajadorUid,
    required int anio,
    required int mes,
    required double horasTrabajadas,
    required double sueldoBruto,
  }) async {
    final sueldoNeto = sueldoBruto * (1 - 0.15 - 0.0635);

    // Comprobar si ya existe nómina para ese mes y trabajador
    final existente = await _firestore
        .collection('nominas')
        .where('trabajadorId', isEqualTo: trabajadorUid)
        .where('anio', isEqualTo: anio)
        .where('mesNumero', isEqualTo: mes)
        .limit(1)
        .get();

    final datos = {
      'trabajadorId': trabajadorUid,
      'mes': AppConstants.meses[mes],
      'anio': anio,
      'mesNumero': mes,
      'sueldoBruto': sueldoBruto,
      'sueldoNeto': sueldoNeto,
      'horasTrabajadas': horasTrabajadas,
      'pdfUrl': null,
      'fechaGeneracion': FieldValue.serverTimestamp(),
      'estado': NominaEstado.generada.toString(),
    };

    if (existente.docs.isEmpty) {
      await _firestore.collection('nominas').add(datos);
    } else {
      await existente.docs.first.reference.update(datos);
    }

    // Notificar al trabajador de que su nómina está disponible
    final sueldoNetoCalculado = sueldoBruto * (1 - 0.15 - 0.0635);
    await _notificar(
      trabajadorUid,
      tipo: TipoNotificacion.nominaPublicada,
      titulo: 'Tu nómina está disponible',
      mensaje: '${AppConstants.meses[mes]} $anio — ${sueldoNetoCalculado.toStringAsFixed(2)}€ neto',
      datos: {'anio': anio, 'mesNumero': mes},
    );
  }

  // Actualiza los datos de perfil de un trabajador en Firestore.
  static Future<void> actualizarWorker(
      String uid, Map<String, dynamic> datos) async {
    await _firestore.collection('users').doc(uid).update(datos);
  }

  // Elimina al trabajador de Firestore.
  // Su cuenta de Firebase Auth queda inactiva porque la app exige documento en Firestore.
  static Future<void> eliminarWorker(String uid) async {
    await _firestore.collection('users').doc(uid).delete();
  }

  // Escribe un documento de notificación en Firestore para un trabajador.
  // La Cloud Function onNotificacionCreada (functions/index.js) lo detecta
  // y envía el push FCM al dispositivo del trabajador.
  static Future<void> _notificar(
    String trabajadorId, {
    required TipoNotificacion tipo,
    required String titulo,
    required String mensaje,
    Map<String, dynamic>? datos,
  }) async {
    await _firestore.collection('notificaciones').add({
      'trabajadorId': trabajadorId,
      'tipo': tipo.toString(),
      'titulo': titulo,
      'mensaje': mensaje,
      'timestamp': FieldValue.serverTimestamp(),
      'leida': false,
      'datos': datos,
    });
  }

  // Elimina un evento y todos sus mensajes de chat, y notifica a los trabajadores asignados.
  static Future<void> eliminarEvento(
    String eventoId, {
    required String titulo,
    required List<String> trabajadoresIds,
  }) async {
    // 1. Antes de borrar el evento, estampar rol/tarifa en fichajes y cerrar
    //    los que sigan activos para que el tiempo trabajado no se pierda.
    final eventoDoc = await _firestore.collection('eventos').doc(eventoId).get();
    if (eventoDoc.exists) {
      final roles = Map<String, String>.from(eventoDoc.data()?['trabajadoresRoles'] ?? {});
      final fichajesSnap = await _firestore
          .collection('fichajes')
          .where('eventoId', isEqualTo: eventoId)
          .get();
      final ahora = Timestamp.now();
      for (final fichajeDoc in fichajesSnap.docs) {
        final fData = fichajeDoc.data();
        final trabajadorId = fData['trabajadorId'] as String? ?? '';
        final rol = roles[trabajadorId] ?? RolesEvento.todos.first;
        final tarifa = RolesEvento.tarifaDe(rol);
        final estado = fData['estado'] as String? ?? '';
        final updates = <String, dynamic>{
          'rolSnapshot': rol,
          'tarifaSnapshot': tarifa,
          'tituloEventoSnapshot': titulo,
        };
        // Si el fichaje no estaba finalizado, cerrarlo automáticamente
        if (!estado.contains('finalizado')) {
          updates['estado'] = 'FichajeEstado.finalizado';
          updates['salida'] = ahora;
          updates['cierreAutomatico'] = true;
          // Si estaba en pausa, cerrar la última pausa abierta
          final pausas = List<Map<String, dynamic>>.from(
            (fData['pausas'] as List<dynamic>? ?? []).map((p) => Map<String, dynamic>.from(p as Map)),
          );
          if (pausas.isNotEmpty && pausas.last['fin'] == null) {
            pausas.last['fin'] = ahora;
            updates['pausas'] = pausas;
          }
        }
        await fichajeDoc.reference.update(updates);
      }
    }

    // 2. Borrar mensajes de chat (Firestore no hace cascade delete)
    final mensajes = await _firestore
        .collection('eventos')
        .doc(eventoId)
        .collection('mensajes')
        .get();
    for (final doc in mensajes.docs) {
      await doc.reference.delete();
    }

    // 3. Notificar cancelación a los trabajadores asignados
    for (final uid in trabajadoresIds) {
      await _notificar(
        uid,
        tipo: TipoNotificacion.eventoCancelado,
        titulo: '¡ Evento cancelado',
        mensaje: titulo,
        datos: {'tituloEvento': titulo},
      );
    }

    // 4. Eliminar el documento del evento
    await _firestore.collection('eventos').doc(eventoId).delete();
  }

  // Actualiza un evento en Firestore y notifica a los trabajadores de los cambios.
  static Future<void> actualizarEvento(
    String eventoId, {
    required Map<String, dynamic> datos,
    required List<String> workerIds,
    required String titulo,
  }) async {
    await _firestore.collection('eventos').doc(eventoId).update(datos);
    for (final uid in workerIds) {
      await _notificar(
        uid,
        tipo: TipoNotificacion.cambioEvento,
        titulo: 'Evento actualizado',
        mensaje: titulo,
        datos: {'eventoId': eventoId, 'tituloEvento': titulo},
      );
    }
  }

  // Fase 2: el admin publica el evento SIN asignar a nadie. Solo define las plazas
  // por rol y el estado. Los confirmados llegan luego desde las postulaciones.
  // Al publicar, el único participante es el admin (como Coordinador).
  static Future<void> crearEventoAdmin({
    required String titulo,
    required String descripcion,
    required String ubicacion,
    required DateTime fechaInicio,
    required DateTime fechaFin,
    required Map<String, int> plazasPorRol, // {rol: nº de plazas}
    required String estado, // 'borrador' | 'publicado' | 'finalizado'
    required String adminUid,
    required String adminNombre,
    required String adminTelefono,
  }) async {
    await _firestore.collection('eventos').add({
      'titulo': titulo,
      'descripcion': descripcion,
      'ubicacion': ubicacion,
      'fechaInicio': Timestamp.fromDate(fechaInicio),
      'fechaFin': Timestamp.fromDate(fechaFin),
      'plazasPorRol': plazasPorRol,
      'estado': estado,
      // Sin confirmados todavía: solo el admin como Coordinador.
      'trabajadoresIds': [adminUid],
      'trabajadoresRoles': {adminUid: 'Coordinador'},
      'trabajadoresInfo': {
        adminUid: {
          'nombre': adminNombre,
          'telefono': adminTelefono,
          'rol': 'Coordinador',
          'esAdmin': true,
        },
      },
      'rolAsignado': '',
      'cobroPorHora': 0.0,
      'creadoPor': adminUid,
    });
  }

  // ─── FASE 1: Datos del dashboard admin ──────────────────────────────────────

  // Calcula de una sola vez todos los KPIs de la pantalla de inicio del admin.
  // Sigue el patrón del proyecto: se lee y filtra en Dart (sin índices compuestos).
  static Future<Map<String, dynamic>> getDatosDashboard() async {
    final ahora = DateTime.now();
    final inicioMes = DateTime(ahora.year, ahora.month, 1);
    final finMes = DateTime(ahora.year, ahora.month + 1, 1);
    final limite7dias = ahora.add(const Duration(days: 7));

    // 1. Trabajadores activos (rol worker y activo != false)
    final workersSnap = await _firestore
        .collection('users')
        .where('rol', isEqualTo: 'worker')
        .get();
    final trabajadoresActivos =
        workersSnap.docs.where((d) => d.data()['activo'] != false).length;

    // 2. Eventos: nº en los próximos 7 días + lista corta de próximos con cobertura
    final eventosSnap = await _firestore.collection('eventos').get();
    final proximos = <Map<String, dynamic>>[];
    int eventosProximos7 = 0;
    for (final doc in eventosSnap.docs) {
      final data = doc.data();
      final inicioTs = data['fechaInicio'];
      if (inicioTs is! Timestamp) continue;
      final inicio = inicioTs.toDate();
      if (!inicio.isAfter(ahora)) continue; // solo futuros
      if (inicio.isBefore(limite7dias)) eventosProximos7++;
      // Cobertura = trabajadores asignados sin contar al admin (el creador)
      final ids = List<String>.from(data['trabajadoresIds'] ?? []);
      final creadoPor = data['creadoPor'] as String?;
      final asignados = ids.where((id) => id != creadoPor).length;
      proximos.add({
        'titulo': data['titulo'] ?? 'Sin título',
        'fecha': inicio,
        'asignados': asignados,
      });
    }
    proximos.sort(
        (a, b) => (a['fecha'] as DateTime).compareTo(b['fecha'] as DateTime));
    final proximosCorto = proximos.take(5).toList();

    // 3. Horas fichadas del mes en curso (fichajes finalizados) + quién trabajó
    final fichajesSnap = await _firestore.collection('fichajes').get();
    double horasMes = 0;
    final workersConHoras = <String>{};
    for (final doc in fichajesSnap.docs) {
      final data = doc.data();
      final estado = data['estado'] as String? ?? '';
      if (!estado.contains('finalizado')) continue;
      final entradaTs = data['entrada'];
      final salidaTs = data['salida'];
      if (entradaTs is! Timestamp || salidaTs is! Timestamp) continue;
      final entrada = entradaTs.toDate();
      if (entrada.isBefore(inicioMes) || !entrada.isBefore(finMes)) continue;
      horasMes += salidaTs.toDate().difference(entrada).inMinutes / 60.0;
      final wid = data['trabajadorId'] as String? ?? '';
      if (wid.isNotEmpty) workersConHoras.add(wid);
    }

    // 4. Nóminas pendientes de enviar: workers con horas este mes que aún no
    //    tienen nómina generada para este mes.
    final nominasSnap = await _firestore.collection('nominas').get();
    final nominasMes = <String>{};
    for (final doc in nominasSnap.docs) {
      final data = doc.data();
      if ((data['anio'] ?? 0) == ahora.year &&
          (data['mesNumero'] ?? 0) == ahora.month) {
        final wid = data['trabajadorId'] as String? ?? '';
        if (wid.isNotEmpty) nominasMes.add(wid);
      }
    }
    final nominasPendientes =
        workersConHoras.where((w) => !nominasMes.contains(w)).length;

    return {
      'trabajadoresActivos': trabajadoresActivos,
      'eventosProximos': eventosProximos7,
      'horasMes': horasMes,
      'nominasPendientes': nominasPendientes,
      'proximosEventos': proximosCorto,
    };
  }
}
