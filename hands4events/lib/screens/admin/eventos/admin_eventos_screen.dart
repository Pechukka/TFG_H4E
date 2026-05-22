import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hands4events/core/theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/admin_service.dart';
import '../../../core/roles.dart';
import 'admin_fichajes_evento_screen.dart';
import '../../../utils/top_snackbar.dart';

// Pantalla principal de eventos del admin.
// Muestra la lista de eventos o el formulario de creación según el estado.
class AdminEventosScreen extends StatefulWidget {
  const AdminEventosScreen({super.key});

  @override
  State<AdminEventosScreen> createState() => _AdminEventosScreenState();
}

class _AdminEventosScreenState extends State<AdminEventosScreen> {
  // Si es true, mostramos el formulario de crear evento en vez de la lista
  bool _mostrandoFormulario = false;
  // Evento que se está editando (null si se está creando uno nuevo)
  QueryDocumentSnapshot<Map<String, dynamic>>? _eventoEditando;

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
          const SizedBox(height: 20),
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

                return ListView.separated(
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) => _buildCardEvento(docs[i]),
                );
              },
            ),
          ),
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
          // Número de trabajadores
          Column(
            children: [
              Text(
                '${trabajadoresIds.length}',
                style: const TextStyle(
                    color: AppTheme.verdeNeon,
                    fontWeight: FontWeight.bold,
                    fontSize: 18),
              ),
              const Text('trabajadores',
                  style: TextStyle(
                      color: AppTheme.textoTerciario, fontSize: 10)),
            ],
          ),
          const SizedBox(width: 12),
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

  // Lista de trabajadores cargados desde Firestore
  List<Map<String, dynamic>> _workers = [];
  bool _cargandoWorkers = true;

  // Para cada worker guardamos si está seleccionado y qué rol tiene
  final Map<String, bool> _seleccionados = {};
  final Map<String, String> _roles = {};
  // Indica si ese worker tiene disponibilidad ese día
  final Map<String, bool> _disponibilidades = {};

  bool _guardando = false;
  String? _errorMsg;

  bool get _esEdicion => widget.eventoExistente != null;

  @override
  void initState() {
    super.initState();
    _cargarWorkers();
    if (_esEdicion) _rellenarDatosExistentes();
    // Recalcular disponibilidad cuando cambia la duración
    _duracionCtrl.addListener(() {
      if (_fechaSeleccionada != null) _comprobarDisponibilidades(_fechaSeleccionada!);
    });
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

    final roles = Map<String, String>.from(data['trabajadoresRoles'] ?? {});
    for (var entry in roles.entries) {
      _seleccionados[entry.key] = true;
      _roles[entry.key] = entry.value;
    }
  }

  Future<void> _cargarWorkers() async {
    final lista = await AdminService.getWorkers();
    if (!mounted) return;
    setState(() {
      _workers = lista;
      _cargandoWorkers = false;
      // Inicializamos cada worker como no seleccionado si no venía de edición
      for (var w in lista) {
        final uid = w['uid'] as String;
        _seleccionados.putIfAbsent(uid, () => false);
        _roles.putIfAbsent(uid, () => RolesEvento.todos.first);
      }
    });
    // Al editar, la fecha ya está cargada — lanzar comprobación de disponibilidad
    if (_esEdicion && _fechaSeleccionada != null) {
      _comprobarDisponibilidades(_fechaSeleccionada!);
    }
  }

  // Recalcula la disponibilidad de todos los workers para el rango actual del evento.
  // Si no hay hora o duración todavía, solo comprueba que haya disponibilidad ese día.
  Future<void> _comprobarDisponibilidades(DateTime fecha) async {
    DateTime? eventoInicio;
    DateTime? eventoFin;

    if (_horaSeleccionada != null) {
      eventoInicio = DateTime(
        fecha.year, fecha.month, fecha.day,
        _horaSeleccionada!.hour, _horaSeleccionada!.minute,
      );
      final duracion = int.tryParse(_duracionCtrl.text.trim()) ?? 0;
      if (duracion > 0) eventoFin = eventoInicio.add(Duration(hours: duracion));
    }

    for (var w in _workers) {
      final uid = w['uid'] as String;
      final disponible = await AdminService.tieneDisponibilidad(
          uid, fecha, eventoInicio, eventoFin);
      if (!mounted) return;
      setState(() => _disponibilidades[uid] = disponible);
    }
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
      _comprobarDisponibilidades(fecha);
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
      // Recalculamos con la nueva hora si ya había fecha seleccionada
      if (_fechaSeleccionada != null) _comprobarDisponibilidades(_fechaSeleccionada!);
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

    // Solo los workers que el admin marcó como seleccionados
    final Map<String, String> rolesSeleccionados = {};
    for (var w in _workers) {
      final uid = w['uid'] as String;
      if (_seleccionados[uid] == true) {
        rolesSeleccionados[uid] = _roles[uid] ?? RolesEvento.todos.first;
      }
    }

    setState(() { _guardando = true; _errorMsg = null; });

    try {
      final adminUid = context.read<AuthProvider>().currentUserId ?? '';
      final adminNombre = context.read<AuthProvider>().currentUser?.nombre ?? '';

      if (_esEdicion) {
        final titulo = _tituloCtrl.text.trim();
        await AdminService.actualizarEvento(
          widget.eventoExistente!.id,
          datos: {
            'titulo': titulo,
            'descripcion': _descripcionCtrl.text.trim(),
            'ubicacion': _ubicacionCtrl.text.trim(),
            'fechaInicio': Timestamp.fromDate(fechaInicio),
            'fechaFin': Timestamp.fromDate(fechaFin),
            'trabajadoresRoles': {...rolesSeleccionados, adminUid: 'Coordinador'},
            'trabajadoresIds': [...rolesSeleccionados.keys, adminUid],
          },
          workerIds: rolesSeleccionados.keys.toList(),
          titulo: titulo,
        );
      } else {
        await AdminService.crearEventoAdmin(
          titulo: _tituloCtrl.text.trim(),
          descripcion: _descripcionCtrl.text.trim(),
          ubicacion: _ubicacionCtrl.text.trim(),
          fechaInicio: fechaInicio,
          fechaFin: fechaFin,
          trabajadoresRoles: rolesSeleccionados,
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
                  // Columna derecha: lista de trabajadores para asignar
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _seccion('Trabajadores'),
                        const SizedBox(height: 4),
                        Text(
                          _fechaSeleccionada == null
                              ? 'Selecciona una fecha para ver disponibilidad'
                              : 'El punto verde indica que el trabajador tiene disponibilidad ese día',
                          style: const TextStyle(
                              color: AppTheme.textoTerciario, fontSize: 11),
                        ),
                        const SizedBox(height: 12),
                        Expanded(child: _buildListaWorkers()),
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

  Widget _buildListaWorkers() {
    if (_cargandoWorkers) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.verdeNeon));
    }
    if (_workers.isEmpty) {
      return const Center(
        child: Text('No hay trabajadores registrados',
            style: TextStyle(color: AppTheme.textoSecundario)),
      );
    }

    // Hasta que haya fecha + hora + duración no tiene sentido mostrar disponibilidad
    if (_fechaSeleccionada == null || _horaSeleccionada == null ||
        (int.tryParse(_duracionCtrl.text.trim()) ?? 0) <= 0) {
      return const Center(
        child: Text(
          'Selecciona fecha, hora y duración\npara ver la disponibilidad',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.textoTerciario, fontSize: 12),
        ),
      );
    }

    // Separamos según disponibilidad calculada
    final disponibles = <Map<String, dynamic>>[];
    final noDisponibles = <Map<String, dynamic>>[];
    final comprobando = <Map<String, dynamic>>[];

    for (final w in _workers) {
      final uid = w['uid'] as String;
      final disp = _disponibilidades[uid];
      if (disp == null) {
        comprobando.add(w); // aún calculando
      } else if (disp) {
        disponibles.add(w);
      } else {
        noDisponibles.add(w);
      }
    }

    // Mientras se comprueba la disponibilidad, spinner
    if (comprobando.isNotEmpty) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.verdeNeon));
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (disponibles.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Ningún trabajador tiene disponibilidad en ese horario.',
                style: TextStyle(
                    color: AppTheme.textoSecundario, fontSize: 12),
              ),
            )
          else ...[
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text('DISPONIBLES',
                  style: TextStyle(
                      color: AppTheme.verdeNeon,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5)),
            ),
            _buildSeccionWorkers(disponibles, disponibles: true),
          ],
          if (noDisponibles.isNotEmpty) ...[
            const SizedBox(height: 12),
            // Sección colapsable de no disponibles
            Container(
              decoration: BoxDecoration(
                color: AppTheme.fondoCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.bordeCard),
              ),
              clipBehavior: Clip.antiAlias,
              child: ExpansionTile(
                tilePadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                collapsedIconColor: AppTheme.textoTerciario,
                iconColor: AppTheme.textoTerciario,
                title: Row(
                  children: [
                    const Icon(Icons.block_outlined,
                        size: 14, color: AppTheme.textoTerciario),
                    const SizedBox(width: 6),
                    Text(
                      'No disponibles (${noDisponibles.length})',
                      style: const TextStyle(
                          color: AppTheme.textoTerciario,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                children: noDisponibles.map((w) {
                  final uid = w['uid'] as String;
                  final nombre = w['nombre'] as String;
                  final seleccionado = _seleccionados[uid] ?? false;
                  final rol = _roles[uid] ?? RolesEvento.todos.first;
                  return _buildItemWorker(
                      uid, nombre, seleccionado, rol,
                      disponible: false);
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSeccionWorkers(
      List<Map<String, dynamic>> workers, {required bool disponibles}) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.fondoCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.bordeCard),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: workers.length,
        separatorBuilder: (_, __) =>
            const Divider(height: 1, color: AppTheme.bordeCard),
        itemBuilder: (context, i) {
          final w = workers[i];
          final uid = w['uid'] as String;
          final nombre = w['nombre'] as String;
          final seleccionado = _seleccionados[uid] ?? false;
          final rol = _roles[uid] ?? RolesEvento.todos.first;
          return _buildItemWorker(uid, nombre, seleccionado, rol,
              disponible: disponibles);
        },
      ),
    );
  }

  Widget _buildItemWorker(
    String uid,
    String nombre,
    bool seleccionado,
    String rol, {
    required bool disponible,
  }) {
    return CheckboxListTile(
      value: seleccionado,
      onChanged: (val) => setState(() => _seleccionados[uid] = val ?? false),
      activeColor: AppTheme.verdeNeon,
      checkColor: Colors.black,
      title: Text(
        nombre,
        style: TextStyle(
          color: disponible ? AppTheme.textoBlanco : AppTheme.textoTerciario,
          fontSize: 13,
        ),
      ),
      subtitle: seleccionado
          ? Padding(
              padding: const EdgeInsets.only(top: 4),
              child: DropdownButtonFormField<String>(
                initialValue: RolesEvento.todos.contains(rol)
                    ? rol
                    : RolesEvento.todos.first,
                dropdownColor: AppTheme.fondoCard,
                style: const TextStyle(
                    color: AppTheme.textoBlanco, fontSize: 12),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  filled: true,
                  fillColor: AppTheme.fondoPrincipal,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(color: AppTheme.bordeCard),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(color: AppTheme.bordeCard),
                  ),
                ),
                items: RolesEvento.todos.map((r) {
                  return DropdownMenuItem(
                    value: r,
                    child: Text(
                        '$r  –  ${RolesEvento.tarifaDe(r).toStringAsFixed(1)}€/h'),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _roles[uid] = val);
                },
              ),
            )
          : null,
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
