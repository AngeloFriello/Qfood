import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// App name and info constants.
class AppConst {
  // This class is not meant to be instantiated or extended; this constructor
  // prevents instantiation and extension.
  AppConst._();

  /// Name of the app.
  static const String appName = 'Flexboard';

  /// Current app version.
  static const String version = '0.0.1';
  static int selectedItem = 0;

  /// Copyright years notice.
  static const String copyright = '© 2025';

  /// Author info.
  static const String author = 'Sheikhsoft';

  static double mobileMaxWidth = 600.0;
  static double desktopMaxWidth = 1000.0;

  // Check if this is a Web-WASM build, Web-JS build or native VM build.
  static const bool isRunningWithWasm = bool.fromEnvironment(
    'dart.tool.dart2wasm',
  );
  static const String buildType = isRunningWithWasm
      ? ', WasmGC'
      : kIsWeb
          ? ', JS'
          : ', native VM';

  static const String exportInfo = 'Themes Playground data exported ';

  static String? get font => GoogleFonts.notoSans().fontFamily;

  static final TextStyle notoSansRegular = GoogleFonts.notoSans(
    fontWeight: FontWeight.w400,
  );
  static final TextStyle notoSansMedium = GoogleFonts.notoSans(
    fontWeight: FontWeight.w500,
  );
  static final TextStyle notoSansBold = GoogleFonts.notoSans(
    fontWeight: FontWeight.w700,
  );
  static TextTheme? get textTheme => TextTheme(
        displayLarge: notoSansRegular, // Regular is default
        displayMedium: notoSansRegular, // Regular is default
        displaySmall: notoSansRegular, // Regular is default
        headlineLarge: notoSansRegular, // Regular is default
        headlineMedium: notoSansRegular, // Regular is default
        headlineSmall: notoSansRegular, // Regular is default
        titleLarge: notoSansRegular, // Regular is default
        titleMedium: notoSansMedium, // medium is default
        titleSmall: notoSansMedium, // Medium is default
        bodyLarge: notoSansRegular, // Regular is default
        bodyMedium: notoSansRegular, // Regular is default
        bodySmall: notoSansRegular, // Regular is default
        labelLarge: notoSansMedium, // Medium is default
        labelMedium: notoSansMedium, // Medium is default
        labelSmall: notoSansMedium, // Medium is default
      );
}
