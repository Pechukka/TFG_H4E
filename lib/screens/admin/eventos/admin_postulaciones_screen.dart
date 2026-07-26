import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hands4events/core/theme.dart';
import '../../../providers/idioma_provider.dart';
import '../../../models/postulacion.dart';
import '../../../services/admin_service.dart';
import '../../../services/postulaciones_service.dart';
import '../../../utils/top_snackbar.dart';
import '../../chat/chat_evento_screen.dart';
import 'activar_evento.dart';

// Pantalla admin: postulaciones de un evento. Muestra la cobertura por rol en vivo
// y los pendientes agrupados por rol, con Confirmar / Descartar.
class AdminPostulacionesScreen extends StatefulWidget {
  final String eventoId;
  final String tituloEvento;

  const AdminPostulacionesScreen({
    super.key,
    required this.eventoId,
    required this.tituloEvento,
  });

  @override
  State<AdminPostulacionesScreen> createState() =>
      _AdminPostulacionesScreenState();
}

class _AdminPostulacionesScreenState extends State<AdminPostulacionesScreen> {
  // uid -> {nombre, telefono}. Se carga una vez para mostrar nombres.
  Map<String, Map<String, dynamic>> _workers = {};
  bool _cargandoWorkers = true;

  @override
  void initState() {
    super.initState();
    _cargarWorkers();
  }

  Future<void> _cargarWorkers() async {
    final lista = await AdminService.getWorkers();
    if (!mounted) return;
    setState(() {
      // El teléfono se guarda aquí (memoria del admin, que sí puede leer users) para
      // escribirlo luego en la subcolección `equipo` del evento.
      _workers = {
        for (final w in lista)
          (w['uid'] as String): {
            'nombre': w['nombre'] ?? '',
            'telefono': w['telefono'] ?? '',
            'activo': w['activo'] ?? true,
          }
      };
      _cargandoWorkers = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<IdiomaProvider>();
    return Scaffold(
      backgroundColor: AppTheme.fondoPrincipal,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabecera
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back,
                        color: AppTheme.textoBlanco, size: 20),
                    onPressed: () => Navigator.pop(context),
                    tooltip: t.tr('pl_volver'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t.tr('pl_titulo'),
                            style: Theme.of(context).textTheme.headlineSmall),
                        Text(widget.tituloEvento,
                            style: const TextStyle(
                                color: AppTheme.textoSecundario, fontSize: 13),
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: AdminService.eventoStream(widget.eventoId),
                  builder: (context, eventoSnap) {
                    if (!eventoSnap.hasData || _cargandoWorkers) {
                      return const Center(
                        child: CircularProgressIndicator(
                            color: AppTheme.verdeNeon),
                      );
                    }
                    final data = eventoSnap.data!.data() ?? {};
                    final plazas = (data['plazasPorRol']
                                as Map<String, dynamic>? ??
                            {})
                        .map((rol, n) => MapEntry(rol, (n as num).toInt()));
                    final roles = Map<String, String>.from(
                        data['trabajadoresRoles'] ?? {});
                    final creadoPor = data['creadoPor'] as String?;

                    // Confirmados por rol (sin contar al admin creador)
                    final confirmadosPorRol = <String, int>{};
                    roles.forEach((uid, rol) {
                      if (uid == creadoPor) return;
                      confirmadosPorRol[rol] = (confirmadosPorRol[rol] ?? 0) + 1;
                    });

                    final estadoEv = data['estado'] as String? ?? '';

                    return SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildAccesoChat(estadoEv),
                          const SizedBox(height: 20),
                          _Cobertura(
                              plazas: plazas, confirmados: confirmadosPorRol),
                          // Activación manual: visible mientras el evento esté publicado.
                          if (estadoEv == 'publicado') ...[
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: () => crearGrupoEvento(
                                    context, widget.eventoId, data),
                                icon: const Icon(Icons.groups, size: 18),
                                label: Text(t.tr('pl_crear_grupo')),
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppTheme.verdeNeon,
                                  foregroundColor: Colors.black,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              _EtiquetaSeccion(t.tr('pl_confirmados_sec')),
                              const Spacer(),
                              TextButton.icon(
                                onPressed: () => _anadirIntegrante(
                                    plazas, confirmadosPorRol, roles),
                                icon: const Icon(Icons.person_add_alt_1,
                                    size: 18, color: AppTheme.verdeNeon),
                                label: Text(t.tr('pl_anadir'),
                                    style: const TextStyle(
                                        color: AppTheme.verdeNeon,
                                        fontSize: 13)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _buildConfirmados(roles, creadoPor, data),
                          const SizedBox(height: 24),
                          _EtiquetaSeccion(t.tr('pl_pendientes_sec')),
                          const SizedBox(height: 12),
                          _buildPendientes(plazas, confirmadosPorRol),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Acceso al chat del evento desde el panel admin, con el mismo gateo de 3 estados:
  //  activo      → chat abierto y escribible
  //  finalizado  → chat en solo lectura (histórico)
  //  resto       → cerrado, botón deshabilitado con aviso
  Widget _buildAccesoChat(String estado) {
    final t = context.watch<IdiomaProvider>();
    final abierto = estado == 'activo' || estado == 'finalizado';
    final soloLectura = estado == 'finalizado';

    return SizedBox(
      width: double.infinity,
      // OutlinedButton (no .icon) con Row propia para poder envolver el texto en
      // Flexible + ellipsis: la etiqueta larga (sobre todo en inglés) no desborda.
      child: OutlinedButton(
        onPressed: abierto
            ? () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatEventoScreen(
                      tituloEvento: widget.tituloEvento,
                      eventoId: widget.eventoId,
                      soloLectura: soloLectura,
                    ),
                  ),
                )
            : () => showTopSnackBar(context, t.tr('grupo_aviso'),
                backgroundColor: AppTheme.amarilloAdvertencia,
                icon: Icons.info_outline),
        style: OutlinedButton.styleFrom(
          foregroundColor:
              abierto ? AppTheme.verdeNeon : AppTheme.textoTerciario,
          side: BorderSide(
              color: abierto ? AppTheme.verdeNeon : AppTheme.bordeCampo),
          padding: const EdgeInsets.symmetric(vertical: 14),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              abierto
                  ? (soloLectura ? Icons.history : Icons.chat_bubble_outline)
                  : Icons.lock_outline,
              size: 18,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                abierto
                    ? (soloLectura
                        ? t.tr('pl_ver_historico')
                        : t.tr('pl_abrir_chat'))
                    : t.tr('pl_chat_no_disp'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendientes(
      Map<String, int> plazas, Map<String, int> confirmadosPorRol) {
    return StreamBuilder<List<Postulacion>>(
      stream: PostulacionesService.postulacionesDeEventoStream(widget.eventoId),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(
              child: CircularProgressIndicator(color: AppTheme.verdeNeon));
        }
        final pendientes = snap.data!
            .where((p) => p.estado == Postulacion.pendiente)
            .toList();

        if (pendientes.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(context.watch<IdiomaProvider>().tr('pl_sin_pendientes'),
                style: const TextStyle(color: AppTheme.textoSecundario)),
          );
        }

        // Agrupar por rol
        final porRol = <String, List<Postulacion>>{};
        for (final p in pendientes) {
          porRol.putIfAbsent(p.rol, () => []).add(p);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final entry in porRol.entries) ...[
              _cabeceraRol(entry.key, plazas, confirmadosPorRol),
              const SizedBox(height: 8),
              ...entry.value.map((p) => _tarjetaPostulacion(
                  p, plazas, confirmadosPorRol)),
              const SizedBox(height: 16),
            ],
          ],
        );
      },
    );
  }

  // Sección de confirmados: cada integrante con su rol y botón "Quitar"
  // (el admin creador no se puede quitar).
  Widget _buildConfirmados(
      Map<String, String> roles, String? creadoPor, Map<String, dynamic> data) {
    if (roles.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(context.watch<IdiomaProvider>().tr('pl_sin_confirmados'),
            style: const TextStyle(color: AppTheme.textoSecundario)),
      );
    }
    final info = (data['trabajadoresInfo'] as Map<String, dynamic>? ?? {});
    return Column(
      children: roles.entries.map((e) {
        final uid = e.key;
        final rol = e.value;
        final iInfo = info[uid] as Map<String, dynamic>?;
        final esAdmin = (iInfo?['esAdmin'] == true) || uid == creadoPor;
        final nombre = (iInfo?['nombre'] as String?)?.trim();
        final mostrado = (nombre != null && nombre.isNotEmpty)
            ? nombre
            : ((_workers[uid]?['nombre'] as String?) ??
                context.read<IdiomaProvider>().tr('pl_trabajador'));
        return _tarjetaConfirmado(uid, mostrado, esAdmin ? 'Admin' : rol,
            esAdmin: esAdmin);
      }).toList(),
    );
  }

  Widget _tarjetaConfirmado(String uid, String nombre, String rol,
      {required bool esAdmin}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.fondoCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.bordeCard),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppTheme.verdeNeon.withValues(alpha: 0.15),
            child: Text(nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
                style: const TextStyle(
                    color: AppTheme.verdeNeon,
                    fontSize: 13,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nombre,
                    style: Theme.of(context).textTheme.bodyMedium,
                    overflow: TextOverflow.ellipsis),
                Text(rol,
                    style: const TextStyle(
                        color: AppTheme.textoTerciario, fontSize: 12)),
              ],
            ),
          ),
          if (!esAdmin)
            OutlinedButton(
              onPressed: () => _quitar(uid, nombre),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.rojoError,
                side: BorderSide(
                    color: AppTheme.rojoError.withValues(alpha: 0.5)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                textStyle: const TextStyle(fontSize: 13),
              ),
              child: Text(context.read<IdiomaProvider>().tr('pl_quitar')),
            ),
        ],
      ),
    );
  }

  Future<void> _quitar(String uid, String nombre) async {
    final t = context.read<IdiomaProvider>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.fondoCard,
        title: Text(t.tr('pl_quitar_titulo'),
            style: const TextStyle(color: AppTheme.textoBlanco)),
        content: Text(
          '${t.tr('pl_quitar_pre')}$nombre${t.tr('pl_quitar_post')}',
          style: const TextStyle(color: AppTheme.textoSecundario),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t.tr('cancelar'),
                style: const TextStyle(color: AppTheme.textoSecundario)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.rojoError),
            child: Text(t.tr('pl_quitar')),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await PostulacionesService.quitarIntegrante(
          eventoId: widget.eventoId, trabajadorId: uid);
      if (mounted) {
        showTopSnackBar(context, t.tr('pl_quitado'),
            backgroundColor: AppTheme.textoTerciario, icon: Icons.person_remove);
      }
    } catch (_) {
      if (mounted) {
        showTopSnackBar(context, t.tr('pl_err_quitar'),
            backgroundColor: AppTheme.rojoError, icon: Icons.error_outline);
      }
    }
  }

  // Diálogo para añadir un worker (no confirmado aún) a un rol con plaza libre.
  Future<void> _anadirIntegrante(Map<String, int> plazas,
      Map<String, int> confirmadosPorRol, Map<String, String> roles) async {
    final t = context.read<IdiomaProvider>();
    final rolesConHueco = plazas.entries
        .where((e) => (confirmadosPorRol[e.key] ?? 0) < e.value)
        .map((e) => e.key)
        .toList();
    if (rolesConHueco.isEmpty) {
      showTopSnackBar(context, t.tr('pl_sin_plazas'),
          backgroundColor: AppTheme.amarilloAdvertencia,
          icon: Icons.info_outline);
      return;
    }

    // Workers que aún no están en el evento y siguen ACTIVOS (un trabajador dado de
    // baja no debe poder asignarse a eventos nuevos).
    final disponibles = _workers.entries
        .where((e) => !roles.containsKey(e.key) && e.value['activo'] != false)
        .map((e) => {'uid': e.key, 'nombre': e.value['nombre'] ?? ''})
        .toList()
      ..sort((a, b) =>
          (a['nombre'] as String).compareTo(b['nombre'] as String));
    if (disponibles.isEmpty) {
      showTopSnackBar(context, t.tr('pl_sin_workers'),
          backgroundColor: AppTheme.amarilloAdvertencia,
          icon: Icons.info_outline);
      return;
    }

    String? uidSel = disponibles.first['uid'] as String;
    String rolSel = rolesConHueco.first;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          backgroundColor: AppTheme.fondoCard,
          title: Text(t.tr('pl_anadir'),
              style: const TextStyle(color: AppTheme.textoBlanco)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: uidSel,
                isExpanded: true,
                dropdownColor: AppTheme.fondoCard,
                style: const TextStyle(
                    color: AppTheme.textoBlanco, fontSize: 14),
                decoration:
                    InputDecoration(labelText: t.tr('pl_trabajador_label')),
                items: disponibles
                    .map((w) => DropdownMenuItem(
                          value: w['uid'] as String,
                          child: Text(w['nombre'] as String,
                              overflow: TextOverflow.ellipsis),
                        ))
                    .toList(),
                onChanged: (v) => setLocal(() => uidSel = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: rolSel,
                isExpanded: true,
                dropdownColor: AppTheme.fondoCard,
                style: const TextStyle(
                    color: AppTheme.textoBlanco, fontSize: 14),
                decoration:
                    InputDecoration(labelText: t.tr('pl_rol_label')),
                items: rolesConHueco
                    .map((r) => DropdownMenuItem(
                          value: r,
                          child: Text(
                              '$r  (${(confirmadosPorRol[r] ?? 0)}/${plazas[r]})'),
                        ))
                    .toList(),
                onChanged: (v) => setLocal(() => rolSel = v ?? rolSel),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(t.tr('cancelar'),
                  style: const TextStyle(color: AppTheme.textoSecundario)),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.verdeNeon,
                  foregroundColor: Colors.black),
              child: Text(t.tr('pl_anadir_btn')),
            ),
          ],
        ),
      ),
    );

    if (confirmar != true || uidSel == null) return;
    final nombre = (_workers[uidSel]?['nombre'] as String?) ?? '';
    final telefono = (_workers[uidSel]?['telefono'] as String?) ?? '';
    try {
      await PostulacionesService.anadirIntegrante(
        eventoId: widget.eventoId,
        trabajadorId: uidSel!,
        rol: rolSel,
        nombre: nombre,
        telefono: telefono,
      );
      if (mounted) {
        showTopSnackBar(context, t.tr('pl_anadido'),
            backgroundColor: AppTheme.verdeNeon,
            icon: Icons.check_circle_outline);
      }
    } on RolCompletoException {
      if (mounted) {
        showTopSnackBar(context, t.tr('pl_rol_completo'),
            backgroundColor: AppTheme.amarilloAdvertencia,
            icon: Icons.info_outline);
      }
    } catch (_) {
      if (mounted) {
        showTopSnackBar(context, t.tr('pl_err_anadir'),
            backgroundColor: AppTheme.rojoError, icon: Icons.error_outline);
      }
    }
  }

  Widget _cabeceraRol(
      String rol, Map<String, int> plazas, Map<String, int> confirmados) {
    final c = confirmados[rol] ?? 0;
    final p = plazas[rol] ?? 0;
    return Row(
      children: [
        Text(rol,
            style: const TextStyle(
                color: AppTheme.textoBlanco,
                fontSize: 14,
                fontWeight: FontWeight.w600)),
        const SizedBox(width: 8),
        Text('$c/$p ${context.watch<IdiomaProvider>().tr('pl_confirmados_conteo')}',
            style: const TextStyle(
                color: AppTheme.textoTerciario, fontSize: 12)),
      ],
    );
  }

  Widget _tarjetaPostulacion(
    Postulacion p,
    Map<String, int> plazas,
    Map<String, int> confirmadosPorRol,
  ) {
    final info = _workers[p.trabajadorId];
    final nombre = (info?['nombre'] as String?)?.trim();
    final mostrado = (nombre != null && nombre.isNotEmpty)
        ? nombre
        : context.watch<IdiomaProvider>().tr('pl_trabajador');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.fondoCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.bordeCard),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppTheme.verdeNeon.withValues(alpha: 0.15),
            child: Text(
              mostrado.isNotEmpty ? mostrado[0].toUpperCase() : '?',
              style: const TextStyle(
                  color: AppTheme.verdeNeon,
                  fontSize: 13,
                  fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(mostrado,
                style: Theme.of(context).textTheme.bodyMedium,
                overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 8),
          // Descartar
          OutlinedButton(
            onPressed: () => _descartar(p),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.textoSecundario,
              side: const BorderSide(color: AppTheme.bordeCampo),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              textStyle: const TextStyle(fontSize: 13),
            ),
            child: Text(context.watch<IdiomaProvider>().tr('pl_descartar')),
          ),
          const SizedBox(width: 8),
          // Confirmar
          FilledButton(
            onPressed: () => _confirmar(p, plazas, confirmadosPorRol),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.verdeNeon,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              textStyle: const TextStyle(fontSize: 13),
            ),
            child: Text(context.watch<IdiomaProvider>().tr('pl_confirmar')),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmar(
    Postulacion p,
    Map<String, int> plazas,
    Map<String, int> confirmadosPorRol,
  ) async {
    final t = context.read<IdiomaProvider>();
    final c = confirmadosPorRol[p.rol] ?? 0;
    final plaza = plazas[p.rol] ?? 0;

    // CUPO DURO (Fase 5): no se puede confirmar a un rol lleno. Para meter uno más,
    // hay que editar el evento y subir las plazas de ese rol.
    if (c >= plaza) {
      showTopSnackBar(context, t.tr('pl_rol_completo'),
          backgroundColor: AppTheme.amarilloAdvertencia,
          icon: Icons.info_outline);
      return;
    }

    final info = _workers[p.trabajadorId];
    try {
      await PostulacionesService.confirmar(
        postulacionId: p.id,
        eventoId: p.eventoId,
        trabajadorId: p.trabajadorId,
        rol: p.rol,
        nombre: (info?['nombre'] as String?) ?? '',
        telefono: (info?['telefono'] as String?) ?? '',
        tituloEvento: widget.tituloEvento,
      );
      if (mounted) {
        showTopSnackBar(context, t.tr('pl_confirmado_ok'),
            backgroundColor: AppTheme.verdeNeon,
            icon: Icons.check_circle_outline);
      }
    } on RolCompletoException {
      // Salvaguarda ante carreras: el rol se llenó entre la comprobación y el commit.
      if (mounted) {
        showTopSnackBar(context, t.tr('pl_rol_completo'),
            backgroundColor: AppTheme.amarilloAdvertencia,
            icon: Icons.info_outline);
      }
    } catch (_) {
      if (mounted) {
        showTopSnackBar(context, t.tr('pl_err_confirmar'),
            backgroundColor: AppTheme.rojoError, icon: Icons.error_outline);
      }
    }
  }

  Future<void> _descartar(Postulacion p) async {
    final t = context.read<IdiomaProvider>();
    try {
      await PostulacionesService.descartar(p.id);
      if (mounted) {
        showTopSnackBar(context, t.tr('pl_descartada'),
            backgroundColor: AppTheme.textoTerciario, icon: Icons.close);
      }
    } catch (_) {
      if (mounted) {
        showTopSnackBar(context, t.tr('pl_err_descartar'),
            backgroundColor: AppTheme.rojoError, icon: Icons.error_outline);
      }
    }
  }
}

// Etiqueta de sección en mayúsculas (CONFIRMADOS / PENDIENTES).
class _EtiquetaSeccion extends StatelessWidget {
  final String texto;
  const _EtiquetaSeccion(this.texto);

  @override
  Widget build(BuildContext context) {
    return Text(texto,
        style: const TextStyle(
            color: AppTheme.textoTerciario,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5));
  }
}

// ─────────────────────────────────────────
// Cobertura por rol (confirmados / plazas)
// ─────────────────────────────────────────

class _Cobertura extends StatelessWidget {
  final Map<String, int> plazas;
  final Map<String, int> confirmados;

  const _Cobertura({required this.plazas, required this.confirmados});

  @override
  Widget build(BuildContext context) {
    if (plazas.isEmpty) {
      return Text(context.watch<IdiomaProvider>().tr('pl_sin_plazas_evento'),
          style: const TextStyle(color: AppTheme.textoSecundario, fontSize: 13));
    }
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: plazas.entries.map((e) {
        final c = confirmados[e.key] ?? 0;
        final lleno = e.value > 0 && c >= e.value;
        final color = lleno ? AppTheme.verdeNeon : AppTheme.textoSecundario;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.fondoCard,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: lleno ? AppTheme.verdeNeon : AppTheme.bordeCard),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(lleno ? Icons.check_circle : Icons.groups_outlined,
                  size: 15, color: color),
              const SizedBox(width: 6),
              Text('${e.key}  ',
                  style: const TextStyle(
                      color: AppTheme.textoBlanco, fontSize: 13)),
              Text('$c/${e.value}',
                  style: TextStyle(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        );
      }).toList(),
    );
  }
}
