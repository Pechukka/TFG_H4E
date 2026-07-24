import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hands4events/core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/idioma_provider.dart';
import '../../models/mensaje.dart';
import '../../widgets/app_bar_custom.dart';
import 'equipo_evento_screen.dart';
import 'seleccionar_ubicacion_screen.dart';

class ChatEventoScreen extends StatefulWidget {
  final String tituloEvento;
  final String eventoId;
  // true = solo lectura (evento finalizado): se ve el histórico pero no se envía.
  final bool soloLectura;

  const ChatEventoScreen({
    super.key,
    required this.tituloEvento,
    this.eventoId = '',
    this.soloLectura = false,
  });

  @override
  State<ChatEventoScreen> createState() => _ChatEventoScreenState();
}

class _ChatEventoScreenState extends State<ChatEventoScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();
  // Estado de respuesta / edición
  Mensaje? _replyingTo;
  Mensaje? _editandoMensaje;

  @override
  void initState() {
    super.initState();
    if (widget.eventoId.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<ChatProvider>().cargarMensajes(widget.eventoId);
        final userId = context.read<AuthProvider>().currentUserId;
        if (userId != null) {
          context.read<ChatProvider>().marcarMensajesLeidos(
                widget.eventoId,
                userId,
              );
        }
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocusNode.dispose();
    context.read<ChatProvider>().limpiarMensajes();
    super.dispose();
  }

  // ── Responder ───────────────────────────────────────────────────────────────

  void _setReply(Mensaje mensaje) {
    setState(() {
      _replyingTo = mensaje;
      _editandoMensaje = null;
    });
    // No abrimos el teclado automáticamente; el usuario pulsa cuando quiera escribir
  }

  // ── Editar / Eliminar ───────────────────────────────────────────────────────

  void _setEditar(Mensaje mensaje) {
    setState(() {
      _editandoMensaje = mensaje;
      _replyingTo = null;
      _messageController.text = mensaje.texto;
    });
    _messageFocusNode.requestFocus();
  }

  void _cancelarAccion() {
    setState(() {
      _replyingTo = null;
      _editandoMensaje = null;
    });
    if (_editandoMensaje != null) _messageController.clear();
  }

  void _mostrarOpcionesMensaje(
      BuildContext context, Mensaje mensaje, bool esPropio, IdiomaProvider t) {
    if (!esPropio) return;
    final puedeEditar = mensaje.tipo == 'texto' &&
        DateTime.now().difference(mensaje.timestamp).inMinutes < 10;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.fondoCard,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textoTerciario,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            if (puedeEditar)
              ListTile(
                leading: const Icon(Icons.edit, color: AppTheme.verdeNeon),
                title: Text(t.tr('editar'),
                    style: const TextStyle(color: AppTheme.textoBlanco)),
                onTap: () {
                  Navigator.pop(ctx);
                  _setEditar(mensaje);
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete, color: AppTheme.rojoError),
              title: Text(t.tr('eliminar'),
                  style: const TextStyle(color: AppTheme.rojoError)),
              onTap: () {
                Navigator.pop(ctx);
                _confirmarEliminar(mensaje, t);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _confirmarEliminar(Mensaje mensaje, IdiomaProvider t) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.fondoCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(t.tr('confirmar_eliminar'),
            style: Theme.of(context).textTheme.titleMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t.tr('cancelar'),
                style:
                    const TextStyle(color: AppTheme.textoSecundario)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await context
                  .read<ChatProvider>()
                  .eliminarMensaje(mensaje.id);
            },
            child: Text(t.tr('eliminar'),
                style: const TextStyle(color: AppTheme.rojoError)),
          ),
        ],
      ),
    );
  }

  // ── Imagen ──────────────────────────────────────────────────────────────────

  Future<void> _mostrarOpcionesImagen() async {
    FocusScope.of(context).unfocus();
    final t = context.read<IdiomaProvider>();
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.fondoCard,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textoTerciario,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppTheme.verdeNeon),
              title: Text(t.tr('camara'),
                  style: const TextStyle(color: AppTheme.textoBlanco)),
              onTap: () {
                Navigator.pop(ctx);
                _adjuntarImagen(ImageSource.camera);
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.photo_library, color: AppTheme.verdeNeon),
              title: Text(t.tr('galeria'),
                  style: const TextStyle(color: AppTheme.textoBlanco)),
              onTap: () {
                Navigator.pop(ctx);
                _adjuntarImagen(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _adjuntarImagen(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );
    if (picked == null || !mounted) return;
    FocusScope.of(context).unfocus();

    final authProvider = context.read<AuthProvider>();
    await context.read<ChatProvider>().enviarMensajeConImagen(
          eventoId: widget.eventoId,
          remitenteId: authProvider.currentUserId ?? '',
          remitenteNombre: authProvider.currentUser?.nombre ?? 'Trabajador',
          imagen: File(picked.path),
          texto: _messageController.text.trim().isEmpty
              ? null
              : _messageController.text.trim(),
        );
    _messageController.clear();
    _scrollToBottom();
  }

  // ── Ubicación ───────────────────────────────────────────────────────────────

  Future<void> _seleccionarYEnviarUbicacion() async {
    final chatProvider = context.read<ChatProvider>();
    if (chatProvider.isSending) return;
    FocusScope.of(context).unfocus();

    final resultado = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const SeleccionarUbicacionScreen(),
      ),
    );

    if (!mounted) return;
    FocusScope.of(context).unfocus();
    if (resultado == null) return;

    final authProvider = context.read<AuthProvider>();
    await chatProvider.enviarUbicacion(
      eventoId: widget.eventoId,
      remitenteId: authProvider.currentUserId ?? '',
      remitenteNombre: authProvider.currentUser?.nombre ?? 'Trabajador',
      lat: resultado.latitude,
      lng: resultado.longitude,
    );
    _scrollToBottom();
  }

  // ── Enviar mensaje ──────────────────────────────────────────────────────────

  Future<void> _enviarMensaje() async {
    final texto = _messageController.text.trim();
    if (texto.isEmpty || widget.eventoId.isEmpty) return;

    // Modo edición
    if (_editandoMensaje != null) {
      final id = _editandoMensaje!.id;
      _messageController.clear();
      setState(() => _editandoMensaje = null);
      await context.read<ChatProvider>().editarMensaje(id, texto);
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final reply = _replyingTo;

    _messageController.clear();
    setState(() => _replyingTo = null);

    String? replyTextoPreview;
    if (reply != null) {
      if (reply.tipo == 'ubicacion') {
        replyTextoPreview = '📍 Ubicación';
      } else {
        final t = reply.texto;
        replyTextoPreview = t.length > 60 ? '${t.substring(0, 60)}…' : t;
      }
    }

    await context.read<ChatProvider>().enviarMensaje(
          eventoId: widget.eventoId,
          remitenteId: authProvider.currentUserId ?? '',
          remitenteNombre: authProvider.currentUser?.nombre ?? 'Trabajador',
          texto: texto,
          replyToId: reply?.id,
          replyToNombre: reply?.remitenteNombre,
          replyToTexto: replyTextoPreview,
        );
    _scrollToBottom();
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _mostrarImagenCompleta(BuildContext context, String url) {
    final focusScope = FocusScope.of(context);
    focusScope.unfocus();
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (ctx) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            elevation: 0,
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.network(url, fit: BoxFit.contain,
                  loadingBuilder: (_, child, progress) {
                if (progress == null) return child;
                return const Center(
                    child:
                        CircularProgressIndicator(color: AppTheme.verdeNeon));
              }),
            ),
          ),
        ),
      ),
    ).then((_) {
      if (mounted) focusScope.unfocus();
    });
  }

  Future<void> _abrirMaps(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final t = context.watch<IdiomaProvider>();
    final chatProvider = context.watch<ChatProvider>();
    final mensajes = chatProvider.mensajes;
    final userId = context.read<AuthProvider>().currentUserId ?? '';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && mensajes.isNotEmpty) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.fondoPrincipal,
      appBar: AppBarCustom(
        showLogo: true,
        showBackButton: true,
        title: widget.tituloEvento,
        subtitle: t.tr('chat_subtitulo'),
        actions: const [],
      ),
      body: Column(
        children: [
          // Banner equipo
          InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EquipoEventoScreen(
                  tituloEvento: widget.tituloEvento,
                  eventoId: widget.eventoId,
                ),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.fondoCard,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.group, color: AppTheme.verdeNeon, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t.tr('info_equipo'),
                            style: Theme.of(context).textTheme.titleSmall),
                        const SizedBox(height: 2),
                        Text(t.tr('ver_miembros'),
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppTheme.textoSecundario)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right,
                      color: AppTheme.textoSecundario),
                ],
              ),
            ),
          ),

          // Lista mensajes
          Expanded(
            child: widget.eventoId.isEmpty
                ? Center(
                    child: Text(t.tr('chat_no_disponible'),
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: AppTheme.textoSecundario)))
                : mensajes.isEmpty
                    ? Center(
                        child: Text(t.tr('primer_mensaje'),
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: AppTheme.textoSecundario)))
                    : ListView.separated(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        itemCount: mensajes.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final mensaje = mensajes[index];
                          final esPropio = mensaje.remitenteId == userId;
                          return _buildSwipeableBubble(
                              context, t, mensaje, esPropio);
                        },
                      ),
          ),

          // Barra de respuesta/edición
          if (_replyingTo != null) _buildReplyBar(t, _replyingTo!),
          if (_editandoMensaje != null) _buildEditBar(t),

          // Input (o barra de solo lectura si el evento está finalizado)
          widget.soloLectura
              ? _buildBarraLectura(t)
              : _buildInputBar(t, chatProvider),
        ],
      ),
    );
  }

  // ── Swipeable bubble ─────────────────────────────────────────────────────────

  Widget _buildSwipeableBubble(
    BuildContext context,
    IdiomaProvider t,
    Mensaje mensaje,
    bool esPropio,
  ) {
    final replyBackground = Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      color: Colors.transparent,
      child: const Icon(Icons.reply, color: AppTheme.verdeNeon, size: 28),
    );

    return Dismissible(
      key: Key('msg_${mensaje.id}'),
      direction: DismissDirection.startToEnd,
      confirmDismiss: (_) async {
        _setReply(mensaje);
        return false; // Never actually remove the item
      },
      background: replyBackground,
      child: GestureDetector(
        onLongPress: esPropio
            ? () => _mostrarOpcionesMensaje(context, mensaje, esPropio, t)
            : null,
        child: _buildMessageBubble(context, t: t, mensaje: mensaje, esPropio: esPropio),
      ),
    );
  }

  // ── Reply bar ────────────────────────────────────────────────────────────────

  Widget _buildReplyBar(IdiomaProvider t, Mensaje mensaje) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: const BoxDecoration(
        color: AppTheme.fondoCard,
        border: Border(top: BorderSide(color: AppTheme.bordeCampo)),
      ),
      child: Row(
        children: [
          Container(width: 3, height: 40, color: AppTheme.verdeNeon),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${t.tr('respondiendo_a')} ${mensaje.remitenteNombre}',
                  style: const TextStyle(
                    color: AppTheme.verdeNeon,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  mensaje.tipo == 'ubicacion'
                      ? '📍 ${t.tr('ubicacion_compartida')}'
                      : mensaje.tieneImagen()
                          ? '🖼️ ${t.tr('adjuntar_imagen')}'
                          : mensaje.texto,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textoSecundario,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: AppTheme.textoSecundario, size: 20),
            onPressed: _cancelarAccion,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 36, height: 36),
          ),
        ],
      ),
    );
  }

  // ── Edit bar ─────────────────────────────────────────────────────────────────

  Widget _buildEditBar(IdiomaProvider t) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: const BoxDecoration(
        color: AppTheme.fondoCard,
        border: Border(top: BorderSide(color: AppTheme.bordeCampo)),
      ),
      child: Row(
        children: [
          Container(width: 3, height: 36, color: Colors.orange),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              t.tr('editando_mensaje'),
              style: const TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: AppTheme.textoSecundario, size: 20),
            onPressed: () {
              _cancelarAccion();
              _messageController.clear();
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 36, height: 36),
          ),
        ],
      ),
    );
  }

  // ── Barra de solo lectura (evento finalizado) ───────────────────────────────

  Widget _buildBarraLectura(IdiomaProvider t) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppTheme.fondoInput,
        border: Border(top: BorderSide(color: AppTheme.bordeCampo, width: 1)),
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline,
                size: 16, color: AppTheme.textoTerciario),
            const SizedBox(width: 8),
            Text(
              t.tr('evento_finalizado_lectura'),
              style: const TextStyle(
                  color: AppTheme.textoTerciario, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  // ── Input bar ────────────────────────────────────────────────────────────────

  Widget _buildInputBar(IdiomaProvider t, ChatProvider chatProvider) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: AppTheme.fondoInput,
        border: Border(top: BorderSide(color: AppTheme.bordeCampo, width: 1)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.attach_file,
                  color: AppTheme.textoSecundario),
              tooltip: t.tr('adjuntar_imagen'),
              onPressed:
                  chatProvider.isSending ? null : _mostrarOpcionesImagen,
            ),
            IconButton(
              icon: const Icon(Icons.location_on,
                  color: AppTheme.textoSecundario),
              tooltip: t.tr('compartir_ubicacion'),
              onPressed: chatProvider.isSending
                  ? null
                  : _seleccionarYEnviarUbicacion,
            ),
            Expanded(
              child: TextField(
                controller: _messageController,
                focusNode: _messageFocusNode,
                style: const TextStyle(color: AppTheme.textoBlanco),
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _enviarMensaje(),
                decoration: InputDecoration(
                  hintText: t.tr('escribe_mensaje'),
                  hintStyle:
                      const TextStyle(color: AppTheme.textoTerciario),
                  filled: true,
                  fillColor: AppTheme.fondoCard,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: const BoxDecoration(
                color: AppTheme.verdeNeon,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: chatProvider.isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.black),
                      )
                    : Icon(
                        _editandoMensaje != null ? Icons.check : Icons.send,
                        color: AppTheme.textoSobreVerde,
                      ),
                onPressed: chatProvider.isSending ? null : _enviarMensaje,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Message bubble ────────────────────────────────────────────────────────────

  Widget _buildMessageBubble(
    BuildContext context, {
    required IdiomaProvider t,
    required Mensaje mensaje,
    required bool esPropio,
  }) {
    final partes = mensaje.remitenteNombre.trim().split(' ');
    final iniciales = partes.length >= 2
        ? '${partes[0][0]}${partes[1][0]}'.toUpperCase()
        : mensaje.remitenteNombre.isNotEmpty
            ? mensaje.remitenteNombre[0].toUpperCase()
            : '?';

    final bubbleColor = esPropio ? AppTheme.verdeNeon : AppTheme.fondoCard;
    final textColor =
        esPropio ? AppTheme.textoSobreVerde : AppTheme.textoBlanco;
    final metaColor = esPropio
        ? AppTheme.textoSobreVerde.withValues(alpha: 0.55)
        : AppTheme.textoTerciario;

    final radius = BorderRadius.only(
      topLeft: Radius.circular(esPropio ? 14 : 4),
      topRight: Radius.circular(esPropio ? 4 : 14),
      bottomLeft: const Radius.circular(14),
      bottomRight: const Radius.circular(14),
    );

    return Row(
      mainAxisAlignment:
          esPropio ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!esPropio) ...[
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppTheme.verdeNeon.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                iniciales,
                style: const TextStyle(
                  color: AppTheme.verdeNeon,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
        ],
        Flexible(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.72,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: radius,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!esPropio) ...[
                    Text(
                      mensaje.remitenteNombre,
                      style: const TextStyle(
                        color: AppTheme.verdeNeon,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 2),
                  ],

                  // Cita de respuesta — compacta en una línea
                  if (mensaje.tieneReply()) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 5),
                      padding: const EdgeInsets.fromLTRB(7, 3, 6, 3),
                      decoration: BoxDecoration(
                        color: esPropio
                            ? Colors.black.withValues(alpha: 0.12)
                            : AppTheme.fondoInput,
                        borderRadius: BorderRadius.circular(5),
                        border: const Border(
                          left: BorderSide(color: AppTheme.verdeNeon, width: 2),
                        ),
                      ),
                      child: RichText(
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '${mensaje.replyToNombre}  ',
                              style: const TextStyle(
                                color: AppTheme.verdeNeon,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                            TextSpan(
                              text: mensaje.replyToTexto ?? '',
                              style: TextStyle(
                                color: esPropio
                                    ? AppTheme.textoSobreVerde
                                        .withValues(alpha: 0.65)
                                    : AppTheme.textoSecundario,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // Imagen adjunta (ampliable)
                  if (mensaje.tieneImagen()) ...[
                    GestureDetector(
                      onTap: () =>
                          _mostrarImagenCompleta(context, mensaje.imagenUrl!),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              mensaje.imagenUrl!,
                              width: 200,
                              fit: BoxFit.cover,
                              loadingBuilder: (_, child, progress) {
                                if (progress == null) return child;
                                return Container(
                                  width: 200,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    color: AppTheme.fondoInput,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                        color: AppTheme.verdeNeon,
                                        strokeWidth: 2),
                                  ),
                                );
                              },
                            ),
                          ),
                          Positioned(
                            bottom: 6,
                            right: 6,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(4)),
                              child: const Icon(Icons.zoom_in,
                                  color: Colors.white, size: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (mensaje.texto.isNotEmpty) const SizedBox(height: 6),
                  ],

                  // Ubicación
                  if (mensaje.tipo == 'ubicacion') ...[
                    GestureDetector(
                      onTap: () => _abrirMaps(mensaje.texto),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.location_on,
                              color: esPropio
                                  ? AppTheme.textoSobreVerde
                                  : AppTheme.rojoError,
                              size: 18),
                          const SizedBox(width: 5),
                          Text(
                            t.tr('abrir_maps'),
                            style: TextStyle(
                              color: esPropio
                                  ? AppTheme.textoSobreVerde
                                  : AppTheme.verdeNeon,
                              fontSize: 13,
                              decoration: TextDecoration.underline,
                              decorationColor: esPropio
                                  ? AppTheme.textoSobreVerde
                                  : AppTheme.verdeNeon,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else if (mensaje.texto.isNotEmpty) ...[
                    Text(
                      mensaje.texto,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: textColor),
                    ),
                  ],

                  // Pie: hora + editado
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        mensaje.horaFormateada,
                        style: TextStyle(color: metaColor, fontSize: 10),
                      ),
                      if (mensaje.editado) ...[
                        Text(
                          ' · ${t.tr('mensaje_editado')}',
                          style: TextStyle(
                            color: metaColor,
                            fontSize: 10,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
