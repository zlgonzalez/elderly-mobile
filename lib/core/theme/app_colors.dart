import 'package:flutter/material.dart';

/// Design color tokens extracted directly from Figma design `wMzyM9baD4XT5PLTu2sijV`
/// ("Kubo North (Family only)").
class AppColors {
  AppColors._();

  // Primary background & canvas
  static const Color background = Color(0xFFF2FAF5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFEAF4EE);
  static const Color surfaceContainerLow = Color(0xFFF6FBF7);
  static const Color surfaceContainerHigh = Color(0xFFE2EFE7);

  // Brand primary (Forest / Sage)
  static const Color primary = Color(0xFF2D6A4F);
  static const Color primaryContainer = Color(0xFF40916C);
  static const Color primaryLight = Color(0xFFD8F3DC);
  static const Color onPrimary = Color(0xFFFFFFFF);

  // Secondary & Accents
  static const Color secondary = Color(0xFF52796F);
  static const Color secondaryContainer = Color(0xFFC7E2D4);
  static const Color onSecondary = Color(0xFFFFFFFF);

  // Text colors (Dignity-centered, high legibility)
  static const Color textPrimary = Color(0xFF1B2A20);
  static const Color textSecondary = Color(0xFF52796F);
  static const Color textMuted = Color(0xFF739389);
  static const Color textDisabled = Color(0xFFA5B8B0);

  // Status & Clinical indicators
  static const Color statusGreen = Color(0xFF2D6A4F);
  static const Color statusYellow = Color(0xFFFFB900);
  static const Color statusTeal = Color(0xFF00D5BE);
  static const Color statusRed = Color(0xFFC10007);
  static const Color allergyRed = Color(0xFFD90429);
  static const Color allergyRedBg = Color(0xFFFFEBEB);

  // Borders & Dividers
  static const Color border = Color(0xFFD1E3D8);
  static const Color borderLight = Color(0xFFE2EDE6);

  // Category Badges
  static const Color badgePhysical = Color(0xFFE2F0D9);
  static const Color badgePhysicalText = Color(0xFF385723);
  static const Color badgeActivity = Color(0xFFFFF2CC);
  static const Color badgeActivityText = Color(0xFF7F6000);
  static const Color badgeSocial = Color(0xFFDEEBF7);
  static const Color badgeSocialText = Color(0xFF1F4E79);
}
