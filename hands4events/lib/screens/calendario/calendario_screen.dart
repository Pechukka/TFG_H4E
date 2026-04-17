import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_bar_custom.dart';

/// Pantalla Calendario
/// Muestra vista mensual de eventos y permite gestionar disponibilidad
class CalendarioScreen extends StatelessWidget {
  const CalendarioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppBarCustom(
        showLogo: true,
        showBackButton: false,
      ),
      body: Column(
        children: [
          // Header "Calendario"
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            color: AppTheme.fondoPrincipal,
            child: Center(
              child: Text(
                'Calendario',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Placeholder del calendario
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calendar_month,
                    size: 80,
                    color: AppTheme.verdeNeon.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Vista de calendario',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.textoSecundario,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Proximamente: CalendarioMensual widget',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textoTerciario,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}