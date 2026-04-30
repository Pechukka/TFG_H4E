import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/mensaje.dart';
import '../services/chat_service.dart';
import '../services/storage_service.dart';

/// Provider de Chat
/// Gestiona mensajes en tiempo real por evento
class ChatProvider with ChangeNotifier {
  final ChatService _chatService = ChatService();
  final StorageService _storageService = StorageService();

  List<Mensaje> _mensajes = [];
  bool _isLoading = false;
  bool _isSending = false;
  String? _errorMessage;
  int _mensajesNoLeidos = 0;

  // Getters
  List<Mensaje> get mensajes => _mensajes;
  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  String? get errorMessage => _errorMessage;
  int get mensajesNoLeidos => _mensajesNoLeidos;

  /// CARGAR MENSAJES DEL EVENTO
  void cargarMensajes(String eventoId) {
    _chatService.getMensajesEvento(eventoId).listen(
      (mensajes) {
        _mensajes = mensajes;
        notifyListeners();
      },
      onError: (error) {
        _setError('Error al cargar mensajes: $error');
      },
    );
  }

  /// ENVIAR MENSAJE
  Future<bool> enviarMensaje({
    required String eventoId,
    required String remitenteId,
    required String remitenteNombre,
    required String texto,
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

  /// ENVIAR MENSAJE CON IMAGEN
  Future<bool> enviarMensajeConImagen({
    required String eventoId,
    required String remitenteId,
    required String remitenteNombre,
    required File imagen,
    String? texto,
  }) async {
    _isSending = true;
    _clearError();
    notifyListeners();

    try {
      // Subir imagen a Storage
      final imagenUrl = await _storageService.subirImagenChat(imagen, eventoId);

      // Enviar mensaje con URL de imagen
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

  /// MARCAR MENSAJES COMO LEÍDOS
  Future<void> marcarMensajesLeidos(String eventoId, String userId) async {
    try {
      await _chatService.marcarMensajesLeidos(eventoId, userId);
      _mensajesNoLeidos = 0;
      notifyListeners();
    } catch (e) {
      _setError('Error al marcar mensajes como leídos: $e');
    }
  }

  /// CONTAR MENSAJES NO LEÍDOS
  Future<void> contarMensajesNoLeidos(String eventoId, String userId) async {
    try {
      _mensajesNoLeidos = await _chatService.contarMensajesNoLeidos(eventoId, userId);
      notifyListeners();
    } catch (e) {
      _setError('Error al contar mensajes no leídos: $e');
    }
  }

  /// LIMPIAR MENSAJES (al salir del chat)
  void limpiarMensajes() {
    _mensajes = [];
    _mensajesNoLeidos = 0;
    notifyListeners();
  }

  // Métodos auxiliares
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void clearError() {
    _clearError();
    notifyListeners();
  }
}