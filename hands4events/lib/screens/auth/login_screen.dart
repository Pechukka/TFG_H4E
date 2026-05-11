import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hands4events/core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/primary_button.dart';
import 'recuperar_password_screen.dart';

/// Pantalla de inicio de sesión
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
  bool _recordarCuenta = false;
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
      final exito = await authProvider.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (mounted) {
        setState(() => _isLoading = false);

        if (exito) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('¡Bienvenido! Iniciando sesión...'),
              backgroundColor: AppTheme.verdeNeon.withOpacity(0.9),
              behavior: SnackBarBehavior.floating,
            ),
          );
          // AuthWrapper detecta isAuthenticated=true y navega a MainScaffold
        } else {
          final error = authProvider.errorMessage ?? 'Error al iniciar sesión';
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

  /// Traduce errores de Firebase a mensajes legibles
  String _traducirError(String error) {
    if (error.contains('user-not-found') || error.contains('invalid-credential')) {
      return 'Correo o contraseña incorrectos';
    } else if (error.contains('wrong-password')) {
      return 'Contraseña incorrecta';
    } else if (error.contains('too-many-requests')) {
      return 'Demasiados intentos. Espera unos minutos';
    } else if (error.contains('network-request-failed')) {
      return 'Sin conexión a internet';
    }
    return 'Error al iniciar sesión. Inténtalo de nuevo';
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
                  
                  // Header con etiqueta (estilo Figma - más pequeño y centrado)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.fondoInput,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'INICIO DE SESIÓN',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTheme.textoTerciario,
                          letterSpacing: 1.5,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 60),
                  
                  // Logo de la mano verde GRANDE
                  Center(
                    child: Image.asset(
                      'assets/images/logo_hand.png',
                      width: 140,
                      height: 140,
                      fit: BoxFit.contain,
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Título
                  Center(
                    child: Text(
                      'Iniciar Sesión',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Subtítulo
                  Center(
                    child: Text(
                      'Accede a tu cuenta corporativa para gestionar eventos y\ncoordinar equipos de trabajo.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textoSecundario,
                        height: 1.5,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Campo Email/Usuario
                  CustomTextField(
                    hintText: 'Correo electrónico o nombre de usuario',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingresa tu correo o usuario';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Campo Contraseña
                  CustomTextField(
                    hintText: 'Contraseña',
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
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingresa tu contraseña';
                      }
                      if (value.length < 6) {
                        return 'La contraseña debe tener al menos 6 caracteres';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Checkbox Recordar cuenta
                  Row(
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: _recordarCuenta,
                          onChanged: (value) {
                            setState(() {
                              _recordarCuenta = value ?? false;
                            });
                          },
                          activeColor: AppTheme.verdeNeon,
                          checkColor: AppTheme.textoSobreVerde,
                          side: const BorderSide(
                            color: AppTheme.bordeCampo,
                            width: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Recordar cuenta',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Botón Iniciar Sesión
                  PrimaryButton(
                    text: 'Iniciar Sesión',
                    onPressed: _handleLogin,
                    isLoading: _isLoading,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Link ¿Olvidaste tu contraseña?
                  Center(
                    child: TextButton(
                      onPressed: _navigateToRecuperarPassword,
                      child: Text(
                        '¿Olvidaste tu contraseña?',
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