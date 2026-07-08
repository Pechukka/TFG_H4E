import 'package:flutter/material.dart';
import 'package:hands4events/core/theme.dart';
import 'package:hands4events/core/constants.dart';
import '../../../services/admin_service.dart';
import '../../../utils/pdf_generator.dart';
import '../../../utils/top_snackbar.dart';

// Pantalla de nóminas del admin.
// El admin elige un mes, ve qué trabajadores han trabajado y puede
// enviarles la nómina (se guarda en Firestore para que la vean en su app).
class AdminNominasScreen extends StatefulWidget {
  const AdminNominasScreen({super.key});

  @override
  State<AdminNominasScreen> createState() => _AdminNominasScreenState();
}

class _AdminNominasScreenState extends State<AdminNominasScreen> {
  int _anio = DateTime.now().year;
  int _mes = DateTime.now().month;
  bool _calculando = false;
  bool _calculado = false;
  List<Map<String, dynamic>> _resumen = [];

  // UIDs de trabajadores cuya nómina ya fue enviada en esta sesión
  final Set<String> _enviadas = {};

  Future<void> _calcular() async {
    setState(() {
      _calculando = true;
      _calculado = false;
      _resumen = [];
      _enviadas.clear();
    });

    final resultado = await AdminService.calcularResumenMes(_anio, _mes);

    setState(() {
      _resumen = resultado;
      _calculando = false;
      _calculado = true;
    });
  }

  // Guarda la nómina en Firestore para que el trabajador la vea en su app
  Future<void> _enviarNomina(Map<String, dynamic> worker) async {
    final uid = worker['uid'] as String;
    final horas = worker['totalHoras'] as double;
    final bruto = worker['sueldoBruto'] as double;

    await AdminService.guardarNomina(
      trabajadorUid: uid,
      anio: _anio,
      mes: _mes,
      horasTrabajadas: horas,
      sueldoBruto: bruto,
    );

    if (!mounted) return;
    setState(() => _enviadas.add(uid));

    showTopSnackBar(context, 'Nómina de ${worker['nombre']} enviada correctamente',
        backgroundColor: AppTheme.verdeNeon, icon: Icons.check_circle_outline);
  }

  // Descarga el PDF de la nómina (solo para el admin, no se sube a ningún lado)
  Future<void> _descargarPdf(Map<String, dynamic> worker) async {
    await PdfGenerator.descargarNomina(
      nombre: worker['nombre'] as String,
      mes: AppConstants.meses[_mes],
      anio: _anio,
      eventos: List<Map<String, dynamic>>.from(worker['eventos'] as List),
      totalHoras: worker['totalHoras'] as double,
      sueldoBruto: worker['sueldoBruto'] as double,
      sueldoNeto: worker['sueldoNeto'] as double,
    );
  }

  // Envía las nóminas de todos los trabajadores del mes de golpe
  Future<void> _enviarTodas() async {
    for (final worker in _resumen) {
      final uid = worker['uid'] as String;
      if (_enviadas.contains(uid)) continue;
      await _enviarNomina(worker);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Nóminas', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 20),
          _buildSelectorMes(),
          const SizedBox(height: 24),
          if (_calculando)
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppTheme.verdeNeon),
                    SizedBox(height: 16),
                    Text('Calculando horas y sueldos...',
                        style: TextStyle(color: AppTheme.textoSecundario)),
                  ],
                ),
              ),
            )
          else if (_calculado)
            Expanded(child: _buildResultados())
          else
            Expanded(child: _buildInstrucciones()),
        ],
      ),
    );
  }

  Widget _buildSelectorMes() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.fondoCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.bordeCard),
      ),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<int>(
              initialValue: _mes,
              dropdownColor: AppTheme.fondoCard,
              style: const TextStyle(color: AppTheme.textoBlanco),
              decoration: InputDecoration(
                labelText: 'Mes',
                labelStyle: const TextStyle(
                    color: AppTheme.textoSecundario, fontSize: 13),
                filled: true,
                fillColor: AppTheme.fondoPrincipal,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.bordeCard),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.bordeCard),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              items: List.generate(12, (i) {
                return DropdownMenuItem(
                  value: i + 1,
                  child: Text(AppConstants.meses[i + 1]),
                );
              }),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _mes = val;
                    _calculado = false;
                  });
                }
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<int>(
              initialValue: _anio,
              dropdownColor: AppTheme.fondoCard,
              style: const TextStyle(color: AppTheme.textoBlanco),
              decoration: InputDecoration(
                labelText: 'Año',
                labelStyle: const TextStyle(
                    color: AppTheme.textoSecundario, fontSize: 13),
                filled: true,
                fillColor: AppTheme.fondoPrincipal,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.bordeCard),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.bordeCard),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              items: [_anio - 1, _anio, _anio + 1].map((y) {
                return DropdownMenuItem(value: y, child: Text('$y'));
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _anio = val;
                    _calculado = false;
                  });
                }
              },
            ),
          ),
          const SizedBox(width: 16),
          FilledButton.icon(
            onPressed: _calculando ? null : _calcular,
            icon: const Icon(Icons.calculate_outlined, size: 18),
            label: const Text('Calcular'),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.verdeNeon,
              foregroundColor: Colors.black,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstrucciones() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.description_outlined,
              color: AppTheme.textoSecundario, size: 48),
          SizedBox(height: 16),
          Text(
            'Selecciona un mes y pulsa "Calcular"',
            style: TextStyle(color: AppTheme.textoSecundario),
          ),
          SizedBox(height: 8),
          Text(
            'Verás qué trabajadores han fichado ese mes\ny podrás enviarles su nómina.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textoTerciario, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildResultados() {
    if (_resumen.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inbox_outlined,
                color: AppTheme.textoSecundario, size: 48),
            const SizedBox(height: 16),
            Text(
              'Ningún trabajador ha trabajado en ${AppConstants.meses[_mes]} $_anio',
              style: const TextStyle(color: AppTheme.textoSecundario),
            ),
            const SizedBox(height: 8),
            const Text(
              'Solo aparecen trabajadores con fichajes finalizados en ese mes.',
              style: TextStyle(
                  color: AppTheme.textoTerciario, fontSize: 12),
            ),
          ],
        ),
      );
    }

    final todasEnviadas = _enviadas.length == _resumen.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cabecera con resumen y botón "Enviar todas"
        Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_resumen.length} trabajador(es) en ${AppConstants.meses[_mes]} $_anio',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  'Las nóminas enviadas quedan visibles en la app del trabajador.',
                  style: const TextStyle(
                      color: AppTheme.textoTerciario, fontSize: 11),
                ),
              ],
            ),
            const Spacer(),
            if (!todasEnviadas)
              FilledButton.icon(
                onPressed: _enviarTodas,
                icon: const Icon(Icons.send_outlined, size: 16),
                label: const Text('Enviar todas'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.verdeNeon,
                  foregroundColor: Colors.black,
                ),
              )
            else
              Row(
                children: const [
                  Icon(Icons.check_circle,
                      color: AppTheme.verdeNeon, size: 18),
                  SizedBox(width: 6),
                  Text('Todas enviadas',
                      style: TextStyle(
                          color: AppTheme.verdeNeon, fontSize: 13)),
                ],
              ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.separated(
            itemCount: _resumen.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) => _buildCardWorker(_resumen[i]),
          ),
        ),
      ],
    );
  }

  Widget _buildCardWorker(Map<String, dynamic> worker) {
    final uid = worker['uid'] as String;
    final nombre = worker['nombre'] as String;
    final horas = worker['totalHoras'] as double;
    final bruto = worker['sueldoBruto'] as double;
    final neto = worker['sueldoNeto'] as double;
    final eventos =
        List<Map<String, dynamic>>.from(worker['eventos'] as List);
    final enviada = _enviadas.contains(uid);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.fondoCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: enviada
              ? AppTheme.verdeNeon.withValues(alpha: 0.4)
              : AppTheme.bordeCard,
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 18,
                  backgroundColor: enviada
                      ? AppTheme.verdeNeon.withValues(alpha: 0.2)
                      : AppTheme.verdeNeon.withValues(alpha: 0.1),
                  child: enviada
                      ? const Icon(Icons.check,
                          color: AppTheme.verdeNeon, size: 18)
                      : Text(
                          nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
                          style: const TextStyle(
                              color: AppTheme.verdeNeon,
                              fontWeight: FontWeight.bold),
                        ),
                ),
                const SizedBox(width: 12),
                // Nombre y resumen de horas
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(nombre,
                          style: Theme.of(context).textTheme.titleSmall),
                      Text(
                        '${horas.toStringAsFixed(1)}h trabajadas · ${eventos.length} evento(s)',
                        style: const TextStyle(
                            color: AppTheme.textoSecundario, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                // Sueldo
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${neto.toStringAsFixed(2)}€ neto',
                      style: const TextStyle(
                        color: AppTheme.verdeNeon,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '${bruto.toStringAsFixed(2)}€ bruto',
                      style: const TextStyle(
                          color: AppTheme.textoSecundario, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                // Botones de acción
                if (enviada) ...[
                  // Nómina ya enviada — solo opción de descargar PDF
                  OutlinedButton.icon(
                    onPressed: () => _descargarPdf(worker),
                    icon: const Icon(Icons.download_outlined,
                        size: 15, color: AppTheme.verdeNeon),
                    label: const Text('PDF',
                        style: TextStyle(
                            color: AppTheme.verdeNeon, fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.verdeNeon),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                    ),
                  ),
                ] else ...[
                  // Botón principal: enviar nómina al trabajador
                  FilledButton.icon(
                    onPressed: () => _enviarNomina(worker),
                    icon: const Icon(Icons.send_outlined, size: 15),
                    label: const Text('Enviar nómina'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.verdeNeon,
                      foregroundColor: Colors.black,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Botón secundario: solo descargar PDF sin enviar
                  Tooltip(
                    message: 'Descargar PDF sin enviar',
                    child: IconButton(
                      onPressed: () => _descargarPdf(worker),
                      icon: const Icon(Icons.download_outlined,
                          color: AppTheme.textoSecundario),
                      style: IconButton.styleFrom(
                        side: const BorderSide(color: AppTheme.bordeCard),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Desglose de eventos
          if (eventos.isNotEmpty) ...[
            const Divider(height: 1, color: AppTheme.bordeCard),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                children: eventos.map((e) {
                  final tHoras =
                      (e['horas'] as double).toStringAsFixed(1);
                  final tarifa =
                      (e['tarifa'] as double).toStringAsFixed(1);
                  final subtotal =
                      (e['subtotal'] as double).toStringAsFixed(2);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        const Icon(Icons.event_outlined,
                            size: 13,
                            color: AppTheme.textoTerciario),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            e['titulo'] as String,
                            style: const TextStyle(
                                color: AppTheme.textoSecundario,
                                fontSize: 12),
                          ),
                        ),
                        Text(
                          '${e['rol']}  ·  ${tHoras}h × $tarifa€  =  $subtotal€',
                          style: const TextStyle(
                              color: AppTheme.textoTerciario,
                              fontSize: 11),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            // Pie con el resumen de deducciones
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                color: AppTheme.fondoPrincipal,
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(12)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Bruto: ${bruto.toStringAsFixed(2)}€  '
                    '–  IRPF 15% + SS 6.35%  '
                    '=  Neto: ${neto.toStringAsFixed(2)}€',
                    style: const TextStyle(
                        color: AppTheme.textoSecundario, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
