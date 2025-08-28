import 'package:flutter/material.dart';

class AppColors {
  // Light Theme
  static const light = _AppThemeColors(
    background: Color(0xFFFFFFFF),
    foreground: Color(0xFF252525),
    primary: Colors.blueAccent,
    primaryForeground: Color(0xFFFFFFFF),
    secondary: Color(0xFFF2F2FF),
    secondaryForeground: Color(0xFF030213),
    muted: Color(0xFFECECF0),
    mutedForeground: Color(0xFF717182),
    accent: Color(0xFFE9EBEF),
    accentForeground: Color(0xFF030213),
    destructive: Color(0xFFD4183D),
    destructiveForeground: Color(0xFFFFFFFF),
    border: Color.fromRGBO(0, 0, 0, 0.1),
    inputBackground: Color(0xFFF3F3F5),
    switchBackground: Color(0xFFCBCCD4),
  );

  // Dark Theme
  static const dark = _AppThemeColors(
    background: Color(0xFF252525),
    foreground: Color(0xFFFFFFFF),
    primary: Color(0xFFFFFFFF),
    primaryForeground: Color(0xFF353535),
    secondary: Color(0xFF454545),
    secondaryForeground: Color(0xFFFFFFFF),
    muted: Color(0xFF454545),
    mutedForeground: Color(0xFFB4B4B4),
    accent: Color(0xFF454545),
    accentForeground: Color(0xFFFFFFFF),
    destructive: Color(0xFFB74134),
    destructiveForeground: Color(0xFFA35555),
    border: Color(0xFF454545),
    inputBackground: Color(0xFF454545),
    switchBackground: Color(0xFF999999),
  );
}

class _AppThemeColors {
  final Color background;
  final Color foreground;
  final Color primary;
  final Color primaryForeground;
  final Color secondary;
  final Color secondaryForeground;
  final Color muted;
  final Color mutedForeground;
  final Color accent;
  final Color accentForeground;
  final Color destructive;
  final Color destructiveForeground;
  final Color border;
  final Color inputBackground;
  final Color switchBackground;

  const _AppThemeColors({
    required this.background,
    required this.foreground,
    required this.primary,
    required this.primaryForeground,
    required this.secondary,
    required this.secondaryForeground,
    required this.muted,
    required this.mutedForeground,
    required this.accent,
    required this.accentForeground,
    required this.destructive,
    required this.destructiveForeground,
    required this.border,
    required this.inputBackground,
    required this.switchBackground,
  });
}
