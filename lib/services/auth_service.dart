import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import '../core/constants.dart';

class AuthService {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<firebase_auth.User?> get authStateChanges => _auth.authStateChanges();
  firebase_auth.User? get currentFirebaseUser => _auth.currentUser;
  String? get currentUserId => _auth.currentUser?.uid;
  bool get isLoggedIn => _auth.currentUser != null;

  Future<User?> login(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (credential.user != null) {
        return await getUserData(credential.user!.uid);
      }
      return null;
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<User?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection(AppConstants.colUsers).doc(uid).get();
      if (doc.exists) return User.fromFirestore(doc);
      // Si no existe el doc el admin lo eliminó — cerrar sesión
      await _auth.signOut();
      return null;
    } catch (e) {
      throw 'Error al obtener datos del usuario';
    }
  }

  Future<void> updateProfile({
    String? nombre,
    String? telefono,
    String? direccion,
    String? idioma,
    String? avatarUrl,
    bool? notifActivadas,
  }) async {
    if (currentUserId == null) throw 'Usuario no autenticado';

    final updates = <String, dynamic>{};
    if (nombre != null) updates['nombre'] = nombre;
    if (telefono != null) updates['telefono'] = telefono;
    if (direccion != null) updates['direccion'] = direccion;
    if (idioma != null) updates['idioma'] = idioma;
    if (avatarUrl != null) updates['avatarUrl'] = avatarUrl;
    if (notifActivadas != null) updates['notifActivadas'] = notifActivadas;

    if (updates.isEmpty) return;

    await _firestore
        .collection(AppConstants.colUsers)
        .doc(currentUserId)
        .update(updates);
  }

  // Solo válido justo después del login, no requiere reautenticación
  Future<void> updatePasswordDirect(String newPassword) async {
    final user = _auth.currentUser;
    if (user == null) throw 'Usuario no autenticado';
    try {
      await user.updatePassword(newPassword);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<void> updateProfileRaw(Map<String, dynamic> datos) async {
    if (currentUserId == null) throw 'Usuario no autenticado';
    await _firestore
        .collection(AppConstants.colUsers)
        .doc(currentUserId)
        .update(datos);
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Traduce los códigos de error de Firebase Auth a mensajes legibles
  String _handleAuthException(firebase_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No existe ninguna cuenta con este correo';
      case 'wrong-password':
        return 'Contraseña incorrecta';
      case 'email-already-in-use':
        return 'Este correo ya está registrado';
      case 'invalid-email':
        return 'Correo electrónico inválido';
      case 'weak-password':
        return 'La contraseña es demasiado débil';
      case 'user-disabled':
        return 'Esta cuenta ha sido deshabilitada';
      case 'too-many-requests':
        return 'Demasiados intentos. Intenta más tarde';
      case 'network-request-failed':
        return 'Error de conexión. Verifica tu internet';
      default:
        return 'Error de autenticación: ${e.message}';
    }
  }
}
