import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hands4events/core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_bar_custom.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/primary_button.dart';

/// Pantalla de recuperación de contraseña
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

  Future<void> _handleEnviarInstrucciones() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final email = _emailController.text.trim();

      // Verificar primero si el email existe en nuestra base de datos
      final existe = await authProvider.emailExisteEnFirestore(email);

      if (mounted && !existe) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No existe ninguna cuenta con ese correo electrónico'),
            backgroundColor: AppTheme.rojoError,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      // Email existe → enviar instrucciones
      final exito = await authProvider.resetPassword(email);

      if (mounted) {
        setState(() => _isLoading = false);

        if (exito) {
          setState(() => _emailEnviado = true);
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) Navigator.pop(context);
          });
        } else {
          final error = authProvider.errorMessage ?? 'Error al enviar correo';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_traducirError(error)),
              backgroundColor: AppTheme.rojoError,
              behavior: SnackBarBehavior.floating,
            ),
          );
          authProvider.clearError();
        }
      }
    }
  }

  String _traducirError(String error) {
    if (error.contains('user-not-found') || error.contains('invalid-email')) {
      return 'No existe una cuenta con ese correo';
    } else if (error.contains('network-request-failed')) {
      return 'Sin conexión a internet';
    } else if (error.contains('too-many-requests')) {
      return 'Demasiados intentos. Espera unos minutos';
    }
    return 'Error al enviar el correo. Inténtalo de nuevo';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.fondoPrincipal,
      appBar: const AppBarCustom(
        showLogo: false,
        showBackButton: true,
        title: 'Recuperar contraseña',
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
                  
                  // Logo de la mano verde GRANDE
                  Image.asset(
                    'assets/images/logo_hand.png',
                    width: 140,
                    height: 140,
                    fit: BoxFit.contain,
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Título
                  Text(
                    _emailEnviado
                        ? '¡Correo enviado!'
                        : 'Introduce tu correo electrónico',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Subtítulo
                  Text(
                    _emailEnviado
                        ? 'Si el correo está registrado en nuestra plataforma, recibirás las instrucciones en tu bandeja de entrada.'
                        : 'Te enviaremos instrucciones para restablecer tu contraseña.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textoSecundario,
                      height: 1.6,
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  if (!_emailEnviado) ...[
                    CustomTextField(
                      hintText: 'Correo electrónico',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa tu correo electrónico';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                            .hasMatch(value)) {
                          return 'Por favor ingresa un correo válido';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 32),
                    
                    PrimaryButton(
                      text: 'Enviar instrucciones',
                      onPressed: _handleEnviarInstrucciones,
                      isLoading: _isLoading,
                    ),
                  ],
                  
                  if (_emailEnviado) ...[
                    Icon(
                      Icons.check_circle,
                      size: 80,
                      color: AppTheme.verdeExito,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Redirigiendo al inicio de sesión...',
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