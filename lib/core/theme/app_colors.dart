import 'package:flutter/material.dart';

/// Premium TripCosmos.co Brand Palette
class AppColors {
  // Primary Palette: Royal Celestial Midnight & Deep Sapphire
  static const Color primary = Color(0xFF0F172A); // Slate 900
  static const Color primaryDark = Color(0xFF070D1E); // Midnight
  static const Color primaryLight = Color(0xFF1E293B); // Slate 800
  static const Color surface = Color(0xFF0B132B); // Deep Space Navy
  static const Color surfaceCard = Color(0xFF16223F); // Elevated Navy Glass
  static const Color surfaceElevated = Color(0xFF1E2D52);

  // Sacred Saffron & Varanasi Gold Accents (High Intent & Highlights)
  static const Color accentGold = Color(0xFFF59E0B); // Saffron Gold
  static const Color accentGoldGlow = Color(0xFFFFB703);
  static const Color accentOrange = Color(0xFFEA580C); // Deep Sunset
  static const Color accentBlue = Color(0xFF2563EB); // Royal Sapphire Blue

  // Status & Telephony Badges
  static const Color successGreen = Color(0xFF10B981); // Emerald Active
  static const Color successBg = Color(0xFF064E3B);
  static const Color warningYellow = Color(0xFFFBBF24);
  static const Color errorRed = Color(0xFFEF4444);
  static const Color missedCall = Color(0xFFF87171);
  static const Color incomingCall = Color(0xFF34D399);
  static const Color outboundCall = Color(0xFF60A5FA);

  // Text & Content
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);
  static const Color borderSubtle = Color(0xFF334155);
  static const Color borderHighlight = Color(0xFF475569);

  // Telephony SIM Colors
  static const Color jioBlue = Color(0xFF0A66C2);
  static const Color whatsappGreen = Color(0xFF25D366);

  // Light Mode Palette
  static const Color lightSurface = Color(0xFFF8FAFC); // Slate 50
  static const Color lightSurfaceCard = Color(0xFFFFFFFF); // Pure Crisp White
  static const Color lightSurfaceElevated = Color(0xFFF1F5F9); // Slate 100
  static const Color lightTextPrimary = Color(0xFF0F172A); // Slate 900
  static const Color lightTextSecondary = Color(0xFF475569); // Slate 600
  static const Color lightTextMuted = Color(0xFF94A3B8); // Slate 400
  static const Color lightBorderSubtle = Color(0xFFE2E8F0); // Slate 200
  static const Color lightBorderHighlight = Color(0xFFCBD5E1); // Slate 300

  // Dynamic Theme-Aware Color Resolvers
  static Color getSurface(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light ? lightSurface : surface;

  static Color getCard(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light ? lightSurfaceCard : surfaceCard;

  static Color getElevated(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light ? lightSurfaceElevated : surfaceElevated;

  static Color getTextPrimary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light ? lightTextPrimary : textPrimary;

  static Color getTextSecondary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light ? lightTextSecondary : textSecondary;

  static Color getTextMuted(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light ? lightTextMuted : textMuted;

  static Color getBorder(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light ? lightBorderSubtle : borderSubtle;

  // Gradients
  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF0B132B), Color(0xFF1C2541)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGlowGradient = LinearGradient(
    colors: [Color(0xFF1C2A4D), Color(0xFF141F38)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
