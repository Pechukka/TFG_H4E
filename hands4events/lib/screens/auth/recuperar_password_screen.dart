import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
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

  void _handleEnviarInstrucciones() {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _emailEnviado = true;
          });
          
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) {
              Navigator.pop(context);
            }
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.fondoPrincipal,
      appBar: AppBar(
        backgroundColor: AppTheme.fondoInput,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textoBlanco),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'RECUPERAR CONTRASEÑA',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: AppTheme.textoTerciario,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: false,
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
                        ? 'Hemos enviado las instrucciones de recuperación a tu correo.\n\nRevisa tu bandeja de entrada.'
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