import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import '../core/constants.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Sube una imagen del chat (MÓVIL) y devuelve la URL de descarga.
  // En web no se puede usar dart:io File — ver subirImagenChatBytes.
  Future<String> subirImagenChat(File archivo, String eventoId) async {
    final extension = path.extension(archivo.path);
    final ref = _storage.ref().child(_rutaChat(eventoId, extension));
    final uploadTask = await ref.putFile(archivo);
    return await uploadTask.ref.getDownloadURL();
  }

  // Sube una imagen del chat desde sus BYTES (web, donde no hay dart:io File).
  // Hace falta pasar el contentType para que Storage la sirva como imagen.
  Future<String> subirImagenChatBytes({
    required Uint8List bytes,
    required String eventoId,
    required String extension,
    required String contentType,
  }) async {
    final ref = _storage.ref().child(_rutaChat(eventoId, extension));
    final uploadTask =
        await ref.putData(bytes, SettableMetadata(contentType: contentType));
    return await uploadTask.ref.getDownloadURL();
  }

  String _rutaChat(String eventoId, String extension) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final ext = extension.isEmpty ? '.jpg' : extension;
    return '${AppConstants.storageChatImages}/chat_${eventoId}_$timestamp$ext';
  }
}