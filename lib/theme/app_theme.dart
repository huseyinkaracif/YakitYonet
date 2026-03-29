import 'package:flutter/material.dart';

class AppTheme {
  // ── Core Palette ───────────────────────────────────────────────────────────
  // Warm white/amber light theme — automotive logbook aesthetic

  static const Color bgMain        = Color(0xFFFAF9F6); // warm off-white scaffold
  static const Color surface       = Color(0xFFFFFFFF); // pure white cards
  static const Color surfaceAlt    = Color(0xFFF5F2EC); // warm cream alt surface
  static const Color borderSubtle  = Color(0xFFE5E1D8); // warm stone border

  static const Color textPrimary   = Color(0xFF1C1917); // near-black, warm undertone
  static const Color textSecondary = Color(0xFF78716C); // stone gray
  static const Color textHint      = Color(0xFFA8A29E); // light stone

  static const Color dividerColor  = Color(0xFFE7E4DC); // warm divider

  // Primary accent — amber (petroleum / decisive action)
  static const Color accent        = Color(0xFFD97706);
  static const Color accentLight   = Color(0xFFFEF3C7); // amber tint bg
  static const Color accentDark    = Color(0xFFB45309); // amber pressed

  // Category semantic colors
  static const Color fuelColor     = Color(0xFFD97706); // amber — fuel
  static const Color maintColor    = Color(0xFF0D9488); // teal — maintenance
  static const Color insurColor    = Color(0xFF64748B); // slate-600 — insurance

  // Status
  static const Color successColor  = Color(0xFF15803D); // forest green
  static const Color dangerColor   = Color(0xFFDC2626); // red

  // ── Legacy Aliases (keep for screen compatibility) ─────────────────────────
  static const Color primaryDark   = bgMain;       // was dark navy, now bg
  static const Color primaryMid    = surfaceAlt;
  static const Color primaryLight  = borderSubtle;
  static const Color accentBlue    = maintColor;   // slate
  static const Color accentCyan    = Color(0xFF0891B2); // teal (less used)
  static const Color accentGreen   = successColor;
  static const Color accentOrange  = accent;       // amber = primary accent
  static const Color accentRed     = dangerColor;
  static const Color accentPurple  = insurColor;   // stone → insurance
  static const Color surfaceCard   = surface;
  static const Color surfaceOverlay = surfaceAlt;

  // ── Decorations ────────────────────────────────────────────────────────────

  static BoxDecoration get cardDecoration => const BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.all(Radius.circular(12)),
        border: Border.fromBorderSide(BorderSide(color: borderSubtle, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Color(0x061C1917),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      );

  static BoxDecoration get glassDecoration => const BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.all(Radius.circular(12)),
        border: Border.fromBorderSide(BorderSide(color: borderSubtle, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Color(0x061C1917),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      );

  // Gradient kept for compat — now renders as solid warm white
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [bgMain, bgMain],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [surface, surface],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent, accentDark],
  );

  // ── Theme Data ─────────────────────────────────────────────────────────────

  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: bgMain,
        colorScheme: const ColorScheme.light(
          primary: accent,
          secondary: accentDark,
          surface: surface,
          error: dangerColor,
          onPrimary: Colors.white,
          onSurface: textPrimary,
          onSecondary: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
          iconTheme: IconThemeData(color: textPrimary),
        ),
        cardTheme: CardThemeData(
          color: surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: borderSubtle, width: 1),
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surfaceAlt,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: borderSubtle),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: borderSubtle, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: accent, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: dangerColor, width: 1),
          ),
          labelStyle: const TextStyle(color: textSecondary, fontSize: 14),
          hintStyle: const TextStyle(color: textHint),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: accent,
            side: const BorderSide(color: accent, width: 1.5),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: accent,
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: surface,
          selectedItemColor: accent,
          unselectedItemColor: textHint,
        ),
        tabBarTheme: const TabBarThemeData(
          labelColor: Colors.white,
          unselectedLabelColor: textSecondary,
          indicatorColor: accent,
        ),
        dividerTheme: const DividerThemeData(
          color: dividerColor,
          thickness: 1,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: textPrimary,
          contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          behavior: SnackBarBehavior.floating,
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return accent;
            return textHint;
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return accentLight;
            return borderSubtle;
          }),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          titleTextStyle: const TextStyle(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
          contentTextStyle: const TextStyle(
            color: textSecondary,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        popupMenuTheme: PopupMenuThemeData(
          color: surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: borderSubtle),
          ),
          elevation: 4,
          textStyle: const TextStyle(color: textPrimary, fontSize: 14),
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: accent,
        ),
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return accent;
            return Colors.transparent;
          }),
          side: const BorderSide(color: borderSubtle, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
      );

  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFF1C1917), // very dark gray/near black
        colorScheme: const ColorScheme.dark(
          primary: accent,
          secondary: accentDark,
          surface: Color(0xFF292524), // dark card surface
          error: dangerColor,
          onPrimary: Colors.white,
          onSurface: Color(0xFFF5F5F4),
          onSecondary: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: Color(0xFFF5F5F4),
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
          iconTheme: IconThemeData(color: Color(0xFFF5F5F4)),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF292524),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFF44403C), width: 1),
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF44403C),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF57534E)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF57534E), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: accent, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: dangerColor, width: 1),
          ),
          labelStyle: const TextStyle(color: Color(0xFFD6D3D1), fontSize: 14),
          hintStyle: const TextStyle(color: Color(0xFFA8A29E)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: accent,
            side: const BorderSide(color: accent, width: 1.5),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: accent,
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF292524),
          selectedItemColor: accent,
          unselectedItemColor: Color(0xFFD6D3D1),
        ),
        tabBarTheme: const TabBarThemeData(
          labelColor: Colors.white,
          unselectedLabelColor: Color(0xFFD6D3D1),
          indicatorColor: accent,
        ),
        dividerTheme: const DividerThemeData(
          color: Color(0xFF44403C),
          thickness: 1,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: const Color(0xFF44403C),
          contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          behavior: SnackBarBehavior.floating,
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return accent;
            return const Color(0xFF78716C);
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return accentDark;
            return const Color(0xFF44403C);
          }),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: const Color(0xFF292524),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          titleTextStyle: const TextStyle(
            color: Color(0xFFF5F5F4),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
          contentTextStyle: const TextStyle(
            color: Color(0xFFD6D3D1),
            fontSize: 14,
            height: 1.5,
          ),
        ),
        popupMenuTheme: PopupMenuThemeData(
          color: const Color(0xFF292524),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFF44403C)),
          ),
          elevation: 4,
          textStyle: const TextStyle(color: Color(0xFFF5F5F4), fontSize: 14),
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: accent,
        ),
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return accent;
            return Colors.transparent;
          }),
          side: const BorderSide(color: Color(0xFF57534E), width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
      );

  // ── Theme-aware helpers ─────────────────────────────────────────────────────

  /// Card / surface background colour that adapts to light/dark.
  static Color surfaceFor(BuildContext ctx) =>
      Theme.of(ctx).brightness == Brightness.dark
          ? const Color(0xFF292524)
          : surface;

  /// Slightly elevated surface (alt fill) that adapts to light/dark.
  static Color surfaceAltFor(BuildContext ctx) =>
      Theme.of(ctx).brightness == Brightness.dark
          ? const Color(0xFF3C3836)
          : surfaceAlt;

  /// Card border colour that adapts to light/dark.
  static Color borderFor(BuildContext ctx) =>
      Theme.of(ctx).brightness == Brightness.dark
          ? const Color(0xFF44403C)
          : borderSubtle;

  /// Primary text color that adapts to light/dark.
  static Color textPrimaryFor(BuildContext ctx) =>
      Theme.of(ctx).brightness == Brightness.dark
          ? const Color(0xFFF5F5F4)
          : textPrimary;

  /// Secondary text color that adapts to light/dark.
  static Color textSecondaryFor(BuildContext ctx) =>
      Theme.of(ctx).brightness == Brightness.dark
          ? const Color(0xFFD6D3D1) // Daha belirgin, parlak gri
          : textSecondary;

  /// Hint text color that adapts to light/dark.
  static Color textHintFor(BuildContext ctx) =>
      Theme.of(ctx).brightness == Brightness.dark
          ? const Color(0xFFA8A29E) // Eski secondary rengi hint yapıldı, daha okunur
          : textHint;

  /// Divider color that adapts to light/dark.
  static Color dividerFor(BuildContext ctx) =>
      Theme.of(ctx).brightness == Brightness.dark
          ? const Color(0xFF44403C)
          : dividerColor;

  /// Theme-aware card decoration (replaces static cardDecoration / glassDecoration).
  static BoxDecoration cardDecorationFor(BuildContext ctx) => BoxDecoration(
        color: surfaceFor(ctx),
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        border: Border.fromBorderSide(
            BorderSide(color: borderFor(ctx), width: 1)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x061C1917), blurRadius: 8, offset: Offset(0, 2)),
        ],
      );

  // ── Fuel Type Helpers ──────────────────────────────────────────────────────

  static Color getFuelTypeColor(String fuelType) {
    switch (fuelType.toLowerCase()) {
      case 'benzin':
        return fuelColor;
      case 'dizel':
        return maintColor;
      case 'lpg':
        return successColor;
      case 'elektrik':
        return const Color(0xFF0891B2); // teal
      default:
        return textSecondary;
    }
  }

  static IconData getFuelTypeIcon(String fuelType) {
    switch (fuelType.toLowerCase()) {
      case 'benzin':
        return Icons.local_gas_station;
      case 'dizel':
        return Icons.local_gas_station;
      case 'lpg':
        return Icons.propane_tank;
      case 'elektrik':
        return Icons.ev_station;
      default:
        return Icons.local_gas_station;
    }
  }
}
