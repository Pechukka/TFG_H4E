import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_bar_custom.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/outline_button.dart';

/// Pantalla de fichaje (Clock It)
/// Permite registrar entrada, salida y pausas con validación GPS
class FichajeScreen extends StatefulWidget {
  final String tituloEvento;
  final String fecha;

  const FichajeScreen({
    super.key,
    required this.tituloEvento,
    required this.fecha,
  });

  @override
  State<FichajeScreen> createState() => _FichajeScreenState();
}

class _FichajeScreenState extends State<FichajeScreen> {
  // Estados: 'no_iniciado', 'en_curso', 'pausado', 'finalizado'
  String _estado = 'no_iniciado';
  int _segundosTranscurridos = 0;
  String _tiempoFormateado = '00:00:00';

  void _iniciarFichaje() {
    setState(() {
      _estado = 'en_curso';
      _segundosTranscurridos = 0;
    });
    print('Fichaje iniciado');
  }

  void _pausarFichaje() {
    setState(() {
      _estado = 'pausado';
      _segundosTranscurridos = 10; // Simulación
      _tiempoFormateado = '00:00:10';
    });
    print('Fichaje pausado');
  }

  void _reanudarFichaje() {
    setState(() {
      _estado = 'en_curso';
      _segundosTranscurridos = 8; // Simulación
      _tiempoFormateado = '00:00:08';
    });
    print('Fichaje reanudado');
  }

  void _finalizarFichaje() {
    setState(() {
      _estado = 'finalizado';
      _segundosTranscurridos = 11; // Simulación
      _tiempoFormateado = '00:00:11';
    });
    print('Fichaje finalizado');
  }

  Color _getEstadoColor() {
    switch (_estado) {
      case 'en_curso':
        return AppTheme.verdeNeon;
      case 'pausado':
        return AppTheme.amarilloAdvertencia;
      case 'finalizado':
        return AppTheme.azulInfo;
      default:
        return AppTheme.textoSecundario;
    }
  }

  String _getEstadoTexto() {
    switch (_estado) {
      case 'en_curso':
        return 'Fichaje en curso';
      case 'pausado':
        return 'Fichaje en pausa';
      case 'finalizado':
        return 'Fichaje finalizado';
      default:
        return 'No iniciado';
    }
  }

  IconData _getEstadoIcono() {
    switch (_estado) {
      case 'en_curso':
        return Icons.play_circle_outline;
      case 'pausado':
        return Icons.pause_circle_outline;
      case 'finalizado':
        return Icons.check_circle;
      default:
        return Icons.access_time;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.fondoPrincipal,
      appBar: const AppBarCustom(
        showLogo: true,
        showBackButton: true,
        title: 'Fichaje',
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 40),

              // Logo mano verde
              Image.asset(
                'assets/images/logo_hand.png',
                width: 120,
                height: 120,
                fit: BoxFit.contain,
              ),

              const SizedBox(height: 24),

              // Nombre del evento
              Text(
                widget.tituloEvento,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),

              const SizedBox(height: 8),

              // Fecha
              Text(
                widget.fecha,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textoSecundario,
                ),
              ),

              const SizedBox(height: 40),

              // Card de estado
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.fondoCard,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    // Estado actual
                    Text(
                      'Estado actual',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppTheme.textoTerciario,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Ícono y texto de estado
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _getEstadoIcono(),
                          color: _getEstadoColor(),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _getEstadoTexto(),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: _getEstadoColor(),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Cronómetro
                    Text(
                      _tiempoFormateado,
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: _getEstadoColor(),
                        letterSpacing: 4,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Botones según estado
              if (_estado == 'no_iniciado') ...[
                PrimaryButton(
                  text: 'FICHAR ENTRADA',
                  icon: Icons.login,
                  onPressed: _iniciarFichaje,
                ),
              ],

              if (_estado == 'en_curso') ...[
                CustomOutlineButton(
                  text: 'PAUSAR',
                  icon: Icons.pause,
                  borderColor: AppTheme.amarilloAdvertencia,
                  textColor: AppTheme.amarilloAdvertencia,
                  onPressed: _pausarFichaje,
                ),
                const SizedBox(height: 12),
                PrimaryButton(
                  text: 'FICHAR SALIDA',
                  icon: Icons.logout,
                  onPressed: _finalizarFichaje,
                ),
              ],

              if (_estado == 'pausado') ...[
                CustomOutlineButton(
                  text: 'REANUDAR',
                  icon: Icons.play_arrow,
                  onPressed: _reanudarFichaje,
                ),
                const SizedBox(height: 12),
                PrimaryButton(
                  text: 'FICHAR SALIDA',
                  icon: Icons.logout,
                  onPressed: _finalizarFichaje,
                ),
              ],

              const SizedBox(height: 24),

              // Texto info GPS
              Text(
                'La ubicación se registra al fichar entrada y salida',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textoTerciario,
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}