import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';

/// Servicio de traducción usando Google Cloud Translation API v2 (REST)
/// Requiere que "Cloud Translation API" esté habilitada en Google Cloud Console
class TranslationService {
  static const String _baseUrl =
      'https://translation.googleapis.com/language/translate/v2';

  final Map<String, String> _cache = {};

  /// Traduce varios textos en una sola llamada batch.
  /// Devuelve null si la API falla (clave no válida, API no habilitada, etc.)
  Future<List<String>?> traducirLote(
      List<String> textos, String targetLang) async {
    if (textos.isEmpty) return [];

    final resultados = List<String>.filled(textos.length, '');
    final indices = <int>[];
    final textosATraducir = <String>[];

    for (int i = 0; i < textos.length; i++) {
      final texto = textos[i];
      if (texto.trim().isEmpty) {
        resultados[i] = texto;
        continue;
      }
      final cacheKey = '$texto:$targetLang';
      if (_cache.containsKey(cacheKey)) {
        resultados[i] = _cache[cacheKey]!;
      } else {
        indices.add(i);
        textosATraducir.add(texto);
      }
    }

    if (textosATraducir.isEmpty) return resultados;

    final uri =
        Uri.parse('$_baseUrl?key=${AppConstants.googleTranslationApiKey}');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json; charset=utf-8'},
      body: jsonEncode({'q': textosATraducir, 'target': targetLang}),
    );

    if (response.statusCode != 200) {
      // Propagar el error para que la UI pueda mostrarlo
      final err = jsonDecode(response.body);
      final msg = err['error']?['message'] ?? 'HTTP ${response.statusCode}';
      throw Exception(msg);
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final translations = data['data']['translations'] as List;

    for (int i = 0; i < indices.length; i++) {
      final traduccion = translations[i]['translatedText'] as String;
      final cacheKey = '${textosATraducir[i]}:$targetLang';
      _cache[cacheKey] = traduccion;
      resultados[indices[i]] = traduccion;
    }

    return resultados;
  }
}
