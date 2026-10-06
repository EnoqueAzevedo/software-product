import 'package:flutter/material.dart';

/// Paleta de cores

class AppColors {
  AppColors._();

  // Fundos
  static const Color background = Color(0xFFF7EDEE); // Rosa claro de fundo
  static const Color cardBackground = Color(0xFFFFFFFF); // Branco
  static const Color beigeCard = Color(0xFFE8D3CF); // Nude rosado
  static const Color pillBackground = Color(0xFFE8D3CF); // Nude rosado

  // Hero (área escura)
  static const Color heroBackground = Color(0xFF7D4B58); // Vinho suave
  static const Color heroBackgroundLight = Color(
    0xFF935F6D,
  ); // Vinho um pouco mais claro (derivada)

  // Destaques
  static const Color accent = Color(0xFFD58F9D); // Rosa elegante
  static const Color accentDark = Color(0xFF7D4B58); // Vinho suave

  // Textos
  static const Color textPrimary = Color(0xFF7D4B58); // Vinho suave
  static const Color textSecondary = Color(
    0xFFA37F89,
  ); // Vinho esmaecido (derivada)
  static const Color textOnDark = Color(0xFFF7EDEE); // Rosa claro
  static const Color textOnDarkMuted = Color(0xFFE8D3CF); // Nude rosado

  // Bordas e divisores
  static const Color divider = Color(0xFFECE7E7); // Cinza claro
}

/// Raios de borda padronizados usados nos cards e botões.
class AppRadius {
  AppRadius._();

  static const double large = 28;
  static const double medium = 20;
  static const double small = 14;
  static const double pill = 100;
}

/// Espaçamentos padronizados.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    final base = ThemeData.light(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.accent,
        secondary: AppColors.accentDark,
        surface: AppColors.cardBackground,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
      ),
      textTheme: base.textTheme.copyWith(
        headlineMedium: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: AppColors.textOnDark,
          height: 1.25,
        ),
        titleLarge: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleMedium: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        bodyLarge: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
        bodyMedium: const TextStyle(
          fontSize: 13.5,
          color: AppColors.textSecondary,
        ),
        labelLarge: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.accentDark,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.pillBackground,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),
    );
  }
}

/// Extensão para facilitar o uso da fonte Cormorant Garamond em qualquer texto
extension CustomTextTheme on TextTheme {
  TextStyle get cormorantTitle => const TextStyle(
    fontFamily: 'CormorantGaramond',
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.textOnDark,
  );
}
