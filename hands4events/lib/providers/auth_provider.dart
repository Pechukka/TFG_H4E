import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

/// Provider de Autenticación
/// Gestiona el estado de autenticación del usuario
class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;
  String? get currentUserId => _currentUser?.id;

  /// INICIALIZAR - Verificar si hay usuario logueado
  Future<void> initialize() async {
    _setLoading(true);
    
    final firebaseUser = _authService.currentFirebaseUser;
    if (firebaseUser != null) {
      _currentUser = await _authService.getUserData(firebaseUser.uid);
      notifyListeners();
    }
    
    _setLoading(false);
  }

  /// LOGIN
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      _currentUser = await _authService.login(email, password);
      _setLoading(false);
      notifyListeners();
      return _currentUser != null;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// REGISTRO
  Future<bool> register({
    required String email,
    required String password,
    required String nombre,
    String? telefono,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      _currentUser = await _authService.register(
        email: email,
        password: password,
        nombre: nombre,
        telefono: telefono,
      );
      _setLoading(false);
      notifyListeners();
      return _currentUser != null;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// LOGOUT
  Future<void> logout() async {
    _setLoading(true);
    await _authService.logout();
    _currentUser = null;
    _setLoading(false);
    notifyListeners();
  }

  /// ACTUALIZAR PERFIL
  Future<bool> updateProfile({
    String? nombre,
    String? telefono,
    String? direccion,
    String? idioma,
  }) async {
    if (_currentUser == null) return false;

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
      _currentUser = _currentUser!.copyWith(
        nombre: nombre ?? _currentUser!.nombre,
        telefono: telefono ?? _currentUser!.telefono,
        direccion: direccion ?? _currentUser!.direccion,
        idioma: idioma ?? _currentUser!.idioma,
      );

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// VERIFICAR SI UN EMAIL EXISTE EN FIRESTORE
  Future<bool> emailExisteEnFirestore(String email) async {
    return await _authService.emailExisteEnFirestore(email);
  }

  /// RECUPERAR CONTRASEÑA
  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.resetPassword(email);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// CAMBIAR CONTRASEÑA
  Future<bool> changePassword(String currentPassword, String newPassword) async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.changePassword(currentPassword, newPassword);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// RECARGAR DATOS DEL USUARIO
  Future<void> reloadUserData() async {
    if (_currentUser == null) return;

    final updatedUser = await _authService.getUserData(_currentUser!.id);
    if (updatedUser != null) {
      _currentUser = updatedUser;
      notifyListeners();
    }
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

  /// Limpiar mensaje de error manualmente
  void clearError() {
    _clearError();
    notifyListeners();
  }
}