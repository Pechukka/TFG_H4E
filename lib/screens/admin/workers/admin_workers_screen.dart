import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hands4events/core/theme.dart';
import '../../../services/admin_service.dart';
import '../../../utils/pdf_generator.dart';
import '../../../utils/top_snackbar.dart';

class AdminWorkersScreen extends StatefulWidget {
  const AdminWorkersScreen({super.key});

  @override
  State<AdminWorkersScreen> createState() => _AdminWorkersScreenState();
}

class _AdminWorkersScreenState extends State<AdminWorkersScreen> {
  final _buscarCtrl = TextEditingController();
  String _busqueda = '';

  @override
  void dispose() {
    _buscarCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Trabajadores',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => _mostrarCrearWorker(context),
                icon: const Icon(Icons.person_add_outlined, size: 18),
                label: const Text('Nuevo trabajador'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.verdeNeon,
                  foregroundColor: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Buscador por nombre
          _BuscadorWorkers(
            controller: _buscarCtrl,
            onChanged: (v) => setState(() => _busqueda = v.trim().toLowerCase()),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: AdminService.workersStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppTheme.verdeNeon),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error al cargar trabajadores',
                      style: TextStyle(color: AppTheme.textoSecundario),
                    ),
                  );
                }

                final docs = <QueryDocumentSnapshot<Map<String, dynamic>>>[
                  ...(snapshot.data?.docs ?? []),
                ]..sort((a, b) => (a.data()['nombre'] as String? ?? '')
                    .compareTo(b.data()['nombre'] as String? ?? ''));

                if (docs.isEmpty) {
                  return _SinWorkers(onCrear: () => _mostrarCrearWorker(context));
                }

                // Filtro por nombre/apellidos (en Dart)
                final filtrados = _busqueda.isEmpty
                    ? docs
                    : docs.where((d) {
                        final data = d.data();
                        final nombre =
                            '${data['nombre'] ?? ''} ${data['apellidos'] ?? ''}'
                                .toLowerCase();
                        return nombre.contains(_busqueda);
                      }).toList();

                if (filtrados.isEmpty) {
                  return const _SinResultados();
                }

                return _TablaWorkers(docs: filtrados);
              },
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarCrearWorker(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const _ModalCrearWorker(),
    );
  }
}

// ─────────────────────────────────────────
// Buscador
// ─────────────────────────────────────────

class _BuscadorWorkers extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _BuscadorWorkers({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 360,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(color: AppTheme.textoBlanco, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Buscar por nombre…',
          hintStyle:
              const TextStyle(color: AppTheme.textoTerciario, fontSize: 14),
          prefixIcon: const Icon(Icons.search,
              color: AppTheme.textoTerciario, size: 20),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close,
                      color: AppTheme.textoTerciario, size: 18),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                ),
          filled: true,
          fillColor: AppTheme.fondoInput,
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// Sin resultados de búsqueda
// ─────────────────────────────────────────

class _SinResultados extends StatelessWidget {
  const _SinResultados();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off, color: AppTheme.textoSecundario, size: 44),
          SizedBox(height: 12),
          Text('Ningún trabajador coincide con la búsqueda',
              style: TextStyle(color: AppTheme.textoSecundario)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// Lista de trabajadores
// ─────────────────────────────────────────

class _TablaWorkers extends StatelessWidget {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;
  const _TablaWorkers({required this.docs});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.fondoCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.bordeCard),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Cabecera tabla
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: AppTheme.fondoPrincipal,
            child: Row(
              children: [
                _cabecera('NOMBRE', flex: 3),
                _cabecera('EMAIL', flex: 4),
                _cabecera('TELÉFONO', flex: 2),
                _cabecera('ESTADO', flex: 1),
                _cabecera('', flex: 1),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.bordeCard),
          // Filas
          Expanded(
            child: ListView.separated(
              itemCount: docs.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: AppTheme.bordeCard),
              itemBuilder: (context, i) {
                final uid = docs[i].id;
                final data = docs[i].data();
                final nombre = '${data['nombre'] ?? ''} ${data['apellidos'] ?? ''}'.trim();
                final email = data['email'] ?? '';
                final telefono = data['telefono'] ?? '—';
                final activo = data['activo'] ?? true;

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor:
                                  AppTheme.verdeNeon.withValues(alpha: 0.15),
                              child: Text(
                                nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
                                style: const TextStyle(
                                  color: AppTheme.verdeNeon,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Flexible(
                              child: Text(
                                nombre,
                                style: Theme.of(context).textTheme.bodyMedium,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 4,
                        child: Text(
                          email,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.textoSecundario,
                              ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          telefono,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.textoSecundario,
                              ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Row(
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: activo ? AppTheme.verdeNeon : AppTheme.textoTerciario,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              activo ? 'Activo' : 'Inactivo',
                              style: TextStyle(
                                color: activo ? AppTheme.verdeNeon : AppTheme.textoTerciario,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => showDialog(
                              context: context,
                              builder: (ctx) => _ModalGestionarWorker(
                                uid: uid,
                                datosActuales: data,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: AppTheme.verdeNeon,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                            ),
                            child: const Text('Gestionar',
                                style: TextStyle(fontSize: 12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _cabecera(String text, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: const TextStyle(
          color: AppTheme.textoTerciario,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// Estado vacío
// ─────────────────────────────────────────

class _SinWorkers extends StatelessWidget {
  final VoidCallback onCrear;
  const _SinWorkers({required this.onCrear});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.people_outline, color: AppTheme.textoSecundario, size: 48),
          const SizedBox(height: 16),
          const Text(
            'Todavía no hay trabajadores',
            style: TextStyle(color: AppTheme.textoSecundario),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: onCrear,
            icon: const Icon(Icons.person_add_outlined, color: AppTheme.verdeNeon),
            label: const Text('Crear el primero', style: TextStyle(color: AppTheme.verdeNeon)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// Modal: Gestionar trabajador (editar / eliminar)
// ─────────────────────────────────────────

class _ModalGestionarWorker extends StatefulWidget {
  final String uid;
  final Map<String, dynamic> datosActuales;

  const _ModalGestionarWorker({
    required this.uid,
    required this.datosActuales,
  });

  @override
  State<_ModalGestionarWorker> createState() => _ModalGestionarWorkerState();
}

class _ModalGestionarWorkerState extends State<_ModalGestionarWorker> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _apellidosCtrl;
  late final TextEditingController _telefonoCtrl;
  late final TextEditingController _dniCtrl;
  late bool _activo;

  bool _isLoading = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    final d = widget.datosActuales;
    _nombreCtrl = TextEditingController(text: d['nombre'] ?? '');
    _apellidosCtrl = TextEditingController(text: d['apellidos'] ?? '');
    final telStored = (d['telefono'] as String? ?? '').replaceAll(RegExp(r'^\+34\s*'), '').trim();
    _telefonoCtrl = TextEditingController(text: telStored);
    _dniCtrl = TextEditingController(text: d['dni'] ?? '');
    _activo = d['activo'] ?? true;
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _apellidosCtrl.dispose();
    _telefonoCtrl.dispose();
    _dniCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMsg = null; });

    try {
      await AdminService.actualizarWorker(widget.uid, {
        'nombre': _nombreCtrl.text.trim(),
        'apellidos': _apellidosCtrl.text.trim(),
        'telefono': _telefonoCtrl.text.trim(),
        'dni': _dniCtrl.text.trim(),
        'activo': _activo,
      });
      if (!mounted) return;
      Navigator.pop(context);
      showTopSnackBar(context, 'Datos actualizados correctamente',
          backgroundColor: AppTheme.verdeNeon, icon: Icons.check_circle_outline);
    } catch (e) {
      setState(() {
        _errorMsg = 'Error al guardar. Inténtalo de nuevo.';
        _isLoading = false;
      });
    }
  }

  Future<void> _confirmarEliminar() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.fondoCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Eliminar trabajador',
            style: TextStyle(color: AppTheme.textoBlanco)),
        content: Text(
          '¿Seguro que quieres eliminar a '
          '${_nombreCtrl.text.trim()} ${_apellidosCtrl.text.trim()}? '
          'Esta acción no se puede deshacer.',
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
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    setState(() => _isLoading = true);
    try {
      await AdminService.eliminarWorker(widget.uid);
      if (!mounted) return;
      Navigator.pop(context);
      showTopSnackBar(context, 'Trabajador eliminado',
          backgroundColor: AppTheme.rojoError, icon: Icons.delete_outline);
    } catch (e) {
      setState(() {
        _errorMsg = 'Error al eliminar. Inténtalo de nuevo.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = widget.datosActuales['email'] ?? '';

    return Dialog(
      backgroundColor: AppTheme.fondoCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 480,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cabecera
                Row(
                  children: [
                    Text('Gestionar trabajador',
                        style: Theme.of(context).textTheme.titleMedium),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close,
                          color: AppTheme.textoSecundario),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Email (no editable, solo informativo)
                Text(email,
                    style: const TextStyle(
                        color: AppTheme.textoTerciario, fontSize: 12)),
                const SizedBox(height: 20),
                // Campos editables
                Row(
                  children: [
                    Expanded(child: _campo('Nombre *', _nombreCtrl, requerido: true)),
                    const SizedBox(width: 12),
                    Expanded(child: _campo('Apellidos', _apellidosCtrl)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _campo('Teléfono', _telefonoCtrl,
                        keyboardType: TextInputType.phone,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return null;
                          if (!RegExp(r'^[6-9][0-9]{8}$').hasMatch(v.trim())) {
                            return 'Formato: 6XXXXXXXX';
                          }
                          return null;
                        })),
                    const SizedBox(width: 12),
                    Expanded(child: _campo('DNI', _dniCtrl,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return null;
                          if (!RegExp(r'^[0-9]{8}[A-Z]$').hasMatch(v.trim().toUpperCase())) {
                            return 'Formato: 12345678A';
                          }
                          return null;
                        })),
                  ],
                ),
                const SizedBox(height: 16),
                // Toggle activo/inactivo
                Row(
                  children: [
                    Switch(
                      value: _activo,
                      onChanged: (v) => setState(() => _activo = v),
                      activeThumbColor: AppTheme.verdeNeon,
                      activeTrackColor: AppTheme.verdeNeon.withValues(alpha: 0.4),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _activo ? 'Trabajador activo' : 'Trabajador inactivo',
                      style: TextStyle(
                        color: _activo
                            ? AppTheme.verdeNeon
                            : AppTheme.textoSecundario,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                if (_errorMsg != null) ...[
                  const SizedBox(height: 10),
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
                // Botones
                Row(
                  children: [
                    // Eliminar (izquierda)
                    TextButton.icon(
                      onPressed: _isLoading ? null : _confirmarEliminar,
                      icon: const Icon(Icons.delete_outline,
                          color: Colors.redAccent, size: 16),
                      label: const Text('Eliminar',
                          style: TextStyle(
                              color: Colors.redAccent, fontSize: 13)),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed:
                          _isLoading ? null : () => Navigator.pop(context),
                      child: const Text('Cancelar',
                          style:
                              TextStyle(color: AppTheme.textoSecundario)),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _isLoading ? null : _guardar,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.verdeNeon,
                        foregroundColor: Colors.black,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.black),
                            )
                          : const Text('Guardar cambios'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _campo(
    String label,
    TextEditingController ctrl, {
    bool requerido = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
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
      validator: validator ??
          (requerido
              ? (v) => (v == null || v.trim().isEmpty) ? 'Campo obligatorio' : null
              : null),
    );
  }
}

// ─────────────────────────────────────────
// Modal: Crear trabajador
// ─────────────────────────────────────────

class _ModalCrearWorker extends StatefulWidget {
  const _ModalCrearWorker();

  @override
  State<_ModalCrearWorker> createState() => _ModalCrearWorkerState();
}

class _ModalCrearWorkerState extends State<_ModalCrearWorker> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _apellidosCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _dniCtrl = TextEditingController();

  bool _isLoading = false;
  bool _verPassword = false;
  String? _errorMsg;

  // Resultado tras crear — para mostrar el botón de ticket
  Map<String, String>? _workerCreado;

  @override
  void initState() {
    super.initState();
    _passwordCtrl.text = AdminService.generarPassword();
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _apellidosCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _telefonoCtrl.dispose();
    _dniCtrl.dispose();
    super.dispose();
  }

  Future<void> _crear() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMsg = null; });

    try {
      await AdminService.crearWorker(
        nombre: _nombreCtrl.text.trim(),
        apellidos: _apellidosCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        telefono: _telefonoCtrl.text.trim(),
        dni: _dniCtrl.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _workerCreado = {
          'nombre': _nombreCtrl.text.trim(),
          'apellidos': _apellidosCtrl.text.trim(),
          'email': _emailCtrl.text.trim(),
          'password': _passwordCtrl.text,
        };
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMsg = _mensajeError(e.toString());
        _isLoading = false;
      });
    }
  }

  String _mensajeError(String raw) {
    if (raw.contains('email-already-in-use')) return 'Ese email ya está registrado.';
    if (raw.contains('invalid-email')) return 'El email no es válido.';
    if (raw.contains('weak-password')) return 'La contraseña es demasiado débil.';
    return 'Error al crear el trabajador. Inténtalo de nuevo.';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.fondoCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 460,
        child: _workerCreado != null
            ? _buildExito()
            : _buildFormulario(),
      ),
    );
  }

  // ── Formulario de creación ──

  Widget _buildFormulario() {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Nuevo trabajador',
                    style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: AppTheme.textoSecundario),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: _campo('Nombre *', _nombreCtrl, requerido: true)),
                const SizedBox(width: 12),
                Expanded(child: _campo('Apellidos', _apellidosCtrl)),
              ],
            ),
            const SizedBox(height: 12),
            _campo('Email *', _emailCtrl, requerido: true, keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 12),
            _campoPassword(),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _campo('Teléfono', _telefonoCtrl,
                    keyboardType: TextInputType.phone,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return null;
                      if (!RegExp(r'^[6-9][0-9]{8}$').hasMatch(v.trim())) {
                        return 'Formato: 6XXXXXXXX';
                      }
                      return null;
                    })),
                const SizedBox(width: 12),
                Expanded(child: _campo('DNI', _dniCtrl,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return null;
                      if (!RegExp(r'^[0-9]{8}[A-Z]$').hasMatch(v.trim().toUpperCase())) {
                        return 'Formato: 12345678A';
                      }
                      return null;
                    })),
              ],
            ),
            if (_errorMsg != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Text(
                  _errorMsg!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                ),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                  child: const Text('Cancelar',
                      style: TextStyle(color: AppTheme.textoSecundario)),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _isLoading ? null : _crear,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.verdeNeon,
                    foregroundColor: Colors.black,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.black),
                        )
                      : const Text('Crear trabajador'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _campo(
    String label,
    TextEditingController ctrl, {
    bool requerido = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppTheme.textoBlanco),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppTheme.textoSecundario, fontSize: 13),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      validator: validator ??
          (requerido
              ? (v) => (v == null || v.trim().isEmpty) ? 'Campo obligatorio' : null
              : null),
    );
  }

  Widget _campoPassword() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _passwordCtrl,
            obscureText: !_verPassword,
            style: const TextStyle(color: AppTheme.textoBlanco, fontFamily: 'monospace'),
            decoration: InputDecoration(
              labelText: 'Contraseña *',
              labelStyle: const TextStyle(color: AppTheme.textoSecundario, fontSize: 13),
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
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              suffixIcon: IconButton(
                icon: Icon(
                  _verPassword ? Icons.visibility_off : Icons.visibility,
                  color: AppTheme.textoSecundario, size: 18,
                ),
                onPressed: () => setState(() => _verPassword = !_verPassword),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Campo obligatorio';
              if (v.length < 6) return 'Mínimo 6 caracteres';
              return null;
            },
          ),
        ),
        const SizedBox(width: 8),
        Tooltip(
          message: 'Generar nueva contraseña',
          child: IconButton(
            onPressed: () => setState(() => _passwordCtrl.text = AdminService.generarPassword()),
            icon: const Icon(Icons.refresh, color: AppTheme.verdeNeon),
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.verdeNeon.withValues(alpha: 0.1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ],
    );
  }

  // ── Pantalla de éxito ──

  Widget _buildExito() {
    final w = _workerCreado!;
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: AppTheme.verdeNeon.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: AppTheme.verdeNeon, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            'Trabajador creado',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            '${w['nombre']} ${w['apellidos']}'.trim(),
            style: const TextStyle(color: AppTheme.textoSecundario),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.fondoPrincipal,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.bordeCard),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _datoCredencial('Email', w['email']!),
                const SizedBox(height: 8),
                _datoCredencial('Contraseña', w['password']!),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => PdfGenerator.descargarTicketWorker(
                nombre: w['nombre']!,
                apellidos: w['apellidos']!,
                email: w['email']!,
                password: w['password']!,
              ),
              icon: const Icon(Icons.download_outlined, size: 18),
              label: const Text('Descargar ticket PDF'),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.verdeNeon,
                foregroundColor: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar', style: TextStyle(color: AppTheme.textoSecundario)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _datoCredencial(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(color: AppTheme.textoSecundario, fontSize: 12),
        ),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(
              color: AppTheme.textoBlanco,
              fontSize: 12,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    );
  }
}
