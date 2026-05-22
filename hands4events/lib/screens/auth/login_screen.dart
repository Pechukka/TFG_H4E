import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hands4events/core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/idioma_provider.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/primary_button.dart';
import 'recuperar_password_screen.dart';
import '../../utils/top_snackbar.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final t = context.read<IdiomaProvider>();
      final exito = await authProvider.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (mounted) {
        setState(() => _isLoading = false);

        if (exito) {
          showTopSnackBar(context, t.tr('bienvenido'),
              backgroundColor: AppTheme.verdeNeon,
              icon: Icons.check_circle_outline);
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
    if (error.contains('user-not-found') || error.contains('invalid-credential')) {
      return t.tr('error_credenciales');
    } else if (error.contains('wrong-password')) {
      return t.tr('error_credenciales');
    } else if (error.contains('too-many-requests')) {
      return t.tr('error_muchos_intentos');
    } else if (error.contains('network-request-failed')) {
      return t.tr('error_sin_conexion');
    }
    return t.tr('error_sesion_gen');
  }

  void _navigateToRecuperarPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RecuperarPasswordScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<IdiomaProvider>();

    return Scaffold(
      backgroundColor: AppTheme.fondoPrincipal,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),

                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.fondoInput,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        t.tr('inicio_sesion_etiqueta'),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTheme.textoTerciario,
                          letterSpacing: 1.5,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 60),

                  Center(
                    child: Image.asset(
                      'assets/images/logo_hand.png',
                      width: 140,
                      height: 140,
                      fit: BoxFit.contain,
                    ),
                  ),

                  const SizedBox(height: 40),

                  Center(
                    child: Text(
                      t.tr('iniciar_sesion'),
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Center(
                    child: Text(
                      t.tr('subtitulo_login'),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textoSecundario,
                        height: 1.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  CustomTextField(
                    hintText: t.tr('email_usuario'),
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return t.tr('error_campo_email');
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  CustomTextField(
                    hintText: t.tr('contrasena'),
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: AppTheme.textoSecundario,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return t.tr('error_campo_contrasena');
                      }
                      if (value.length < 6) {
                        return t.tr('error_contrasena_corta');
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 32),

                  PrimaryButton(
                    text: t.tr('iniciar_sesion'),
                    onPressed: _handleLogin,
                    isLoading: _isLoading,
                  ),

                  const SizedBox(height: 24),

                  Center(
                    child: TextButton(
                      onPressed: _navigateToRecuperarPassword,
                      child: Text(
                        t.tr('olvidaste_contrasena'),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.verdeNeon,
                          decoration: TextDecoration.underline,
                          decorationColor: AppTheme.verdeNeon,
                        ),
                      ),
                    ),
                  ),

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
