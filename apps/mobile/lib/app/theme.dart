import 'package:flutter/material.dart';

/// Brand seed: dark blue. The only hard-coded color; everything else derives
/// from the Material 3 [ColorScheme] generated from it.
const Color xScannerSeed = Color(0xFF0D47A1);

ThemeData buildTheme(Brightness brightness) {
  final colors = ColorScheme.fromSeed(
    seedColor: xScannerSeed,
    brightness: brightness,
  );
  final base = ThemeData(colorScheme: colors, useMaterial3: true);
  final rounded = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(20),
  );
  return base.copyWith(
    scaffoldBackgroundColor: colors.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: colors.surface,
      foregroundColor: colors.onSurface,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: base.textTheme.titleLarge?.copyWith(
        color: colors.onSurface,
        fontWeight: FontWeight.w700,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: colors.surfaceContainerLow,
      shape: rounded.copyWith(side: BorderSide(color: colors.outlineVariant)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 52),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 52),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(minimumSize: const Size.square(48)),
    ),
    dialogTheme: DialogThemeData(shape: rounded),
    pageTransitionsTheme: PageTransitionsTheme(
      builders: {
        for (final MapEntry(:key, :value)
            in const PageTransitionsTheme().builders.entries)
          key: ReducedMotionPageTransitionsBuilder(value),
      },
    ),
    bottomSheetTheme: const BottomSheetThemeData(showDragHandle: true),
  );
}

/// Uses [motion] unless the system asks for reduced motion
/// ([MediaQuery.disableAnimationsOf]), when the new page simply appears
/// without sliding or zooming (UX-VISUAL-001, WCAG 2.3.3).
class ReducedMotionPageTransitionsBuilder extends PageTransitionsBuilder {
  const ReducedMotionPageTransitionsBuilder(this.motion);

  /// The platform's usual transition.
  final PageTransitionsBuilder motion;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => MediaQuery.disableAnimationsOf(context)
      ? child
      : motion.buildTransitions(
          route,
          context,
          animation,
          secondaryAnimation,
          child,
        );
}
