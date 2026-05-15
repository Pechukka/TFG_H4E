import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hands4events/core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/idioma_provider.dart';
import '../../providers/nominas_provider.dart';
import '../../widgets/app_bar_custom.dart';

class NominasScreen extends StatefulWidget {
  const NominasScreen({super.key});

  @override
  State<NominasScreen> createState() => _NominasScreenState();
}

class _NominasScreenState extends State<NominasScreen> {
  int? _anioFiltro;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().currentUserId;
      if (userId != null) {
        context.read<NominasProvider>().cargarNominas(userId);
      }
    });
  }

  Future<void> _refrescar() async {
    final userId = context.read<AuthProvider>().currentUserId;
    if (userId == null) return;
    context.read<NominasProvider>().refresh(userId);
    await Future.delayed(const Duration(milliseconds: 600));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<IdiomaProvider>();
    final nominasProvider = context.watch<NominasProvider>();
    final todasLasNominas = nominasProvider.nominas;

    final aniosDisponibles = todasLasNominas
        .map((n) => n.anio)
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    if (_anioFiltro != null && !aniosDisponibles.contains(_anioFiltro)) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => setState(() => _anioFiltro = null),
      );
    }

    final nominas = _anioFiltro == null
        ? todasLasNominas
        : todasLasNominas.where((n) => n.anio == _anioFiltro).toList();

    return Scaffold(
      backgroundColor: AppTheme.fondoPrincipal,
      appBar: AppBarCustom(
        showLogo: true,
        showBackButton: true,
        title: t.tr('seccion_nominas'),
      ),
      body: RefreshIndicator(
        color: AppTheme.verdeNeon,
        onRefresh: _refrescar,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(t.tr('seccion_nominas'), style: Theme.of(context).textTheme.titleMedium),
              ),

              const SizedBox(height: 12),

              if (nominasProvider.isLoading)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator(color: AppTheme.verdeNeon)),
                )
              else ...[
                if (aniosDisponibles.length > 1) ...[
                  SizedBox(
                    height: 36,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        _buildChipAnio(context, null, t.tr('todos'), t),
                        ...aniosDisponibles
                            .map((anio) => _buildChipAnio(context, anio, '$anio', t)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (nominas.isEmpty)
                  _buildSinNominas(context, t)
                else
                  ...nominas.map((nomina) => _buildNominaCard(context, nomina: nomina, t: t)),
              ],

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChipAnio(BuildContext context, int? anio, String label, IdiomaProvider t) {
    final seleccionado = _anioFiltro == anio;
    return GestureDetector(
      onTap: () => setState(() => _anioFiltro = anio),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: seleccionado ? AppTheme.verdeNeon : AppTheme.fondoCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: seleccionado ? AppTheme.verdeNeon : AppTheme.bordeCampo,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: seleccionado ? AppTheme.textoSobreVerde : AppTheme.textoBlanco,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildSinNominas(BuildContext context, IdiomaProvider t) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.fondoCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          t.tr('sin_nominas'),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textoSecundario,
              ),
        ),
      ),
    );
  }

  Widget _buildNominaCard(BuildContext context, {required nomina, required IdiomaProvider t}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.fondoCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.verdeNeon.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.description, color: AppTheme.verdeNeon, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nomina.nombreCompleto, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(
                  nomina.sueldoNetoFormateado,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.verdeNeon,
                      ),
                ),
              ],
            ),
          ),
          if (nomina.tienePdf())
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppTheme.verdeNeon,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.download, color: AppTheme.textoSobreVerde, size: 20),
                onPressed: () async {
                  final uri = Uri.parse(nomina.pdfUrl!);
                  try {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } catch (_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(t.tr('no_se_puede_abrir')),
                          backgroundColor: AppTheme.rojoError,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                },
              ),
            ),
        ],
      ),
    );
  }
}
