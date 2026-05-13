

import '../models/ordine.dart';
import '../models/ordine_stato.dart';


//Decide cosa è consentito
class OrdiniPermissions {
  static bool canEditOrdine(Ordine ordine) {
    return !ordine.stato.isFinale;
  }

  static bool canChangeStato(Ordine ordine) {
    return ordine.stato != OrdineStato.annullato;
  }

  static bool canAddItems(Ordine ordine) {
    return ordine.stato == OrdineStato.nuovo ||
        ordine.stato == OrdineStato.inPreparazione;
  }

  static bool canRemoveItems(Ordine ordine) {
    return canAddItems(ordine);
  }

  static bool canStartConsegna(Ordine ordine) {
    return ordine.stato == OrdineStato.pronto &&
        ordine.tipo.name == 'consegna';
  }

  static bool canGoToPagamento(Ordine ordine) {
    return ordine.stato != OrdineStato.annullato;
  }

  static bool canDelete(Ordine ordine) {
    return ordine.stato == OrdineStato.nuovo;
  }
}
