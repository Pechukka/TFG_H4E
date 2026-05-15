import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hands4events/core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/idioma_provider.dart';
import 'modal_base.dart';

const List<Map<String, String>> _avatares = [
  {'url': 'https://api.dicebear.com/7.x/bottts-neutral/png?seed=felix&size=128', 'nombre': 'Bot Félix'},
  {'url': 'https://api.dicebear.com/7.x/bottts-neutral/png?seed=aneka&size=128', 'nombre': 'Bot Aneka'},
  {'url': 'https://api.dicebear.com/7.x/bottts-neutral/png?seed=nova&size=128', 'nombre': 'Bot Nova'},
  {'url': 'https://api.dicebear.com/7.x/adventurer-neutral/png?seed=lily&size=128', 'nombre': 'Lily'},
  {'url': 'https://api.dicebear.com/7.x/adventurer-neutral/png?seed=max&size=128', 'nombre': 'Max'},
  {'url': 'https://api.dicebear.com/7.x/adventurer-neutral/png?seed=sofia&size=128', 'nombre': 'Sofía'},
  {'url': 'https://api.dicebear.com/7.x/fun-emoji/png?seed=cookie&size=128', 'nombre': 'Cookie'},
  {'url': 'https://api.dicebear.com/7.x/fun-emoji/png?seed=mia&size=128', 'nombre': 'Mia'},
  {'url': 'https://api.dicebear.com/7.x/pixel-art-neutral/png?seed=leo&size=128', 'nombre': 'Leo'},
  {'url': 'https://api.dicebear.com/7.x/pixel-art-neutral/png?seed=zara&size=128', 'nombre': 'Zara'},
];

class ModalSeleccionarAvatar extends StatefulWidget {
  const ModalSeleccionarAvatar({super.key});

  @override
  State<ModalSeleccionarAvatar> createState() => _ModalSeleccionarAvatarState();
}

class _ModalSeleccionarAvatarState extends State<ModalSeleccionarAvatar> {
  String? _seleccionado;
  File? _imagenLocal;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _seleccionado = context.read<AuthProvider>().currentUser?.avatarUrl;
  }

  Future<void> _elegirDeGaleria() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() {
        _imagenLocal = File(picked.path);
        _seleccionado = null;
      });
    }
  }

  Future<void> _tomarFoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() {
        _imagenLocal = File(picked.path);
        _seleccionado = null;
      });
    }
  }

  Future<void> _guardar(IdiomaProvider t) async {
    if (_imagenLocal == null && _seleccionado == null) return;
    setState(() => _isLoading = true);

    bool exito;
    if (_imagenLocal != null) {
      exito = await context.read<AuthProvider>().subirYActualizarAvatar(_imagenLocal!);
    } else {
      exito = await context.read<AuthProvider>().updateProfile(avatarUrl: _seleccionado);
    }

    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(exito ? t.tr('avatar_actualizado') : t.tr('error_actualizar_avatar')),
          backgroundColor: exito ? AppTheme.verdeExito : AppTheme.rojoError,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _eliminarAvatar() async {
    setState(() => _isLoading = true);
    await context.read<AuthProvider>().updateProfile(avatarUrl: '');
    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<IdiomaProvider>();
    final avatarActual = context.read<AuthProvider>().currentUser?.avatarUrl ?? '';
    final haySeleccion = _imagenLocal != null || _seleccionado != null;

    return ModalBase(
      titulo: t.tr('seleccionar_avatar'),
      contenido: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildBotonFuente(
                  context: context,
                  icono: Icons.photo_library_outlined,
                  label: t.tr('galeria'),
                  onTap: _isLoading ? null : _elegirDeGaleria,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildBotonFuente(
                  context: context,
                  icono: Icons.camera_alt_outlined,
                  label: t.tr('camara'),
                  onTap: _isLoading ? null : _tomarFoto,
                ),
              ),
            ],
          ),

          if (_imagenLocal != null) ...[
            const SizedBox(height: 16),
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  ClipOval(
                    child: Image.file(
                      _imagenLocal!,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _imagenLocal = null),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppTheme.rojoError,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.fondoPrincipal, width: 2),
                      ),
                      child: const Icon(Icons.close, color: Colors.white, size: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          Text(
            t.tr('avatar_predefinido'),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textoSecundario,
                ),
          ),
          const SizedBox(height: 16),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1,
            ),
            itemCount: _avatares.length,
            itemBuilder: (context, index) {
              final avatar = _avatares[index];
              final url = avatar['url']!;
              final estaSeleccionado = _seleccionado == url && _imagenLocal == null;

              return GestureDetector(
                onTap: () => setState(() {
                  _seleccionado = url;
                  _imagenLocal = null;
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: estaSeleccionado ? AppTheme.verdeNeon : Colors.transparent,
                      width: 3,
                    ),
                    boxShadow: estaSeleccionado
                        ? [
                            BoxShadow(
                              color: AppTheme.verdeNeon.withValues(alpha: 0.4),
                              blurRadius: 8,
                              spreadRadius: 2,
                            )
                          ]
                        : null,
                  ),
                  child: ClipOval(
                    child: Image.network(
                      url,
                      fit: BoxFit.cover,
                      loadingBuilder: (_, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          color: AppTheme.fondoInput,
                          child: const Center(
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: AppTheme.verdeNeon),
                            ),
                          ),
                        );
                      },
                      errorBuilder: (_, __, ___) => Container(
                        color: AppTheme.fondoInput,
                        child: const Icon(Icons.person, color: AppTheme.textoTerciario),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          if (avatarActual.isNotEmpty) ...[
            const SizedBox(height: 16),
            InkWell(
              onTap: _isLoading ? null : _eliminarAvatar,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.text_fields, color: AppTheme.textoSecundario, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      t.tr('usar_iniciales'),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textoSecundario,
                            decoration: TextDecoration.underline,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
      botonesAccion: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: (_isLoading || !haySeleccion) ? null : () => _guardar(t),
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
                    t.tr('guardar_avatar'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildBotonFuente({
    required BuildContext context,
    required IconData icono,
    required String label,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.fondoInput,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.bordeCampo),
        ),
        child: Column(
          children: [
            Icon(icono, color: AppTheme.verdeNeon, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textoSecundario,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
