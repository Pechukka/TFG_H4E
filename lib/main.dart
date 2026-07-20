import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/eventos_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/fichaje_provider.dart';
import 'providers/nominas_provider.dart';
import 'providers/notificaciones_provider.dart';
import 'providers/idioma_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_scaffold.dart';
import 'screens/admin/admin_shell.dart';
import 'screens/auth/primer_login_screen.dart';
import 'services/fcm_service.dart';
import 'core/theme.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  appNavigatorKey = GlobalKey<NavigatorState>();

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
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => FichajeProvider()),
        ChangeNotifierProvider(create: (_) => NominasProvider()),
        ChangeNotifierProvider(create: (_) => NotificacionesProvider()),
        ChangeNotifierProvider(create: (_) => IdiomaProvider()),
      ],
      child: MaterialApp(
        title: 'Hands4Events',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        navigatorKey: appNavigatorKey,
        home: const AuthWrapper(),
      ),
    );
  }
}

// El spinner solo aparece en el arranque inicial; LoginScreen permanece montado durante login/logout
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _inicializado = false;
  bool _eraAutenticado = false;
  AuthProvider? _authProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _authProvider = Provider.of<AuthProvider>(context, listen: false);
      _authProvider!.addListener(_onAuthStateChanged);

      await _authProvider!.initialize();

      if (mounted) {
        _eraAutenticado = _authProvider!.isAuthenticated;

        final idioma = _authProvider!.currentUser?.idioma ?? 'es';
        Provider.of<IdiomaProvider>(context, listen: false).cambiarIdioma(idioma);

        // Si ya hay sesión activa, inicializar FCM (solo móvil — web no soportado sin VAPID)
        if (!kIsWeb && _authProvider!.isAuthenticated && _authProvider!.currentUserId != null) {
          FcmService.initialize(_authProvider!.currentUserId!);
        }

        setState(() => _inicializado = true);
      }
    });
  }

  @override
  void dispose() {
    _authProvider?.removeListener(_onAuthStateChanged);
    super.dispose();
  }

  void _onAuthStateChanged() {
    final isAuth = _authProvider?.isAuthenticated ?? false;

    if (!_eraAutenticado && isAuth) {
      // Usuario acaba de iniciar sesión — inicializar FCM (solo móvil)
      final userId = _authProvider?.currentUserId;
      if (!kIsWeb && userId != null) FcmService.initialize(userId);
    }

    if (_eraAutenticado && !isAuth) {
      // Usuario acaba de cerrar sesión — resetear todos los providers
      if (mounted) {
        context.read<EventosProvider>().reset();
        context.read<NominasProvider>().reset();
        context.read<NotificacionesProvider>().reset();
        context.read<FichajeProvider>().reset();
        context.read<ChatProvider>().reset();
      }
    }

    _eraAutenticado = isAuth;
  }

  @override
  Widget build(BuildContext context) {
    if (!_inicializado) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0F0A),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF84CC16)),
        ),
      );
    }

    final authProvider = Provider.of<AuthProvider>(context);
    if (!authProvider.isAuthenticated) return const LoginScreen();
    if (authProvider.currentUser?.debeReiniciarPassword == true) {
      return const PrimerLoginScreen();
    }
    final esAdmin = authProvider.currentUser?.rol == 'admin';
    if (esAdmin && kIsWeb) return const AdminShell();
    return const MainScaffold();
  }
}
