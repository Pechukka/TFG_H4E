import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

// Providers
import 'providers/auth_provider.dart';
import 'providers/eventos_provider.dart';
import 'providers/perfil_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/fichaje_provider.dart';

// Screens
import 'screens/auth/login_screen.dart';
import 'screens/main_scaffold.dart';

// Core
import 'core/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp();
    print('✅ Firebase inicializado correctamente');
  } catch (e) {
    print('❌ Error al inicializar Firebase: $e');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => EventosProvider()),
        ChangeNotifierProvider(create: (_) => PerfilProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => FichajeProvider()),
      ],
      child: MaterialApp(
        title: 'Hands4Events',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const AuthWrapper(),
      ),
    );
  }
}

/// Wrapper que decide mostrar Login o MainScaffold
/// El spinner SOLO aparece en el arranque inicial (initialize),
/// NO durante login/logout → así LoginScreen permanece montado
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _inicializado = false;

  @override
  void initState() {
    super.initState();
    // Verificar sesión guardada al arrancar la app
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.initialize();
      if (mounted) {
        setState(() => _inicializado = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Spinner solo mientras verifica sesión al arrancar
    if (!_inicializado) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0F0A),
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF84CC16),
          ),
        ),
      );
    }

    final authProvider = Provider.of<AuthProvider>(context);

    // Una vez inicializado: MainScaffold o LoginScreen según sesión
    return authProvider.isAuthenticated
        ? const MainScaffold()
        : const LoginScreen();
  }
}