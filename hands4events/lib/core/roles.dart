// Los 4 roles disponibles para trabajadores en los eventos
class RolesEvento {
  static const List<String> todos = [
    'H4ndMontaje',
    'H4ndDesmontaje',
    'Coordinador',
    'Runner',
  ];

  // Cuánto cobra por hora cada rol
  static const Map<String, double> tarifas = {
    'H4ndMontaje': 8.0,
    'H4ndDesmontaje': 7.5,
    'Coordinador': 10.0,
    'Runner': 9.0,
  };

  static double tarifaDe(String rol) => tarifas[rol] ?? 0.0;
}
