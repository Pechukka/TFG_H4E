class AppConstants {
  static const String googleMapsApiKey = 'AIzaSyDSmbT8xDTvuonInBdCxAqdxuPu_7uOs3Y';

  // Roles
  static const String rolWorker = 'worker';
  static const String rolAdmin = 'admin';

  // Colecciones Firestore
  static const String colUsers = 'users';
  static const String colEventos = 'eventos';
  static const String colFichajes = 'fichajes';
  static const String colDisponibilidad = 'disponibilidad';
  static const String colMensajes = 'mensajes';
  static const String colNominas = 'nominas';

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