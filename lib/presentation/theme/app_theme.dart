import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PREMIUM THEME EXTENSION
// ─────────────────────────────────────────────────────────────────────────────
@immutable
class AppBrandColors extends ThemeExtension<AppBrandColors> {
  const AppBrandColors({
    required this.heroGradient,
    required this.cardGradient,
    required this.buttonGradient,
    required this.gold,
    required this.goldLight,
  });

  final LinearGradient heroGradient;
  final LinearGradient cardGradient;
  final LinearGradient buttonGradient;
  final Color gold;
  final Color goldLight;

  @override
  AppBrandColors copyWith({
    LinearGradient? heroGradient,
    LinearGradient? cardGradient,
    LinearGradient? buttonGradient,
    Color? gold,
    Color? goldLight,
  }) {
    return AppBrandColors(
      heroGradient: heroGradient ?? this.heroGradient,
      cardGradient: cardGradient ?? this.cardGradient,
      buttonGradient: buttonGradient ?? this.buttonGradient,
      gold: gold ?? this.gold,
      goldLight: goldLight ?? this.goldLight,
    );
  }

  @override
  AppBrandColors lerp(ThemeExtension<AppBrandColors>? other, double t) {
    if (other is! AppBrandColors) return this;
    return AppBrandColors(
      heroGradient: LinearGradient.lerp(heroGradient, other.heroGradient, t) ??
          heroGradient,
      cardGradient: LinearGradient.lerp(cardGradient, other.cardGradient, t) ??
          cardGradient,
      buttonGradient:
          LinearGradient.lerp(buttonGradient, other.buttonGradient, t) ??
              buttonGradient,
      gold: Color.lerp(gold, other.gold, t) ?? gold,
      goldLight: Color.lerp(goldLight, other.goldLight, t) ?? goldLight,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MAIN THEME CLASS
// ─────────────────────────────────────────────────────────────────────────────
class AppTheme {
  AppTheme._();

  // ───────────────────────── COLOR PALETTE ─────────────────────────
  // Midnight Blue – primary brand color
  static const midnightBlue = Color(0xFF1E3A5F);
  static const midnightDeep = Color(0xFF0F2540);
  static const midnightLight = Color(0xFF2E4A6F);

  // Gold/Amber accent
  static const goldAccent = Color(0xFFD4AF37);
  static const goldLight = Color(0xFFE9C767);
  static const amberWarm = Color(0xFFF5A623);

  // Neutrals
  static const surfaceLight = Color(0xFFFAFAFC);
  static const surfaceDark = Color(0xFF0D1B2A);
  static const cardLight = Color(0xFFFFFFFF);
  static const cardDark = Color(0xFF162A3E);
  static const borderLight = Color(0xFFE8ECF2);
  static const borderDark = Color(0xFF2A3F55);
  static const textPrimary = Color(0xFF1A1D21);
  static const textSecondary = Color(0xFF5A6370);
  static const textOnDark = Color(0xFFF5F5F7);
  static const textMuted = Color(0xFF8A929E);

  // Semantic
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFEF4444);
  static const info = Color(0xFF3B82F6);

  // ───────────────────────── PUBLIC THEMES ─────────────────────────
  static final ThemeData lightTheme = _buildTheme(Brightness.light);
  static final ThemeData darkTheme = _buildTheme(Brightness.dark);

  // ───────────────────────── THEME BUILDER ─────────────────────────
  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    // Generate base scheme from midnight blue seed
    final baseScheme = ColorScheme.fromSeed(
      seedColor: midnightBlue,
      brightness: brightness,
    );

    // Override with our premium palette
    final scheme = baseScheme.copyWith(
      primary: midnightBlue,
      onPrimary: Colors.white,
      primaryContainer: isDark ? midnightLight : const Color(0xFFD6E4F5),
      onPrimaryContainer: isDark ? Colors.white : midnightDeep,
      secondary: goldAccent,
      onSecondary: midnightDeep,
      secondaryContainer:
          isDark ? const Color(0xFF3D3520) : goldLight.withOpacity(0.3),
      onSecondaryContainer: isDark ? goldLight : const Color(0xFF5C4A1A),
      tertiary: amberWarm,
      onTertiary: Colors.white,
      error: danger,
      onError: Colors.white,
      surface: isDark ? surfaceDark : surfaceLight,
      onSurface: isDark ? textOnDark : textPrimary,
      surfaceContainerHighest: isDark ? cardDark : cardLight,
      outline: isDark ? borderDark : borderLight,
      outlineVariant: isDark ? borderDark.withOpacity(0.5) : borderLight,
    );

    // Typography with Google Fonts
    final headingFont = GoogleFonts.poppins();
    final bodyFont = GoogleFonts.inter();

    final textTheme = TextTheme(
      displayLarge: headingFont.copyWith(
        fontSize: 57,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.5,
        color: scheme.onSurface,
      ),
      displayMedium: headingFont.copyWith(
        fontSize: 45,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: scheme.onSurface,
      ),
      displaySmall: headingFont.copyWith(
        fontSize: 36,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.25,
        color: scheme.onSurface,
      ),
      headlineLarge: headingFont.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: scheme.onSurface,
      ),
      headlineMedium: headingFont.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: scheme.onSurface,
      ),
      headlineSmall: headingFont.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: scheme.onSurface,
      ),
      titleLarge: headingFont.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: scheme.onSurface,
      ),
      titleMedium: headingFont.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
        color: scheme.onSurface,
      ),
      titleSmall: headingFont.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: scheme.onSurface,
      ),
      bodyLarge: bodyFont.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        color: scheme.onSurface,
      ),
      bodyMedium: bodyFont.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        color: scheme.onSurface,
      ),
      bodySmall: bodyFont.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        color: scheme.onSurface.withOpacity(0.75),
      ),
      labelLarge: bodyFont.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: scheme.onSurface,
      ),
      labelMedium: bodyFont.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: scheme.onSurface,
      ),
      labelSmall: bodyFont.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: scheme.onSurface.withOpacity(0.7),
      ),
    );

    // Brand extension with gradients
    final brand = AppBrandColors(
      heroGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? const [Color(0xFF0D1B2A), Color(0xFF1E3A5F)]
            : const [Color(0xFF1E3A5F), Color(0xFF2E5A8F)],
      ),
      cardGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? const [Color(0xFF162A3E), Color(0xFF1A3550)]
            : const [Color(0xFFFFFFFE), Color(0xFFF8FAFC)],
      ),
      buttonGradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1E3A5F), Color(0xFF2E5A8F)],
      ),
      gold: goldAccent,
      goldLight: goldLight,
    );

    final radius12 = BorderRadius.circular(12);
    final radius16 = BorderRadius.circular(16);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      visualDensity: VisualDensity.standard,
      textTheme: textTheme,
      extensions: <ThemeExtension<dynamic>>[brand],

      // ─────────────────── APP BAR ───────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: IconThemeData(color: scheme.onSurface, size: 24),
      ),

      // ─────────────────── CARD ───────────────────
      cardTheme: CardThemeData(
        color: isDark ? cardDark : cardLight,
        elevation: 0,
        shadowColor: Colors.black.withOpacity(isDark ? 0.4 : 0.08),
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: radius16,
          side: BorderSide(
            color: scheme.outline.withOpacity(isDark ? 0.3 : 0.6),
            width: 1,
          ),
        ),
      ),

      // ─────────────────── INPUT DECORATION ───────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF1A2D42) : const Color(0xFFF1F5F9),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurface.withOpacity(0.5),
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurface.withOpacity(0.7),
        ),
        floatingLabelStyle: textTheme.labelMedium?.copyWith(
          color: scheme.primary,
          fontWeight: FontWeight.w600,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: radius12,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius12,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius12,
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: radius12,
          borderSide: BorderSide(color: scheme.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: radius12,
          borderSide: BorderSide(color: scheme.error, width: 2),
        ),
        prefixIconColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.focused)) return scheme.primary;
          return scheme.onSurface.withOpacity(0.5);
        }),
      ),

      // ─────────────────── ELEVATED BUTTON ───────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          elevation: 0,
          shadowColor: scheme.primary.withOpacity(0.3),
          minimumSize: const Size(0, 50),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: radius12),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ).copyWith(
          elevation: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) return 0;
            if (states.contains(WidgetState.hovered)) return 4;
            return 2;
          }),
          shadowColor: WidgetStateProperty.all(
            scheme.primary.withOpacity(0.4),
          ),
        ),
      ),

      // ─────────────────── FILLED BUTTON ───────────────────
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size(0, 50),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: radius12),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),

      // ─────────────────── OUTLINED BUTTON ───────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          side: BorderSide(color: scheme.primary, width: 1.5),
          minimumSize: const Size(0, 50),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: radius12),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),

      // ─────────────────── TEXT BUTTON ───────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: radius12),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ─────────────────── ICON BUTTON ───────────────────
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: scheme.onSurface,
          shape: RoundedRectangleBorder(borderRadius: radius12),
        ),
      ),

      // ─────────────────── FAB ───────────────────
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: goldAccent,
        foregroundColor: midnightDeep,
        elevation: 4,
        focusElevation: 6,
        hoverElevation: 8,
        shape: RoundedRectangleBorder(borderRadius: radius16),
      ),

      // ─────────────────── CHIP ───────────────────
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? cardDark : const Color(0xFFF1F5F9),
        selectedColor: scheme.primary.withOpacity(0.15),
        labelStyle: textTheme.labelMedium,
        secondaryLabelStyle: textTheme.labelMedium,
        side: BorderSide(color: scheme.outline.withOpacity(0.3)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),

      // ─────────────────── DIVIDER ───────────────────
      dividerTheme: DividerThemeData(
        color: scheme.outline.withOpacity(isDark ? 0.4 : 0.6),
        thickness: 1,
        space: 0,
      ),

      // ─────────────────── ICON ───────────────────
      iconTheme: IconThemeData(
        color: scheme.onSurface,
        size: 22,
      ),

      // ─────────────────── LIST TILE ───────────────────
      listTileTheme: ListTileThemeData(
        iconColor: scheme.onSurface.withOpacity(0.7),
        textColor: scheme.onSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: radius12),
      ),

      // ─────────────────── SNACKBAR ───────────────────
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? const Color(0xFF2A3F55) : midnightDeep,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: radius12),
        elevation: 6,
      ),

      // ─────────────────── BOTTOM SHEET ───────────────────
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        dragHandleColor: scheme.outline,
        dragHandleSize: const Size(40, 4),
      ),

      // ─────────────────── DIALOG ───────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? cardDark : cardLight,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: radius16),
        elevation: 8,
      ),

      // ─────────────────── NAVIGATION BAR ───────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: scheme.primary.withOpacity(0.15),
        labelTextStyle: WidgetStateProperty.all(
          textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: scheme.primary, size: 24);
          }
          return IconThemeData(
              color: scheme.onSurface.withOpacity(0.6), size: 24);
        }),
      ),

      // ─────────────────── BOTTOM NAV BAR ───────────────────
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: scheme.surface,
        selectedItemColor: scheme.primary,
        unselectedItemColor: scheme.onSurface.withOpacity(0.5),
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle:
            textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: textTheme.labelSmall,
      ),

      // ─────────────────── TAB BAR ───────────────────
      tabBarTheme: TabBarThemeData(
        indicatorColor: goldAccent,
        labelColor: scheme.onSurface,
        unselectedLabelColor: scheme.onSurface.withOpacity(0.6),
        labelStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: textTheme.labelLarge,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
      ),

      // ─────────────────── PROGRESS INDICATOR ───────────────────
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: goldAccent,
        linearTrackColor: scheme.outline.withOpacity(0.3),
        circularTrackColor: scheme.outline.withOpacity(0.3),
      ),

      // ─────────────────── CHECKBOX / RADIO / SWITCH ───────────────────
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return scheme.primary;
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        side: BorderSide(color: scheme.outline, width: 1.5),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return scheme.primary;
          return scheme.outline;
        }),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return scheme.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return scheme.primary;
          return scheme.outline.withOpacity(0.3);
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),

      // ─────────────────── TOOLTIP ───────────────────
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A3F55) : midnightDeep,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: textTheme.bodySmall?.copyWith(color: Colors.white),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),

      // ─────────────────── PAGE TRANSITIONS ───────────────────
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: ZoomPageTransitionsBuilder(),
          TargetPlatform.macOS: ZoomPageTransitionsBuilder(),
          TargetPlatform.windows: ZoomPageTransitionsBuilder(),
        },
      ),

      // ─────────────────── POPUP MENU ───────────────────
      popupMenuTheme: PopupMenuThemeData(
        shape: RoundedRectangleBorder(borderRadius: radius12),
        elevation: 4,
        color: isDark ? cardDark : cardLight,
        surfaceTintColor: Colors.transparent,
      ),

      // ─────────────────── MENU BUTTON ───────────────────
      menuButtonTheme: MenuButtonThemeData(
        style: MenuItemButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: radius12),
        ),
      ),
    );
  }

  // ───────────────────────── UTILITY COLORS ─────────────────────────
  // For direct usage in custom widgets (legacy support)
  static const primaryColor = midnightBlue;
  static const secondaryColor = goldAccent;
  static const successColor = success;
  static const warningColor = warning;
  static const dangerColor = danger;
  static const infoColor = info;
  static const backgroundColor = surfaceLight;
  static const surfaceColor = cardLight;
  static const borderColor = borderLight;
  static const textColor = textPrimary;
  static const textLightColor = textSecondary;
}

// ─────────────────────────────────────────────────────────────────────────────
// GLASSMORPHISM CONTAINER WIDGET
// ─────────────────────────────────────────────────────────────────────────────
class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius,
    this.blur = 12,
    this.opacity = 0.15,
    this.borderOpacity = 0.2,
  });

  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final double blur;
  final double opacity;
  final double borderOpacity;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveRadius = borderRadius ?? BorderRadius.circular(16);

    return Container(
      width: width,
      height: height,
      margin: margin,
      child: ClipRRect(
        borderRadius: effectiveRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding ?? const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: effectiveRadius,
              color: isDark
                  ? Colors.white.withOpacity(opacity * 0.6)
                  : Colors.white.withOpacity(opacity),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(borderOpacity * 0.5)
                    : Colors.white.withOpacity(borderOpacity),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PREMIUM GRADIENT BUTTON WIDGET
// ─────────────────────────────────────────────────────────────────────────────
class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.gradient,
    this.width,
    this.height = 50,
    this.borderRadius,
    this.elevation = 4,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final Gradient? gradient;
  final double? width;
  final double height;
  final BorderRadius? borderRadius;
  final double elevation;

  @override
  Widget build(BuildContext context) {
    final brand = Theme.of(context).extension<AppBrandColors>();
    final effectiveGradient = gradient ??
        brand?.buttonGradient ??
        const LinearGradient(
          colors: [AppTheme.midnightBlue, AppTheme.midnightLight],
        );
    final effectiveRadius = borderRadius ?? BorderRadius.circular(12);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: onPressed != null ? effectiveGradient : null,
        color: onPressed == null ? Colors.grey.shade400 : null,
        borderRadius: effectiveRadius,
        boxShadow: onPressed != null
            ? [
                BoxShadow(
                  color: AppTheme.midnightBlue.withOpacity(0.3),
                  blurRadius: elevation * 2,
                  offset: Offset(0, elevation),
                ),
                BoxShadow(
                  color: AppTheme.midnightBlue.withOpacity(0.15),
                  blurRadius: elevation,
                  offset: Offset(0, elevation / 2),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: effectiveRadius,
          splashColor: Colors.white.withOpacity(0.2),
          highlightColor: Colors.white.withOpacity(0.1),
          child: Center(child: child),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GOLD ACCENT BUTTON (for CTAs)
// ─────────────────────────────────────────────────────────────────────────────
class GoldButton extends StatelessWidget {
  const GoldButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.width,
    this.height = 50,
  });

  final VoidCallback? onPressed;
  final String label;
  final IconData? icon;
  final double? width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: onPressed != null
            ? const LinearGradient(
                colors: [AppTheme.goldAccent, AppTheme.goldLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: onPressed == null ? Colors.grey.shade400 : null,
        borderRadius: BorderRadius.circular(12),
        boxShadow: onPressed != null
            ? [
                BoxShadow(
                  color: AppTheme.goldAccent.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          splashColor: Colors.white.withOpacity(0.3),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: AppTheme.midnightDeep, size: 20),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: textTheme.labelLarge?.copyWith(
                    color: AppTheme.midnightDeep,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
