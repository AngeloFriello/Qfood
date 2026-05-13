import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';

import '../controllers/theme_controller.dart';

abstract final class AppColor {
  static const FlexSchemeColor _myScheme1Light = FlexSchemeColor(
    primary: Color(0xFF00296B),
    primaryContainer: Color(0xFFA0C2ED),
    secondary: Color(0xFFD26900),
    secondaryContainer: Color(0xFFFFD270),
    tertiary: Color(0xFF5C5C95),
    tertiaryContainer: Color(0xFFC8DBF8),
    appBarColor: Color(0xFFC8DCF8),
    swapOnMaterial3: true,
  );

  static const FlexSchemeColor _myScheme1Dark = FlexSchemeColor(
    primary: Color(0xFFB1CFF5),
    primaryContainer: Color(0xFF3873BA),
    primaryLightRef: Color(0xFF00296B),
    secondary: Color(0xFFFFD270),
    secondaryContainer: Color(0xFFD26900),
    secondaryLightRef: Color(0xFFD26900),
    tertiary: Color(0xFFC9CBFC),
    tertiaryContainer: Color(0xFF535393),
    tertiaryLightRef: Color(0xFF5C5C95),
    appBarColor: Color(0xFF00102B),
    swapOnMaterial3: true,
  );

  static final FlexSchemeColor _myScheme2Light = FlexSchemeColor.from(
    primary: const Color(0xFF065808),
    brightness: Brightness.light,
  );
  static final FlexSchemeColor _myScheme2Dark = FlexSchemeColor.from(
    primary: const Color(0xFF629F80),
    primaryLightRef: _myScheme2Light.primary,
    secondaryLightRef: _myScheme2Light.secondary,
    tertiaryLightRef: _myScheme2Light.tertiary,
    brightness: Brightness.dark,
  );

  static final FlexSchemeColor _myScheme3Light = FlexSchemeColor.from(
    primary: const Color(0xFF1145A4),
    secondary: const Color(0xFFB61D1D),
    brightness: Brightness.light,
    swapOnMaterial3: true,
  );

  static const Color customPrimaryLight = Color(0xFF004881);
  static const Color customPrimaryContainerLight = Color(0xFFD0E4FF);
  static const Color customSecondaryLight = Color(0xFFAC3306);
  static const Color customSecondaryContainerLight = Color(0xFFFFDBCF);
  static const Color customTertiaryLight = Color(0xFF006875);
  static const Color customTertiaryContainerLight = Color(0xFF95F0FF);

  static const Color customPrimaryDark = Color(0xFF9FC9FF);
  static const Color customPrimaryContainerDark = Color(0xFF00325B);
  static const Color customSecondaryDark = Color(0xFFFFB59D);
  static const Color customSecondaryContainerDark = Color(0xFF872100);
  static const Color customTertiaryDark = Color(0xFF86D2E1);
  static const Color customTertiaryContainerDark = Color(0xFF004E59);

  static final List<FlexSchemeData> customSchemes = <FlexSchemeData>[
    const FlexSchemeData(
      name: 'Example Midnight',
      description: 'Midnight blue theme, created as an in code example by '
          'using custom color values for all colors in the scheme',
      light: _myScheme1Light,
      dark: _myScheme1Dark,
    ),
    FlexSchemeData(
      name: 'Example Greens',
      description: 'Vivid green theme, created as an in code example from one '
          'primary color in light mode and another primary for dark mode',
      light: _myScheme2Light,
      dark: _myScheme2Dark,
    ),
    FlexSchemeData(
      name: 'Example Red & Blue',
      description: 'Classic red and blue, created as an in code example from '
          'only light theme mode primary and secondary colors',
      light: _myScheme3Light,
      dark: _myScheme3Light.defaultError.toDark(30, true),
    ),
    ...FlexColor.schemesList,
  ];

  static final List<FlexSchemeData> schemes = <FlexSchemeData>[
    ...customSchemes,
    FlexColor.customColors.copyWith(name: 'Customizable'),
  ];

  static FlexSchemeData scheme(final ThemeController controller) =>
      schemeAtIndex(controller.schemeIndex, controller);

  static FlexSchemeData schemeAtIndex(
      final int index, final ThemeController controller) {
    if (index == schemes.length - 1) {
      return controller.customScheme.copyWith(
          dark: controller.useKeyColors
              ? controller.customScheme.dark
              : controller.useToDarkMethod
                  ? controller.customScheme.light.defaultError.toDark(
                      controller.toDarkMethodLevel,
                      controller.toDarkSwapPrimaryAndContainer)
                  : null);
    }

    if (index > schemes.length - 1) {
      return schemes[0].copyWith(
          dark: controller.useToDarkMethod
              ? schemes[0].light.defaultError.toDark(
                  controller.toDarkMethodLevel,
                  controller.toDarkSwapPrimaryAndContainer)
              : null);
    }
    return schemes[index].copyWith(
        dark: controller.useToDarkMethod
            ? schemes[index].light.defaultError.toDark(
                controller.toDarkMethodLevel,
                controller.toDarkSwapPrimaryAndContainer)
            : null);
  }

  static String explainUsedColors(ThemeController controller) {
    final String errorExplanation = controller.useError
        ? '. Additionally a given error color is used to seed the error palette'
        : '';
    if (!controller.useKeyColors) {
      return 'Material 3 ColorScheme seeding from key colors is OFF and not '
          'used. The effective ColorScheme is based directly on the selected '
          'pre-defined FlexColorScheme colors';
    }
    if (!controller.useSecondary && !controller.useTertiary) {
      return 'Light scheme defined Primary color is used to generate '
          'the Colorscheme. '
          "This is like using Flutter's ColorScheme.fromSeed with the scheme "
          'defined Primary color as seed color$errorExplanation';
    }
    if (controller.useSecondary && !controller.useTertiary) {
      return 'Tonal palettes for the ColorScheme are made with light scheme '
          'defined Primary and Secondary colors as seed keys. Tertiary key '
          'is computed from Primary color$errorExplanation';
    }
    if (!controller.useSecondary && controller.useTertiary) {
      return 'Tonal palettes for the ColorScheme, are made with light scheme '
          'defined Primary and Tertiary colors as seed keys. Secondary key is '
          'computed from Primary color$errorExplanation';
    }
    return 'Light scheme defined Primary, Secondary and Tertiary colors are '
        'used as key colors to generate tonal palettes that define '
        'the ColorScheme$errorExplanation';
  }
}
