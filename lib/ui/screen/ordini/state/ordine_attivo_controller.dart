import 'package:dashboard/modelli/customer.dart';
import 'package:flutter/foundation.dart';
import 'package:dashboard/ui/screen/ordini/models/ordine.dart';
import 'ordine_state.dart';

class OrdineAttivoController extends ChangeNotifier {
  OrdineState _state = const OrdineState();
  OrdineState get state => _state;
  Ordine? get ordine => _state.ordine;
  bool get hasOrdine => _state.hasOrdine;
  bool get isDirty => _state.isDirty;

  void updateHeader({
    CustomerModel? cliente,
    String? telefono,
    String? indirizzo,
  }) {
    if (_state.ordine == null) return;

    _state = _state.copyWith(
      ordine: _state.ordine!.copyWith(
        cliente: cliente ?? _state.ordine!.cliente,
        telefono: telefono ?? _state.ordine!.telefono,
        indirizzo: indirizzo ?? _state.ordine!.indirizzo,
      ),
      isDirty: true,
    );

    notifyListeners();
  }


  /// Aggancia un ordine al carrello
  void setOrdine(Ordine ordine) {
    _state = OrdineState(
      ordine: ordine,
      isDirty: false,
    );
    notifyListeners();
  }

  /// Aggiorna l’ordine (modifica prodotti, note, ecc.)
  void updateOrdine(Ordine ordine) {
    _state = _state.copyWith(
      ordine: ordine,
      isDirty: true,
    );
    notifyListeners();
  }

  /// Salva modifiche (chiamata API esterna)
  void markSaved() {
    _state = _state.copyWith(isDirty: false);
    notifyListeners();
  }

  /// Sgancia l’ordine → carrello libero
  void clearOrdine() {
    _state = const OrdineState();
    notifyListeners();
  }
}
