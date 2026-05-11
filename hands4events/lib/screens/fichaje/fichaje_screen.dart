import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hands4events/core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/fichaje_provider.dart';
import '../../models/fichaje.dart';
import '../../widgets/app_bar_custom.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/outline_button.dart';

/// Pantalla de fichaje (Clock It)
/// Permite registrar entrada, salida y pausas con validación GPS
class FichajeScreen extends StatefulWidget {
  final String tituloEvento;
  final String fecha;
  final String eventoId;

  const FichajeScreen({
    super.key,
    required this.tituloEvento,
    required this.fecha,
    this.eventoId = '',
  });

  @override
  State<FichajeScreen> createState() => _FichajeScreenState();
}

class _FichajeScreenState extends State<FichajeScreen> {
  // Cronómetro local para actualizar la UI cada segundo
  Timer? _timerUI;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarFichajeActivo();
    });
  }

  @override
  void dispose() {
    _timerUI?.cancel();
    super.dispose();
  }

  void _cargarFichajeActivo() {
    final userId = context.read<AuthProvider>().currentUserId;
    if (userId != null && widget.eventoId.isNotEmpty) {
      context
          .read<FichajeProvider>()
          .cargarFichajeActivo(userId, widget.eventoId);
    }
  }

  void _iniciarTimerUI() {
    _timerUI?.cancel();
    _timerUI = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  void _detenerTimerUI() {
    _timerUI?.cancel();
    _timerUI = null;
  }

  Future<void> _iniciarFichaje() async {
    final userId = context.read<AuthProvider>().currentUserId;
    if (userId == null) return;

    final provider = context.read<FichajeProvider>();
    final exito = await provider.ficharEntrada(userId, widget.eventoId);

    if (mounted) {
      if (exito) {
        _iniciarTimerUI();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Fichaje iniciado correctamente'),
            backgroundColor: AppTheme.verdeNeon.withOpacity(0.9),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        _mostrarError(provider.errorMessage ?? 'Error al fichar entrada');
        provider.clearError();
      }
    }
  }

  Future<void> _pausarFichaje() async {
    final provider = context.read<FichajeProvider>();
    final exito = await provider.pausarFichaje();

    if (mounted) {
      if (exito) {
        _detenerTimerUI();
      } else {
        _mostrarError(provider.errorMessage ?? 'Error al pausar');
        provider.clearError();
      }
    }
  }

  Future<void> _reanudarFichaje() async {
    final provider = context.read<FichajeProvider>();
    final exito = await provider.reanudarFichaje();

    if (mounted) {
      if (exito) {
        _iniciarTimerUI();
      } else {
        _mostrarError(provider.errorMessage ?? 'Error al reanudar');
        provider.clearError();
      }
    }
  }

  Future<void> _finalizarFichaje() async {
    final provider = context.read<FichajeProvider>();
    final exito = await provider.ficharSalida();

    if (mounted) {
      _detenerTimerUI();
      if (exito) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Fichaje finalizado correctamente'),
            backgroundColor: AppTheme.verdeNeon.withOpacity(0.9),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        _mostrarError(provider.errorMessage ?? 'Error al fichar salida');
        provider.clearError();
      }
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: AppTheme.rojoError,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ─── Helpers visuales (idénticos al diseño original) ───────────────────────

  FichajeEstado get _estado {
    final fichaje = context.read<FichajeProvider>().fichajeActivo;
    if (fichaje == null) return FichajeEstado.noIniciado;
    return fichaje.estado;
  }

  String get _tiempoFormateado {
    final fichaje = context.read<FichajeProvider>().fichajeActivo;
    return fichaje?.tiempoFormateado ?? '00:00:00';
  }

  Color _getEstadoColor(FichajeEstado estado) {
    switch (estado) {
      case FichajeEstado.enCurso:
        return AppTheme.verdeNeon;
      case FichajeEstado.pausado:
        return AppTheme.amarilloAdvertencia;
      case FichajeEstado.finalizado:
        return AppTheme.azulInfo;
      default:
        return AppTheme.textoSecundario;
    }
  }

  String _getEstadoTexto(FichajeEstado estado) {
    switch (estado) {
      case FichajeEstado.enCurso:
        return 'Fichaje en curso';
      case FichajeEstado.pausado:
        return 'Fichaje en pausa';
      case FichajeEstado.finalizado:
        return 'Fichaje finalizado';
      default:
        return 'No iniciado';
    }
  }

  IconData _getEstadoIcono(FichajeEstado estado) {
    switch (estado) {
      case FichajeEstado.enCurso:
        return Icons.play_circle_outline;
      case FichajeEstado.pausado:
        return Icons.pause_circle_outline;
      case FichajeEstado.finalizado:
        return Icons.check_circle;
      default:
        return Icons.access_time;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FichajeProvider>();
    final fichaje = provider.fichajeActivo;
    final estado = fichaje?.estado ?? FichajeEstado.noIniciado;
    final tiempo = fichaje?.tiempoFormateado ?? '00:00:00';
    final cargando = provider.isLoading;

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
                          _getEstadoIcono(estado),
                          color: _getEstadoColor(estado),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _getEstadoTexto(estado),
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(color: _getEstadoColor(estado)),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Cronómetro
                    Text(
                      tiempo,
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: _getEstadoColor(estado),
                        letterSpacing: 4,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Botones según estado
              if (estado == FichajeEstado.noIniciado) ...[
                PrimaryButton(
                  text: 'FICHAR ENTRADA',
                  icon: Icons.login,
                  isLoading: cargando,
                  onPressed: _iniciarFichaje,
                ),
              ],

              if (estado == FichajeEstado.enCurso) ...[
                CustomOutlineButton(
                  text: 'PAUSAR',
                  icon: Icons.pause,
                  borderColor: AppTheme.amarilloAdvertencia,
                  textColor: AppTheme.amarilloAdvertencia,
                  isLoading: cargando,
                  onPressed: _pausarFichaje,
                ),
                const SizedBox(height: 12),
                PrimaryButton(
                  text: 'FICHAR SALIDA',
                  icon: Icons.logout,
                  isLoading: cargando,
                  onPressed: _finalizarFichaje,
                ),
              ],

              if (estado == FichajeEstado.pausado) ...[
                CustomOutlineButton(
                  text: 'REANUDAR',
                  icon: Icons.play_arrow,
                  isLoading: cargando,
                  onPressed: _reanudarFichaje,
                ),
                const SizedBox(height: 12),
                PrimaryButton(
                  text: 'FICHAR SALIDA',
                  icon: Icons.logout,
                  isLoading: cargando,
                  onPressed: _finalizarFichaje,
                  ),
              ],

              if (estado == FichajeEstado.finalizado) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.verdeNeon.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.verdeNeon, width: 1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle, color: AppTheme.verdeNeon),
                      const SizedBox(width: 8),
                      Text(
                        'Fichaje completado',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppTheme.verdeNeon,
                        ),
                      ),
                    ],
                  ),
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