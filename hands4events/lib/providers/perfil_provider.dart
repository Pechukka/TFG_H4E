import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

/// Provider de Perfil
/// Gestiona el perfil del usuario y subida de avatar
class PerfilProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();

  User? _user;
  bool _isLoading = false;
  bool _isUploadingAvatar = false;
  String? _errorMessage;

  // Getters
  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isUploadingAvatar => _isUploadingAvatar;
  String? get errorMessage => _errorMessage;

  /// CARGAR DATOS DEL USUARIO
  Future<void> cargarPerfil(String userId) async {
    _setLoading(true);
    _clearError();

    try {
      _user = await _authService.getUserData(userId);
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Error al cargar perfil: $e');
      _setLoading(false);
    }
  }

  /// ACTUALIZAR PERFIL
  Future<bool> actualizarPerfil({
    String? nombre,
    String? telefono,
    String? direccion,
    String? idioma,
  }) async {
    if (_user == null) return false;

    _setLoading(true);
    _clearError();

    try {
      await _authService.updateProfile(
        nombre: nombre,
        telefono: telefono,
        direccion: direccion,
        idioma: idioma,
      );

      // Actualizar usuario local
      _user = _user!.copyWith(
        nombre: nombre ?? _user!.nombre,
        telefono: telefono ?? _user!.telefono,
        direccion: direccion ?? _user!.direccion,
        idioma: idioma ?? _user!.idioma,
      );

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Error al actualizar perfil: $e');
      _setLoading(false);
      return false;
    }
  }

  /// SUBIR AVATAR
  Future<bool> subirAvatar(File imagen) async {
    if (_user == null) return false;

    _isUploadingAvatar = true;
    _clearError();
    notifyListeners();

    try {
      // Subir imagen a Firebase Storage
      final url = await _storageService.subirAvatar(imagen, _user!.id);

      // Actualizar URL en Firestore
      await _authService.updateProfile();
      
      // Actualizar usuario local
      _user = _user!.copyWith(avatarUrl: url);

      _isUploadingAvatar = false;
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Error al subir avatar: $e');
      _isUploadingAvatar = false;
      notifyListeners();
      return false;
    }
  }

  /// CAMBIAR CONTRASEÑA
  Future<bool> cambiarContrasena(String currentPassword, String newPassword) async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.changePassword(currentPassword, newPassword);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Error al cambiar contraseña: $e');
      _setLoading(false);
      return false;
    }
  }

  /// RECARGAR PERFIL
  Future<void> recargarPerfil() async {
    if (_user == null) return;
    await cargarPerfil(_user!.id);
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