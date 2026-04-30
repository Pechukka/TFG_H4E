import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Servicio de Notificaciones Push
/// Gestiona Firebase Cloud Messaging para notificaciones en tiempo real
class NotificationsService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// INICIALIZAR NOTIFICACIONES
  Future<void> initialize() async {
    // Solicitar permisos
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ Permisos de notificaciones concedidos');
      
      // Obtener token FCM
      final token = await _messaging.getToken();
      if (token != null) {
        print('📱 Token FCM: $token');
        // Guardar token en Firestore (para enviar notificaciones desde admin)
        await _guardarTokenFCM(token);
      }

      // Escuchar cuando el token se actualice
      _messaging.onTokenRefresh.listen(_guardarTokenFCM);
    } else {
      print('❌ Permisos de notificaciones denegados');
    }
  }

  /// GUARDAR TOKEN FCM EN FIRESTORE
  Future<void> _guardarTokenFCM(String token) async {
    // Obtener userId del servicio de auth
    // Por ahora solo guardamos el token
    // En producción: guardar en documento del usuario
    print('Token FCM guardado: $token');
  }

  /// CONFIGURAR MANEJADORES DE NOTIFICACIONES
  void configurarManejadores({
    required Function(RemoteMessage) onMessageReceived,
    required Function(RemoteMessage) onMessageOpened,
  }) {
    // Cuando la app está en foreground
    FirebaseMessaging.onMessage.listen(onMessageReceived);

    // Cuando se abre una notificación (app en background)
    FirebaseMessaging.onMessageOpenedApp.listen(onMessageOpened);

    // Manejar notificación que abrió la app (cuando estaba terminada)
    _messaging.getInitialMessage().then((message) {
      if (message != null) {
        onMessageOpened(message);
      }
    });
  }

  /// SUSCRIBIRSE A UN TOPIC (para notificaciones masivas)
  Future<void> suscribirseATopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
    print('✅ Suscrito al topic: $topic');
  }

  /// DESUSCRIBIRSE DE UN TOPIC
  Future<void> desuscribirseDeEvento(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
    print('❌ Desuscrito del topic: $topic');
  }

  /// OBTENER TOKEN ACTUAL
  Future<String?> getToken() async {
    return await _messaging.getToken();
  }

  /// ELIMINAR TOKEN (al cerrar sesión)
  Future<void> eliminarToken() async {
    await _messaging.deleteToken();
  }
}

/// Manejador de notificaciones en background (fuera de la clase)
/// Debe ser función top-level
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('📩 Notificación en background: ${message.notification?.title}');
}