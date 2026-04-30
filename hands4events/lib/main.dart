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

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    if (!authProvider.isAuthenticated) {
      authProvider.initialize();
    }

    if (authProvider.isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0F0A),
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF84CC16),
          ),
        ),
      );
    }

    return authProvider.isAuthenticated 
        ? const MainScaffold() 
        : const LoginScreen();
  }
}