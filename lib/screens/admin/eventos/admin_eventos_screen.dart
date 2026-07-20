import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hands4events/core/theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/admin_service.dart';
import '../../../core/roles.dart';
import 'admin_fichajes_evento_screen.dart';
import 'admin_postulaciones_screen.dart';
import '../../../utils/top_snackbar.dart';

// Pantalla principal de eventos del admin.
// Muestra la lista de eventos o el formulario de creación según el estado.
class AdminEventosScreen extends StatefulWidget {
  const AdminEventosScreen({super.key});

  @override
  State<AdminEventosScreen> createState() => _AdminEventosScreenState();
}

// Filtro por estado (derivado de las fechas, no hay campo estado hasta Fase 3)
enum _FiltroEstado { todos, proximos, enCurso, finalizados }

class _AdminEventosScreenState extends State<AdminEventosScreen> {
  // Si es true, mostramos el formulario de crear evento en vez de la lista
  bool _mostrandoFormulario = false;
  // Evento que se está editando (null si se está creando uno nuevo)
  QueryDocumentSnapshot<Map<String, dynamic>>? _eventoEditando;
  // Filtros de la lista
  _FiltroEstado _filtroEstado = _FiltroEstado.todos;
  DateTime? _fechaFiltro;

  @override
  Widget build(BuildContext context) {
    if (_mostrandoFormulario) {
      return _AdminCrearEventoForm(
        eventoExistente: _eventoEditando,
        onVolver: () => setState(() {
          _mostrandoFormulario = false;
          _eventoEditando = null;
        }),
      );
    }
    return _buildLista();
  }

  Widget _buildLista() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Eventos', style: Theme.of(context).textTheme.headlineSmall),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => setState(() => _mostrandoFormulario = true),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Nuevo evento'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.verdeNeon,
                  foregroundColor: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildFiltros(),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: AdminService.todosLosEventosStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppTheme.verdeNeon),
                  );
                }
                if (snapshot.hasError) {
                  return const Center(
                    child: Text('Error al cargar eventos',
                        style: TextStyle(color: AppTheme.textoSecundario)),
                  );
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return _buildSinEventos();
                }

                final filtrados = _aplicarFiltros(docs);
                if (filtrados.isEmpty) {
                  return _buildSinResultados();
                }

                return ListView.separated(
                  itemCount: filtrados.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) => _buildCardEvento(filtrados[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Aplica el filtro por estado (derivado de fechas) y por fecha concreta.
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _aplicarFiltros(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final ahora = DateTime.now();
    return docs.where((doc) {
      final data = doc.data();
      final inicioTs = data['fechaInicio'];
      final finTs = data['fechaFin'];
      if (inicioTs is! Timestamp || finTs is! Timestamp) return false;
      final inicio = inicioTs.toDate();
      final fin = finTs.toDate();

      // Filtro por estado
      switch (_filtroEstado) {
        case _FiltroEstado.todos:
          break;
        case _FiltroEstado.proximos:
          if (!inicio.isAfter(ahora)) return false;
          break;
        case _FiltroEstado.enCurso:
          if (!(ahora.isAfter(inicio) && ahora.isBefore(fin))) return false;
          break;
        case _FiltroEstado.finalizados:
          if (!ahora.isAfter(fin)) return false;
          break;
      }

      // Filtro por fecha concreta (mismo día)
      if (_fechaFiltro != null) {
        final f = _fechaFiltro!;
        if (inicio.year != f.year ||
            inicio.month != f.month ||
            inicio.day != f.day) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  Widget _buildFiltros() {
    return Row(
      children: [
        _chipEstado('Todos', _FiltroEstado.todos),
        const SizedBox(width: 8),
        _chipEstado('Próximos', _FiltroEstado.proximos),
        const SizedBox(width: 8),
        _chipEstado('En curso', _FiltroEstado.enCurso),
        const SizedBox(width: 8),
        _chipEstado('Finalizados', _FiltroEstado.finalizados),
        const Spacer(),
        // Filtro por fecha
        OutlinedButton.icon(
          onPressed: _seleccionarFechaFiltro,
          icon: const Icon(Icons.calendar_today, size: 15),
          label: Text(
            _fechaFiltro == null
                ? 'Fecha'
                : '${_fechaFiltro!.day.toString().padLeft(2, '0')}/${_fechaFiltro!.month.toString().padLeft(2, '0')}/${_fechaFiltro!.year}',
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: _fechaFiltro == null
                ? AppTheme.textoSecundario
                : AppTheme.verdeNeon,
            side: BorderSide(
                color: _fechaFiltro == null
                    ? AppTheme.bordeCampo
                    : AppTheme.verdeNeon),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
        if (_fechaFiltro != null)
          IconButton(
            onPressed: () => setState(() => _fechaFiltro = null),
            icon: const Icon(Icons.close,
                color: AppTheme.textoTerciario, size: 18),
            tooltip: 'Quitar filtro de fecha',
          ),
      ],
    );
  }

  Widget _chipEstado(String label, _FiltroEstado estado) {
    final seleccionado = _filtroEstado == estado;
    return ChoiceChip(
      label: Text(label),
      selected: seleccionado,
      onSelected: (_) => setState(() => _filtroEstado = estado),
      showCheckmark: false,
      backgroundColor: AppTheme.fondoInput,
      selectedColor: AppTheme.verdeNeon.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        color: seleccionado ? AppTheme.verdeNeon : AppTheme.textoSecundario,
        fontSize: 13,
        fontWeight: seleccionado ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(
        color: seleccionado ? AppTheme.verdeNeon : AppTheme.bordeCampo,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  Future<void> _seleccionarFechaFiltro() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaFiltro ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 2)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppTheme.verdeNeon,
            onPrimary: Colors.black,
            surface: AppTheme.fondoCard,
          ),
        ),
        child: child!,
      ),
    );
    if (fecha != null) setState(() => _fechaFiltro = fecha);
  }

  Widget _buildSinResultados() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.filter_alt_off_outlined,
              color: AppTheme.textoSecundario, size: 44),
          SizedBox(height: 12),
          Text('Ningún evento coincide con los filtros',
              style: TextStyle(color: AppTheme.textoSecundario)),
        ],
      ),
    );
  }

  Widget _buildCardEvento(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final titulo = data['titulo'] ?? 'Sin título';
    final ubicacion = data['ubicacion'] ?? '';
    final fechaInicio = (data['fechaInicio'] as Timestamp).toDate();
    final fechaFin = (data['fechaFin'] as Timestamp).toDate();
    final trabajadoresIds = List<String>.from(data['trabajadoresIds'] ?? []);
    // Estado del evento (eventos antiguos sin estado → publicado en la vista admin)
    final estadoRaw = (data['estado'] as String?) ?? '';
    final estadoVista = estadoRaw.isEmpty ? 'publicado' : estadoRaw;
    // Confirmados = asignados sin contar al admin creador
    final creadoPor = data['creadoPor'] as String?;
    final confirmados = trabajadoresIds.where((id) => id != creadoPor).length;

    final fechaStr =
        '${fechaInicio.day.toString().padLeft(2, '0')}/${fechaInicio.month.toString().padLeft(2, '0')}/${fechaInicio.year}';
    final horaStr =
        '${_hora(fechaInicio)} – ${_hora(fechaFin)}';
    final duracion = fechaFin.difference(fechaInicio).inHours;

    final ahora = DateTime.now();
    final enCurso = ahora.isAfter(fechaInicio) && ahora.isBefore(fechaFin);
    final pasado = ahora.isAfter(fechaFin);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.fondoCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: enCurso
              ? AppTheme.verdeNeon.withValues(alpha: 0.4)
              : AppTheme.bordeCard,
        ),
      ),
      child: Row(
        children: [
          // Icono de estado
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.verdeNeon.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.event,
              color: pasado ? AppTheme.textoTerciario : AppTheme.verdeNeon,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(titulo,
                          style: Theme.of(context).textTheme.titleSmall),
                    ),
                    if (estadoVista == 'borrador') ...[
                      const SizedBox(width: 8),
                      _badgeEstado('BORRADOR', AppTheme.amarilloAdvertencia),
                    ] else if (estadoVista == 'finalizado') ...[
                      const SizedBox(width: 8),
                      _badgeEstado('FINALIZADO', AppTheme.textoTerciario),
                    ],
                    if (enCurso) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.verdeNeon.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppTheme.verdeNeon),
                        ),
                        child: const Text('EN CURSO',
                            style: TextStyle(
                                color: AppTheme.verdeNeon,
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '$fechaStr · $horaStr · ${duracion}h',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppTheme.verdeNeon),
                ),
                if (ubicacion.isNotEmpty)
                  Text(ubicacion,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppTheme.textoSecundario)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Nº de confirmados (sin contar al admin)
          Column(
            children: [
              Text(
                '$confirmados',
                style: const TextStyle(
                    color: AppTheme.verdeNeon,
                    fontWeight: FontWeight.bold,
                    fontSize: 18),
              ),
              const Text('confirmados',
                  style: TextStyle(
                      color: AppTheme.textoTerciario, fontSize: 10)),
            ],
          ),
          const SizedBox(width: 12),
          // Botón ver postulaciones
          IconButton(
            icon: const Icon(Icons.how_to_reg_outlined,
                color: AppTheme.textoSecundario, size: 18),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AdminPostulacionesScreen(
                  eventoId: doc.id,
                  tituloEvento: data['titulo'] as String? ?? 'Evento',
                ),
              ),
            ),
            tooltip: 'Ver postulaciones',
          ),
          // Botón ver fichajes
          IconButton(
            icon: const Icon(Icons.fingerprint,
                color: AppTheme.textoSecundario, size: 18),
            onPressed: () => _verFichajes(context, doc),
            tooltip: 'Ver fichajes',
          ),
          // Botón editar
          IconButton(
            icon: const Icon(Icons.edit_outlined,
                color: AppTheme.textoSecundario, size: 18),
            onPressed: () => setState(() {
              _eventoEditando = doc;
              _mostrandoFormulario = true;
            }),
            tooltip: 'Editar evento',
          ),
          // Botón eliminar
          IconButton(
            icon: const Icon(Icons.delete_outline,
                color: Colors.redAccent, size: 18),
            onPressed: () => _confirmarEliminar(doc),
            tooltip: 'Eliminar evento',
          ),
        ],
      ),
    );
  }

  Widget _badgeEstado(String texto, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color),
      ),
      child: Text(texto,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Future<void> _confirmarEliminar(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final data = doc.data();
    final titulo = data['titulo'] as String? ?? 'este evento';
    final todos = List<String>.from(data['trabajadoresIds'] ?? []);
    final adminUid = context.read<AuthProvider>().currentUserId ?? '';
    final workerIds = todos.where((id) => id != adminUid).toList();

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.fondoCard,
        title: const Text('Eliminar evento',
            style: TextStyle(color: AppTheme.textoBlanco)),
        content: Text(
          '¿Seguro que quieres eliminar "$titulo"?\n\n'
          'Se borrarán los mensajes del chat y se notificará a los trabajadores asignados.',
          style: const TextStyle(color: AppTheme.textoSecundario),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar',
                style: TextStyle(color: AppTheme.textoSecundario)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    await AdminService.eliminarEvento(
      doc.id,
      titulo: titulo,
      trabajadoresIds: workerIds,
    );

    if (mounted) {
      showTopSnackBar(context, 'Evento "$titulo" eliminado',
          backgroundColor: AppTheme.fondoCard, icon: Icons.delete_outline);
    }
  }

  void _verFichajes(
      BuildContext context, QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final titulo = data['titulo'] as String? ?? 'Evento';
    final ids = List<String>.from(data['trabajadoresIds'] ?? []);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminFichajesEventoScreen(
          eventoId: doc.id,
          tituloEvento: titulo,
          trabajadoresIds: ids,
        ),
      ),
    );
  }

  Widget _buildSinEventos() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.event_outlined,
              color: AppTheme.textoSecundario, size: 48),
          const SizedBox(height: 16),
          const Text('Todavía no hay eventos',
              style: TextStyle(color: AppTheme.textoSecundario)),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => setState(() => _mostrandoFormulario = true),
            icon: const Icon(Icons.add, color: AppTheme.verdeNeon),
            label: const Text('Crear el primero',
                style: TextStyle(color: AppTheme.verdeNeon)),
          ),
        ],
      ),
    );
  }

  String _hora(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Formulario de crear / editar evento
// ─────────────────────────────────────────────────────────────────────────────

class _AdminCrearEventoForm extends StatefulWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>>? eventoExistente;
  final VoidCallback onVolver;

  const _AdminCrearEventoForm({
    this.eventoExistente,
    required this.onVolver,
  });

  @override
  State<_AdminCrearEventoForm> createState() => _AdminCrearEventoFormState();
}

class _AdminCrearEventoFormState extends State<_AdminCrearEventoForm> {
  final _formKey = GlobalKey<FormState>();
  final _tituloCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  final _ubicacionCtrl = TextEditingController();
  final _duracionCtrl = TextEditingController(text: '8');

  DateTime? _fechaSeleccionada;
  TimeOfDay? _horaSeleccionada;

  // Plazas objetivo por rol {rol: nº}. Se inicializa a 0 para cada rol.
  final Map<String, int> _plazas = {for (final r in RolesEvento.todos) r: 0};
  // Estado de publicación del evento
  String _estado = 'publicado';

  bool _guardando = false;
  String? _errorMsg;

  bool get _esEdicion => widget.eventoExistente != null;

  @override
  void initState() {
    super.initState();
    if (_esEdicion) _rellenarDatosExistentes();
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _descripcionCtrl.dispose();
    _ubicacionCtrl.dispose();
    _duracionCtrl.dispose();
    super.dispose();
  }

  // Rellena el formulario con los datos del evento que se está editando
  void _rellenarDatosExistentes() {
    final data = widget.eventoExistente!.data();
    _tituloCtrl.text = data['titulo'] ?? '';
    _descripcionCtrl.text = data['descripcion'] ?? '';
    _ubicacionCtrl.text = data['ubicacion'] ?? '';

    final inicio = (data['fechaInicio'] as Timestamp).toDate();
    final fin = (data['fechaFin'] as Timestamp).toDate();
    _fechaSeleccionada = inicio;
    _horaSeleccionada = TimeOfDay(hour: inicio.hour, minute: inicio.minute);
    _duracionCtrl.text = fin.difference(inicio).inHours.toString();

    // Plazas por rol y estado del evento
    final plazas = Map<String, dynamic>.from(data['plazasPorRol'] ?? {});
    for (final entry in plazas.entries) {
      _plazas[entry.key] = (entry.value as num).toInt();
    }
    final est = data['estado'] as String?;
    _estado = (est == null || est.isEmpty) ? 'publicado' : est;
  }

  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppTheme.verdeNeon,
            onPrimary: Colors.black,
            surface: AppTheme.fondoCard,
          ),
        ),
        child: child!,
      ),
    );
    if (fecha != null) {
      setState(() => _fechaSeleccionada = fecha);
    }
  }

  Future<void> _seleccionarHora() async {
    final hora = await showTimePicker(
      context: context,
      initialTime: _horaSeleccionada ?? TimeOfDay.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppTheme.verdeNeon,
            onPrimary: Colors.black,
            surface: AppTheme.fondoCard,
          ),
        ),
        child: child!,
      ),
    );
    if (hora != null) {
      setState(() => _horaSeleccionada = hora);
    }
  }

  Future<void> _eliminarEvento() async {
    final data = widget.eventoExistente!.data();
    final titulo = data['titulo'] as String? ?? 'este evento';
    final todos = List<String>.from(data['trabajadoresIds'] ?? []);
    final adminUid = context.read<AuthProvider>().currentUserId ?? '';
    final workerIds = todos.where((id) => id != adminUid).toList();

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.fondoCard,
        title: const Text('Eliminar evento',
            style: TextStyle(color: AppTheme.textoBlanco)),
        content: Text(
          '¿Seguro que quieres eliminar "$titulo"?\n\n'
          'Se borrarán los mensajes del chat y se notificará a los trabajadores asignados.',
          style: const TextStyle(color: AppTheme.textoSecundario),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar',
                style: TextStyle(color: AppTheme.textoSecundario)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    await AdminService.eliminarEvento(
      widget.eventoExistente!.id,
      titulo: titulo,
      trabajadoresIds: workerIds,
    );

    if (mounted) widget.onVolver();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_fechaSeleccionada == null || _horaSeleccionada == null) {
      setState(() => _errorMsg = 'Debes seleccionar fecha y hora.');
      return;
    }

    final duracion = int.tryParse(_duracionCtrl.text.trim()) ?? 0;
    if (duracion <= 0) {
      setState(() => _errorMsg = 'La duración debe ser mayor que 0.');
      return;
    }

    final fechaInicio = DateTime(
      _fechaSeleccionada!.year,
      _fechaSeleccionada!.month,
      _fechaSeleccionada!.day,
      _horaSeleccionada!.hour,
      _horaSeleccionada!.minute,
    );
    final fechaFin = fechaInicio.add(Duration(hours: duracion));

    // Plazas por rol: solo las que tienen algún hueco (> 0)
    final Map<String, int> plazasPorRol = {};
    _plazas.forEach((rol, n) {
      if (n > 0) plazasPorRol[rol] = n;
    });
    if (plazasPorRol.isEmpty) {
      setState(() => _errorMsg = 'Define al menos una plaza en algún rol.');
      return;
    }

    setState(() { _guardando = true; _errorMsg = null; });

    try {
      final adminUid = context.read<AuthProvider>().currentUserId ?? '';
      final adminNombre = context.read<AuthProvider>().currentUser?.nombre ?? '';

      if (_esEdicion) {
        final titulo = _tituloCtrl.text.trim();
        // Al editar NO se tocan los confirmados (trabajadoresIds/Roles/Info): eso lo
        // gestionan las confirmaciones de postulaciones. Solo datos + plazas + estado.
        final data = widget.eventoExistente!.data();
        final idsActuales = List<String>.from(data['trabajadoresIds'] ?? []);
        final confirmadosIds =
            idsActuales.where((id) => id != adminUid).toList();
        await AdminService.actualizarEvento(
          widget.eventoExistente!.id,
          datos: {
            'titulo': titulo,
            'descripcion': _descripcionCtrl.text.trim(),
            'ubicacion': _ubicacionCtrl.text.trim(),
            'fechaInicio': Timestamp.fromDate(fechaInicio),
            'fechaFin': Timestamp.fromDate(fechaFin),
            'plazasPorRol': plazasPorRol,
            'estado': _estado,
          },
          workerIds: confirmadosIds,
          titulo: titulo,
        );
      } else {
        await AdminService.crearEventoAdmin(
          titulo: _tituloCtrl.text.trim(),
          descripcion: _descripcionCtrl.text.trim(),
          ubicacion: _ubicacionCtrl.text.trim(),
          fechaInicio: fechaInicio,
          fechaFin: fechaFin,
          plazasPorRol: plazasPorRol,
          estado: _estado,
          adminUid: adminUid,
          adminNombre: adminNombre,
        );
      }

      if (mounted) widget.onVolver();
    } catch (e) {
      setState(() {
        _errorMsg = 'No se pudo guardar el evento. Inténtalo de nuevo.';
        _guardando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabecera con botón volver (y eliminar si estamos editando)
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back,
                    color: AppTheme.textoBlanco, size: 20),
                onPressed: widget.onVolver,
                tooltip: 'Volver a la lista',
              ),
              const SizedBox(width: 8),
              Text(
                _esEdicion ? 'Editar evento' : 'Nuevo evento',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              if (_esEdicion) ...[
                const Spacer(),
                TextButton.icon(
                  onPressed: _guardando ? null : _eliminarEvento,
                  icon: const Icon(Icons.delete_outline,
                      color: Colors.redAccent, size: 18),
                  label: const Text('Eliminar evento',
                      style: TextStyle(color: Colors.redAccent)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Form(
              key: _formKey,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Columna izquierda: detalles del evento
                  Expanded(
                    flex: 5,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _seccion('Detalles del evento'),
                          const SizedBox(height: 12),
                          _campo('Nombre del evento *', _tituloCtrl, requerido: true),
                          const SizedBox(height: 12),
                          _campo('Descripción (opcional)', _descripcionCtrl, lineas: 2),
                          const SizedBox(height: 12),
                          _campo('Ubicación *', _ubicacionCtrl, requerido: true),
                          const SizedBox(height: 12),
                          // Fecha, hora y duración en una fila
                          Row(
                            children: [
                              Expanded(child: _botonFecha()),
                              const SizedBox(width: 10),
                              Expanded(child: _botonHora()),
                              const SizedBox(width: 10),
                              SizedBox(
                                width: 100,
                                child: _campo('Duración (h) *', _duracionCtrl,
                                    requerido: true,
                                    keyboardType: TextInputType.number),
                              ),
                            ],
                          ),
                          if (_errorMsg != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: Colors.red.withValues(alpha: 0.3)),
                              ),
                              child: Text(_errorMsg!,
                                  style: const TextStyle(
                                      color: Colors.redAccent, fontSize: 13)),
                            ),
                          ],
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed:
                                    _guardando ? null : widget.onVolver,
                                child: const Text('Cancelar',
                                    style: TextStyle(
                                        color: AppTheme.textoSecundario)),
                              ),
                              const SizedBox(width: 8),
                              FilledButton.icon(
                                onPressed: _guardando ? null : _guardar,
                                icon: _guardando
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.black))
                                    : const Icon(Icons.check, size: 16),
                                label: Text(
                                    _esEdicion ? 'Guardar cambios' : 'Crear evento'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppTheme.verdeNeon,
                                  foregroundColor: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  // Columna derecha: plazas por rol + estado de publicación
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _seccion('Plazas por rol'),
                        const SizedBox(height: 4),
                        const Text(
                          '¿Cuántos trabajadores necesitas de cada rol?',
                          style: TextStyle(
                              color: AppTheme.textoTerciario, fontSize: 11),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                for (final rol in RolesEvento.todos)
                                  _filaPlaza(rol),
                                const SizedBox(height: 24),
                                _seccion('Estado'),
                                const SizedBox(height: 10),
                                _selectorEstado(),
                              ],
                            ),
                          ),
                        ),
                      ],
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

  // Fila para definir cuántas plazas se necesitan de un rol (stepper - / +).
  Widget _filaPlaza(String rol) {
    final n = _plazas[rol] ?? 0;
    final tarifa = RolesEvento.tarifaDe(rol);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.fondoCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: n > 0
              ? AppTheme.verdeNeon.withValues(alpha: 0.4)
              : AppTheme.bordeCard,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rol,
                    style: const TextStyle(
                        color: AppTheme.textoBlanco, fontSize: 13)),
                Text('${tarifa.toStringAsFixed(1)} €/h',
                    style: const TextStyle(
                        color: AppTheme.textoTerciario, fontSize: 11)),
              ],
            ),
          ),
          _botonPlaza(
              Icons.remove, n > 0 ? () => setState(() => _plazas[rol] = n - 1) : null),
          SizedBox(
            width: 32,
            child: Text('$n',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: n > 0
                        ? AppTheme.verdeNeon
                        : AppTheme.textoSecundario,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
          ),
          _botonPlaza(Icons.add, () => setState(() => _plazas[rol] = n + 1)),
        ],
      ),
    );
  }

  Widget _botonPlaza(IconData icon, VoidCallback? onTap) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      color: AppTheme.verdeNeon,
      disabledColor: AppTheme.textoSutil,
      visualDensity: VisualDensity.compact,
      style: IconButton.styleFrom(
        backgroundColor: AppTheme.fondoPrincipal,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    );
  }

  Widget _selectorEstado() {
    return Row(
      children: [
        _chipEstadoForm('Borrador', 'borrador'),
        const SizedBox(width: 8),
        _chipEstadoForm('Publicado', 'publicado'),
        const SizedBox(width: 8),
        _chipEstadoForm('Finalizado', 'finalizado'),
      ],
    );
  }

  Widget _chipEstadoForm(String label, String valor) {
    final sel = _estado == valor;
    return ChoiceChip(
      label: Text(label),
      selected: sel,
      onSelected: (_) => setState(() => _estado = valor),
      showCheckmark: false,
      backgroundColor: AppTheme.fondoInput,
      selectedColor: AppTheme.verdeNeon.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        color: sel ? AppTheme.verdeNeon : AppTheme.textoSecundario,
        fontSize: 13,
        fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(color: sel ? AppTheme.verdeNeon : AppTheme.bordeCampo),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  // ── Widgets de apoyo ──

  Widget _seccion(String texto) {
    return Text(
      texto.toUpperCase(),
      style: const TextStyle(
        color: AppTheme.textoTerciario,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _campo(
    String label,
    TextEditingController ctrl, {
    bool requerido = false,
    int lineas = 1,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: ctrl,
      maxLines: lineas,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppTheme.textoBlanco),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            const TextStyle(color: AppTheme.textoSecundario, fontSize: 13),
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
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppTheme.verdeNeon),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      validator: requerido
          ? (v) => (v == null || v.trim().isEmpty) ? 'Campo obligatorio' : null
          : null,
    );
  }

  Widget _botonFecha() {
    final texto = _fechaSeleccionada == null
        ? 'Fecha *'
        : '${_fechaSeleccionada!.day.toString().padLeft(2, '0')}/'
            '${_fechaSeleccionada!.month.toString().padLeft(2, '0')}/'
            '${_fechaSeleccionada!.year}';

    return OutlinedButton.icon(
      onPressed: _seleccionarFecha,
      icon: const Icon(Icons.calendar_today_outlined,
          size: 16, color: AppTheme.verdeNeon),
      label: Text(texto,
          style: TextStyle(
              color: _fechaSeleccionada == null
                  ? AppTheme.textoSecundario
                  : AppTheme.textoBlanco)),
      style: OutlinedButton.styleFrom(
        side: BorderSide(
            color: _fechaSeleccionada == null
                ? AppTheme.bordeCard
                : AppTheme.verdeNeon),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _botonHora() {
    final texto = _horaSeleccionada == null
        ? 'Hora *'
        : '${_horaSeleccionada!.hour.toString().padLeft(2, '0')}:'
            '${_horaSeleccionada!.minute.toString().padLeft(2, '0')}';

    return OutlinedButton.icon(
      onPressed: _seleccionarHora,
      icon: const Icon(Icons.access_time_outlined,
          size: 16, color: AppTheme.verdeNeon),
      label: Text(texto,
          style: TextStyle(
              color: _horaSeleccionada == null
                  ? AppTheme.textoSecundario
                  : AppTheme.textoBlanco)),
      style: OutlinedButton.styleFrom(
        side: BorderSide(
            color: _horaSeleccionada == null
                ? AppTheme.bordeCard
                : AppTheme.verdeNeon),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
