import 'package:cloud_firestore/cloud_firestore.dart';

class Nomina {
  final String id;
  final String trabajadorId;
  final String mes; // Formato: "Enero 2025"
  final int anio;
  final int mesNumero; // 1-12
  final double sueldoBruto;
  final double sueldoNeto;
  final double horasTrabajadas;
  final String? pdfUrl; // URL del PDF en Firebase Storage
  final DateTime? fechaGeneracion;
  final NominaEstado estado;

  const Nomina({
    required this.id,
    required this.trabajadorId,
    required this.mes,
    required this.anio,
    required this.mesNumero,
    required this.sueldoBruto,
    required this.sueldoNeto,
    required this.horasTrabajadas,
    this.pdfUrl,
    this.fechaGeneracion,
    this.estado = NominaEstado.generada,
  });

  String get nombreCompleto {
    return '$mes $anio';
  }

  String get sueldoNetoFormateado {
    return '${sueldoNeto.toStringAsFixed(2)}€';
  }

  String get sueldoBrutoFormateado {
    return '${sueldoBruto.toStringAsFixed(2)}€';
  }

  String get horasFormateadas {
    return '${horasTrabajadas.toStringAsFixed(2)}h';
  }

  bool tienePdf() => pdfUrl != null && pdfUrl!.isNotEmpty;

  // Firebase → Dart
  factory Nomina.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return Nomina(
      id: doc.id,
      trabajadorId: data['trabajadorId'] ?? '',
      mes: data['mes'] ?? '',
      anio: (data['anio'] ?? 0).toInt(),
      mesNumero: (data['mesNumero'] ?? 0).toInt(),
      sueldoBruto: (data['sueldoBruto'] ?? 0).toDouble(),
      sueldoNeto: (data['sueldoNeto'] ?? 0).toDouble(),
      horasTrabajadas: (data['horasTrabajadas'] ?? 0).toDouble(),
      pdfUrl: data['pdfUrl'] as String?,
      fechaGeneracion: (data['fechaGeneracion'] as Timestamp?)?.toDate(),
      estado: NominaEstado.values.firstWhere(
        (e) => e.toString() == data['estado'],
        orElse: () => NominaEstado.generada,
      ),
    );
  }

  // Dart → Firebase
  Map<String, dynamic> toFirestore() {
    return {
      'trabajadorId': trabajadorId,
      'mes': mes,
      'anio': anio,
      'mesNumero': mesNumero,
      'sueldoBruto': sueldoBruto,
      'sueldoNeto': sueldoNeto,
      'horasTrabajadas': horasTrabajadas,
      'pdfUrl': pdfUrl,
      'fechaGeneracion': fechaGeneracion != null
          ? Timestamp.fromDate(fechaGeneracion!)
          : FieldValue.serverTimestamp(),
      'estado': estado.toString(),
    };
  }

  Nomina copyWith({
    String? id,
    String? trabajadorId,
    String? mes,
    int? anio,
    int? mesNumero,
    double? sueldoBruto,
    double? sueldoNeto,
    double? horasTrabajadas,
    String? pdfUrl,
    DateTime? fechaGeneracion,
    NominaEstado? estado,
  }) {
    return Nomina(
      id: id ?? this.id,
      trabajadorId: trabajadorId ?? this.trabajadorId,
      mes: mes ?? this.mes,
      anio: anio ?? this.anio,
      mesNumero: mesNumero ?? this.mesNumero,
      sueldoBruto: sueldoBruto ?? this.sueldoBruto,
      sueldoNeto: sueldoNeto ?? this.sueldoNeto,
      horasTrabajadas: horasTrabajadas ?? this.horasTrabajadas,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      fechaGeneracion: fechaGeneracion ?? this.fechaGeneracion,
      estado: estado ?? this.estado,
    );
  }
}

enum NominaEstado {
  generada,   // Nómina generada pero no revisada
  revisada,   // Revisada por el trabajador
  pagada,     // Sueldo ya pagado
}