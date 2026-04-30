import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo de Usuario
/// Combina entidad de dominio + DTO para simplificar
class User {
  final String id;
  final String nombre;
  final String email;
  final String? telefono;
  final String? direccion;
  final String? idioma;
  final String rol; // 'worker' o 'admin'
  final String? avatarUrl;
  final DateTime? createdAt;

  User({
    required this.id,
    required this.nombre,
    required this.email,
    this.telefono,
    this.direccion,
    this.idioma = 'es',
    this.rol = 'worker',
    this.avatarUrl,
    this.createdAt,
  });

  // Getter iniciales
  String get iniciales {
    final palabras = nombre.split(' ');
    if (palabras.length >= 2) {
      return '${palabras[0][0]}${palabras[1][0]}'.toUpperCase();
    }
    return nombre.substring(0, 2).toUpperCase();
  }

  // Firebase → Dart
  factory User.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return User(
      id: doc.id,
      nombre: data['nombre'] ?? '',
      email: data['email'] ?? '',
      telefono: data['telefono'],
      direccion: data['direccion'],
      idioma: data['idioma'] ?? 'es',
      rol: data['rol'] ?? 'worker',
      avatarUrl: data['avatarUrl'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  // Dart → Firebase
  Map<String, dynamic> toFirestore() {
    return {
      'nombre': nombre,
      'email': email,
      'telefono': telefono,
      'direccion': direccion,
      'idioma': idioma,
      'rol': rol,
      'avatarUrl': avatarUrl,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }

  // CopyWith
  User copyWith({
    String? id,
    String? nombre,
    String? email,
    String? telefono,
    String? direccion,
    String? idioma,
    String? rol,
    String? avatarUrl,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      email: email ?? this.email,
      telefono: telefono ?? this.telefono,
      direccion: direccion ?? this.direccion,
      idioma: idioma ?? this.idioma,
      rol: rol ?? this.rol,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}