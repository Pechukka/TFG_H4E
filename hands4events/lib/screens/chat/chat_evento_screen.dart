import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hands4events/core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../models/mensaje.dart';
import '../../widgets/app_bar_custom.dart';
import 'equipo_evento_screen.dart';

/// Pantalla de chat del evento
/// Permite comunicación en tiempo real entre trabajadores del evento
class ChatEventoScreen extends StatefulWidget {
  final String tituloEvento;
  final String eventoId;

  const ChatEventoScreen({
    super.key,
    required this.tituloEvento,
    this.eventoId = '',
  });

  @override
  State<ChatEventoScreen> createState() => _ChatEventoScreenState();
}

class _ChatEventoScreenState extends State<ChatEventoScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    if (widget.eventoId.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<ChatProvider>().cargarMensajes(widget.eventoId);
        // Marcar mensajes como leídos al abrir el chat
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
    context.read<ChatProvider>().limpiarMensajes();
    super.dispose();
  }

  Future<void> _enviarMensaje() async {
    final texto = _messageController.text.trim();
    if (texto.isEmpty || widget.eventoId.isEmpty) return;

    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.currentUserId ?? '';
    final nombre = authProvider.currentUser?.nombre ?? 'Trabajador';

    _messageController.clear();

    await context.read<ChatProvider>().enviarMensaje(
      eventoId: widget.eventoId,
      remitenteId: userId,
      remitenteNombre: nombre,
      texto: texto,
    );

    // Scroll al final tras enviar
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

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();
    final mensajes = chatProvider.mensajes;
    final userId = context.read<AuthProvider>().currentUserId ?? '';

    // Scroll al fondo cuando llegan nuevos mensajes
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
        subtitle: 'Chat del evento',
      ),
      body: Column(
        children: [
          // Banner info del equipo
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EquipoEventoScreen(
                    tituloEvento: widget.tituloEvento,
                    eventoId: widget.eventoId,
                  ),
                ),
              );
            },
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
                        Text(
                          'Información del equipo',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Ver miembros del equipo',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.textoSecundario,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppTheme.textoSecundario),
                ],
              ),
            ),
          ),

          // Lista de mensajes
          Expanded(
            child: widget.eventoId.isEmpty
                ? Center(
                    child: Text(
                      'Chat no disponible',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textoSecundario,
                          ),
                    ),
                  )
                : mensajes.isEmpty
                    ? Center(
                        child: Text(
                          'Sé el primero en escribir',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.textoSecundario,
                                  ),
                        ),
                      )
                    : ListView.separated(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        itemCount: mensajes.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final mensaje = mensajes[index];
                          final esPropio = mensaje.remitenteId == userId;
                          return _buildMessageBubble(
                            context,
                            mensaje: mensaje,
                            esPropio: esPropio,
                          );
                        },
                      ),
          ),

          // Input de mensaje
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppTheme.fondoInput,
              border: Border(
                top: BorderSide(color: AppTheme.bordeCampo, width: 1),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  const SizedBox(width: 8),

                  // Campo de texto
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(color: AppTheme.textoBlanco),
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _enviarMensaje(),
                      decoration: InputDecoration(
                        hintText: 'Escribe un mensaje...',
                        hintStyle:
                            const TextStyle(color: AppTheme.textoTerciario),
                        filled: true,
                        fillColor: AppTheme.fondoCard,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Botón enviar
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
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : const Icon(Icons.send,
                              color: AppTheme.textoSobreVerde),
                      onPressed: chatProvider.isSending ? null : _enviarMensaje,
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

  Widget _buildMessageBubble(
    BuildContext context, {
    required Mensaje mensaje,
    required bool esPropio,
  }) {
    // Iniciales del remitente
    final partes = mensaje.remitenteNombre.trim().split(' ');
    final iniciales = partes.length >= 2
        ? '${partes[0][0]}${partes[1][0]}'.toUpperCase()
        : mensaje.remitenteNombre.isNotEmpty
            ? mensaje.remitenteNombre[0].toUpperCase()
            : '?';

    return Row(
      mainAxisAlignment:
          esPropio ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar (solo para mensajes de otros)
        if (!esPropio) ...[
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.verdeNeon.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                iniciales,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppTheme.verdeNeon,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],

        // Burbuja de mensaje
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: esPropio ? AppTheme.verdeNeon : AppTheme.fondoCard,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nombre del usuario (solo si no es propio)
                if (!esPropio) ...[
                  Text(
                    mensaje.remitenteNombre,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTheme.verdeNeon,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                ],

                // Imagen si la hay
                if (mensaje.tieneImagen()) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      mensaje.imagenUrl!,
                      width: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                  if (mensaje.texto.isNotEmpty) const SizedBox(height: 8),
                ],

                // Texto del mensaje
                if (mensaje.texto.isNotEmpty)
                  Text(
                    mensaje.texto,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: esPropio
                              ? AppTheme.textoSobreVerde
                              : AppTheme.textoBlanco,
                        ),
                  ),

                const SizedBox(height: 4),

                // Hora
                Text(
                  mensaje.horaFormateada,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: esPropio
                            ? AppTheme.textoSobreVerde.withOpacity(0.6)
                            : AppTheme.textoTerciario,
                      ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
