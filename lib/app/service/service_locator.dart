import 'package:dashboard/app/service/theme_service_hive.dart';
import 'package:dashboard/app/service/toast_service.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../router/app_router.dart';
import '../theme/controllers/theme_controller.dart';
import 'theme_service.dart';

final serviceLocator = GetIt.instance;
final ValueNotifier<UniqueKey> appRestartNotifier = ValueNotifier(UniqueKey());

Future<void> initDependencies() async {
  serviceLocator.registerSingleton<AppRouter>( AppRouter() );
  serviceLocator.registerSingleton<ThemeService>(ThemeServiceHive('sheiksofy_dashboard') as ThemeService);
  await serviceLocator<ThemeService>().init();
  serviceLocator.registerSingleton<ThemeController>(
      ThemeController(serviceLocator<ThemeService>()));
  await serviceLocator<ThemeController>().loadAll();
  serviceLocator.registerSingleton<ToastService>(ToastService(appRouter: serviceLocator()));
}
