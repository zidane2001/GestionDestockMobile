import 'package:flutter/material.dart';

class AppColors {
  final Color canvas;
  final Color surface;
  final Color surface2;
  final Color line;
  final Color ink;
  final Color muted;
  final Color primary;
  final Color primarySoft;
  final Color onPrimary;
  final Color accent;
  final Color danger;
  final Color success;

  const AppColors({
    required this.canvas,
    required this.surface,
    required this.surface2,
    required this.line,
    required this.ink,
    required this.muted,
    required this.primary,
    required this.primarySoft,
    required this.onPrimary,
    required this.accent,
    required this.danger,
    required this.success,
  });

  static const clair = AppColors(
    canvas: Color(0xFFF4F6F8),
    surface: Color(0xFFFFFFFF),
    surface2: Color(0xFFEEF1F5),
    line: Color(0xFFDFE5EC),
    ink: Color(0xFF0E1621),
    muted: Color(0xFF687888),
    primary: Color(0xFF0D6E64),
    primarySoft: Color(0xFFE0F2EF),
    onPrimary: Color(0xFFFFFFFF),
    accent: Color(0xFFC26C0C),
    danger: Color(0xFFC82828),
    success: Color(0xFF168F52),
  );

  static const sombre = AppColors(
    canvas: Color(0xFF090E16),
    surface: Color(0xFF131B27),
    surface2: Color(0xFF1B2533),
    line: Color(0xFF283547),
    ink: Color(0xFFE9EFF6),
    muted: Color(0xFF8D9CAF),
    primary: Color(0xFF1CB09E),
    primarySoft: Color(0xFF142F2E),
    onPrimary: Color(0xFF051412),
    accent: Color(0xFFE8A030),
    danger: Color(0xFFF06060),
    success: Color(0xFF34BE78),
  );
}

extension BuildContextColors on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppTheme>()!.colors;
}

class AppTheme extends ThemeExtension<AppTheme> {
  final AppColors colors;

  const AppTheme(this.colors);

  @override
  AppTheme copyWith({AppColors? colors}) => AppTheme(colors ?? this.colors);

  @override
  AppTheme lerp(ThemeExtension<AppTheme>? other, double t) {
    if (other is! AppTheme) return this;
    return AppTheme(colors);
  }

  static AppTheme of(BuildContext context) =>
      Theme.of(context).extension<AppTheme>()!;
}

ThemeData buildTheme(AppColors c, Brightness brightness) {
  final base = ThemeData(
    brightness: brightness,
    useMaterial3: true,
  );
  return base.copyWith(
    scaffoldBackgroundColor: c.canvas,
    colorScheme: ColorScheme(
      brightness: brightness,
      primary: c.primary,
      onPrimary: c.onPrimary,
      secondary: c.accent,
      onSecondary: c.surface,
      error: c.danger,
      onError: Colors.white,
      surface: c.surface,
      onSurface: c.ink,
    ),
    extensions: [AppTheme(c)],
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    textTheme: base.textTheme.apply(bodyColor: c.ink, displayColor: c.ink),
  );
}