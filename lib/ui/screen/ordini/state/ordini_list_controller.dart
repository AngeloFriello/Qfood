import 'package:flutter/foundation.dart';
import 'package:dashboard/ui/screen/ordini/models/ordine.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ordine_stato.dart';
import '../models/ordine_tipo.dart';


//Gestione lista ordini + filtri
class OrdiniListController extends ChangeNotifier {

  OrdiniListController() {
    getOrders();
  }

  List<Ordine> _ordini = [];
  static const String _storageKey = 'ordini_salvati';

  OrdineTipo?  filtroTipo;
  OrdineStato? filtroStato;
  int?         idRiderFilter;
  bool         ordiniCompletati = false;

  void setFiltroOrdiniCompletati ( bool v ){
    ordiniCompletati = v;
    notifyListeners();
  }

  Future<void> getOrders () async {
    _ordini  = await Ordine.getAllOrder();
    notifyListeners(); 
  }

  void setFilterIdRider ( int? idRider ) {
    filtroTipo = OrdineTipo.consegna;
    idRiderFilter  = idRider;
    notifyListeners(); 
  }

  //gestisce il calendario
  DateTime _giornoSelezionato    = DateTime.now();
  DateTime get giornoSelezionato => _giornoSelezionato;

  void setGiorno(DateTime giorno) {
    _giornoSelezionato = DateTime(giorno.year, giorno.month, giorno.day);
    notifyListeners();
  }
  void vaiAOggi() {
    final now = DateTime.now();
    _giornoSelezionato = DateTime(now.year, now.month, now.day);
    notifyListeners();
  }

  List<Ordine> get ordiniFiltrati {
    return _ordini.where((ordine) {
      // filtro DATA (OBBLIGATORIO)
      final stessaData =
              ordine.data.year  == _giornoSelezionato.year &&
              ordine.data.month == _giornoSelezionato.month &&
              ordine.data.day   == _giornoSelezionato.day;

      if (!stessaData) return false;

      // filtro TIPO
      if (filtroTipo != null && ordine.tipo != filtroTipo) {
        return false;
      }

      // filtro STATO
      if (filtroStato != null && ordine.stato != filtroStato) {
        return false;
      }

      return true;
    }).toList().where((ordine)  {

        if ( idRiderFilter == null ) {
          return true;
        }
        
        if( idRiderFilter != null ){
          return ordine.idRider == idRiderFilter;
        }
        return true;
    }).toList().where((o) {
      if(  o.stato == OrdineStato.completato ){
          return ordiniCompletati;
      }
      return true;
    } ).toList();
  }

  int get countPrenotazioni {
    return _ordini.where(
          (o) =>
      o.stato == OrdineStato.nuovo ||
          o.stato == OrdineStato.inPreparazione,
    ).length;
  }


  // per gestire i numeri sui filtri
  int get totaleOrdini    => ordiniFiltrati.length;

  int get totaleRitiro    => ordiniFiltrati.where((o) => o.tipo == OrdineTipo.ritiro).length;

  int get totaleConsegna  => ordiniFiltrati.where((o) => o.tipo == OrdineTipo.consegna).length;

  int get totaleMangiaQui => ordiniFiltrati.where((o) => o.tipo == OrdineTipo.mangiaQui).length;


  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(_ordini.map((o) => o.toJson()).toList());
    await prefs.setString(_storageKey, json);
  }


  List<Ordine> get ordini {
    return _ordini.where((o) {
      // filtro tipo
      if (filtroTipo != null && o.tipo != filtroTipo) {
        return false;
      }

      // filtro stato
      if (filtroStato != null && o.stato != filtroStato) {
        return false;
      }

      // filtro data
      if ( o.data.day != _giornoSelezionato.day || o.data.month != _giornoSelezionato.month ||  o.data.year != _giornoSelezionato.year ) {
        return false;
      }

      return true;
    }).toList().toList().where((ordine)  {

        if ( idRiderFilter == null ) {
          return true;
        }
        
        if( idRiderFilter != null ){
          return ordine.idRider == idRiderFilter;
        }
        return true;
    }).toList().where((o) {
      if(  o.stato == OrdineStato.completato ){
          return ordiniCompletati;
      }
      return true;
    } ).toList();;
  }


  void aggiornaOrdine(Ordine ordine) async {
    final index = _ordini.indexWhere((o) => o.id == ordine.id);

    if (index != -1) {
      _ordini[index] = ordine;
      await _persist();
      notifyListeners();
    }
  }


  void setTipo(OrdineTipo? tipo) {
    filtroTipo = tipo;
    notifyListeners();
  }


  Future<void> salvaOrdine(Ordine ordine) async {
    final index = _ordini.indexWhere((o) => o.id == ordine.id);

    if (index != -1) {
      _ordini[index] = ordine;
    } else {
      _ordini.insert(0, ordine);
    }

    notifyListeners();
    await _persist();
  }



  Future<void> addOrdine(Ordine ordine) async {
    _ordini.insert(0, ordine);
    await _persist();
    notifyListeners();
  }





  void setStato(OrdineStato? stato) {
    filtroStato = stato;
    notifyListeners();
  }

  void setOrdini(List<Ordine> ordini) {
    _ordini = ordini;
    notifyListeners();
  }

  void aggiungiOrdine(Ordine ordine) {
    _ordini.insert(0, ordine);
    notifyListeners();
  }

  Future<void> rimuoviOrdine(int id) async {
    _ordini.removeWhere((o) => o.id == id);
    await _persist();
    notifyListeners();
  }

}
