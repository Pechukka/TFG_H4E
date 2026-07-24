import 'package:flutter/material.dart';
import 'package:hands4events/core/theme.dart';
import '../../../services/admin_service.dart';
import '../../../utils/top_snackbar.dart';

// Activación manual del evento ("Crear grupo"), compartida por la lista de eventos
// (menú del chip de estado) y la pantalla de gestión del evento (botón visible), para
// que las dos vías se comporten exactamente igual.

// Plazas que faltan por cubrir, por rol. Excluye al admin creador del conteo.
Map<String, int> faltantesPorRol(Map<String, dynamic> data) {
  final plazas = (data['plazasPorRol'] as Map<String, dynamic>? ?? {})
      .map((k, v) => MapEntry(k, (v as num).toInt()));
  final roles = Map<String, String>.from(data['trabajadoresRoles'] ?? {});
  final creadoPor = data['creadoPor'] as String?;

  final confirmadosPorRol = <String, int>{};
  roles.forEach((uid, rol) {
    if (uid == creadoPor) return;
    confirmadosPorRol[rol] = (confirmadosPorRol[rol] ?? 0) + 1;
  });

  final faltan = <String, int>{};
  plazas.forEach((rol, plaza) {
    final c = confirmadosPorRol[rol] ?? 0;
    if (plaza - c > 0) faltan[rol] = plaza - c;
  });
  return faltan;
}

// Avisa de la cobertura actual y, si el admin acepta, pone el evento en 'activo'.
// Se puede activar aunque falten plazas: el admin decide. Devuelve true si se activó.
Future<bool> crearGrupoEvento(
    BuildContext context, String eventoId, Map<String, dynamic> data) async {
  final faltan = faltantesPorRol(data);
  final contenido = faltan.isEmpty
      ? 'El equipo está completo. Se creará el grupo y el evento pasará a activo '
          '(sale del feed y se abre el chat).'
      : 'Aún faltan plazas por cubrir:\n\n'
          '${faltan.entries.map((e) => '· ${e.key}: faltan ${e.value}').join('\n')}'
          '\n\n¿Crear el grupo igualmente? El evento saldrá del feed.';

  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppTheme.fondoCard,
      title: const Text('Crear grupo',
          style: TextStyle(color: AppTheme.textoBlanco)),
      content:
          Text(contenido, style: const TextStyle(color: AppTheme.textoSecundario)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancelar',
              style: TextStyle(color: AppTheme.textoSecundario)),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: FilledButton.styleFrom(
              backgroundColor: AppTheme.verdeNeon,
              foregroundColor: Colors.black),
          child: const Text('Crear grupo'),
        ),
      ],
    ),
  );
  if (ok != true) return false;

  try {
    await AdminService.actualizarEstadoEvento(eventoId, 'activo');
    if (context.mounted) {
      showTopSnackBar(context, 'Grupo creado: evento activo',
          backgroundColor: AppTheme.verdeNeon,
          icon: Icons.check_circle_outline);
    }
    return true;
  } catch (_) {
    if (context.mounted) {
      showTopSnackBar(context, 'No se pudo crear el grupo',
          backgroundColor: AppTheme.rojoError, icon: Icons.error_outline);
    }
    return false;
  }
}
