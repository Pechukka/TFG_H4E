class AppConstants {
  // 🔧 AJUSTAR: La API key de Google Maps YA NO va hardcodeada en el código.
  // La key antigua está comprometida (estuvo en el repo público) → genera una NUEVA
  // en Google Cloud restringida por app/dominio y desactiva/borra la vieja.
  // Se pasa por --dart-define al ejecutar o compilar. Ejemplos:
  //   flutter run --dart-define=GOOGLE_MAPS_API_KEY=tu_key_nueva
  //   flutter build apk --dart-define=GOOGLE_MAPS_API_KEY=tu_key_nueva
  // Si no se pasa, queda vacía y las llamadas a Google Maps fallarán (esperado).
  static const String googleMapsApiKey =
      String.fromEnvironment('GOOGLE_MAPS_API_KEY');

  // Roles
  static const String rolWorker = 'worker';
  static const String rolAdmin = 'admin';

  // Colecciones Firestore
  static const String colUsers = 'users';
  static const String colEventos = 'eventos';
  static const String colFichajes = 'fichajes';
  static const String colMensajes = 'mensajes';
  static const String colNominas = 'nominas';
  static const String colPostulaciones = 'postulaciones';
  static const String colNotificaciones = 'notificaciones';

  // Rutas de Storage
  static const String storageNominas = 'nominas';
  static const String storageChatImages = 'chat_images';

  static const int minPasswordLength = 6;

  // Días de la semana
  static const List<String> diasSemana = [
    '',
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];
  
  // Meses del año
  static const List<String> meses = [
    '',
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre',
  ];
}