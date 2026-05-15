import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hands4events/core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/idioma_provider.dart';
import 'modal_base.dart';

class ModalSeleccionarIdioma extends StatefulWidget {
  const ModalSeleccionarIdioma({super.key});

  @override
  State<ModalSeleccionarIdioma> createState() => _ModalSeleccionarIdiomaState();
}

class _ModalSeleccionarIdiomaState extends State<ModalSeleccionarIdioma> {
  late String _codigoSeleccionado;
  bool _isLoading = false;

  static const List<Map<String, String>> _idiomas = [
    {'codigo': 'es', 'clave': 'idioma_es', 'bandera': '🇪🇸'},
    {'codigo': 'en', 'clave': 'idioma_en', 'bandera': '🇬🇧'},
  ];

  @override
  void initState() {
    super.initState();
    _codigoSeleccionado =
        Provider.of<AuthProvider>(context, listen: false).currentUser?.idioma ?? 'es';
  }

  Future<void> _guardar(IdiomaProvider t) async {
    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final idiomaProvider = Provider.of<IdiomaProvider>(context, listen: false);

    final exito = await authProvider.updateProfile(idioma: _codigoSeleccionado);

    if (exito) {
      idiomaProvider.cambiarIdioma(_codigoSeleccionado);
    }

    if (mounted) {
      setState(() => _isLoading = false);
      final clave = _idiomas.firstWhere((i) => i['codigo'] == _codigoSeleccionado)['clave']!;
      final nombre = t.tr(clave);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(exito
              ? '${t.tr('idioma_cambiado_a')} $nombre'
              : t.tr('error_cambiar_idioma')),
          backgroundColor: exito ? AppTheme.verdeExito : AppTheme.rojoError,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<IdiomaProvider>();

    return ModalBase(
      titulo: t.tr('seleccionar_idioma'),
      contenido: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _idiomas.map((idioma) {
          final estaSeleccionado = _codigoSeleccionado == idioma['codigo'];

          return InkWell(
            onTap: () => setState(() => _codigoSeleccionado = idioma['codigo']!),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: estaSeleccionado
                    ? AppTheme.verdeNeon.withValues(alpha: 0.1)
                    : AppTheme.fondoInput,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: estaSeleccionado ? AppTheme.verdeNeon : AppTheme.bordeCampo,
                  width: estaSeleccionado ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Text(idioma['bandera']!, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      t.tr(idioma['clave']!),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: estaSeleccionado
                                ? AppTheme.verdeNeon
                                : AppTheme.textoBlanco,
                          ),
                    ),
                  ),
                  if (estaSeleccionado)
                    const Icon(Icons.check_circle, color: AppTheme.verdeNeon, size: 24),
                ],
              ),
            ),
          );
        }).toList(),
      ),
      botonesAccion: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : () => _guardar(t),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.verdeNeon,
              foregroundColor: AppTheme.textoSobreVerde,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.textoSobreVerde),
                  )
                : Text(
                    t.tr('confirmar_cambio'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
      ],
    );
  }
}
