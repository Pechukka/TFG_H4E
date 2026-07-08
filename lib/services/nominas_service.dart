import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/nomina.dart';
import '../core/constants.dart';

class NominasService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Nomina>> getNominasTrabajador(String trabajadorId) {
    return _firestore
        .collection(AppConstants.colNominas)
        .where('trabajadorId', isEqualTo: trabajadorId)
        .snapshots()
        .map((snapshot) {
          final lista = snapshot.docs
              .map((doc) => Nomina.fromFirestore(doc))
              .toList();
          lista.sort((a, b) {
            final yearComp = b.anio.compareTo(a.anio);
            return yearComp != 0 ? yearComp : b.mesNumero.compareTo(a.mesNumero);
          });
          return lista;
        });
  }

  Future<Nomina?> getNominaPorMes(
    String trabajadorId,
    int anio,
    int mesNumero,
  ) async {
    final snapshot = await _firestore
        .collection(AppConstants.colNominas)
        .where('trabajadorId', isEqualTo: trabajadorId)
        .where('anio', isEqualTo: anio)
        .where('mesNumero', isEqualTo: mesNumero)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return Nomina.fromFirestore(snapshot.docs.first);
    }
    return null;
  }

  Future<void> marcarComoRevisada(String nominaId) async {
    await _firestore
        .collection(AppConstants.colNominas)
        .doc(nominaId)
        .update({
          'estado': NominaEstado.revisada.toString(),
        });
  }

  Future<List<Nomina>> getUltimasNominas(String trabajadorId, {int limite = 6}) async {
    final snapshot = await _firestore
        .collection(AppConstants.colNominas)
        .where('trabajadorId', isEqualTo: trabajadorId)
        .get();

    final lista = snapshot.docs.map((doc) => Nomina.fromFirestore(doc)).toList();
    lista.sort((a, b) {
      final y = b.anio.compareTo(a.anio);
      return y != 0 ? y : b.mesNumero.compareTo(a.mesNumero);
    });
    return lista.take(limite).toList();
  }

  Future<double> getTotalGanadoAnio(String trabajadorId, int anio) async {
    final snapshot = await _firestore
        .collection(AppConstants.colNominas)
        .where('trabajadorId', isEqualTo: trabajadorId)
        .where('anio', isEqualTo: anio)
        .get();

    double total = 0;
    for (var doc in snapshot.docs) {
      final nomina = Nomina.fromFirestore(doc);
      total += nomina.sueldoNeto;
    }

    return total;
  }

  Future<String> crearNomina(Nomina nomina) async {
    final doc = await _firestore
        .collection(AppConstants.colNominas)
        .add(nomina.toFirestore());
    return doc.id;
  }
}