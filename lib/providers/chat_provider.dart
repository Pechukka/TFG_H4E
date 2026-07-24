import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import '../models/mensaje.dart';
import '../services/chat_service.dart';
import '../services/storage_service.dart';

class ChatProvider with ChangeNotifier {
  final ChatService _chatService = ChatService();
  final StorageService _storageService = StorageService();

  List<Mensaje> _mensajes = [];
  bool _isLoading = false;
  bool _isSending = false;
  String? _errorMessage;
  int _mensajesNoLeidos = 0;

  List<Mensaje> get mensajes => _mensajes;
  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  String? get errorMessage => _errorMessage;
  int get mensajesNoLeidos => _mensajesNoLeidos;

  void cargarMensajes(String eventoId) {
    _setLoading(true);
    _chatService.getMensajesEvento(eventoId).listen(
      (mensajes) {
        _mensajes = mensajes;
        _isLoading = false;
        notifyListeners();
      },
      onError: (error) => _setError('Error al cargar mensajes: $error'),
    );
  }

  Future<bool> enviarMensaje({
    required String eventoId,
    required String remitenteId,
    required String remitenteNombre,
    required String texto,
    String? replyToId,
    String? replyToNombre,
    String? replyToTexto,
  }) async {
    if (texto.trim().isEmpty) return false;
    _isSending = true;
    _clearError();
    notifyListeners();
    try {
      await _chatService.enviarMensaje(
        eventoId: eventoId,
        remitenteId: remitenteId,
        remitenteNombre: remitenteNombre,
        texto: texto,
        replyToId: replyToId,
        replyToNombre: replyToNombre,
        replyToTexto: replyToTexto,
      );
      _isSending = false;
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Error al enviar mensaje: $e');
      _isSending = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> enviarMensajeConImagen({
    required String eventoId,
    required String remitenteId,
    required String remitenteNombre,
    required XFile imagen,
    String? texto,
  }) async {
    _isSending = true;
    _clearError();
    notifyListeners();
    try {
      // En web no existe dart:io File: se suben los bytes con putData.
      // En móvil se mantiene el flujo con putFile.
      final String imagenUrl;
      if (kIsWeb) {
        final bytes = await imagen.readAsBytes();
        final extension = path.extension(imagen.name);
        imagenUrl = await _storageService.subirImagenChatBytes(
          bytes: bytes,
          eventoId: eventoId,
          extension: extension,
          contentType: imagen.mimeType ?? _contentTypeDe(extension),
        );
      } else {
        imagenUrl =
            await _storageService.subirImagenChat(File(imagen.path), eventoId);
      }
      await _chatService.enviarMensajeConImagen(
        eventoId: eventoId,
        remitenteId: remitenteId,
        remitenteNombre: remitenteNombre,
        imagenUrl: imagenUrl,
        texto: texto,
      );
      _isSending = false;
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Error al enviar imagen: $e');
      _isSending = false;
      notifyListeners();
      return false;
    }
  }

  // Tipo MIME a partir de la extensión, por si el picker no lo trae (web).
  String _contentTypeDe(String extension) {
    switch (extension.toLowerCase()) {
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      case '.heic':
        return 'image/heic';
      default:
        return 'image/jpeg';
    }
  }

  Future<bool> enviarUbicacion({
    required String eventoId,
    required String remitenteId,
    required String remitenteNombre,
    required double lat,
    required double lng,
  }) async {
    _isSending = true;
    _clearError();
    notifyListeners();
    try {
      await _chatService.enviarUbicacion(
        eventoId: eventoId,
        remitenteId: remitenteId,
        remitenteNombre: remitenteNombre,
        lat: lat,
        lng: lng,
      );
      _isSending = false;
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Error al enviar ubicación: $e');
      _isSending = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> editarMensaje(String mensajeId, String nuevoTexto) async {
    try {
      await _chatService.editarMensaje(mensajeId, nuevoTexto);
      return true;
    } catch (e) {
      _setError('Error al editar mensaje: $e');
      notifyListeners();
      return false;
    }
  }

  Future<bool> eliminarMensaje(String mensajeId) async {
    try {
      await _chatService.eliminarMensaje(mensajeId);
      return true;
    } catch (e) {
      _setError('Error al eliminar mensaje: $e');
      notifyListeners();
      return false;
    }
  }

  Future<void> marcarMensajesLeidos(String eventoId, String userId) async {
    try {
      await _chatService.marcarMensajesLeidos(eventoId, userId);
      _mensajesNoLeidos = 0;
      notifyListeners();
    } catch (e) {
      _setError('Error al marcar mensajes como leídos: $e');
    }
  }

  Future<void> contarMensajesNoLeidos(String eventoId, String userId) async {
    try {
      _mensajesNoLeidos =
          await _chatService.contarMensajesNoLeidos(eventoId, userId);
      notifyListeners();
    } catch (e) {
      _setError('Error al contar mensajes no leídos: $e');
    }
  }

  void limpiarMensajes() {
    _mensajes = [];
    _mensajesNoLeidos = 0;
    notifyListeners();
  }

  void reset() {
    limpiarMensajes();
    _isLoading = false;
    _isSending = false;
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() => _errorMessage = null;

  void clearError() {
    _clearError();
    notifyListeners();
  }
}
