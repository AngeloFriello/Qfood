import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../filtri/prenotazioni_controller_filtri.dart';
import '../../header_footer/prenotazioni_footer.dart';
import '../../header_footer/prenotazioni_header.dart';
import 'prenotazioni_filters_bar.dart';
import 'prenotazioni_list.dart';


/*
Legge istanza da SharedPreferences
crea una sola volta PrenotazioniController
inizializza API + DB correttamente
carica il DB prima di mostrare la UI
Provider NON riceve mai un controller nullo
 */
class PrenotazioniPage extends StatefulWidget {
  const PrenotazioniPage({super.key});

  @override
  State<PrenotazioniPage> createState() => _PrenotazioniPageState();
}

class _PrenotazioniPageState extends State<PrenotazioniPage> {
  PrenotazioniController? _controller;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  Future<void> _initController() async {
    final prefs = await SharedPreferences.getInstance();
    final istanza = prefs.getString('istanza') ?? 'instance1';

    final controller = PrenotazioniController(istanza);

    debugPrint('[PAGE] INIT CONTROLLER ($istanza)');

    await controller.loadFromDb();

    if (!mounted) return;

    setState(() {
      _controller = controller;
      _ready = true;
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready || _controller == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return ChangeNotifierProvider<PrenotazioniController>.value(
      value: _controller!,
      child: const _PrenotazioniView(),
    );
  }
}

class _PrenotazioniView extends StatelessWidget {
  const _PrenotazioniView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PrenotazioniHeader(),
      body: Column(
        children: const [
          PrenotazioniFiltersBar(),
          PrenotazioniListHeaderM3(),
          Expanded(
            child: PrenotazioniList(),
          ),
        ],
      ),
      bottomNavigationBar: const PrenotazioniFooter(),
    );
  }
}
