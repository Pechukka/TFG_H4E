import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';
import '../utils/top_snackbar.dart';

// Clave global para navegar desde los handlers de FCM sin BuildContext
late final GlobalKey<NavigatorState> appNavigatorKey;

// El MainScaffold escucha este notifier para cambiar de pestaña al abrir una notificación
final ValueNotifier<int?> pendingNavTab = ValueNotifier<int?>(null);

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

class FcmService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // Inicializa FCM al autenticar el usuario
  static Future<void> initialize(String userId) async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    final token = await _messaging.getToken();
    if (token != null) await _saveToken(userId, token);

    _messaging.onTokenRefresh.listen((newToken) => _saveToken(userId, newToken));
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpened);

    // App abierta desde notificación en estado terminado
    final initial = await _messaging.getInitialMessage();
    if (initial != null) _handleMessageOpened(initial);
  }

  static Future<void> _saveToken(String userId, String token) async {
    await FirebaseFirestore.instance
        .collection(AppConstants.colUsers)
        .doc(userId)
        .update({'fcmToken': token});
  }

  static void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    final context = appNavigatorKey.currentContext;
    if (context == null) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.notifDesactivadas) return;

    showTopSnackBar(
      context,
      notification.title ?? '',
      subtitle: notification.body,
      backgroundColor: AppTheme.fondoCard,
      icon: Icons.notifications,
      iconColor: AppTheme.verdeNeon,
      duration: const Duration(seconds: 4),
    );
  }

  static void _handleMessageOpened(RemoteMessage message) {
    final tipo = message.data['tipo'] ?? '';
    switch (tipo) {
      case 'nuevoEvento':
      case 'cambioEvento':
      case 'nuevoMensaje':
      case 'recordatorio':
        pendingNavTab.value = 2;
        break;
      case 'nominaPublicada':
      case 'documentoRequerido':
        pendingNavTab.value = 3;
        break;
      default:
        pendingNavTab.value = 0;
    }
  }
}
