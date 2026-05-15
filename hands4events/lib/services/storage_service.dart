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
    final ruta = 'avatars/$userId/avatar$extension';
    final ref = _storage.ref().child(ruta);
    final uploadTask = await ref.putFile(archivo);
    return await uploadTask.ref.getDownloadURL();
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

}