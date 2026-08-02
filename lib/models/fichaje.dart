import 'package:cloud_firestore/cloud_firestore.dart';

enum FichajeEstado { noIniciado, enCurso, pausado, finalizado }

class Fichaje {
  final String id;
  final String trabajadorId;
  final String eventoId;
  final DateTime? entrada;
  final DateTime? salida;
  final List<Pausa> pausas;
  final FichajeEstado estado;

  Fichaje({
    required this.id,
    required this.trabajadorId,
    required this.eventoId,
    this.entrada,
    this.salida,
    this.pausas = const [],
    this.estado = FichajeEstado.noIniciado,
  });

  Duration get tiempoTotal {
    if (entrada == null) return Duration.zero;
    
    final fin = salida ?? DateTime.now();
    var total = fin.difference(entrada!);

    for (var pausa in pausas) {
      // Una pausa ABIERTA (sin fin) también se descuenta: mientras el fichaje está
      // pausado el reloj no debe seguir sumando. Se corta en la salida si ya la hay,
      // y si no, en el instante actual.
      final finPausa = pausa.fin ?? (salida ?? DateTime.now());
      total -= finPausa.difference(pausa.inicio);
    }

    return total;
  }

  String get tiempoFormateado {
    final d = tiempoTotal;
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  // Horas trabajadas NETAS (entrada→salida menos las pausas) a partir de los datos
  // crudos de Firestore. Fuente única para el panel admin y el cálculo de nóminas, para
  // que ambos coincidan con el "Tiempo trabajado" que ve el worker (tiempoTotal).
  // Devuelve 0 si el fichaje no está cerrado (falta entrada o salida).
  static double horasNetas(Map<String, dynamic> data) {
    final entrada = (data['entrada'] as Timestamp?)?.toDate();
    final salida = (data['salida'] as Timestamp?)?.toDate();
    if (entrada == null || salida == null) return 0;
    var total = salida.difference(entrada);
    for (final p in (data['pausas'] as List<dynamic>? ?? [])) {
      final m = p as Map<String, dynamic>;
      final ini = (m['inicio'] as Timestamp?)?.toDate();
      if (ini == null) continue;
      // Pausa sin fin (no debería pasar en un fichaje cerrado): se corta en la salida.
      final fin = (m['fin'] as Timestamp?)?.toDate() ?? salida;
      total -= fin.difference(ini);
    }
    // Nunca negativo (por si hubiera datos inconsistentes).
    return total.isNegative ? 0 : total.inMinutes / 60.0;
  }

  // Firebase → Dart
  factory Fichaje.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Fichaje(
      id: doc.id,
      trabajadorId: data['trabajadorId'] ?? '',
      eventoId: data['eventoId'] ?? '',
      entrada: (data['entrada'] as Timestamp?)?.toDate(),
      salida: (data['salida'] as Timestamp?)?.toDate(),
      pausas: (data['pausas'] as List<dynamic>?)
              ?.map((p) => Pausa.fromMap(p as Map<String, dynamic>))
              .toList() ??
          [],
      estado: FichajeEstado.values.firstWhere(
        (e) => e.toString() == data['estado'],
        orElse: () => FichajeEstado.noIniciado,
      ),
    );
  }

  // Dart → Firebase
  Map<String, dynamic> toFirestore() {
    return {
      'trabajadorId': trabajadorId,
      'eventoId': eventoId,
      'entrada': entrada != null ? Timestamp.fromDate(entrada!) : null,
      'salida': salida != null ? Timestamp.fromDate(salida!) : null,
      'pausas': pausas.map((p) => p.toMap()).toList(),
      'estado': estado.toString(),
    };
  }

  Fichaje copyWith({
    String? id,
    String? trabajadorId,
    String? eventoId,
    DateTime? entrada,
    DateTime? salida,
    List<Pausa>? pausas,
    FichajeEstado? estado,
  }) {
    return Fichaje(
      id: id ?? this.id,
      trabajadorId: trabajadorId ?? this.trabajadorId,
      eventoId: eventoId ?? this.eventoId,
      entrada: entrada ?? this.entrada,
      salida: salida ?? this.salida,
      pausas: pausas ?? this.pausas,
      estado: estado ?? this.estado,
    );
  }
}

class Pausa {
  final DateTime inicio;
  final DateTime? fin;

  Pausa({required this.inicio, this.fin});

  factory Pausa.fromMap(Map<String, dynamic> map) {
    return Pausa(
      inicio: (map['inicio'] as Timestamp).toDate(),
      fin: (map['fin'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'inicio': Timestamp.fromDate(inicio),
      'fin': fin != null ? Timestamp.fromDate(fin!) : null,
    };
  }
}