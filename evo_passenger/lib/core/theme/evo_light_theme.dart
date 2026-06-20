import 'package:flutter/material.dart';
import 'package:evo_passenger/core/constants/evo_colors.dart';

/// EVO Light Theme — Passenger App
/// Inspired by the reference design: white background, green accents
class EvoLightTheme {
  EvoLightTheme._();

  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        fontFamily: 'Cairo',
        colorScheme: const ColorScheme.light(
          primary: EvoColors.primary,
          onPrimary: Colors.white,
          secondary: EvoColors.primaryLight,
          onSecondary: Colors.white,
          surface: EvoColors.lightSurface,
          onSurface: EvoColors.textPrimary,
          error: EvoColors.error,
        ),

        // App Bar
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: EvoColors.textPrimary,
          elevation: 0,
          scrolledUnderElevation: 1,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: EvoColors.textPrimary,
          ),
          iconTheme: IconThemeData(color: EvoColors.textPrimary),
        ),

        // Elevated Button — Primary CTA
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: EvoColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shadowColor: Colors.transparent,
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

        // Outlined Button
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: EvoColors.primary,
            side: const BorderSide(color: EvoColors.primary, width: 1.5),
            minimumSize: const Size.fromHeight(54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // Text Button
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: EvoColors.primary,
            textStyle: const TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // Input Fields
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: EvoColors.lightBg,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: EvoColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: EvoColors.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: EvoColors.error),
          ),
          hintStyle: const TextStyle(color: EvoColors.textHint, fontFamily: 'Cairo'),
          labelStyle: const TextStyle(color: EvoColors.textSecondary, fontFamily: 'Cairo'),
        ),

        // Cards
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shadowColor: const Color(0x1A000000),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: EvoColors.border, width: 0.5),
          ),
          clipBehavior: Clip.antiAlias,
        ),

        // Bottom Navigation
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: EvoColors.primary,
          unselectedItemColor: EvoColors.textHint,
          selectedLabelStyle: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600, fontSize: 11),
          unselectedLabelStyle: TextStyle(fontFamily: 'Cairo', fontSize: 11),
          type: BottomNavigationBarType.fixed,
          elevation: 16,
        ),

        // Divider
        dividerTheme: const DividerThemeData(
          color: EvoColors.divider,
          thickness: 1,
          space: 1,
        ),

        // Snack Bar
        snackBarTheme: SnackBarThemeData(
          backgroundColor: EvoColors.darkBg,
          contentTextStyle: const TextStyle(fontFamily: 'Cairo', color: Colors.white),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          behavior: SnackBarBehavior.floating,
        ),

        // Text Theme (Cairo font)
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontFamily: 'Cairo', fontSize: 32, fontWeight: FontWeight.w700, color: EvoColors.textPrimary),
          displayMedium: TextStyle(fontFamily: 'Cairo', fontSize: 28, fontWeight: FontWeight.w700, color: EvoColors.textPrimary),
          headlineLarge: TextStyle(fontFamily: 'Cairo', fontSize: 24, fontWeight: FontWeight.w700, color: EvoColors.textPrimary),
          headlineMedium: TextStyle(fontFamily: 'Cairo', fontSize: 20, fontWeight: FontWeight.w600, color: EvoColors.textPrimary),
          headlineSmall: TextStyle(fontFamily: 'Cairo', fontSize: 18, fontWeight: FontWeight.w600, color: EvoColors.textPrimary),
          titleLarge: TextStyle(fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.w700, color: EvoColors.textPrimary),
          titleMedium: TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.w600, color: EvoColors.textPrimary),
          bodyLarge: TextStyle(fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.w400, color: EvoColors.textPrimary),
          bodyMedium: TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.w400, color: EvoColors.textSecondary),
          bodySmall: TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.w400, color: EvoColors.textHint),
          labelLarge: TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.w600),
        ),

        scaffoldBackgroundColor: EvoColors.lightBg,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      );
}

