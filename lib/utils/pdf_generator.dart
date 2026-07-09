import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

// Clase para generar PDFs de la aplicación
class PdfGenerator {
  // Carga las fuentes Roboto (soportan el símbolo €)
  static Future<(pw.Font, pw.Font)> _fuentes() async {
    final regular = await PdfGoogleFonts.robotoRegular();
    final bold = await PdfGoogleFonts.robotoBold();
    return (regular, bold);
  }

  // Genera y descarga el ticket con las credenciales de acceso del trabajador.
  // En el navegador (web) lo descarga como archivo. En móvil abre el menú de compartir.
  static Future<void> descargarTicketWorker({
    required String nombre,
    required String apellidos,
    required String email,
    required String password,
  }) async {
    final (fontRegular, fontBold) = await _fuentes();
    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
    );
    final nombreCompleto = '$nombre $apellidos'.trim();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Cabecera
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#84CC16'),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Text(
                  'HANDS4EVENTS',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black,
                  ),
                ),
              ),
              pw.SizedBox(height: 24),

              // Título
              pw.Text(
                'Credenciales de acceso',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                'Guarda este documento en un lugar seguro.',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
              ),
              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.SizedBox(height: 16),

              // Datos
              _campo('Trabajador', nombreCompleto),
              pw.SizedBox(height: 10),
              _campo('Email', email),
              pw.SizedBox(height: 10),
              _campo('Contraseña temporal', password),
              pw.SizedBox(height: 24),
              pw.Divider(),
              pw.SizedBox(height: 12),

              // Nota
              pw.Text(
                'Para acceder, descarga la app Hands4Events en tu dispositivo móvil '
                'e inicia sesión con estas credenciales. Cambia tu contraseña en el perfil '
                'tras el primer acceso.',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
              ),
            ],
          );
        },
      ),
    );

    final bytes = await pdf.save();
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'ticket_${nombre.toLowerCase().replaceAll(' ', '_')}.pdf',
    );
  }

  // Genera y descarga la nómina mensual de un trabajador en PDF.
  static Future<void> descargarNomina({
    required String nombre,
    required String mes,
    required int anio,
    required List<Map<String, dynamic>> eventos,
    required double totalHoras,
    required double sueldoBruto,
    required double sueldoNeto,
  }) async {
    final (fontRegular, fontBold) = await _fuentes();
    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
    );
    final irpf = sueldoBruto * 0.15;
    final ss = sueldoBruto * 0.0635;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Cabecera
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#84CC16'),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('HANDS4EVENTS',
                        style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.black)),
                    pw.Text('NÓMINA',
                        style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.black)),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Datos del trabajador y periodo
              pw.Row(
                children: [
                  pw.Expanded(child: _campo('Trabajador', nombre)),
                  pw.SizedBox(width: 16),
                  pw.Expanded(child: _campo('Periodo', '$mes $anio')),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.SizedBox(height: 12),

              // Cabecera tabla de eventos
              pw.Text('DESGLOSE DE EVENTOS',
                  style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey600)),
              pw.SizedBox(height: 8),
              pw.Container(
                color: PdfColors.grey200,
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: pw.Row(
                  children: [
                    pw.Expanded(flex: 4, child: pw.Text('Evento', style: const pw.TextStyle(fontSize: 9))),
                    pw.Expanded(flex: 2, child: pw.Text('Rol', style: const pw.TextStyle(fontSize: 9))),
                    pw.Expanded(flex: 1, child: pw.Text('Horas', style: const pw.TextStyle(fontSize: 9))),
                    pw.Expanded(flex: 1, child: pw.Text('€/h', style: const pw.TextStyle(fontSize: 9))),
                    pw.Expanded(flex: 1, child: pw.Text('Total', style: const pw.TextStyle(fontSize: 9))),
                  ],
                ),
              ),

              // Filas de eventos
              ...eventos.map((e) {
                return pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300)),
                  ),
                  child: pw.Row(
                    children: [
                      pw.Expanded(flex: 4, child: pw.Text(e['titulo'] as String, style: const pw.TextStyle(fontSize: 9))),
                      pw.Expanded(flex: 2, child: pw.Text(e['rol'] as String, style: const pw.TextStyle(fontSize: 9))),
                      pw.Expanded(flex: 1, child: pw.Text('${(e['horas'] as double).toStringAsFixed(1)}h', style: const pw.TextStyle(fontSize: 9))),
                      pw.Expanded(flex: 1, child: pw.Text('${(e['tarifa'] as double).toStringAsFixed(1)}€', style: const pw.TextStyle(fontSize: 9))),
                      pw.Expanded(flex: 1, child: pw.Text('${(e['subtotal'] as double).toStringAsFixed(2)}€', style: const pw.TextStyle(fontSize: 9))),
                    ],
                  ),
                );
              }),

              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.SizedBox(height: 12),

              // Resumen económico
              pw.Text('RESUMEN ECONÓMICO',
                  style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey600)),
              pw.SizedBox(height: 10),
              _filaResumen('Horas totales trabajadas', '${totalHoras.toStringAsFixed(2)}h'),
              _filaResumen('Sueldo bruto', '${sueldoBruto.toStringAsFixed(2)}€'),
              _filaResumen('Retención IRPF (15%)', '- ${irpf.toStringAsFixed(2)}€'),
              _filaResumen('Seguridad Social (6.35%)', '- ${ss.toStringAsFixed(2)}€'),
              pw.SizedBox(height: 6),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                color: PdfColor.fromHex('#84CC16'),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('SUELDO NETO A PERCIBIR',
                        style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                    pw.Text('${sueldoNeto.toStringAsFixed(2)}€',
                        style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    final bytes = await pdf.save();
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'nomina_${nombre.toLowerCase().replaceAll(' ', '_')}_${mes.toLowerCase()}_$anio.pdf',
    );
  }

  // Genera el PDF de una nómina desde los datos guardados en Firestore.
  // Lo usa el worker para descargarse su propia nómina desde la app.
  static Future<void> descargarNominaWorker({
    required String nombreTrabajador,
    required String mes,
    required int anio,
    required double horasTrabajadas,
    required double sueldoBruto,
    required double sueldoNeto,
  }) async {
    final (fontRegular, fontBold) = await _fuentes();
    final irpf = sueldoBruto * 0.15;
    final ss = sueldoBruto * 0.0635;

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#84CC16'),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('HANDS4EVENTS',
                        style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                    pw.Text('NOMINA',
                        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Row(
                children: [
                  pw.Expanded(child: _campo('Trabajador', nombreTrabajador)),
                  pw.SizedBox(width: 16),
                  pw.Expanded(child: _campo('Periodo', '$mes $anio')),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.SizedBox(height: 12),
              pw.Text('RESUMEN ECONOMICO',
                  style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600)),
              pw.SizedBox(height: 10),
              _filaResumen('Horas totales trabajadas', '${horasTrabajadas.toStringAsFixed(2)}h'),
              _filaResumen('Sueldo bruto', '${sueldoBruto.toStringAsFixed(2)}€'),
              _filaResumen('Retencion IRPF (15%)', '- ${irpf.toStringAsFixed(2)}€'),
              _filaResumen('Seguridad Social (6.35%)', '- ${ss.toStringAsFixed(2)}€'),
              pw.SizedBox(height: 6),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                color: PdfColor.fromHex('#84CC16'),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('SUELDO NETO A PERCIBIR',
                        style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                    pw.Text('${sueldoNeto.toStringAsFixed(2)}€',
                        style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    final bytes = await pdf.save();
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'nomina_${mes.toLowerCase()}_$anio.pdf',
    );
  }

  static pw.Widget _filaResumen(String concepto, String valor) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(concepto, style: const pw.TextStyle(fontSize: 10)),
          pw.Text(valor, style: const pw.TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  static pw.Widget _campo(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label.toUpperCase(),
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
        ),
        pw.SizedBox(height: 3),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Text(
            value,
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
