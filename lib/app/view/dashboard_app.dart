
import 'package:dashboard/app/router/app_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../utils/app_scroll_behavior.dart';


import '../service/service_locator.dart';
import '../theme/constants/app_const.dart';
import '../theme/controllers/theme_controller.dart';

import '../theme/flex_theme_dark.dart';
import '../theme/flex_theme_light.dart';

import '../theme/theme_data_dark.dart';
import '../theme/theme_data_light.dart';

// ignore_for_file: prefer_mixin

/// The [MaterialApp] widget for the ThemeDemo application.
///
/// We use a StatefulWidget to access the Riverpod providers we
/// use to control the used light and dark themes, as well as theme mode.
///
/// We use stateful version to be able to update the Drawer width provider used
/// in the app theme when media width changes on window resize. We do this
/// before we have a MediaQuery in the context. This may be a bit overkill,
/// but is used here to demonstrate how we can make a media size dependent
/// Drawer width theme, even if Flutter framework does not support media size
/// dependent theme out-of-the box as theme property for the Drawer.
class DashboardApp extends StatefulWidget {
  const DashboardApp({super.key});

  @override
  State<DashboardApp> createState() => _DashboardAppState();
}

class _DashboardAppState extends State<DashboardApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('Rebuild MaterialApp');
    final appRouter = serviceLocator<AppRouter>();
    final themeController = serviceLocator<ThemeController>();

    return ListenableBuilder(
      listenable: themeController,
      builder: (context, child) {
        debugPrint('Rebuild MaterialApp with ListenableBuilder');
        return MaterialApp.router(
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          debugShowCheckedModeBanner: false,
          scrollBehavior: const AppScrollBehavior(),
          title: AppConst.appName,
          theme: themeController.useFlexColorScheme
              ? flexThemeLight(themeController)
              : themeDataLight(themeController),
          darkTheme: themeController.useFlexColorScheme
              ? flexThemeDark(themeController)
              : themeDataDark(themeController),
          // Use the dark/light theme based on controller setting.
          themeMode: themeController.themeMode,
          routerConfig: appRouter.config(),
        );
      },
    );
  }
}
