

import '../models/ordine.dart';
import '../models/ordine_stato.dart';



//Decide il flusso corretto, non solo sì/no
/*
Questo governa:
popup “Cambia stato”
pulsante “Partenza”
automazioni future
 */
class OrdiniFlow {
  static OrdineStato? nextStato(Ordine ordine) {
    switch (ordine.stato) {
      case OrdineStato.nuovo:
        return OrdineStato.inPreparazione;
      case OrdineStato.inPreparazione:
        return OrdineStato.pronto;
      case OrdineStato.pronto:
        return OrdineStato.partito;
      case OrdineStato.partito:
        return OrdineStato.completato;
      case OrdineStato.completato:
      case OrdineStato.annullato:
        return null;
    }
  }

  static bool canChangeTo(
      Ordine ordine,
      OrdineStato nuovoStato,
      ) {
    if (ordine.stato.isFinale) return false;

    final allowed = <OrdineStato>{
      ordine.stato,
      if (nextStato(ordine) != null) nextStato(ordine)!,
      OrdineStato.annullato,
    };

    return allowed.contains(nuovoStato);
  }
}
