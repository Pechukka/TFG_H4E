import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/idioma_provider.dart';

class PrimerLoginScreen extends StatefulWidget {
  const PrimerLoginScreen({super.key});

  @override
  State<PrimerLoginScreen> createState() => _PrimerLoginScreenState();
}

class _PrimerLoginScreenState extends State<PrimerLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nuevaCtrl = TextEditingController();
  final _confirmarCtrl = TextEditingController();
  bool _verNueva = false;
  bool _verConfirmar = false;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _nuevaCtrl.dispose();
    _confirmarCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _error = null; });

    final auth = context.read<AuthProvider>();
    final t = context.read<IdiomaProvider>();
    final ok = await auth.updatePasswordDirect(_nuevaCtrl.text);
    if (!ok || !mounted) {
      setState(() { _isLoading = false; _error = auth.errorMessage ?? t.tr('plogin_error'); });
      auth.clearError();
      return;
    }

    await auth.marcarPasswordReinicializada();
    // AuthWrapper reconstruye automáticamente al notifyListeners
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<IdiomaProvider>();
    return Scaffold(
      backgroundColor: AppTheme.fondoPrincipal,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lock_reset, color: AppTheme.verdeNeon, size: 48),
                    const SizedBox(height: 20),
                    Text(
                      t.tr('plogin_titulo'),
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      t.tr('plogin_subtitulo'),
                      style: const TextStyle(color: AppTheme.textoSecundario),
                    ),
                    const SizedBox(height: 32),
                    _campoPassword(t.tr('plogin_nueva'), _nuevaCtrl, _verNueva,
                        onToggle: () => setState(() => _verNueva = !_verNueva),
                        validator: (v) {
                          if (v == null || v.isEmpty) return t.tr('plogin_obligatorio');
                          if (v.length < 8) return t.tr('plogin_min8');
                          return null;
                        }),
                    const SizedBox(height: 16),
                    _campoPassword(t.tr('plogin_confirmar'), _confirmarCtrl, _verConfirmar,
                        onToggle: () => setState(() => _verConfirmar = !_verConfirmar),
                        validator: (v) {
                          if (v != _nuevaCtrl.text) return t.tr('plogin_no_coinciden');
                          return null;
                        }),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.rojoError.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.rojoError.withValues(alpha: 0.4)),
                        ),
                        child: Text(_error!, style: const TextStyle(color: AppTheme.rojoError, fontSize: 13)),
                      ),
                    ],
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        onPressed: _isLoading ? null : _guardar,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.verdeNeon,
                          foregroundColor: AppTheme.textoSobreVerde,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                              )
                            : Text(t.tr('plogin_guardar'),
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _campoPassword(
    String label,
    TextEditingController ctrl,
    bool visible, {
    required VoidCallback onToggle,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: ctrl,
      obscureText: !visible,
      style: const TextStyle(color: AppTheme.textoBlanco),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppTheme.textoSecundario),
        filled: true,
        fillColor: AppTheme.fondoCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppTheme.bordeCard),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppTheme.bordeCard),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppTheme.verdeNeon),
        ),
        suffixIcon: IconButton(
          icon: Icon(visible ? Icons.visibility_off : Icons.visibility,
              color: AppTheme.textoSecundario, size: 20),
          onPressed: onToggle,
        ),
      ),
      validator: validator,
    );
  }
}
