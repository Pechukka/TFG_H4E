import 'package:flutter/material.dart';
import 'package:hands4events/core/theme.dart';
import '../../../core/constants.dart';
import '../../../services/admin_service.dart';

// Pantalla de inicio del panel admin: KPIs de un vistazo + próximos eventos.
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late Future<Map<String, dynamic>> _datos;

  @override
  void initState() {
    super.initState();
    _datos = AdminService.getDatosDashboard();
  }

  void _recargar() {
    setState(() => _datos = AdminService.getDatosDashboard());
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: FutureBuilder<Map<String, dynamic>>(
        future: _datos,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.verdeNeon),
            );
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return _buildError();
          }

          final d = snapshot.data!;
          final horas = (d['horasMes'] as double? ?? 0);
          final proximos =
              (d['proximosEventos'] as List?)?.cast<Map<String, dynamic>>() ?? [];

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Resumen',
                        style: Theme.of(context).textTheme.headlineSmall),
                    const Spacer(),
                    IconButton(
                      onPressed: _recargar,
                      icon: const Icon(Icons.refresh,
                          color: AppTheme.textoSecundario, size: 20),
                      tooltip: 'Actualizar',
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Tarjetas KPI (se ajustan al ancho disponible)
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _KpiCard(
                      icon: Icons.people_outline,
                      color: AppTheme.verdeNeon,
                      valor: '${d['trabajadoresActivos'] ?? 0}',
                      etiqueta: 'Trabajadores activos',
                    ),
                    _KpiCard(
                      icon: Icons.event_outlined,
                      color: AppTheme.azulInfo,
                      valor: '${d['eventosProximos'] ?? 0}',
                      etiqueta: 'Eventos próximos (7 días)',
                    ),
                    _KpiCard(
                      icon: Icons.schedule,
                      color: AppTheme.verdeNeonHover,
                      valor: '${horas.toStringAsFixed(1)} h',
                      etiqueta: 'Horas fichadas este mes',
                    ),
                    _KpiCard(
                      icon: Icons.receipt_long_outlined,
                      color: AppTheme.amarilloAdvertencia,
                      valor: '${d['nominasPendientes'] ?? 0}',
                      etiqueta: 'Nóminas pendientes de enviar',
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Text('Próximos eventos',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                _ProximosEventos(eventos: proximos),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline,
              color: AppTheme.textoSecundario, size: 40),
          const SizedBox(height: 12),
          const Text('No se pudieron cargar los datos',
              style: TextStyle(color: AppTheme.textoSecundario)),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: _recargar,
            icon: const Icon(Icons.refresh, color: AppTheme.verdeNeon),
            label: const Text('Reintentar',
                style: TextStyle(color: AppTheme.verdeNeon)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// Tarjeta KPI
// ─────────────────────────────────────────

class _KpiCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String valor;
  final String etiqueta;

  const _KpiCard({
    required this.icon,
    required this.color,
    required this.valor,
    required this.etiqueta,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.fondoCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.bordeCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 16),
          Text(
            valor,
            style: const TextStyle(
              color: AppTheme.textoBlanco,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            etiqueta,
            style: const TextStyle(
                color: AppTheme.textoSecundario, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// Lista corta de próximos eventos
// ─────────────────────────────────────────

class _ProximosEventos extends StatelessWidget {
  final List<Map<String, dynamic>> eventos;
  const _ProximosEventos({required this.eventos});

  @override
  Widget build(BuildContext context) {
    if (eventos.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 36),
        decoration: BoxDecoration(
          color: AppTheme.fondoCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.bordeCard),
        ),
        child: const Column(
          children: [
            Icon(Icons.event_available_outlined,
                color: AppTheme.textoTerciario, size: 36),
            SizedBox(height: 10),
            Text('No hay eventos próximos',
                style: TextStyle(color: AppTheme.textoSecundario)),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.fondoCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.bordeCard),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (int i = 0; i < eventos.length; i++) ...[
            if (i > 0)
              const Divider(height: 1, color: AppTheme.bordeCard),
            _filaEvento(context, eventos[i]),
          ],
        ],
      ),
    );
  }

  Widget _filaEvento(BuildContext context, Map<String, dynamic> e) {
    final fecha = e['fecha'] as DateTime;
    final asignados = e['asignados'] as int? ?? 0;
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = AppConstants.meses[fecha.month];
    final hora =
        '${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.verdeNeon.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(dia,
                    style: const TextStyle(
                        color: AppTheme.verdeNeon,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
                Text(mes.length > 3 ? mes.substring(0, 3) : mes,
                    style: const TextStyle(
                        color: AppTheme.verdeNeon, fontSize: 10)),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e['titulo'] as String? ?? '',
                    style: Theme.of(context).textTheme.titleSmall,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text('$dia $mes · $hora',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppTheme.textoSecundario)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Cobertura: nº de trabajadores asignados
          Row(
            children: [
              const Icon(Icons.groups_outlined,
                  color: AppTheme.textoTerciario, size: 16),
              const SizedBox(width: 5),
              Text('$asignados',
                  style: const TextStyle(
                      color: AppTheme.verdeNeon,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
              const SizedBox(width: 4),
              const Text('asignados',
                  style:
                      TextStyle(color: AppTheme.textoTerciario, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}
