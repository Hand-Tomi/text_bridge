import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

final class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      surface: AppColors.surface,
      onSurface: AppColors.onSurface,
      error: AppColors.error,
      onError: AppColors.onError,
    ),
    scaffoldBackgroundColor: AppColors.background,
    textTheme: const TextTheme(
      headlineLarge: AppTypography.headingL,
      headlineMedium: AppTypography.headingM,
      headlineSmall: AppTypography.headingS,
      bodyLarge: AppTypography.bodyL,
      bodyMedium: AppTypography.bodyM,
      bodySmall: AppTypography.bodyS,
      labelLarge: AppTypography.labelL,
      labelMedium: AppTypography.labelM,
    ),
  );
}
