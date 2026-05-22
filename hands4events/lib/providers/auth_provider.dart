import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<DocumentSnapshot>? _userDocSub;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;
  String? get currentUserId => _currentUser?.id;

  Future<void> initialize() async {
    _setLoading(true);

    final firebaseUser = _authService.currentFirebaseUser;
    if (firebaseUser != null) {
      _currentUser = await _authService.getUserData(firebaseUser.uid);
      if (_currentUser != null) _listenToUserDoc(firebaseUser.uid);
      notifyListeners();
    }

    _setLoading(false);
  }

  // Si el admin elimina al usuario, lo expulsa al login en tiempo real
  void _listenToUserDoc(String uid) {
    _userDocSub?.cancel();
    _userDocSub = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen((snap) {
      if (!snap.exists) logout();
    });
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      _currentUser = await _authService.login(email, password);
      if (_currentUser != null) _listenToUserDoc(_currentUser!.id);
      _setLoading(false);
      notifyListeners();
      return _currentUser != null;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<void> logout() async {
    _userDocSub?.cancel();
    _userDocSub = null;
    _setLoading(true);
    await _authService.logout();
    _currentUser = null;
    _setLoading(false);
    notifyListeners();
  }

  Future<bool> updateProfile({
    String? nombre,
    String? telefono,
    String? direccion,
    String? idioma,
    String? avatarUrl,
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
        avatarUrl: avatarUrl,
      );

      _currentUser = _currentUser!.copyWith(
        nombre: nombre ?? _currentUser!.nombre,
        telefono: telefono ?? _currentUser!.telefono,
        direccion: direccion ?? _currentUser!.direccion,
        idioma: idioma ?? _currentUser!.idioma,
        avatarUrl: avatarUrl ?? _currentUser!.avatarUrl,
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

  Future<bool> actualizarNotificaciones(bool activadas) async {
    if (_currentUser == null) return false;
    try {
      await _authService.updateProfile(notifActivadas: activadas);
      _currentUser = _currentUser!.copyWith(notifActivadas: activadas);
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  bool get notifDesactivadas => !(_currentUser?.notifActivadas ?? true);

  Future<bool> updatePasswordDirect(String newPassword) async {
    _setLoading(true);
    _clearError();
    try {
      await _authService.updatePasswordDirect(newPassword);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<void> marcarPasswordReinicializada() async {
    if (_currentUser == null) return;
    await _authService.updateProfileRaw({'debeReiniciarPassword': false});
    _currentUser = _currentUser!.copyWith(debeReiniciarPassword: false);
    notifyListeners();
  }

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