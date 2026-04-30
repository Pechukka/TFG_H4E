class AppConstants {
  // Roles
  static const String rolWorker = 'worker';
  static const String rolAdmin = 'admin';

  // Firebase Collections
  static const String colUsers = 'users';
  static const String colEventos = 'eventos';
  static const String colFichajes = 'fichajes';
  static const String colDisponibilidad = 'disponibilidad';
  static const String colMensajes = 'mensajes';
  static const String colNominas = 'nominas';

  // Storage Paths
  static const String storageNominas = 'nominas';
  static const String storageAvatars = 'avatars';
  static const String storageChatImages = 'chat_images';

  // Validaciones
  static const int minPasswordLength = 6;
  static const int phoneLength = 9;
  
  // Límites
  static const int maxChatImageSize = 5 * 1024 * 1024; // 5MB
  static const int maxAvatarSize = 2 * 1024 * 1024; // 2MB
  
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