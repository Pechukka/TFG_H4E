import 'package:flutter/material.dart';
import 'package:hands4events/core/theme.dart';
import '../../widgets/app_bar_custom.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/modals/modal_solicitar_vacaciones.dart';

/// Pantalla de nóminas y vacaciones
/// Permite consultar nóminas y solicitar días de vacaciones
class NominasScreen extends StatelessWidget {
  const NominasScreen({super.key});

  void _mostrarModalVacaciones(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ModalSolicitarVacaciones(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.fondoPrincipal,
      appBar: const AppBarCustom(
        showLogo: true,
        showBackButton: true,
        title: 'Nóminas y vacaciones',
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),

            // Sección Nóminas
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Nóminas',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),

            const SizedBox(height: 12),

            // Lista de nóminas
            _buildNominaCard(context, mes: 'Diciembre 2024'),
            _buildNominaCard(context, mes: 'Noviembre 2024'),
            _buildNominaCard(context, mes: 'Octubre 2024'),
            _buildNominaCard(context, mes: 'Septiembre 2024'),
            _buildNominaCard(context, mes: 'Agosto 2024'),
            _buildNominaCard(context, mes: 'Julio 2024'),

            const SizedBox(height: 32),

            // Sección Vacaciones
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Vacaciones',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),

            const SizedBox(height: 12),

            // Card de vacaciones
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.fondoCard,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    'DÍAS DISPONIBLES',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppTheme.textoTerciario,
                      letterSpacing: 1.2,
                    ),
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    '15',
                    style: TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.verdeNeon,
                    ),
                  ),

                  const SizedBox(height: 24),

                  PrimaryButton(
                    text: 'Solicitar vacaciones',
                    icon: Icons.event_available,
                    onPressed: () => _mostrarModalVacaciones(context),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    'Las solicitudes serán revisadas por la empresa',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textoTerciario,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildNominaCard(BuildContext context, {required String mes}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.fondoCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Ícono documento
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.verdeNeon.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.description,
              color: AppTheme.verdeNeon,
              size: 20,
            ),
          ),

          const SizedBox(width: 12),

          // Texto mes
          Expanded(
            child: Text(
              mes,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),

          // Botón descarga
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppTheme.verdeNeon,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(
                Icons.download,
                color: AppTheme.textoSobreVerde,
                size: 20,
              ),
              onPressed: () {
                print('Descargar nómina de $mes');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Descargando nómina de $mes'),
                    backgroundColor: AppTheme.verdeExito,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}