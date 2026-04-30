import 'package:flutter/material.dart';
import 'package:hands4events/core/theme.dart';
import '../../widgets/app_bar_custom.dart';
import 'equipo_evento_screen.dart';

/// Pantalla de chat del evento
/// Permite comunicación en tiempo real entre trabajadores del evento
class ChatEventoScreen extends StatefulWidget {
  final String tituloEvento;

  const ChatEventoScreen({
    super.key,
    required this.tituloEvento,
  });

  @override
  State<ChatEventoScreen> createState() => _ChatEventoScreenState();
}

class _ChatEventoScreenState extends State<ChatEventoScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                  const Icon(
                    Icons.group,
                    color: AppTheme.verdeNeon,
                    size: 24,
                  ),
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
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.textoSecundario,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: AppTheme.textoSecundario,
                  ),
                ],
              ),
            ),
          ),

          // Lista de mensajes
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                // Mensaje de otro usuario
                _buildMessageBubble(
                  context,
                  nombre: 'Carlos Martínez',
                  mensaje:
                      'Recordad llevar chaleco reflectante y calzado cómodo',
                  hora: '14:30',
                  esPropio: false,
                  avatar: 'CM',
                ),

                const SizedBox(height: 12),

                // Mensaje propio
                _buildMessageBubble(
                  context,
                  mensaje: 'Genial. Así es el lugar exacto?',
                  hora: '14:47',
                  esPropio: true,
                ),

                const SizedBox(height: 12),

                // Mensaje de otro usuario
                _buildMessageBubble(
                  context,
                  nombre: 'Carlos Martínez',
                  mensaje: 'Sí, exactamente. Es la entrada del Recinto Ferial',
                  hora: '15:48',
                  esPropio: false,
                  avatar: 'CM',
                ),

                const SizedBox(height: 12),

                // Mensaje de otro usuario
                _buildMessageBubble(
                  context,
                  nombre: 'Ana López',
                  mensaje: 'Alguna pregunta sobre el evento?',
                  hora: '16:02',
                  esPropio: false,
                  avatar: 'AL',
                ),
              ],
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
                  // Botón cámara
                  IconButton(
                    icon: const Icon(Icons.camera_alt,
                        color: AppTheme.textoSecundario),
                    onPressed: () {
                      print('Abrir cámara');
                    },
                  ),

                  // Botón galería
                  IconButton(
                    icon: const Icon(Icons.image,
                        color: AppTheme.textoSecundario),
                    onPressed: () {
                      print('Abrir galería');
                    },
                  ),

                  const SizedBox(width: 8),

                  // Campo de texto
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(color: AppTheme.textoBlanco),
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
                      icon: const Icon(Icons.send,
                          color: AppTheme.textoSobreVerde),
                      onPressed: () {
                        if (_messageController.text.isNotEmpty) {
                          print('Enviar: ${_messageController.text}');
                          _messageController.clear();
                        }
                      },
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
    String? nombre,
    required String mensaje,
    required String hora,
    required bool esPropio,
    String? avatar,
  }) {
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
                avatar ?? '',
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
                if (!esPropio && nombre != null) ...[
                  Text(
                    nombre,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTheme.verdeNeon,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                ],

                // Mensaje
                Text(
                  mensaje,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: esPropio
                            ? AppTheme.textoSobreVerde
                            : AppTheme.textoBlanco,
                      ),
                ),

                const SizedBox(height: 4),

                // Hora
                Text(
                  hora,
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
