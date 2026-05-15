import 'package:flutter/foundation.dart';
import '../core/traducciones.dart';

class IdiomaProvider with ChangeNotifier {
  String _idioma = 'es';

  String get idioma => _idioma;

  void cambiarIdioma(String codigo) {
    if (_idioma == codigo) return;
    _idioma = codigo;
    notifyListeners();
  }

  String tr(String clave) => Traducciones.tr(_idioma, clave);
}
