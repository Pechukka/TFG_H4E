import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hands4events/core/theme.dart';
import '../../../models/postulacion.dart';
import '../../../services/admin_service.dart';
import '../../../services/postulaciones_service.dart';
import '../../../utils/top_snackbar.dart';

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
      _workers = {
        for (final w in lista)
          (w['uid'] as String): {
            'nombre': w['nombre'] ?? '',
            'telefono': w['telefono'] ?? '',
          }
      };
      _cargandoWorkers = false;
    });
  }

  @override
  Widget build(BuildContext context) {
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
                    tooltip: 'Volver',
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Postulaciones',
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

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Cobertura(
                            plazas: plazas,
                            confirmados: confirmadosPorRol),
                        const SizedBox(height: 20),
                        const Text('PENDIENTES',
                            style: TextStyle(
                                color: AppTheme.textoTerciario,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5)),
                        const SizedBox(height: 12),
                        Expanded(
                          child: _buildPendientes(
                              plazas, confirmadosPorRol),
                        ),
                      ],
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
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.inbox_outlined,
                    color: AppTheme.textoSecundario, size: 44),
                SizedBox(height: 12),
                Text('No hay postulaciones pendientes',
                    style: TextStyle(color: AppTheme.textoSecundario)),
              ],
            ),
          );
        }

        // Agrupar por rol
        final porRol = <String, List<Postulacion>>{};
        for (final p in pendientes) {
          porRol.putIfAbsent(p.rol, () => []).add(p);
        }

        return ListView(
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
        Text('$c/$p confirmados',
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
    final mostrado =
        (nombre != null && nombre.isNotEmpty) ? nombre : 'Trabajador';

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
            child: const Text('Descartar'),
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
            child: const Text('Confirmar'),
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
    final c = confirmadosPorRol[p.rol] ?? 0;
    final plaza = plazas[p.rol] ?? 0;

    // Si el rol ya está lleno, avisar pero dejar decidir al admin.
    if (plaza > 0 && c >= plaza) {
      final seguir = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppTheme.fondoCard,
          title: const Text('Rol completo',
              style: TextStyle(color: AppTheme.textoBlanco)),
          content: Text(
            'El rol ${p.rol} ya está completo ($c/$plaza). '
            '¿Confirmar a esta persona de todos modos?',
            style: const TextStyle(color: AppTheme.textoSecundario),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar',
                  style: TextStyle(color: AppTheme.textoSecundario)),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style:
                  FilledButton.styleFrom(backgroundColor: AppTheme.verdeNeon),
              child: const Text('Confirmar igual',
                  style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      );
      if (seguir != true) return;
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
      );
      if (mounted) {
        showTopSnackBar(context, 'Trabajador confirmado',
            backgroundColor: AppTheme.verdeNeon,
            icon: Icons.check_circle_outline);
      }
    } catch (_) {
      if (mounted) {
        showTopSnackBar(context, 'No se pudo confirmar',
            backgroundColor: AppTheme.rojoError, icon: Icons.error_outline);
      }
    }
  }

  Future<void> _descartar(Postulacion p) async {
    try {
      await PostulacionesService.descartar(p.id);
      if (mounted) {
        showTopSnackBar(context, 'Postulación descartada',
            backgroundColor: AppTheme.textoTerciario, icon: Icons.close);
      }
    } catch (_) {
      if (mounted) {
        showTopSnackBar(context, 'No se pudo descartar',
            backgroundColor: AppTheme.rojoError, icon: Icons.error_outline);
      }
    }
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
      return const Text('Este evento no define plazas por rol.',
          style: TextStyle(color: AppTheme.textoSecundario, fontSize: 13));
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
