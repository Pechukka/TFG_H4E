import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import '../core/constants.dart';

/// Servicio de Autenticación
/// Gestiona login, registro, logout y sesión del usuario
class AuthService {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream del estado de autenticación
  Stream<firebase_auth.User?> get authStateChanges => _auth.authStateChanges();

  // Usuario actual de Firebase Auth
  firebase_auth.User? get currentFirebaseUser => _auth.currentUser;

  // UID del usuario actual
  String? get currentUserId => _auth.currentUser?.uid;

  // Verificar si hay un usuario logueado
  bool get isLoggedIn => _auth.currentUser != null;

  /// LOGIN - Iniciar sesión con email y contraseña
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

  /// REGISTRO - Crear nueva cuenta
  Future<User?> register({
    required String email,
    required String password,
    required String nombre,
    String? telefono,
  }) async {
    try {
      // Crear usuario en Firebase Auth
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (credential.user != null) {
        // Crear documento en Firestore
        final user = User(
          id: credential.user!.uid,
          nombre: nombre.trim(),
          email: email.trim(),
          telefono: telefono?.trim(),
          rol: AppConstants.rolWorker,
          createdAt: DateTime.now(),
        );

        await _firestore
            .collection(AppConstants.colUsers)
            .doc(user.id)
            .set(user.toFirestore());

        return user;
      }
      return null;
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// LOGOUT - Cerrar sesión
  Future<void> logout() async {
    await _auth.signOut();
  }

  /// OBTENER DATOS DEL USUARIO
  /// Si no existe en Firestore (ej: creado desde Console), crea documento básico
  Future<User?> getUserData(String uid) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.colUsers)
          .doc(uid)
          .get();

      if (doc.exists) {
        return User.fromFirestore(doc);
      }

      // Usuario existe en Auth pero no en Firestore → crear documento básico
      final firebaseUser = _auth.currentUser;
      if (firebaseUser != null) {
        final nuevoUsuario = User(
          id: uid,
          nombre: firebaseUser.displayName ?? firebaseUser.email!.split('@')[0],
          email: firebaseUser.email!,
          rol: AppConstants.rolWorker,
          createdAt: DateTime.now(),
        );
        await _firestore
            .collection(AppConstants.colUsers)
            .doc(uid)
            .set(nuevoUsuario.toFirestore());
        return nuevoUsuario;
      }
      return null;
    } catch (e) {
      throw 'Error al obtener datos del usuario';
    }
  }

  /// ACTUALIZAR PERFIL
  Future<void> updateProfile({
    String? nombre,
    String? telefono,
    String? direccion,
    String? idioma,
    String? avatarUrl,
    Object? notifMutadaHasta = _authSentinel,
  }) async {
    if (currentUserId == null) throw 'Usuario no autenticado';

    final updates = <String, dynamic>{};
    if (nombre != null) updates['nombre'] = nombre;
    if (telefono != null) updates['telefono'] = telefono;
    if (direccion != null) updates['direccion'] = direccion;
    if (idioma != null) updates['idioma'] = idioma;
    if (avatarUrl != null) updates['avatarUrl'] = avatarUrl;
    if (notifMutadaHasta != _authSentinel) {
      updates['notifMutadaHasta'] = notifMutadaHasta == null
          ? null
          : Timestamp.fromDate(notifMutadaHasta as DateTime);
    }

    if (updates.isEmpty) return;

    await _firestore
        .collection(AppConstants.colUsers)
        .doc(currentUserId)
        .update(updates);
  }

  /// VERIFICAR SI UN EMAIL EXISTE EN FIRESTORE
  Future<bool> emailExisteEnFirestore(String email) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.colUsers)
          .where('email', isEqualTo: email.trim())
          .limit(1)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false; // En caso de error, permitimos continuar
    }
  }

  /// RECUPERAR CONTRASEÑA
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// CAMBIAR CONTRASEÑA
  Future<void> changePassword(String currentPassword, String newPassword) async {
    final user = _auth.currentUser;
    if (user == null) throw 'Usuario no autenticado';

    try {
      // Re-autenticar usuario
      final credential = firebase_auth.EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Cambiar contraseña
      await user.updatePassword(newPassword);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// MANEJO DE ERRORES DE FIREBASE AUTH
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

const Object _authSentinel = Object();