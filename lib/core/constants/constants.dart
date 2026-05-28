import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors (Nature themed)
  static const Color primary = Color(0xFF2D6A4F);      // Dark Emerald Green
  static const Color primaryLight = Color(0xFF52B788); // Soft Sage Green
  static const Color primaryDark = Color(0xFF1B4332);  // Deep Forest Green
  static const Color secondary = Color(0xFF74C69D);    // Mint Green
  static const Color accent = Color(0xFFF5A623);       // Warm Sun Amber

  // Light Mode Colors
  static const Color bgLight = Color(0xFFF7FBF8);      // Very light fresh green-gray
  static const Color cardLight = Color(0xFFFFFFFF);    // Pure white cards
  static const Color textLight = Color(0xFF1E293B);    // Charcoal dark text
  static const Color textLightMuted = Color(0xFF64748B); // Slate gray

  // Dark Mode Colors
  static const Color bgDark = Color(0xFF0D1812);       // Dark deep forest/black
  static const Color cardDark = Color(0xFF16251D);     // Dark olive-grey cards
  static const Color textDark = Color(0xFFF8FAFC);     // Soft off-white
  static const Color textDarkMuted = Color(0xFF94A3B8);  // Soft gray

  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color danger = Color(0xFFE53935);
  static const Color info = Color(0xFF2196F3);

  // Shading / Border Colors
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color borderDark = Color(0xFF263D31);
}

class AppDimensions {
  // Padding & Margin
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;

  // Border Radius
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 20.0;
  static const double radiusXl = 30.0;

  // Icon Sizes
  static const double iconSm = 18.0;
  static const double iconMd = 24.0;
  static const double iconLg = 32.0;
}

class AppTextStyles {
  static const String fontName = 'Outfit'; // If user wants custom font, otherwise default Sans

  static TextStyle headingLarge(BuildContext context, {Color? color}) {
    return TextStyle(
      fontSize: 28.0,
      fontWeight: FontWeight.bold,
      letterSpacing: -0.5,
      color: color ?? Theme.of(context).textTheme.headlineLarge?.color,
    );
  }

  static TextStyle headingMedium(BuildContext context, {Color? color}) {
    return TextStyle(
      fontSize: 22.0,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.2,
      color: color ?? Theme.of(context).textTheme.headlineMedium?.color,
    );
  }

  static TextStyle headingSmall(BuildContext context, {Color? color}) {
    return TextStyle(
      fontSize: 18.0,
      fontWeight: FontWeight.w600,
      color: color ?? Theme.of(context).textTheme.headlineSmall?.color,
    );
  }

  static TextStyle bodyLarge(BuildContext context, {Color? color}) {
    return TextStyle(
      fontSize: 16.0,
      fontWeight: FontWeight.normal,
      color: color ?? Theme.of(context).textTheme.bodyLarge?.color,
    );
  }

  static TextStyle bodyMedium(BuildContext context, {Color? color}) {
    return TextStyle(
      fontSize: 14.0,
      fontWeight: FontWeight.normal,
      color: color ?? Theme.of(context).textTheme.bodyMedium?.color,
    );
  }

  static TextStyle caption(BuildContext context, {Color? color}) {
    return TextStyle(
      fontSize: 12.0,
      fontWeight: FontWeight.w500,
      color: color ?? Theme.of(context).textTheme.bodySmall?.color,
    );
  }
}
