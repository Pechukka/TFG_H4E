import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import '../core/constants.dart';

/// Servicio de Almacenamiento
/// Gestiona subida/descarga de archivos en Firebase Storage
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// SUBIR AVATAR DE USUARIO
  Future<String> subirAvatar(File archivo, String userId) async {
    final extension = path.extension(archivo.path);
    final nombreArchivo = 'avatar_$userId$extension';
    final ruta = '${AppConstants.storageAvatars}/$nombreArchivo';

    final ref = _storage.ref().child(ruta);
    final uploadTask = await ref.putFile(archivo);
    final url = await uploadTask.ref.getDownloadURL();

    return url;
  }

  /// SUBIR IMAGEN DE CHAT
  Future<String> subirImagenChat(File archivo, String eventoId) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = path.extension(archivo.path);
    final nombreArchivo = 'chat_${eventoId}_$timestamp$extension';
    final ruta = '${AppConstants.storageChatImages}/$nombreArchivo';

    final ref = _storage.ref().child(ruta);
    final uploadTask = await ref.putFile(archivo);
    final url = await uploadTask.ref.getDownloadURL();

    return url;
  }

  /// DESCARGAR NÓMINA (obtener URL)
  Future<String?> obtenerUrlNomina(String nombreArchivo) async {
    try {
      final ruta = '${AppConstants.storageNominas}/$nombreArchivo';
      final ref = _storage.ref().child(ruta);
      final url = await ref.getDownloadURL();
      return url;
    } catch (e) {
      return null;
    }
  }

  /// ELIMINAR ARCHIVO
  Future<void> eliminarArchivo(String rutaCompleta) async {
    try {
      final ref = _storage.ref().child(rutaCompleta);
      await ref.delete();
    } catch (e) {
      // Archivo no existe o error de permisos
      print('Error al eliminar archivo: $e');
    }
  }

  /// OBTENER TAMAÑO DE ARCHIVO
  Future<int> obtenerTamanoArchivo(String rutaCompleta) async {
    final ref = _storage.ref().child(rutaCompleta);
    final metadata = await ref.getMetadata();
    return metadata.size ?? 0;
  }
}