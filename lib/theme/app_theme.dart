import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData dark() {
    // 统一的暗色系主题，匹配太空科幻基调。
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFF5CE1E6),
      onPrimary: Color(0xFF041015),
      secondary: Color(0xFFF5C542),
      onSecondary: Color(0xFF1A1200),
      error: Color(0xFFFF5A5A),
      onError: Color(0xFF2A0A0A),
      surface: Color(0xFF0D1117),
      onSurface: Color(0xFFE6EDF3),
    );

    final baseTextTheme = GoogleFonts.notoSansScTextTheme();

    return ThemeData(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: Colors.transparent,
      textTheme: baseTextTheme.apply(
        bodyColor: colorScheme.onSurface,
        displayColor: colorScheme.onSurface,
      ),
      useMaterial3: true,
      cardTheme: const CardThemeData(
        color: Color(0xFF0E1624),
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: Color(0x1A5CE1E6)),
        ),
      ),
      sliderTheme: const SliderThemeData(
        trackHeight: 4,
        thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8),
      ),
    );
  }
}
