import 'dart:io';
import 'package:dashboard/Global.dart';
import 'package:dashboard/app/service/Service_Socket/service_ws_client.dart';
import 'package:dashboard/app/service/Service_Socket/service_ws_server.dart';
import 'package:dashboard/app/service/Service_Socket/service_self_order_polling.dart';
import 'package:dashboard/app/service/service_connection.dart';
import 'package:dashboard/app/service/service_new_update.dart';
import 'package:dashboard/casse_automatiche/bs/bsCash.dart';
import 'package:dashboard/casse_automatiche/cashmatic/http_protocol.dart';
import 'package:dashboard/casse_automatiche/settings_menu_automatic_checkout.dart';
import 'package:dashboard/casse_automatiche/vne/http_protocol.dart';
import 'package:dashboard/modelli/pos.dart';
import 'package:dashboard/ui/screen/checkout/controller_modulo_pagamenti.dart';
import 'package:dashboard/ui/screen/login_opertore/login_operatore_vista.dart';
import 'package:dashboard/ui/screen/ordini/ux/widgets/ordini_table.dart';
import 'package:dashboard/ui/screen/prenotazioni/ui/prenotazioni/prenotazioni_page.dart';
import 'package:dashboard/ui/screen/scontrino/ControllerLookPosInPrint.dart';
import 'package:dashboard/ui/screen/sincronizzazioni/databasesql_lite/local_db.dart';
import 'package:dashboard/state/app_session_controller.dart';
import 'package:dashboard/state/controller_carrello.dart';
import 'package:dashboard/state/controller_impostazioni.dart';
import 'package:dashboard/ui/screen/ordini/state/ordini_list_controller.dart';
import 'package:dashboard/ui/screen/sincronizzazioni/operatori/operator_preferences_controller.dart';
import 'package:dashboard/state/product_search_controller.dart';
import 'package:dashboard/ui/screen/login/login_screen.dart';
import 'package:dashboard/ui/screen/sincronizzazioni/sync_catalogo.dart';
import 'package:dashboard/ui/screen/sincronizzazioni/sync_vista.dart';
import 'package:dashboard/ui/screen/store_e_dispositivi/company_selector_vista.dart';
import 'package:dashboard/ui/screen/store_e_dispositivi/store_device_selector_vista.dart';
import 'package:dashboard/ui/screen/store_e_dispositivi/store_selector_vista.dart';
import 'package:dashboard/ui/screen/tavoli/operativita/widgets_tavolo/controllerTableOpened.dart';
import 'package:dashboard/ui/screen/tavoli/operativita/widgets_tavolo/controller_list_products_tables.dart';
import 'package:dashboard/ui/widget/header_footer/ControllerListPriceSelected.dart';
import 'package:dashboard/ui/widget/header_footer/controller_not_fiscal_in_printing.dart';
import 'package:dashboard/ui/widget/header_footer/footer_navbar.dart';
import 'package:dashboard/ui/widget/tastierino/tastierino_popup.dart';
import 'package:dashboard/varianti/state/variants_controller.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ce/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'app/service/service_locator.dart';
import 'app/theme/controllers/theme_controller.dart';
import 'app/view/dashboard_app.dart';
import 'impostazioni/home_vista.dart';
import 'impostazioni/reso_merce_vista.dart';
import 'ui/screen/ordini/state/ordine_attivo_controller.dart';
import 'package:window_manager/window_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    await windowManager.ensureInitialized();

    const WindowOptions windowOptions = WindowOptions(
      size: Size(1280, 800),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.setFullScreen(true); // full screen per windows mac e os
      await windowManager.show();
      await windowManager.focus();
    });
  }

  // SystemChrome ha effetto solo su Android/iOS
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  }

  await initDependencies();

  // ===============================================
  // SQLITE FFI (DESKTOP) — una sola inizializzazione
  // ===============================================
  if (!kIsWeb && (Platform.isLinux || Platform.isWindows || Platform.isMacOS)) {
    try {
      await writeLogOnFile("info", "Init sqlite FFI desktop");
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      await writeLogOnFile("info", "Init sqlite FFI OK");
    } catch (e) {
      if (kDebugMode) print(e);
      await writeLogOnFile("error", e.toString(), trace: StackTrace.current);
    }
  }

  // ===============================================
  // LOCAL DB
  // ===============================================
  if (!kIsWeb) {
    await LocalDB.instance();
  } else {
    debugPrint("Web mode: LocalDB DISABILITATO");
  }

  // ===============================================
  // HIVE
  // ===============================================
  try {
    if (!kIsWeb) {
      final dir = await path_provider.getApplicationDocumentsDirectory();
      Hive.init(dir.path);
    }
    await Hive.openBox('settings');
  } catch (e) {
    debugPrint("Hive error: $e");
  }

  // ===============================================
  // IMPOSTAZIONI
  // ===============================================
  final impostazioni = ImpostazioniController();
  await impostazioni.carica();

  HttpOverrides.global = CashMaticHTTPsOverride();
  GoogleFonts.config.allowRuntimeFetching = false;

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('it', 'IT'),
        Locale('en'),
        Locale('ar'),
        Locale('es'),
        Locale('hi'),
        Locale('zh'),
        Locale('bn'),
      ],
      fallbackLocale: const Locale('it', 'IT'),
      saveLocale: true,
      path: 'assets/translations',
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => VnePosState()),
          ChangeNotifierProvider(create: (_) => ControllerTimerPos()),
          ChangeNotifierProvider(create: (_) => ControllerListProductsTable()),
          ChangeNotifierProvider<ControllerWsClient>(
            create: (_) => ServiceWsClient.instance(),
          ),
          ChangeNotifierProvider<ControllerWsServer>(
            create: (_) => ServiceWsServer.instance(),
          ),
          ChangeNotifierProvider<ControllerLastUpdate>(
            create: (_) => ServiceNewUpdate.instance(),
          ),
          ChangeNotifierProvider(create: (_) => ControllerNuovoOrdine()),
          ChangeNotifierProvider(create: (_) => ControllerOrdiniSelezionati()),
          ChangeNotifierProvider(create: (_) => ControllerTastierinoAperto()),
          ChangeNotifierProvider(create: (_) => BSCASHCONTROLLER()),
          ChangeNotifierProvider(create: (_) => SyncController()),
          ChangeNotifierProvider(create: (_) => CarrelloController()),
          ChangeNotifierProvider(create: (_) => VariantsController()),
          ChangeNotifierProvider(create: (_) => ControllerNotFiscalInPrinting()),
          ChangeNotifierProvider(create: (_) => ControllerListPriceSelected()),
          ChangeNotifierProvider(create: (_) => ControllerModuloPagamenti()),
          ChangeNotifierProvider(create: (_) => ConnectionController()),
          ChangeNotifierProvider(create: (_) => ControllerLookPosInPrinder()),
          ChangeNotifierProvider(create: (_) => ControllerTableOpened()),
          ChangeNotifierProvider(create: (_) => ControllerAutomaticCheckout()),
          ChangeNotifierProvider(
            create: (_) => serviceLocator<ThemeController>(),
          ),
          ChangeNotifierProvider.value(value: impostazioni),
          ChangeNotifierProvider(
            create: (_) => OperatorPreferencesController(),
          ),
          ChangeNotifierProvider(
            create: (_) => AppSessionController(),
          ),
          ChangeNotifierProvider(create: (_) => ProductSearchController()),
          ChangeNotifierProvider(
            create: (_) => OrdineAttivoController(),
          ),
          ChangeNotifierProvider(
            create: (_) => OrdiniListController(),
          ),
        ],
        child: const MyApp(),
      ),
    ),
  );
}


class AdminController extends ChangeNotifier {
  bool _pinBancoAbilitato = false;

  bool get pinBancoAbilitato => _pinBancoAbilitato;

  void abilitaBanco() {
    _pinBancoAbilitato = true;
    notifyListeners();
  }
}


class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}


class _MyAppState extends State<MyApp> {

  late final FocusNode globalFocus;
  String chiavettaBuffer = '';
  DateTime? lastInputTime;
  bool stop = false;

  @override
  void initState() {
    super.initState();
    globalFocus = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) => globalFocus.requestFocus());
  }

  @override
  void dispose() {
    globalFocus.dispose();
    super.dispose();
  }

  void _onKeyEvent(KeyEvent event) {
    stop = false;
    if (event is KeyDownEvent && event.character?.isNotEmpty == true) {
      chiavettaBuffer += event.character!;
      lastInputTime = DateTime.now();
      debugPrint('MSR: $chiavettaBuffer ###########################################################################');
      Future.delayed(const Duration(milliseconds: 100), () {
        if (lastInputTime != null && DateTime.now().difference(lastInputTime!).inMilliseconds > 80) {
          _processaMSR();
        }
      });
    }
  }

  void _processaMSR() async {
    try {
      if (chiavettaBuffer == 'Out') {
        if (navigatorKey.currentContext != null) {
          Navigator.pushReplacementNamed(navigatorKey.currentContext!, '/login-operator');
        }
        chiavettaBuffer = '';
        return;
      }
      if (chiavettaBuffer.endsWith('out') && !stop) {
        stop = true;
        debugPrint('✅ CHIAVETTA MAGNETICA: $chiavettaBuffer');
        if (logInOperatorGlobalKey.currentState != null || logInOperatorGlobalKey.currentState!.mounted == false) {
          await logInOperatorGlobalKey.currentState!.magneticLogIn(chiavettaBuffer.split('out')[0]);
          chiavettaBuffer = '';
          lastInputTime = null;
          return;
        }
      }
      chiavettaBuffer = '';
      lastInputTime = null;
    } catch (err) {
      chiavettaBuffer = '';
      lastInputTime = null;
      debugPrint(err.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final imp = context.watch<ImpostazioniController>();
    return Consumer<ThemeController>(
      builder: (context, themeCtrl, _) {
        return KeyboardListener(
          focusNode: globalFocus,
          onKeyEvent: (value) {
            _onKeyEvent(value);
          },
          child: MaterialApp(
            navigatorKey: navigatorKey,
            navigatorObservers: [routeObserver],
            scaffoldMessengerKey: messengerKey,
            title: 'QFood',
            debugShowCheckedModeBanner: false,
            locale: context.locale,
            supportedLocales: context.supportedLocales + const [
              Locale('it', 'IT'),
            ],
            localizationsDelegates: [
              ...context.localizationDelegates,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            themeMode: imp.darkMode ? ThemeMode.dark : themeCtrl.themeMode,
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF95C01F),
                brightness: Brightness.light,
              ),
              scaffoldBackgroundColor: const Color(0xFFF8F8F2),
              fontFamily: GoogleFonts.inter().fontFamily,
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF95C01F),
                brightness: Brightness.dark,
              ),
              scaffoldBackgroundColor: const Color(0xFF111111),
              fontFamily: GoogleFonts.inter().fontFamily,
            ),
            initialRoute: '/',
            routes: {
              '/': (context) => const _BootstrapLoader(),
              '/login': (context) => const LoginScreen(),
              '/company': (context) => const CompanySelectorVista(),
              '/store': (context) {
                return FutureBuilder<SharedPreferences>(
                  future: SharedPreferences.getInstance(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Scaffold(
                        body: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final prefs = snapshot.data!;
                    final idAzienda = prefs.getInt("idCompany") ?? 0;
                    final nomeAzienda = prefs.getString("nomeCompany") ?? "Azienda";
                    return StoreSelectorVista(
                      idAzienda: idAzienda,
                      nomeAzienda: nomeAzienda,
                    );
                  },
                );
              },
              '/device': (context) {
                return FutureBuilder<SharedPreferences>(
                  future: SharedPreferences.getInstance(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Scaffold(
                        body: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final prefs = snapshot.data!;
                    final idStore = prefs.getInt("idStore") ?? 0;
                    final nomeStore = prefs.getString("storeTitle") ?? "Store";
                    return StoreDeviceSelectorVista(
                      idStore: idStore,
                      nomeStore: nomeStore,
                    );
                  },
                );
              },
              '/home': (context) => const HomeVista(),
              '/dashboard': (context) => const DashboardApp(),
              '/sync': (context) => const SyncVista(),
              '/reso-merce': (context) => const ResoMerceVista(),
              '/login-operator': (context) => LoginOperatorVista(key: logInOperatorGlobalKey),
              '/prenotazione': (context) => const PrenotazioniPage(),
            },
          ),
        );
      },
    );
  }
}


class _BootstrapLoader extends StatefulWidget {
  const _BootstrapLoader();

  @override
  State<_BootstrapLoader> createState() => _BootstrapLoaderState();
}

class _BootstrapLoaderState extends State<_BootstrapLoader> {
  @override
  void initState() {
    super.initState();
    _startFlow();
  }

  Future<void> _startFlow() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      debugPrint("========== SESSIONE =============");
      debugPrint("logged: ${prefs.getBool("logged")}");
      debugPrint("companySelected: ${prefs.getBool("companySelected")}");
      debugPrint("storeSelected: ${prefs.getBool("storeSelected")}");
      debugPrint("deviceSelected: ${prefs.getBool("deviceSelected")}");
      debugPrint("=================================");

      final bool logged          = prefs.getBool("logged")          ?? false;
      final bool companySelected = prefs.getBool("companySelected") ?? false;
      final bool storeSelected   = prefs.getBool("storeSelected")   ?? false;
      final bool deviceSelected  = prefs.getBool("deviceSelected")  ?? false;

      if (!logged)          return _go('/login');
      if (!companySelected) return _go('/company');
      if (!storeSelected)   return _go('/store');
      if (!deviceSelected)  return _go('/device');
      return _go('/sync');

    } catch (e) {
      debugPrint("❌ Errore durante il bootstrap: $e");
      return _go('/login');
    }
  }

  void _go(String route) {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => Navigator.pushReplacementNamed(context, route),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}