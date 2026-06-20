import 'package:flutter/material.dart';
import 'package:evo_driver/core/constants/evo_colors.dart';

/// EVO Dark Theme — Driver/Captain App
/// Dark mode: deep navy/black bg + electric green accents
class EvoDarkTheme {
  EvoDarkTheme._();

  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        fontFamily: 'Cairo',
        colorScheme: const ColorScheme.dark(
          primary: EvoColors.primary,
          onPrimary: Colors.black,
          secondary: EvoColors.primaryLight,
          onSecondary: Colors.black,
          surface: EvoColors.darkCard,
          onSurface: EvoColors.textOnDark,
          error: EvoColors.error,
        ),

        scaffoldBackgroundColor: EvoColors.darkBg,

        // App Bar — dark
        appBarTheme: const AppBarTheme(
          backgroundColor: EvoColors.darkBg,
          foregroundColor: EvoColors.textOnDark,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: EvoColors.textOnDark,
          ),
          iconTheme: IconThemeData(color: EvoColors.textOnDark),
        ),

        // Elevated Button — green CTA
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: EvoColors.primary,
            foregroundColor: Colors.black,
            elevation: 0,
            minimumSize: const Size.fromHeight(54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),

        // Outlined button
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: EvoColors.primary,
            side: const BorderSide(color: EvoColors.primary, width: 1.5),
            minimumSize: const Size.fromHeight(54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),

        // Text button
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: EvoColors.primary,
            textStyle: const TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // Input fields
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: EvoColors.darkCard,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: EvoColors.borderDark),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: EvoColors.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: EvoColors.error),
          ),
          hintStyle: const TextStyle(color: EvoColors.textOnDarkSecondary, fontFamily: 'Cairo'),
          labelStyle: const TextStyle(color: EvoColors.textOnDarkSecondary, fontFamily: 'Cairo'),
        ),

        // Cards — dark surface
        cardTheme: CardThemeData(
          color: EvoColors.darkCard,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: EvoColors.borderDark, width: 0.5),
          ),
          clipBehavior: Clip.antiAlias,
        ),

        // Bottom Nav
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: EvoColors.darkCard,
          selectedItemColor: EvoColors.primary,
          unselectedItemColor: EvoColors.textOnDarkSecondary,
          selectedLabelStyle: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600, fontSize: 11),
          unselectedLabelStyle: TextStyle(fontFamily: 'Cairo', fontSize: 11),
          type: BottomNavigationBarType.fixed,
          elevation: 16,
        ),

        // Divider
        dividerTheme: const DividerThemeData(
          color: EvoColors.borderDark,
          thickness: 1,
          space: 1,
        ),

        // Snack Bar
        snackBarTheme: SnackBarThemeData(
          backgroundColor: EvoColors.darkCard,
          contentTextStyle: const TextStyle(fontFamily: 'Cairo', color: EvoColors.textOnDark),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          behavior: SnackBarBehavior.floating,
        ),

        // Text Theme
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontFamily: 'Cairo', fontSize: 32, fontWeight: FontWeight.w700, color: EvoColors.textOnDark),
          displayMedium: TextStyle(fontFamily: 'Cairo', fontSize: 28, fontWeight: FontWeight.w700, color: EvoColors.textOnDark),
          headlineLarge: TextStyle(fontFamily: 'Cairo', fontSize: 24, fontWeight: FontWeight.w700, color: EvoColors.textOnDark),
          headlineMedium: TextStyle(fontFamily: 'Cairo', fontSize: 20, fontWeight: FontWeight.w600, color: EvoColors.textOnDark),
          headlineSmall: TextStyle(fontFamily: 'Cairo', fontSize: 18, fontWeight: FontWeight.w600, color: EvoColors.textOnDark),
          titleLarge: TextStyle(fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.w700, color: EvoColors.textOnDark),
          titleMedium: TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.w600, color: EvoColors.textOnDark),
          bodyLarge: TextStyle(fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.w400, color: EvoColors.textOnDark),
          bodyMedium: TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.w400, color: EvoColors.textOnDarkSecondary),
          bodySmall: TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.w400, color: EvoColors.textOnDarkSecondary),
          labelLarge: TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.w600, color: EvoColors.textOnDark),
        ),

        visualDensity: VisualDensity.adaptivePlatformDensity,
      );
}

