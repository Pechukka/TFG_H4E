import 'package:flutter/material.dart';
import 'package:hands4events/core/theme.dart';
import 'modal_base.dart';

/// Modal para seleccionar idioma
class ModalSeleccionarIdioma extends StatefulWidget {
  const ModalSeleccionarIdioma({super.key});

  @override
  State<ModalSeleccionarIdioma> createState() => _ModalSeleccionarIdiomaState();
}

class _ModalSeleccionarIdiomaState extends State<ModalSeleccionarIdioma> {
  String _idiomaSeleccionado = 'Español';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<Map<String, String>> _idiomas = [
    {'nombre': 'Español', 'codigo': 'ES', 'bandera': '🇪🇸'},
    {'nombre': 'English', 'codigo': 'EN', 'bandera': '🇬🇧'},
    {'nombre': 'Français', 'codigo': 'FR', 'bandera': '🇫🇷'},
    {'nombre': 'Deutsch', 'codigo': 'DE', 'bandera': '🇩🇪'},
    {'nombre': 'Italiano', 'codigo': 'IT', 'bandera': '🇮🇹'},
    {'nombre': 'Português', 'codigo': 'PT', 'bandera': '🇵🇹'},
  ];

  List<Map<String, String>> get _idiomasFiltrados {
    if (_searchQuery.isEmpty) return _idiomas;
    return _idiomas
        .where((idioma) =>
            idioma['nombre']!.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ModalBase(
      titulo: 'Seleccionar idioma',
      contenido: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Buscador
          TextField(
            controller: _searchController,
            style: const TextStyle(color: AppTheme.textoBlanco),
            decoration: InputDecoration(
              hintText: 'Buscar idioma...',
              hintStyle: const TextStyle(color: AppTheme.textoTerciario),
              prefixIcon: const Icon(Icons.search, color: AppTheme.textoSecundario),
              filled: true,
              fillColor: AppTheme.fondoInput,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),

          const SizedBox(height: 16),

          // Lista de idiomas
          ..._idiomasFiltrados.map((idioma) {
            final estaSeleccionado = _idiomaSeleccionado == idioma['nombre'];

            return InkWell(
              onTap: () {
                setState(() {
                  _idiomaSeleccionado = idioma['nombre']!;
                });
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: estaSeleccionado
                      ? AppTheme.verdeNeon.withOpacity(0.1)
                      : AppTheme.fondoInput,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: estaSeleccionado
                        ? AppTheme.verdeNeon
                        : AppTheme.bordeCampo,
                    width: estaSeleccionado ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      idioma['bandera']!,
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        idioma['nombre']!,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: estaSeleccionado
                              ? AppTheme.verdeNeon
                              : AppTheme.textoBlanco,
                        ),
                      ),
                    ),
                    if (estaSeleccionado)
                      const Icon(
                        Icons.check_circle,
                        color: AppTheme.verdeNeon,
                        size: 24,
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
      botonesAccion: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Idioma cambiado a $_idiomaSeleccionado'),
                  backgroundColor: AppTheme.verdeExito,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.verdeNeon,
              foregroundColor: AppTheme.textoSobreVerde,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Confirmar cambio',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}