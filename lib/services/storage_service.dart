import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import '../core/constants.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Sube una imagen del chat y devuelve la URL de descarga
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