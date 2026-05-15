import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hands4events/core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/fichaje_provider.dart';
import '../../providers/idioma_provider.dart';
import '../../models/fichaje.dart';
import '../../widgets/app_bar_custom.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/outline_button.dart';

class FichajeScreen extends StatefulWidget {
  final String tituloEvento;
  final String fecha;
  final String eventoId;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;

  const FichajeScreen({
    super.key,
    required this.tituloEvento,
    required this.fecha,
    this.eventoId = '',
    this.fechaInicio,
    this.fechaFin,
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
      final provider = context.read<FichajeProvider>();
      provider.cargarFichajeActivo(userId, widget.eventoId);
      provider.cargarHistorial(userId, widget.eventoId);
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
    final t = context.read<IdiomaProvider>();
    final exito = await provider.ficharEntrada(userId, widget.eventoId);

    if (mounted) {
      if (exito) {
        _iniciarTimerUI();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t.tr('fichaje_iniciado')),
            backgroundColor: AppTheme.verdeNeon.withValues(alpha: 0.9),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        _mostrarError(provider.errorMessage ?? t.tr('error_fichar_entrada'));
        provider.clearError();
      }
    }
  }

  Future<void> _pausarFichaje() async {
    final provider = context.read<FichajeProvider>();
    final t = context.read<IdiomaProvider>();
    final exito = await provider.pausarFichaje();

    if (mounted) {
      if (exito) {
        _detenerTimerUI();
      } else {
        _mostrarError(provider.errorMessage ?? t.tr('error_pausar'));
        provider.clearError();
      }
    }
  }

  Future<void> _reanudarFichaje() async {
    final provider = context.read<FichajeProvider>();
    final t = context.read<IdiomaProvider>();
    final exito = await provider.reanudarFichaje();

    if (mounted) {
      if (exito) {
        _iniciarTimerUI();
      } else {
        _mostrarError(provider.errorMessage ?? t.tr('error_reanudar'));
        provider.clearError();
      }
    }
  }

  Future<void> _finalizarFichaje() async {
    final userId = context.read<AuthProvider>().currentUserId;
    final provider = context.read<FichajeProvider>();
    final t = context.read<IdiomaProvider>();
    final exito = await provider.ficharSalida();

    if (mounted) {
      _detenerTimerUI();
      if (exito) {
        if (userId != null && widget.eventoId.isNotEmpty) {
          provider.cargarHistorial(userId, widget.eventoId);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t.tr('fichaje_finalizado_ok')),
            backgroundColor: AppTheme.verdeNeon.withValues(alpha: 0.9),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        _mostrarError(provider.errorMessage ?? t.tr('error_fichar_salida'));
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

  // ─── Restricciones de fichaje ──────────────────────────────────────────────

  bool _puedeIniciarFichaje(FichajeProvider provider) {
    if (widget.fechaInicio == null) return true;

    final ahora = DateTime.now();

    // Evento ya terminado → nunca permitir
    if (widget.fechaFin != null && ahora.isAfter(widget.fechaFin!)) {
      return false;
    }

    final ventana = widget.fechaInicio!.subtract(const Duration(hours: 1));

    // Primera vez: solo dentro de la ventana de 1h antes o durante el evento
    if (provider.historial.isEmpty) {
      return !ahora.isBefore(ventana);
    }

    // Tras finalizar un fichaje: solo si el evento ya ha comenzado
    return !ahora.isBefore(widget.fechaInicio!);
  }

  String _mensajeBloqueo(FichajeProvider provider, IdiomaProvider t) {
    if (widget.fechaInicio == null) return '';

    final ahora = DateTime.now();

    // Evento ya terminado
    if (widget.fechaFin != null && ahora.isAfter(widget.fechaFin!)) {
      return t.tr('fichaje_evento_terminado');
    }

    final ventana = widget.fechaInicio!.subtract(const Duration(hours: 1));

    // Primera vez, todavía lejos del inicio → mostrar cuenta atrás
    if (provider.historial.isEmpty && ahora.isBefore(ventana)) {
      final diff = ventana.difference(ahora);
      final h = diff.inHours;
      final m = diff.inMinutes.remainder(60);
      final tiempo = h > 0 ? '${h}h ${m}m' : '${m}m';
      return '${t.tr('fichaje_disponible_en')} $tiempo';
    }

    // Tras un fichaje previo pero el evento aún no ha empezado
    if (provider.historial.isNotEmpty && ahora.isBefore(widget.fechaInicio!)) {
      return t.tr('fichaje_evento_no_iniciado');
    }

    return '';
  }

  String _formatHora(DateTime? dt) {
    if (dt == null) return '--:--';
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatFecha(DateTime? dt) {
    if (dt == null) return '';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  // ─── Helpers visuales (idénticos al diseño original) ───────────────────────

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

  String _getEstadoTexto(FichajeEstado estado, IdiomaProvider t) {
    switch (estado) {
      case FichajeEstado.enCurso:
        return t.tr('estado_en_curso');
      case FichajeEstado.pausado:
        return t.tr('estado_pausado');
      case FichajeEstado.finalizado:
        return t.tr('estado_finalizado');
      default:
        return t.tr('estado_no_iniciado');
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
    final t = context.watch<IdiomaProvider>();
    final provider = context.watch<FichajeProvider>();
    final fichaje = provider.fichajeActivo;
    final estado = fichaje?.estado ?? FichajeEstado.noIniciado;
    final tiempo = fichaje?.tiempoFormateado ?? '00:00:00';
    final cargando = provider.isLoading;
    final puedeIniciar = _puedeIniciarFichaje(provider);
    final mensajeBloqueo = _mensajeBloqueo(provider, t);

    return Scaffold(
      backgroundColor: AppTheme.fondoPrincipal,
      appBar: AppBarCustom(
        showLogo: true,
        showBackButton: true,
        title: t.tr('fichaje'),
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
                    Text(
                      t.tr('estado_actual'),
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
                          _getEstadoTexto(estado, t),
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
                  text: t.tr('fichar_entrada'),
                  icon: Icons.login,
                  isLoading: cargando,
                  onPressed: puedeIniciar ? _iniciarFichaje : null,
                ),
                if (!puedeIniciar && mensajeBloqueo.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.amarilloAdvertencia.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.amarilloAdvertencia.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.access_time,
                            color: AppTheme.amarilloAdvertencia, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          mensajeBloqueo,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.amarilloAdvertencia,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],

              if (estado == FichajeEstado.enCurso) ...[
                CustomOutlineButton(
                  text: t.tr('pausar'),
                  icon: Icons.pause,
                  borderColor: AppTheme.amarilloAdvertencia,
                  textColor: AppTheme.amarilloAdvertencia,
                  isLoading: cargando,
                  onPressed: _pausarFichaje,
                ),
                const SizedBox(height: 12),
                PrimaryButton(
                  text: t.tr('fichar_salida'),
                  icon: Icons.logout,
                  isLoading: cargando,
                  onPressed: _finalizarFichaje,
                ),
              ],

              if (estado == FichajeEstado.pausado) ...[
                CustomOutlineButton(
                  text: t.tr('reanudar'),
                  icon: Icons.play_arrow,
                  isLoading: cargando,
                  onPressed: _reanudarFichaje,
                ),
                const SizedBox(height: 12),
                PrimaryButton(
                  text: t.tr('fichar_salida'),
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
                    color: AppTheme.verdeNeon.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.verdeNeon, width: 1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle, color: AppTheme.verdeNeon),
                      const SizedBox(width: 8),
                      Text(
                        t.tr('fichaje_completado'),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppTheme.verdeNeon,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              Text(
                t.tr('gps_info'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textoTerciario,
                ),
              ),

              // ─── Historial de fichajes finalizados ───────────────────
              if (provider.historial.isNotEmpty) ...[
                const SizedBox(height: 40),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    t.tr('historial'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(height: 12),
                ...provider.historial.map((f) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.fondoCard,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.verdeNeon.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_circle_outline,
                          color: AppTheme.verdeNeon,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _formatFecha(f.entrada),
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: AppTheme.textoSecundario,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_formatHora(f.entrada)} → ${_formatHora(f.salida)}',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.textoBlanco,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        f.tiempoFormateado,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppTheme.verdeNeon,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                )),
              ],

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}