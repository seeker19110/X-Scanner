import 'package:flutter/material.dart';

/// Brand seed: dark blue. The only hard-coded color; everything else derives
/// from the Material 3 [ColorScheme] generated from it.
const Color xScannerSeed = Color(0xFF0D47A1);

ThemeData buildTheme(Brightness brightness) => ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: xScannerSeed,
    brightness: brightness,
  ),
  useMaterial3: true,
);
