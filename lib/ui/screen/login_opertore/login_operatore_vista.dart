import 'dart:convert';
import 'package:dashboard/Global.dart';
import 'package:dashboard/app/service/Service_Socket/ServiceOrderSelOrdering.dart';
import 'package:dashboard/app/service/Service_Socket/service_ws_client.dart';
import 'package:dashboard/app/service/Service_Socket/service_self_order_polling.dart';
import 'package:dashboard/app/service/service_log_pos.dart';
import 'package:dashboard/modelli/operator.dart';
import 'package:dashboard/ui/screen/sincronizzazioni/databasesql_lite/local_db.dart';
import 'package:dashboard/ui/screen/sincronizzazioni/operatori/operator_preferences_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';



class LoginOperatorVista extends StatefulWidget {
  const LoginOperatorVista({super.key});

  @override
  State<LoginOperatorVista> createState() => LoginOperatorVistaState();

}

class LoginOperatorVistaState extends State<LoginOperatorVista> {
  final TextEditingController _pinController = TextEditingController();
  bool disabledPin = true;

  @override
  void initState() {
     _initWsForNewOperator();
    ServiceOrderSelOrdering.instance().connect();
    super.initState();
  }

  Future<void> _initWsForNewOperator() async {
    try {
      await ServiceWsClient.instance().destroy();
    } catch (_) {
    }

  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final size = MediaQuery.of(context).size;
    final width = size.width;

    final bool isMobile = width < 600;
    final bool isTablet = width >= 600 && width < 1100;
    final bool isDesktop = width >= 1100;



    return Scaffold(
      body: Container(

        /// BACKGROUND GRADIENT
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
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),

              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  /// LOGO
                  Hero(
                    tag: 'logo',
                    child: Image.asset(
                      isDark
                          ? 'assets/logodark.png'
                          : 'assets/logoback.png',
                      height: isDesktop
                          ? 200
                          : isTablet
                          ? 160
                          : 120,
                    ),
                  ),

                  const SizedBox(height: 32),

                  /// TITOLO
                  Text(
                    "PIN Operatore",
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),

                  const SizedBox(height: 28),

                  /// CARD LOGIN
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 20 : 28,
                      vertical: isMobile ? 26 : 34,
                    ),

                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF111827)
                          : Colors.white,

                      borderRadius: BorderRadius.circular(24),

                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(.05)
                            : Colors.black.withOpacity(.04),
                      ),

                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(.15),
                          blurRadius: 30,
                          offset: const Offset(0, 20),
                        ),
                      ],
                    ),

                    child: Column(
                      children: [

                        /// PIN FIELD
                        SizedBox(
                          width: 220,
                          child: TextField(
                            enabled: disabledPin,
                            controller: _pinController,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,

                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 8,
                            ),

                            decoration: InputDecoration(

                              hintText: "••••••",

                              hintStyle: TextStyle(
                                letterSpacing: 8,
                                color: Colors.grey.withOpacity(.6),
                              ),

                              filled: true,

                              fillColor: isDark
                                  ? const Color(0xFF1F2937)
                                  : const Color(0xFFF3F4F6),

                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),

                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: theme.colorScheme.primary,
                                  width: 2,
                                ),
                              ),

                              counterText: '',
                            ),

                            onChanged: (value) async {
                             await login(value);
                            },
                          ),
                        ),

                        const SizedBox(height: 22),

                        /// LOADING
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: disabledPin
                              ? const SizedBox()
                              : const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  /// PULSANTE ESCI
                  FilledButton.icon(
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/login',
                          (route) => false,
                    ),
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text("Esci"),

                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 16,
                      ),

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> login( String pin  ) async {
    try{
      
      if( pin.length < 6) return;
      setState(() {
        disabledPin = false;
      });
      final resQuery = await LocalDB.query('SELECT * FROM operators WHERE accessCode = "${pin}"')
                        .catchError((err) => writeLogOnFile("catchError query login", err.toString(), trace: StackTrace.current));

      writeLogOnFile("risposta query pin", resQuery.toString(), trace: StackTrace.current);                
      List<OperatoreModel> operator = resQuery.map((e) => OperatoreModel.fromJson(e)).toList();
      if(operator.isNotEmpty){
        operatorLogged = operator[0];
        setPreferenceOperator(context, resQuery[0]);
        final nome = operatorLogged?.firstname ?? 'Operatore';

        //AVVIO  LA WS DOPO IL LOGIN OPERATORE
        try{
          SharedPreferences pref = await SharedPreferences.getInstance();
          dynamic device   = jsonDecode(pref.getString('device') ?? '{}');
          if( device == null || device.isEmpty ) return;
          int isServer = device['deviceServer']; 

          //START DEL SERVER SE SI TRATTA DI UN SERVER
          if( isServer == 0 ){
            ServiceWsClient.instance().connect();
          }
    
        }catch( err ){
          debugPrint(err.toString());
        }
        
        LogService.instance().saveLog('login', 'accesso con pin', '');

        final snackBar = SnackBar(
          content: Text('Benvenuto $nome! 👋'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        );
      
        await ScaffoldMessenger.of(context).showSnackBar(snackBar).closed;
        Navigator.pushReplacementNamed(context, '/home');
        return;
      } else {
        
        await ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('PIN errato!'), duration: Duration(seconds: 1),)).closed;
        setState(() {
          disabledPin = true;
        });
      }
      
    }catch(err){
      writeLogOnFile('Login operatore', err.toString(), trace: StackTrace.current);
      setState(() {
        disabledPin = true;
      });
      await ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Errore operatori!'), duration: Duration(seconds: 1),)).closed;
      debugPrint(err.toString());
      }
  }


  Future<void> magneticLogIn( String pin  ) async {
    try{
      
      if( pin.length < 6) return;
      setState(() {
        disabledPin = false;
      });
      final resQuery = await LocalDB.query('SELECT * FROM operators WHERE magneticKeyCode = "${pin}"')
                        .catchError((err) => writeLogOnFile("catchError query login", err.toString(), trace: StackTrace.current));

      writeLogOnFile("risposta query pin", resQuery.toString(), trace: StackTrace.current);                
      List<OperatoreModel> operator = resQuery.map((e) => OperatoreModel.fromJson(e)).toList();
      if(operator.isNotEmpty){
        operatorLogged = operator[0];
        final nome = operatorLogged?.firstname ?? 'Operatore';

        //AVVIO  LA WS DOPO IL LOGIN OPERATORE
        try{
          SharedPreferences pref = await SharedPreferences.getInstance();
          dynamic device   = jsonDecode(pref.getString('device') ?? '{}');
          if( device == null || device.isEmpty ) return;
          int isServer = device['deviceServer']; 

          //START DEL SERVER SE SI TRATTA DI UN SERVER
          if( isServer == 0 ){
            ServiceWsClient.instance().connect();
          }
          
       
        }catch( err ){
          debugPrint(err.toString());
        }

        final snackBar = SnackBar(
          content: Text('Benvenuto $nome! 👋'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        );
      
        await ScaffoldMessenger.of(context).showSnackBar(snackBar).closed;
        Navigator.pushReplacementNamed(context, '/home');
        return;
      } else {
        
        await ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('PIN errato!'), duration: Duration(seconds: 1),)).closed;
        setState(() {
          disabledPin = true;
        });
      }
      
    }catch(err){
      writeLogOnFile('Login operatore', err.toString(), trace: StackTrace.current);
      setState(() {
        disabledPin = true;
      });
      await ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Errore operatori!'), duration: Duration(seconds: 1),)).closed;
      debugPrint(err.toString());
      }
  }
}


void setPreferenceOperator( BuildContext ctx, dynamic operator  ){
  try{
      if( operatorLogged == null ) return;
      final ctrOperatorSetting = ctx.read<OperatorPreferencesController>();
      ctrOperatorSetting.loadFromApi(operator);
  }catch( err ){
    debugPrint( err.toString() );
  }

}

