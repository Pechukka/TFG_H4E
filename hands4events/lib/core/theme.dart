import 'package:flutter/material.dart';

class AppTheme {
  // ==================== COLORES BASE ====================
  
  // Fondos
  static const Color fondoPrincipal = Color(0xFF0A0F0A); // Verde oscuro muy profundo
  static const Color fondoCard = Color(0xFF1A2218); // Verde oscuro medio
  static const Color fondoInput = Color(0xFF12180F); // Verde muy oscuro
  static const Color fondoHover = Color(0xFF1F2A1D); // Hover en cards
  
  // Verde fosforescente/lima (principal)
  static const Color verdeNeon = Color(0xFF84CC16); // Verde lima principal
  static const Color verdeNeonHover = Color(0xFF9EE629); // Verde lima claro
  static const Color verdeNeonDark = Color(0xFF73B611); // Verde lima oscuro
  
  // Bordes
  static const Color bordeCampo = Color(0xFF2A3228); // Borde inputs
  static const Color bordeCard = Color(0xFF1A2218); // Borde contenedores
  
  // Textos
  static const Color textoBlanco = Color(0xFFFFFFFF);
  static const Color textoSecundario = Color(0xFF9CA3AF); // gray-400
  static const Color textoTerciario = Color(0xFF6B7280); // gray-500
  static const Color textoSutil = Color(0xFF4B5563); // gray-600
  static const Color textoSobreVerde = Color(0xFF0A0F0A); // Negro verdoso
  
  // Estados
  static const Color verdeExito = Color(0xFF84CC16);
  static const Color rojoError = Color(0xFFEF4444); // red-500
  static const Color amarilloAdvertencia = Color(0xFFEAB308); // yellow-500
  static const Color azulInfo = Color(0xFF3B82F6); // blue-500
  static const Color rojoSalir = Color(0xFFF87171); // red-400

  // ==================== THEME DATA ====================
  
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: verdeNeon,
      scaffoldBackgroundColor: fondoPrincipal,
      
      colorScheme: const ColorScheme.dark(
        primary: verdeNeon,
        secondary: verdeNeonDark,
        surface: fondoCard,
        error: rojoError,
        onPrimary: textoSobreVerde,
        onSecondary: textoBlanco,
        onSurface: textoBlanco,
        onError: textoBlanco,
      ),
      
      appBarTheme: const AppBarTheme(
        backgroundColor: fondoInput,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textoBlanco),
        titleTextStyle: TextStyle(
          color: textoBlanco,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      
      cardTheme: CardThemeData(
        color: fondoCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: fondoInput,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: verdeNeon, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: rojoError, width: 1),
        ),
        hintStyle: const TextStyle(color: textoTerciario),
        labelStyle: const TextStyle(color: textoSecundario),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: verdeNeon,
          foregroundColor: textoSobreVerde,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: verdeNeon,
          side: const BorderSide(color: verdeNeon, width: 2),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: fondoInput,
        selectedItemColor: verdeNeon,
        unselectedItemColor: textoTerciario,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 12),
      ),
      
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: textoBlanco),
        headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textoBlanco),
        headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: textoBlanco),
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textoBlanco),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textoBlanco),
        titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textoBlanco),
        bodyLarge: TextStyle(fontSize: 16, color: textoBlanco),
        bodyMedium: TextStyle(fontSize: 14, color: textoBlanco),
        bodySmall: TextStyle(fontSize: 12, color: textoSecundario),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textoSecundario),
        labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: textoTerciario),
        labelSmall: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: textoTerciario),
      ),
      
      iconTheme: const IconThemeData(color: textoBlanco, size: 24),
    );
  }

  // ==================== ESTILOS PERSONALIZADOS ====================
  
  static BoxDecoration cardDecoration = BoxDecoration(
    color: fondoCard,
    borderRadius: BorderRadius.circular(12),
  );
  
  static BoxDecoration borderDecoration = BoxDecoration(
    color: fondoCard,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: bordeCard, width: 1),
  );
}