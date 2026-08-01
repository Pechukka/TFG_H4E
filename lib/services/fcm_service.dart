import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../providers/auth_provider.dart';

// Clave global para navegar desde los handlers de FCM sin BuildContext
late final GlobalKey<NavigatorState> appNavigatorKey;

// El MainScaffold escucha este notifier para cambiar de pestaña al abrir una notificación
final ValueNotifier<int?> pendingNavTab = ValueNotifier<int?>(null);

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

// Plugin de notificaciones locales: se usa SOLO para mostrar el heads-up del sistema
// cuando llega un push con la app en primer plano (en segundo plano/cerrada lo pinta
// el propio sistema a partir del payload `notification` que manda la Cloud Function).
final FlutterLocalNotificationsPlugin _localNotifs =
    FlutterLocalNotificationsPlugin();

// Mismo canal (id, importancia) que crea MainActivity.kt y declara el AndroidManifest,
// para que suene y salga como heads-up igual que las de segundo plano.
const AndroidNotificationChannel _canal = AndroidNotificationChannel(
  'hands4events_notificaciones',
  'Notificaciones Hands4Events',
  description: 'Notificaciones de eventos, mensajes y nóminas',
  importance: Importance.high,
);

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

    await _initLocalNotifs();

    final token = await _messaging.getToken();
    if (token != null) await _saveToken(userId, token);

    _messaging.onTokenRefresh.listen((newToken) => _saveToken(userId, newToken));
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpened);

    // App abierta desde notificación en estado terminado
    final initial = await _messaging.getInitialMessage();
    if (initial != null) _handleMessageOpened(initial);
  }

  // Prepara el plugin local y asegura que el canal existe con alta importancia.
  static Future<void> _initLocalNotifs() async {
    const androidInit = AndroidInitializationSettings('@mipmap/launcher_icon');
    const iosInit = DarwinInitializationSettings();
    await _localNotifs.initialize(
      settings:
          const InitializationSettings(android: androidInit, iOS: iosInit),
      // Al tocar el heads-up mostrado en primer plano, navegamos igual que con FCM.
      onDidReceiveNotificationResponse: (resp) =>
          _navegarPorTipo(resp.payload ?? ''),
    );
    await _localNotifs
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_canal);
  }

  static Future<void> _saveToken(String userId, String token) async {
    await FirebaseFirestore.instance
        .collection(AppConstants.colUsers)
        .doc(userId)
        .update({'fcmToken': token});
  }

  // App en PRIMER PLANO: FCM no muestra nada por sí solo, así que pintamos nosotros
  // el heads-up del sistema (estilo WhatsApp) con el plugin de notificaciones locales.
  static void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    // Respetar la preferencia del usuario (notificaciones silenciadas).
    final context = appNavigatorKey.currentContext;
    if (context != null) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.notifDesactivadas) return;
    }

    final tipo =
        (message.data['tipo'] ?? '').replaceFirst('TipoNotificacion.', '');

    _localNotifs.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _canal.id,
          _canal.name,
          channelDescription: _canal.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/launcher_icon',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: tipo,
    );
  }

  static void _handleMessageOpened(RemoteMessage message) {
    // El campo `tipo` viaja con el prefijo del enum de Dart
    // (p. ej. 'TipoNotificacion.nuevoEvento'); lo quitamos para poder comparar.
    final tipo =
        (message.data['tipo'] ?? '').replaceFirst('TipoNotificacion.', '');
    _navegarPorTipo(tipo);
  }

  // Decide a qué pestaña saltar según el tipo de notificación abierta.
  static void _navegarPorTipo(String tipo) {
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
