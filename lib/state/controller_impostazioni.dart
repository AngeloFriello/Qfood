import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ImpostazioniController extends ChangeNotifier {
  // Tutte le impostazioni disponibili
  bool nomeBreveProdotti = false;
  String grandezzaNomeProdotti = "M";
  String grandezzaNomeBreveProdotti = "M";
  String uiSide = "R"; // R = destro, L = mancino
  bool carrelloInvertito = false;
  bool stampaComandeBanco = false;
  bool visualizzaOrdiniCompletati = true;
  bool visualizzaDettaglioOrdine = true;
  bool visualizzazioneProdottiRidotta = false;
  bool visualizzazioneTavoliRidotta = false;
  bool visualizzazioneCategorieIngrandita = false;
  bool visualizzaUtenteTavolo = true;
  bool aperturaTavoloInPresaComanda = true;
  bool invioOrdineSenzaUscire = false;
  bool rimuoviFiltriProdotto = false;
  bool rimuoviFiltriRicerca = false;
  bool focusPrezzoGenerico = false;
  bool saltaRichiestaScontrino = false;
  bool darkMode = false;
  // NOVITÀ dal nuovo file
  bool extendedCart = false;

  bool loading = true;

  // Carica tutte le impostazioni all'avvio
  Future<void> carica() async {
    final prefs = await SharedPreferences.getInstance();

    nomeBreveProdotti =
        prefs.getBool('nomeBreveProdotti') ?? false;
    await prefs.setString(
      'grandezzaNomeProdotti',
      grandezzaNomeProdotti,
    );
    await prefs.setString(
      'grandezzaNomeBreveProdotti',
      grandezzaNomeBreveProdotti,
    );
    carrelloInvertito =
        prefs.getBool('carrelloInvertito') ?? false;
    stampaComandeBanco =
        prefs.getBool('stampaComandeBanco') ?? false;
    visualizzaOrdiniCompletati =
        prefs.getBool('visualizzaOrdiniCompletati') ?? true;
    visualizzaDettaglioOrdine =
        prefs.getBool('visualizzaDettaglioOrdine') ?? true;
    visualizzazioneProdottiRidotta =
        prefs.getBool('visualizzazioneProdottiRidotta') ??
            false;
    visualizzazioneTavoliRidotta =
        prefs.getBool('visualizzazioneTavoliRidotta') ??
            false;
    visualizzazioneCategorieIngrandita =
        prefs.getBool(
              'visualizzazioneCategorieIngrandita',
            ) ??
            false;
    visualizzaUtenteTavolo =
        prefs.getBool('visualizzaUtenteTavolo') ?? true;
    aperturaTavoloInPresaComanda =
        prefs.getBool('aperturaTavoloInPresaComanda') ??
            true;
    invioOrdineSenzaUscire =
        prefs.getBool('invioOrdineSenzaUscire') ?? false;
    rimuoviFiltriProdotto =
        prefs.getBool('rimuoviFiltriProdotto') ?? false;
    rimuoviFiltriRicerca =
        prefs.getBool('rimuoviFiltriRicerca') ?? false;
    uiSide = prefs.getString('uiSide') ?? "R";
    focusPrezzoGenerico =
        prefs.getBool('focusPrezzoGenerico') ?? false;
    saltaRichiestaScontrino =
        prefs.getBool('saltaRichiestaScontrino') ?? false;
    darkMode = prefs.getBool('darkMode') ?? false;
    // extendedCart non viene ancora letto/salvato in prefs

    loading = false;
    notifyListeners();
  }

  // Aggiorna una singola impostazione e la salva
  Future<void> aggiorna(
    String chiave,
    dynamic valore,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    switch (chiave) {
      case 'nomeBreveProdotti':
        nomeBreveProdotti = valore;
        await prefs.setBool(chiave, valore);
        break;
      case 'grandezzaNomeProdotti':
        grandezzaNomeProdotti = valore;
        await prefs.setString(chiave, valore);
        break;
      case 'grandezzaNomeBreveProdotti':
        grandezzaNomeBreveProdotti = valore;
        await prefs.setString(chiave, valore);
        break;
      case 'carrelloInvertito':
        carrelloInvertito = valore;
        await prefs.setBool(chiave, valore);
        break;
      case 'stampaComandeBanco':
        stampaComandeBanco = valore;
        await prefs.setBool(chiave, valore);
        break;
      case 'visualizzaOrdiniCompletati':
        visualizzaOrdiniCompletati = valore;
        await prefs.setBool(chiave, valore);
        break;
      case 'visualizzaDettaglioOrdine':
        visualizzaDettaglioOrdine = valore;
        await prefs.setBool(chiave, valore);
        break;
      case 'visualizzazioneProdottiRidotta':
        visualizzazioneProdottiRidotta = valore;
        await prefs.setBool(chiave, valore);
        break;
      case 'visualizzazioneTavoliRidotta':
        visualizzazioneTavoliRidotta = valore;
        await prefs.setBool(chiave, valore);
        break;
      case 'uiSide':
        uiSide = valore;
        await prefs.setString(chiave, valore);
        break;
      case 'visualizzazioneCategorieIngrandita':
        visualizzazioneCategorieIngrandita = valore;
        await prefs.setBool(chiave, valore);
        break;
      case 'visualizzaUtenteTavolo':
        visualizzaUtenteTavolo = valore;
        await prefs.setBool(chiave, valore);
        break;
      case 'aperturaTavoloInPresaComanda':
        aperturaTavoloInPresaComanda = valore;
        await prefs.setBool(chiave, valore);
        break;
      case 'invioOrdineSenzaUscire':
        invioOrdineSenzaUscire = valore;
        await prefs.setBool(chiave, valore);
        break;
      case 'rimuoviFiltriProdotto':
        rimuoviFiltriProdotto = valore;
        await prefs.setBool(chiave, valore);
        break;
      case 'rimuoviFiltriRicerca':
        rimuoviFiltriRicerca = valore;
        await prefs.setBool(chiave, valore);
        break;
      case 'focusPrezzoGenerico':
        focusPrezzoGenerico = valore;
        await prefs.setBool(chiave, valore);
        break;
      case 'saltaRichiestaScontrino':
        saltaRichiestaScontrino = valore;
        await prefs.setBool(chiave, valore);
        break;
      case 'darkMode':
        darkMode = valore;
        await prefs.setBool(chiave, valore);
        break;
      // extendedCart per ora è solo in memoria (non persistito)
    }

    notifyListeners();
  }

  // Forza salvataggio di tutte le impostazioni correnti
  Future<void> salvaTutte() async {
    final prefs = await SharedPreferences.getInstance();

    debugPrint("💾 Salvataggio impostazioni…");

    await prefs.setBool(
      'nomeBreveProdotti',
      nomeBreveProdotti,
    );
    await prefs.setString(
      'grandezzaNomeProdotti',
      grandezzaNomeProdotti,
    );
    await prefs.setString(
      'grandezzaNomeBreveProdotti',
      grandezzaNomeBreveProdotti,
    );
    await prefs.setBool(
      'carrelloInvertito',
      carrelloInvertito,
    );
    await prefs.setBool(
      'stampaComandeBanco',
      stampaComandeBanco,
    );
    await prefs.setBool(
      'visualizzaOrdiniCompletati',
      visualizzaOrdiniCompletati,
    );
    await prefs.setBool(
      'visualizzaDettaglioOrdine',
      visualizzaDettaglioOrdine,
    );
    await prefs.setBool(
      'visualizzazioneProdottiRidotta',
      visualizzazioneProdottiRidotta,
    );
    await prefs.setBool(
      'visualizzazioneTavoliRidotta',
      visualizzazioneTavoliRidotta,
    );
    await prefs.setBool(
      'visualizzazioneCategorieIngrandita',
      visualizzazioneCategorieIngrandita,
    );
    await prefs.setBool(
      'visualizzaUtenteTavolo',
      visualizzaUtenteTavolo,
    );
    await prefs.setBool(
      'aperturaTavoloInPresaComanda',
      aperturaTavoloInPresaComanda,
    );
    await prefs.setBool(
      'invioOrdineSenzaUscire',
      invioOrdineSenzaUscire,
    );
    await prefs.setBool(
      'rimuoviFiltriProdotto',
      rimuoviFiltriProdotto,
    );
    await prefs.setBool(
      'rimuoviFiltriRicerca',
      rimuoviFiltriRicerca,
    );
    await prefs.setBool(
      'focusPrezzoGenerico',
      focusPrezzoGenerico,
    );
    await prefs.setBool(
      'saltaRichiestaScontrino',
      saltaRichiestaScontrino,
    );
    await prefs.setBool('darkMode', darkMode);
    await prefs.setString('uiSide', uiSide);
    // extendedCart non viene ancora salvato

    notifyListeners();
  }
}


/* import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ImpostazioniController extends ChangeNotifier {
  //  Tutte le impostazi/*  */oni disponibili
  bool nomeBreveProdotti = false;
  String grandezzaNomeProdotti = "M";
  String grandezzaNomeBreveProdotti = "M";
  String uiSide = "R"; // R = destro, L = mancino
  bool carrelloInvertito = false;
  bool stampaComandeBanco = false;
  bool visualizzaOrdiniCompletati = true;
  bool visualizzaDettaglioOrdine = true;
  bool visualizzazioneProdottiRidotta = false;
  bool visualizzazioneTavoliRidotta = false;
  bool visualizzazioneCategorieIngrandita = false;
  bool visualizzaUtenteTavolo = true;
  bool aperturaTavoloInPresaComanda = true;
  bool invioOrdineSenzaUscire = false;
  bool rimuoviFiltriProdotto = false;
  bool rimuoviFiltriRicerca = false;
  bool focusPrezzoGenerico = false;
  bool saltaRichiestaScontrino = false;
  bool darkMode = false;

  bool loading = true;

  //  Carica tutte le impostazioni all'avvio
  Future<void> carica() async {
    final prefs = await SharedPreferences.getInstance();

    nomeBreveProdotti = prefs.getBool('nomeBreveProdotti') ?? false;
    await prefs.setString('grandezzaNomeProdotti', grandezzaNomeProdotti);
    await prefs.setString('grandezzaNomeBreveProdotti', grandezzaNomeBreveProdotti);
    carrelloInvertito = prefs.getBool('carrelloInvertito') ?? false;
    stampaComandeBanco = prefs.getBool('stampaComandeBanco') ?? false;
    visualizzaOrdiniCompletati = prefs.getBool('visualizzaOrdiniCompletati') ?? true;
    visualizzaDettaglioOrdine = prefs.getBool('visualizzaDettaglioOrdine') ?? true;
    visualizzazioneProdottiRidotta = prefs.getBool('visualizzazioneProdottiRidotta') ?? false;
    visualizzazioneTavoliRidotta = prefs.getBool('visualizzazioneTavoliRidotta') ?? false;
    visualizzazioneCategorieIngrandita = prefs.getBool('visualizzazioneCategorieIngrandita') ?? false;
    visualizzaUtenteTavolo = prefs.getBool('visualizzaUtenteTavolo') ?? true;
    aperturaTavoloInPresaComanda = prefs.getBool('aperturaTavoloInPresaComanda') ?? true;
    invioOrdineSenzaUscire = prefs.getBool('invioOrdineSenzaUscire') ?? false;
    rimuoviFiltriProdotto = prefs.getBool('rimuoviFiltriProdotto') ?? false;
    rimuoviFiltriRicerca = prefs.getBool('rimuoviFiltriRicerca') ?? false;
    uiSide = prefs.getString('uiSide') ?? "R";
    focusPrezzoGenerico = prefs.getBool('focusPrezzoGenerico') ?? false;
    saltaRichiestaScontrino = prefs.getBool('saltaRichiestaScontrino') ?? false;
    darkMode = prefs.getBool('darkMode') ?? false;

    loading = false;
    notifyListeners();
  }

  //  Aggiorna una singola impostazione e la salva
  Future<void> aggiorna(String chiave, dynamic valore) async {
    final prefs = await SharedPreferences.getInstance();

    switch (chiave) {
      case 'nomeBreveProdotti':
        nomeBreveProdotti = valore;
        await prefs.setBool(chiave, valore);
        break;
      case 'grandezzaNomeProdotti':
        grandezzaNomeProdotti = valore;
        await prefs.setString(chiave, valore);
        break;
      case 'grandezzaNomeBreveProdotti':
        grandezzaNomeBreveProdotti = valore;
        await prefs.setString(chiave, valore);
        break;
      case 'carrelloInvertito':
        carrelloInvertito = valore;
        await prefs.setBool(chiave, valore);
        break;
      case 'stampaComandeBanco':
        stampaComandeBanco = valore;
        await prefs.setBool(chiave, valore);
        break;
      case 'visualizzaOrdiniCompletati':
        visualizzaOrdiniCompletati = valore;
        await prefs.setBool(chiave, valore);
        break;
      case 'visualizzaDettaglioOrdine':
        visualizzaDettaglioOrdine = valore;
        await prefs.setBool(chiave, valore);
        break;
      case 'visualizzazioneProdottiRidotta':
        visualizzazioneProdottiRidotta = valore;
        await prefs.setBool(chiave, valore);
        break;
      case 'visualizzazioneTavoliRidotta':
        visualizzazioneTavoliRidotta = valore;
        await prefs.setBool(chiave, valore);
        break;
      case 'uiSide':
        uiSide = valore;
        await prefs.setString(chiave, valore);
        break;
      case 'visualizzazioneCategorieIngrandita':
        visualizzazioneCategorieIngrandita = valore;
        await prefs.setBool(chiave, valore);
        break;
      case 'visualizzaUtenteTavolo':
        visualizzaUtenteTavolo = valore;
        await prefs.setBool(chiave, valore);
        break;
      case 'aperturaTavoloInPresaComanda':
        aperturaTavoloInPresaComanda = valore;
        await prefs.setBool(chiave, valore);
        break;
      case 'invioOrdineSenzaUscire':
        invioOrdineSenzaUscire = valore;
        await prefs.setBool(chiave, valore);
        break;
      case 'rimuoviFiltriProdotto':
        rimuoviFiltriProdotto = valore;
        await prefs.setBool(chiave, valore);
        break;
      case 'rimuoviFiltriRicerca':
        rimuoviFiltriRicerca = valore;
        await prefs.setBool(chiave, valore);
        break;
      case 'focusPrezzoGenerico':
        focusPrezzoGenerico = valore;
        await prefs.setBool(chiave, valore);
        break;
      case 'saltaRichiestaScontrino':
        saltaRichiestaScontrino = valore;
        await prefs.setBool(chiave, valore);
        break;
      case 'darkMode':
        darkMode = valore;
        await prefs.setBool(chiave, valore);
        break;
    }

    notifyListeners();
  }

  //  Forza salvataggio di tutte le impostazioni correnti
  Future<void> salvaTutte() async {
    final prefs = await SharedPreferences.getInstance();

    debugPrint("💾 Salvataggio impostazioni…");


    await prefs.setBool('nomeBreveProdotti', nomeBreveProdotti);
    await prefs.setString('grandezzaNomeProdotti', grandezzaNomeProdotti);
    await prefs.setString('grandezzaNomeBreveProdotti', grandezzaNomeBreveProdotti);
    await prefs.setBool('carrelloInvertito', carrelloInvertito);
    await prefs.setBool('stampaComandeBanco', stampaComandeBanco);
    await prefs.setBool('visualizzaOrdiniCompletati', visualizzaOrdiniCompletati);
    await prefs.setBool('visualizzaDettaglioOrdine', visualizzaDettaglioOrdine);
    await prefs.setBool('visualizzazioneProdottiRidotta', visualizzazioneProdottiRidotta);
    await prefs.setBool('visualizzazioneTavoliRidotta', visualizzazioneTavoliRidotta);
    await prefs.setBool('visualizzazioneCategorieIngrandita', visualizzazioneCategorieIngrandita);
    await prefs.setBool('visualizzaUtenteTavolo', visualizzaUtenteTavolo);
    await prefs.setBool('aperturaTavoloInPresaComanda', aperturaTavoloInPresaComanda);
    await prefs.setBool('invioOrdineSenzaUscire', invioOrdineSenzaUscire);
    await prefs.setBool('rimuoviFiltriProdotto', rimuoviFiltriProdotto);
    await prefs.setBool('rimuoviFiltriRicerca', rimuoviFiltriRicerca);
    await prefs.setBool('focusPrezzoGenerico', focusPrezzoGenerico);
    await prefs.setBool('saltaRichiestaScontrino', saltaRichiestaScontrino);
    await prefs.setBool('darkMode', darkMode);
    await prefs.setString('uiSide', uiSide);

    notifyListeners();
  }
}
 */