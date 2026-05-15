import 'package:flutter/material.dart';

import '../db/prenotazioni_logica_db.dart';
import '../model/model_prenotazione.dart';
import '../model/prenotazione_stato.dart';
import '../ui/prenotazioni/api/prenotazioni_api_service.dart';

/*
Controller principale
carica DB
chiama API
applica filtri (data / stato / sala / turno)
 */
class PrenotazioniController extends ChangeNotifier {

  // DB
  final PrenotazioniLogicaDb _db = PrenotazioniLogicaDb();

  // API
  late final PrenotazioniApiService _api;

  PrenotazioniController(String istanza) {
    _api = PrenotazioniApiService(
      'https://$istanza-api.qfood.it',
    );
  }

  // CACHE LOCALE
  final List<Prenotazione> _tutte = [];
  List<Prenotazione> get tutte => List.unmodifiable(_tutte);

  // FILTRI
  DateTime _giorno = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );

  PrenotazioneStato? _statoFiltro;
  String _sala = 'TUTTE';
  String _turno = 'TUTTI';

  DateTime get giorno => _giorno;
  PrenotazioneStato? get statoFiltro => _statoFiltro;
  String get sala => _sala;
  String get turno => _turno;

  // LOAD DB
  Future<void> loadFromDb() async {
    debugPrint('[CTRL] LOAD DB → START');

    final items = await _db.loadAll();

    _tutte
      ..clear()
      ..addAll(items);

    notifyListeners();

    debugPrint('[CTRL] LOAD DB → END (${_tutte.length})');
  }

  // ADD (API + DB)
  Future<void> add(Prenotazione p) async {
    debugPrint('[CTRL] ADD → START');

    try {
      await _api.creaPrenotazione(p);
      debugPrint('[CTRL] API OK');
    } catch (e) {
      debugPrint('[CTRL] → $e');
    }

    await _db.save(p);
    await loadFromDb();

    debugPrint('[CTRL] ADD → END');
  }

  // UPDATE
  Future<void> update(Prenotazione p) async {
    debugPrint('[CTRL] UPDATE → ID=${p.id}');
    await _db.delete(p.id);
    await _db.save(p);
    await loadFromDb();
  }

  // DELETE
  Future<void> remove(int id) async {
    debugPrint('[CTRL] DELETE → ID=$id');
    await _db.delete(id);
    await loadFromDb();
  }

  // LISTA FILTRATA (UI)
  List<Prenotazione> get filtrate {
    final list = _tutte.where((p) {
      if (!_sameDay(p.data, _giorno)) return false;
      if (_statoFiltro != null && p.stato != _statoFiltro) return false;
      if (_sala != 'TUTTE' && p.sala != _sala) return false;

      if (_turno != 'TUTTI') {
        final h = p.orario.hour;
        if (_turno == 'MATTINO' && h >= 14) return false;
        if (_turno == 'SERA' && h < 14) return false;
      }

      return true;
    }).toList();

    list.sort((a, b) => a.startDateTime.compareTo(b.startDateTime));
    return list;
  }

  // FILTRI UI
  void setGiorno(DateTime d) {
    _giorno = DateTime(d.year, d.month, d.day);
    notifyListeners();
  }

  void setStato(PrenotazioneStato? s) {
    _statoFiltro = s;
    notifyListeners();
  }

  void setSala(String s) {
    _sala = s;
    notifyListeners();
  }

  void setTurno(String t) {
    _turno = t;
    notifyListeners();
  }

  void reset() {
    _giorno = DateTime.now();
    _statoFiltro = null;
    _sala = 'TUTTE';
    _turno = 'TUTTI';
    notifyListeners();
  }

  // UTILS
  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

