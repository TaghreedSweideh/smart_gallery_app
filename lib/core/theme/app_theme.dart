import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

class AppTheme {
  static ThemeData light = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.light.background,
    primaryColor: AppColors.light.primary,
    textTheme: const TextTheme(
      displayLarge: AppTextStyles.h1,
      displayMedium: AppTextStyles.h2,
      displaySmall: AppTextStyles.h3,
      headlineMedium: AppTextStyles.h4,
      bodyLarge: AppTextStyles.body,
      labelLarge: AppTextStyles.label,
      titleMedium: AppTextStyles.button,
      bodyMedium: AppTextStyles.input,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.light.background,
      foregroundColor: AppColors.light.foreground,
    ),
  );

  static ThemeData dark = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.dark.background,
    primaryColor: AppColors.dark.primary,
    textTheme: const TextTheme(
      displayLarge: AppTextStyles.h1,
      displayMedium: AppTextStyles.h2,
      displaySmall: AppTextStyles.h3,
      headlineMedium: AppTextStyles.h4,
      bodyLarge: AppTextStyles.body,
      labelLarge: AppTextStyles.label,
      titleMedium: AppTextStyles.button,
      bodyMedium: AppTextStyles.input,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.dark.background,
      foregroundColor: AppColors.dark.foreground,
    ),
  );
}
