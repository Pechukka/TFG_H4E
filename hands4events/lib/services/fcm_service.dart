import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../core/theme.dart';

/// Global navigator key — set in main.dart and passed to MaterialApp.navigatorKey
/// so FCM handlers can navigate and show SnackBars without a BuildContext.
late final GlobalKey<NavigatorState> appNavigatorKey;

/// Used to switch tabs from a notification tap.
/// MainScaffold listens to this notifier and changes its currentIndex.
final ValueNotifier<int?> pendingNavTab = ValueNotifier<int?>(null);

/// Background handler — must be top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // No UI work here — just log or store if needed
}

class FcmService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Call once when the user authenticates.
  static Future<void> initialize(String userId) async {
    // Request permission (required on iOS; on Android 13+ too)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    // Get token and save it
    final token = await _messaging.getToken();
    if (token != null) await _saveToken(userId, token);

    // Update token when it rotates
    _messaging.onTokenRefresh.listen((newToken) => _saveToken(userId, newToken));

    // Foreground messages — show a SnackBar
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Background tap — user opened the app by tapping the notification
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpened);

    // Check if the app was launched from a terminated state by a notification tap
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.fondoCard,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        content: Row(
          children: [
            const Icon(Icons.notifications, color: AppTheme.verdeNeon, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (notification.title != null)
                    Text(
                      notification.title!,
                      style: const TextStyle(
                        color: AppTheme.textoBlanco,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  if (notification.body != null)
                    Text(
                      notification.body!,
                      style: const TextStyle(
                        color: AppTheme.textoSecundario,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void _handleMessageOpened(RemoteMessage message) {
    final tipo = message.data['tipo'] ?? '';
    switch (tipo) {
      case 'nuevoEvento':
      case 'cambioEvento':
        pendingNavTab.value = 2; // Eventos tab
        break;
      case 'nuevoMensaje':
        pendingNavTab.value = 2; // Eventos tab (para abrir el chat desde ahí)
        break;
      case 'nominaPublicada':
      case 'documentoRequerido':
        pendingNavTab.value = 3; // Perfil tab (tiene acceso a nóminas)
        break;
      default:
        pendingNavTab.value = 0; // Dashboard tab
    }
  }
}
