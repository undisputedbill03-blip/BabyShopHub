import 'package:flutter/material.dart';

/// The BabyShopHub palette.
///
/// A soft rose primary with a calm teal accent - warm enough for a baby
/// store without becoming a nursery cliche.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFFD9607C);
  static const Color primaryDark = Color(0xFFB14A63);
  static const Color primarySoft = Color(0xFFFCE7EC);

  static const Color accent = Color(0xFF2E8B84);
  static const Color accentSoft = Color(0xFFE0F2F0);

  static const Color background = Color(0xFFFDF8F7);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFF5EFEE);

  static const Color textPrimary = Color(0xFF2B2530);
  static const Color textSecondary = Color(0xFF6E6673);
  static const Color textMuted = Color(0xFF9B939F);

  static const Color border = Color(0xFFE7DEDD);
  static const Color success = Color(0xFF1B7A3D);
  static const Color warning = Color(0xFFB98900);
  static const Color danger = Color(0xFFB3261E);
  static const Color star = Color(0xFFF5A623);
}

/// Soft background + icon-colour pairs for category tiles, so the category row
/// reads as a vibrant shelf rather than one block of tint. Shared by the home
/// strip and the Categories tab so a given position is the same colour in
/// both. Cycled by index.
class AppCategoryTints {
  AppCategoryTints._();

  static const List<List<Color>> _pairs = <List<Color>>[
    <Color>[Color(0xFFFCE7EC), Color(0xFFD9607C)],
    <Color>[Color(0xFFE0F2F0), Color(0xFF2E8B84)],
    <Color>[Color(0xFFFFF1D9), Color(0xFFCA8A04)],
    <Color>[Color(0xFFEAE7FB), Color(0xFF6D5BD0)],
    <Color>[Color(0xFFDDEEFB), Color(0xFF2E73C0)],
    <Color>[Color(0xFFE2F5E9), Color(0xFF1B7A3D)],
    <Color>[Color(0xFFFCE4DC), Color(0xFFD2592F)],
    <Color>[Color(0xFFF3E1EF), Color(0xFF9B4D8E)],
  ];

  /// The `[background, foreground]` pair for a tile at [index].
  static List<Color> at(int index) => _pairs[index % _pairs.length];
}

/// Consistent spacing scale. Using these instead of magic numbers keeps
/// every screen visually aligned.
class AppSpacing {
  AppSpacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

class AppRadius {
  AppRadius._();
  static const double sm = 8;
  static const double md = 14;
  static const double lg = 20;
  static const double pill = 999;
}

/// Text styles used across the app.
class AppText {
  AppText._();

  static const TextStyle h1 = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  static const TextStyle h2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.25,
  );

  static const TextStyle h3 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    color: AppColors.textPrimary,
    height: 1.45,
  );

  static const TextStyle bodyMuted = TextStyle(
    fontSize: 14,
    color: AppColors.textSecondary,
    height: 1.45,
  );

  static const TextStyle small = TextStyle(
    fontSize: 12,
    color: AppColors.textSecondary,
  );

  static const TextStyle tiny = TextStyle(
    fontSize: 11,
    color: AppColors.textMuted,
  );

  static const TextStyle price = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.primaryDark,
  );

  static const TextStyle priceLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.primaryDark,
  );

  static const TextStyle button = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
  );
}

/// Ready-made decorations so screens stay short and consistent.
class AppDecorations {
  AppDecorations._();

  static BoxDecoration card({Color? color, double radius = AppRadius.md}) {
    return BoxDecoration(
      color: color ?? AppColors.surface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: AppColors.border),
      boxShadow: const <BoxShadow>[
        // A very soft lift so white cards separate from the warm background
        // without reading as heavy "material" elevation.
        BoxShadow(
          color: Color(0x0F000000),
          blurRadius: 10,
          offset: Offset(0, 3),
        ),
      ],
    );
  }

  static BoxDecoration softCard({
    Color? color,
    double radius = AppRadius.md,
  }) {
    return BoxDecoration(
      color: color ?? AppColors.surface,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: const <BoxShadow>[
        BoxShadow(
          color: Color(0x14000000),
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
      ],
    );
  }

  static BoxDecoration pill(Color color) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(AppRadius.pill),
    );
  }
}

/// Input decoration helper.
///
/// Built as a function rather than a global `inputDecorationTheme` so the
/// project compiles across every recent Flutter version without depending
/// on theme class names that have changed over time.
class AppInput {
  AppInput._();

  static InputDecoration decoration({
    required String label,
    String? hint,
    IconData? icon,
    Widget? suffix,
    String? helper,
    String? prefixText,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      helperText: helper,
      prefixText: prefixText,
      prefixIcon: icon == null ? null : Icon(icon, size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: AppColors.surface,
      labelStyle: const TextStyle(color: AppColors.textSecondary),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.danger, width: 1.6),
      ),
    );
  }
}

/// Button styles.
class AppButtons {
  AppButtons._();

  static ButtonStyle primary({double height = 52}) {
    return ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      disabledBackgroundColor: AppColors.textMuted,
      disabledForegroundColor: Colors.white,
      elevation: 2,
      shadowColor: AppColors.primary.withValues(alpha: 0.35),
      surfaceTintColor: Colors.transparent,
      minimumSize: Size.fromHeight(height),
      textStyle: AppText.button,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
    );
  }

  static ButtonStyle secondary({double height = 52}) {
    return OutlinedButton.styleFrom(
      foregroundColor: AppColors.primaryDark,
      minimumSize: Size.fromHeight(height),
      textStyle: AppText.button,
      side: const BorderSide(color: AppColors.primary),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
    );
  }

  static ButtonStyle danger({double height = 52}) {
    return ElevatedButton.styleFrom(
      backgroundColor: AppColors.danger,
      foregroundColor: Colors.white,
      elevation: 0,
      minimumSize: Size.fromHeight(height),
      textStyle: AppText.button,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
    );
  }

  static ButtonStyle compact() {
    return ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
    );
  }
}

/// Builds the single [ThemeData] used by the app.
///
/// Only long-stable [ThemeData] fields are set here on purpose. Component
/// themes such as card/dialog/tab-bar themes changed class names between
/// Flutter releases, so this project styles those widgets directly instead.
ThemeData buildAppTheme() {
  final ColorScheme scheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.light,
  ).copyWith(
    primary: AppColors.primary,
    secondary: AppColors.accent,
    surface: AppColors.surface,
    error: AppColors.danger,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.background,
    dividerColor: AppColors.border,
    // Gentle on-brand interaction feedback. This reads clearly on Windows
    // desktop (hover) without shouting on touch.
    hoverColor: AppColors.primary.withValues(alpha: 0.04),
    splashColor: AppColors.primary.withValues(alpha: 0.10),
    highlightColor: AppColors.primary.withValues(alpha: 0.06),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    ),
  );
}
