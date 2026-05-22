import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/fichaje.dart';
import '../core/constants.dart';
import 'package:geolocator/geolocator.dart';

class FichajesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Fichaje?> getFichajeActivo(String trabajadorId, String eventoId) async {
    final snapshot = await _firestore
        .collection(AppConstants.colFichajes)
        .where('trabajadorId', isEqualTo: trabajadorId)
        .where('eventoId', isEqualTo: eventoId)
        .where('estado', whereIn: [
          FichajeEstado.enCurso.toString(),
          FichajeEstado.pausado.toString(),
        ])
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return Fichaje.fromFirestore(snapshot.docs.first);
    }
    return null;
  }

  Future<Fichaje> ficharEntrada({
    required String trabajadorId,
    required String eventoId,
    Position? ubicacion,
  }) async {
    // Verificar que no haya fichaje activo
    final fichajeActivo = await getFichajeActivo(trabajadorId, eventoId);
    if (fichajeActivo != null) {
      throw 'Ya tienes un fichaje activo en este evento';
    }

    final fichaje = Fichaje(
      id: '',
      trabajadorId: trabajadorId,
      eventoId: eventoId,
      entrada: DateTime.now(),
      estado: FichajeEstado.enCurso,
    );

    final doc = await _firestore
        .collection(AppConstants.colFichajes)
        .add(fichaje.toFirestore());

    // Guardar ubicación GPS si está disponible
    if (ubicacion != null) {
      await doc.update({
        'ubicacionEntrada': {
          'lat': ubicacion.latitude,
          'lng': ubicacion.longitude,
          'timestamp': FieldValue.serverTimestamp(),
        },
      });
    }

    return fichaje.copyWith(id: doc.id);
  }

  Future<void> ficharSalida({
    required String fichajeId,
    Position? ubicacion,
  }) async {
    await _firestore
        .collection(AppConstants.colFichajes)
        .doc(fichajeId)
        .update({
          'salida': Timestamp.now(),
          'estado': FichajeEstado.finalizado.toString(),
        });

    // Guardar ubicación GPS si está disponible
    if (ubicacion != null) {
      await _firestore
          .collection(AppConstants.colFichajes)
          .doc(fichajeId)
          .update({
            'ubicacionSalida': {
              'lat': ubicacion.latitude,
              'lng': ubicacion.longitude,
              'timestamp': FieldValue.serverTimestamp(),
            },
          });
    }
  }

  Future<void> pausarFichaje(String fichajeId) async {
    final doc = await _firestore
        .collection(AppConstants.colFichajes)
        .doc(fichajeId)
        .get();

    final fichaje = Fichaje.fromFirestore(doc);
    
    final nuevasPausas = List<Pausa>.from(fichaje.pausas);
    nuevasPausas.add(Pausa(inicio: DateTime.now()));

    await _firestore
        .collection(AppConstants.colFichajes)
        .doc(fichajeId)
        .update({
          'pausas': nuevasPausas.map((p) => p.toMap()).toList(),
          'estado': FichajeEstado.pausado.toString(),
        });
  }

  Future<void> reanudarFichaje(String fichajeId) async {
    final doc = await _firestore
        .collection(AppConstants.colFichajes)
        .doc(fichajeId)
        .get();

    final fichaje = Fichaje.fromFirestore(doc);
    
    if (fichaje.pausas.isEmpty || fichaje.pausas.last.fin != null) {
      throw 'No hay pausa activa para reanudar';
    }

    final nuevasPausas = List<Pausa>.from(fichaje.pausas);
    final ultimaPausa = nuevasPausas.removeLast();
    nuevasPausas.add(Pausa(
      inicio: ultimaPausa.inicio,
      fin: DateTime.now(),
    ));

    await _firestore
        .collection(AppConstants.colFichajes)
        .doc(fichajeId)
        .update({
          'pausas': nuevasPausas.map((p) => p.toMap()).toList(),
          'estado': FichajeEstado.enCurso.toString(),
        });
  }

  Future<List<Fichaje>> getFichajesTrabajador(String trabajadorId) async {
    final snapshot = await _firestore
        .collection(AppConstants.colFichajes)
        .where('trabajadorId', isEqualTo: trabajadorId)
        .get();

    final lista = snapshot.docs.map((doc) => Fichaje.fromFirestore(doc)).toList();
    lista.sort((a, b) => (b.entrada ?? DateTime(0)).compareTo(a.entrada ?? DateTime(0)));
    return lista;
  }

  Future<List<Fichaje>> getFichajesEvento(String trabajadorId, String eventoId) async {
    // Filtrar por eventoId y estado en Dart para evitar índice compuesto en Firestore
    final snapshot = await _firestore
        .collection(AppConstants.colFichajes)
        .where('trabajadorId', isEqualTo: trabajadorId)
        .get();

    final lista = snapshot.docs
        .map((doc) => Fichaje.fromFirestore(doc))
        .where((f) => f.eventoId == eventoId && f.estado == FichajeEstado.finalizado)
        .toList();
    lista.sort((a, b) => (b.entrada ?? DateTime(0)).compareTo(a.entrada ?? DateTime(0)));
    return lista;
  }

  Future<Position> obtenerUbicacion() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw 'Los servicios de ubicación están deshabilitados';
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw 'Permisos de ubicación denegados';
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw 'Permisos de ubicación denegados permanentemente';
    }

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }
}