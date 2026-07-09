import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hands4events/core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/idioma_provider.dart';
import '../../widgets/app_bar_custom.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/primary_button.dart';
import '../../utils/top_snackbar.dart';

class RecuperarPasswordScreen extends StatefulWidget {
  const RecuperarPasswordScreen({super.key});

  @override
  State<RecuperarPasswordScreen> createState() => _RecuperarPasswordScreenState();
}

class _RecuperarPasswordScreenState extends State<RecuperarPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailEnviado = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleEnviarInstrucciones(IdiomaProvider t) async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final email = _emailController.text.trim();

      final exito = await authProvider.resetPassword(email);

      if (mounted) {
        setState(() => _isLoading = false);

        if (exito) {
          setState(() => _emailEnviado = true);
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) Navigator.pop(context);
          });
        } else {
          final error = authProvider.errorMessage ?? '';
          showTopSnackBar(context, _traducirError(error, t),
              backgroundColor: AppTheme.rojoError, icon: Icons.error_outline);
          authProvider.clearError();
        }
      }
    }
  }

  String _traducirError(String error, IdiomaProvider t) {
    if (error.contains('user-not-found') || error.contains('invalid-email')) {
      return t.tr('error_correo_no_encontrado');
    } else if (error.contains('network-request-failed')) {
      return t.tr('error_sin_conexion');
    } else if (error.contains('too-many-requests')) {
      return t.tr('error_muchos_intentos');
    }
    return t.tr('error_enviar_correo');
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<IdiomaProvider>();

    return Scaffold(
      backgroundColor: AppTheme.fondoPrincipal,
      appBar: AppBarCustom(
        showLogo: false,
        showBackButton: true,
        title: t.tr('recuperar_contrasena'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 60),

                  Image.asset(
                    'assets/images/logo_hand.png',
                    width: 140,
                    height: 140,
                    fit: BoxFit.contain,
                  ),

                  const SizedBox(height: 40),

                  Text(
                    _emailEnviado
                        ? t.tr('correo_enviado_titulo')
                        : t.tr('introduce_tu_correo'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),

                  const SizedBox(height: 16),

                  Text(
                    _emailEnviado
                        ? t.tr('correo_recibido_desc')
                        : t.tr('instrucciones_desc'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textoSecundario,
                          height: 1.6,
                        ),
                  ),

                  const SizedBox(height: 40),

                  if (!_emailEnviado) ...[
                    CustomTextField(
                      hintText: t.tr('correo_electronico'),
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return t.tr('ingresa_correo_error');
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                            .hasMatch(value)) {
                          return t.tr('correo_invalido_error');
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 32),

                    PrimaryButton(
                      text: t.tr('enviar_instrucciones'),
                      onPressed: () => _handleEnviarInstrucciones(t),
                      isLoading: _isLoading,
                    ),
                  ],

                  if (_emailEnviado) ...[
                    const Icon(
                      Icons.check_circle,
                      size: 80,
                      color: AppTheme.verdeExito,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      t.tr('redirigiendo_login'),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textoSecundario,
                          ),
                    ),
                  ],

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
