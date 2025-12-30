import 'package:flutter/material.dart';

// ========== 프로모드 다크 테마 ==========
class ProThemeDark {
  static const Color bg = Color(0xFF0A0A0A);
  static const Color bgCard = Color(0xFF111111);
  static const Color bgInput = Color(0xFF1A1A1A);
  static const Color border = Color(0xFF2A2A2A);
  static const Color text = Color(0xFFE0E0E0);
  static const Color textDim = Color(0xFF666666);
  static const Color neonGreen = Color(0xFF00FF88);
  static const Color neonCyan = Color(0xFF00F0FF);
  static const Color neonPurple = Color(0xFFBF5FFF);
  static const Color neonPink = Color(0xFFFF0080);

  static List<BoxShadow> get glow => [
    BoxShadow(color: neonGreen.withOpacity(0.4), blurRadius: 15, spreadRadius: 0),
    BoxShadow(color: neonGreen.withOpacity(0.2), blurRadius: 30, spreadRadius: 0),
  ];

  static List<BoxShadow> get glowCyan => [
    BoxShadow(color: neonCyan.withOpacity(0.4), blurRadius: 15, spreadRadius: 0),
    BoxShadow(color: neonCyan.withOpacity(0.2), blurRadius: 30, spreadRadius: 0),
  ];

  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF006E), Color(0xFF8338EC)],
  );
}

// ========== 프로모드 라이트 테마 ==========
class ProThemeLight {
  static const Color bg = Color(0xFFF5F5F7);
  static const Color bgCard = Color(0xFFFFFFFF);
  static const Color bgInput = Color(0xFFF0F0F2);
  static const Color border = Color(0xFFE0E0E5);
  static const Color text = Color(0xFF1A1A1A);
  static const Color textDim = Color(0xFF666666);
  static const Color neonGreen = Color(0xFF00CC6A);
  static const Color neonCyan = Color(0xFF00B8D4);
  static const Color neonPurple = Color(0xFF9C4DFF);
  static const Color neonPink = Color(0xFFE6006A);

  static List<BoxShadow> get glow => [
    BoxShadow(color: neonGreen.withOpacity(0.33), blurRadius: 12, spreadRadius: 0),
    BoxShadow(color: neonGreen.withOpacity(0.2), blurRadius: 25, spreadRadius: 0),
    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2)),
  ];

  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
  );
}

// ========== 기본모드 다크 테마 ==========
class BasicThemeDark {
  static const Color bg = Color(0xFF1A1A1A);
  static const Color bgCard = Color(0xFF2D2D2D);
  static const Color bgInput = Color(0xFF252525);
  static const Color border = Color(0xFF404040);
  static const Color text = Color(0xFFE0E0E0);
  static const Color textDim = Color(0xFF888888);
  static const Color accent = Color(0xFF60A5FA);
  static const Color accentLight = Color(0xFF1E3A5F);
  static const Color success = Color(0xFF4ADE80);
  static const Color warning = Color(0xFFFBBF24);
  static const Color danger = Color(0xFFF87171);

  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF374151), Color(0xFF1F2937)],
  );
}

// ========== 기본모드 라이트 테마 ==========
class BasicThemeLight {
  static const Color bg = Color(0xFFF5F5F4);
  static const Color bgCard = Color(0xFFFAFAF9);
  static const Color bgInput = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFD6D3D1);
  static const Color text = Color(0xFF292524);
  static const Color textDim = Color(0xFF78716C);
  static const Color accent = Color(0xFF6366F1);
  static const Color accentLight = Color(0xFFE0E7FF);
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFEAB308);
  static const Color danger = Color(0xFFEF4444);

  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
  );
}

// ========== 테마 데이터 클래스 ==========
class GachaTheme {
  final Color bg;
  final Color bgCard;
  final Color bgInput;
  final Color border;
  final Color text;
  final Color textDim;
  final Color accent;
  final Color accentLight;
  final Color success;
  final Color warning;
  final Color danger;
  final Color neonGreen;
  final Color neonCyan;
  final Color neonPurple;
  final Color neonPink;
  final LinearGradient headerGradient;
  final List<BoxShadow> glow;
  final bool isDark;
  final bool isProMode;

  const GachaTheme({
    required this.bg,
    required this.bgCard,
    required this.bgInput,
    required this.border,
    required this.text,
    required this.textDim,
    required this.accent,
    required this.accentLight,
    required this.success,
    required this.warning,
    required this.danger,
    required this.neonGreen,
    required this.neonCyan,
    required this.neonPurple,
    required this.neonPink,
    required this.headerGradient,
    required this.glow,
    required this.isDark,
    required this.isProMode,
  });

  static GachaTheme proModeDark() => GachaTheme(
    bg: ProThemeDark.bg,
    bgCard: ProThemeDark.bgCard,
    bgInput: ProThemeDark.bgInput,
    border: ProThemeDark.border,
    text: ProThemeDark.text,
    textDim: ProThemeDark.textDim,
    accent: ProThemeDark.neonCyan,
    accentLight: ProThemeDark.neonGreen.withOpacity(0.2),
    success: ProThemeDark.neonGreen,
    warning: const Color(0xFFFBBF24),
    danger: ProThemeDark.neonPink,
    neonGreen: ProThemeDark.neonGreen,
    neonCyan: ProThemeDark.neonCyan,
    neonPurple: ProThemeDark.neonPurple,
    neonPink: ProThemeDark.neonPink,
    headerGradient: ProThemeDark.headerGradient,
    glow: ProThemeDark.glow,
    isDark: true,
    isProMode: true,
  );

  static GachaTheme proModeLight() => GachaTheme(
    bg: ProThemeLight.bg,
    bgCard: ProThemeLight.bgCard,
    bgInput: ProThemeLight.bgInput,
    border: ProThemeLight.border,
    text: ProThemeLight.text,
    textDim: ProThemeLight.textDim,
    accent: ProThemeLight.neonCyan,
    accentLight: ProThemeLight.neonGreen.withOpacity(0.2),
    success: ProThemeLight.neonGreen,
    warning: const Color(0xFFEAB308),
    danger: ProThemeLight.neonPink,
    neonGreen: ProThemeLight.neonGreen,
    neonCyan: ProThemeLight.neonCyan,
    neonPurple: ProThemeLight.neonPurple,
    neonPink: ProThemeLight.neonPink,
    headerGradient: ProThemeLight.headerGradient,
    glow: ProThemeLight.glow,
    isDark: false,
    isProMode: true,
  );

  static GachaTheme basicModeDark() => GachaTheme(
    bg: BasicThemeDark.bg,
    bgCard: BasicThemeDark.bgCard,
    bgInput: BasicThemeDark.bgInput,
    border: BasicThemeDark.border,
    text: BasicThemeDark.text,
    textDim: BasicThemeDark.textDim,
    accent: BasicThemeDark.accent,
    accentLight: BasicThemeDark.accentLight,
    success: BasicThemeDark.success,
    warning: BasicThemeDark.warning,
    danger: BasicThemeDark.danger,
    neonGreen: BasicThemeDark.success,
    neonCyan: BasicThemeDark.accent,
    neonPurple: const Color(0xFF9C4DFF),
    neonPink: BasicThemeDark.danger,
    headerGradient: BasicThemeDark.headerGradient,
    glow: [],
    isDark: true,
    isProMode: false,
  );

  static GachaTheme basicModeLight() => GachaTheme(
    bg: BasicThemeLight.bg,
    bgCard: BasicThemeLight.bgCard,
    bgInput: BasicThemeLight.bgInput,
    border: BasicThemeLight.border,
    text: BasicThemeLight.text,
    textDim: BasicThemeLight.textDim,
    accent: BasicThemeLight.accent,
    accentLight: BasicThemeLight.accentLight,
    success: BasicThemeLight.success,
    warning: BasicThemeLight.warning,
    danger: BasicThemeLight.danger,
    neonGreen: BasicThemeLight.success,
    neonCyan: BasicThemeLight.accent,
    neonPurple: const Color(0xFF9C4DFF),
    neonPink: BasicThemeLight.danger,
    headerGradient: BasicThemeLight.headerGradient,
    glow: [],
    isDark: false,
    isProMode: false,
  );

  static GachaTheme getTheme({required bool proMode, required bool darkMode}) {
    if (proMode) {
      return darkMode ? proModeDark() : proModeLight();
    } else {
      return darkMode ? basicModeDark() : basicModeLight();
    }
  }
}
