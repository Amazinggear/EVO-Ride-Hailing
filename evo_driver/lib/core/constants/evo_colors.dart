import 'package:flutter/material.dart';

/// EVO Driver App Colors (shared with passenger via same palette)
class EvoColors {
  EvoColors._();

  // PRIMARY — Electric Emerald
  static const Color primary = Color(0xFF00C853);
  static const Color primaryLight = Color(0xFF4CAF50);
  static const Color primaryDark = Color(0xFF00962E);
  static const Color primarySubtle = Color(0xFFE8F5E9);

  // Backgrounds
  static const Color lightBg = Color(0xFFF5F5F5);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightGreenBg = Color(0xFFE8F5E9);

  // Driver App — Dark Mode
  static const Color darkBg = Color(0xFF121212);
  static const Color darkCard = Color(0xFF1E1E2E);
  static const Color darkSurface = Color(0xFF1A1A2E);

  // Text
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFF9E9E9E);
  static const Color textOnDark = Color(0xFFFFFFFF);
  static const Color textOnDarkSecondary = Color(0xFFB0B0B0);

  // Semantic
  static const Color success = Color(0xFF00C853);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFFA726);
  static const Color info = Color(0xFF2196F3);

  // Ride Status
  static const Color statusSearching = Color(0xFFFFA726);
  static const Color statusAccepted = Color(0xFF2196F3);
  static const Color statusArriving = Color(0xFF00C853);
  static const Color statusInProgress = Color(0xFF00C853);
  static const Color statusCompleted = Color(0xFF4CAF50);
  static const Color statusCancelled = Color(0xFFE53935);

  // Financial
  static const Color earningGreen = Color(0xFF00C853);
  static const Color payoutRed = Color(0xFFE53935);

  // Eco
  static const Color ecoBadgeBg = Color(0xFFE8F5E9);
  static const Color ecoBadgeText = Color(0xFF2E7D32);
  static const Color ecoIcon = Color(0xFF43A047);

  // Borders
  static const Color border = Color(0xFFE0E0E0);
  static const Color borderDark = Color(0xFF2C2C3E);
  static const Color divider = Color(0xFFF0F0F0);

  // Shadows
  static const List<BoxShadow> cardShadow = [
    BoxShadow(color: Color(0x1A000000), blurRadius: 12, offset: Offset(0, 4)),
  ];

  static const List<BoxShadow> buttonShadow = [
    BoxShadow(color: Color(0x4000C853), blurRadius: 20, offset: Offset(0, 8)),
  ];
}
