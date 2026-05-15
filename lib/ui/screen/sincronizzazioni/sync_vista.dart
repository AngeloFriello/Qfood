import 'dart:async';
import 'package:dashboard/Global.dart';
import 'package:dashboard/app/service/service_new_update.dart';
import 'package:dashboard/app/service/service_scheduler_document.dart';
import 'package:flutter/material.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:provider/provider.dart';
import 'sync_catalogo.dart';

class SyncVista extends StatefulWidget {
  final List<String> endpoints;

  const SyncVista({
    super.key,
    this.endpoints = const [],
  });

  @override
  State<SyncVista> createState() => _SyncVistaState();
}

class _SyncVistaState extends State<SyncVista> {
  int currentStep = 0;
  bool completed = false;
  String? error;
  static const Color qfoodGreen = Color(0xFF00A651); // Verde cappello QFood
  static const Color qfoodDark  = Color(0xFF1A1A1A);  // Nero testi/logo
  late StreamSubscription<InternetStatus> _subscription;


  @override
  void initState() {
    super.initState();
      if(!initServiceScheduler){
        initServiceScheduler = true;
        ServiceSchedulerDocument.instance().schedule();
        ServiceNewUpdate.instance().checkNewUpdate();
      }

      operatorLogged = null;
      _subscription = InternetConnection().onStatusChange.listen((status) {
    });
      WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SyncController>().onSyncComplete = () {
        if ( context.mounted ) {
          Navigator.pushNamedAndRemoveUntil(context, '/login-operator', (route) => false);
        }
      };});

    Future.delayed(Duration(seconds: 1), () {
      if (mounted) {
        SyncCatalogo.syncAll(context);
      }
    });

  }

   @override
    void dispose() {
      _subscription!.cancel();
      super.dispose();
    }

  // ------------------------------------------------------------
  // UI
  // ------------------------------------------------------------
    @override
  Widget build(BuildContext context) {

    final sync = context.watch<SyncController>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    final bool isMobile = width < 600;
    final bool isTablet = width >= 600 && width < 1100;

    return Scaffold(
      body: Container(

        /// BACKGROUND
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? const [
              Color(0xFF0F172A),
              Color(0xFF020617),
            ]
                : const [
              Color(0xFFF8FAFC),
              Color(0xFFE2E8F0),
            ],
          ),
        ),

        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {

              return SizedBox.expand(

                child: Center(
                  child: ConstrainedBox(

                    constraints: const BoxConstraints(
                      maxWidth: 520,
                    ),

                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [

                        /// LOGO
                        Hero(
                          tag: "logo",
                          child: Image.asset(
                            isDark
                                ? 'assets/logodark.png'
                                : 'assets/logoback.png',
                            height: isMobile ? 80 : 150,
                          ),
                        ),

                        const SizedBox(height: 30),

                        /// CARD
                        Container(
                          width: double.infinity,

                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 20 : 30,
                            vertical: isMobile ? 24 : 32,
                          ),

                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF111827)
                                : Colors.white,

                            borderRadius: BorderRadius.circular(28),

                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withOpacity(.05)
                                  : Colors.black.withOpacity(.05),
                            ),

                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(.15),
                                blurRadius: 40,
                                offset: const Offset(0, 30),
                              ),
                            ],
                          ),

                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [

                              /// TASK
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                child: Text(
                                  sync.currentGlobalTask ?? "Avvio sincronizzazione",
                                  key: ValueKey(sync.currentGlobalTask),
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 8),

                              Text(
                                "Step ${sync.currentGlobalStep}/${sync.totalGlobalSteps}",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: theme.colorScheme.onSurface.withOpacity(.6),
                                ),
                              ),

                              const SizedBox(height: 30),

                              /// PROGRESS CIRCLE
                              Stack(
                                alignment: Alignment.center,
                                children: [

                                  SizedBox(
                                    width: isMobile ? 90 : 120,
                                    height: isMobile ? 90 : 120,
                                    child: CircularProgressIndicator(
                                      value: sync.globalProgress.clamp(0.0, 1.0),
                                      strokeWidth: 8,
                                      color: qfoodGreen,
                                      backgroundColor: isDark
                                          ? Colors.white10
                                          : Colors.grey.shade200,
                                    ),
                                  ),

                                  Text(
                                    "${(sync.globalProgress * 100).toInt()}%",
                                    style: TextStyle(
                                      fontSize: isMobile ? 20 : 26,
                                      fontWeight: FontWeight.bold,
                                      color: qfoodGreen,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 30),

                              /// PROGRESS BAR
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: LinearProgressIndicator(
                                  value: sync.globalProgress.clamp(0.0, 1.0),
                                  minHeight: 8,
                                  backgroundColor: isDark
                                      ? Colors.white12
                                      : Colors.grey.shade200,
                                  color: qfoodGreen,
                                ),
                              ),

                              const SizedBox(height: 20),

                              /// ERRORI
                              if(sync.errors.isNotEmpty)
                                Column(
                                  children: [

                                    Text(
                                      "Sono presenti ${sync.errors.length} errori nella sincronizzazione",
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),

                                    const SizedBox(height: 12),

                                    Wrap(
                                      spacing: 10,
                                      children: [

                                        ElevatedButton(
                                          onPressed: () {
                                            SyncCatalogo.syncAll(context);
                                          },
                                          child: const Text("Riprova"),
                                        ),

                                        OutlinedButton(
                                          onPressed: () {
                                            Navigator.pushNamedAndRemoveUntil(
                                              context,
                                              '/login-operator',
                                                  (route) => false,
                                            );
                                          },
                                          child: const Text("Continua"),
                                        ),
                                      ],
                                    ),
                                  ],
                                )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }}
