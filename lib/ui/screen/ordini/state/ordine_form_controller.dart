import 'package:dashboard/modelli/customer.dart';
import 'package:flutter/foundation.dart';
import 'package:dashboard/ui/screen/ordini/models/ordine.dart';
import '../models/ordine_item.dart';
import '../models/ordine_stato.dart';
import '../models/ordine_tipo.dart';



/*
Usato solo per:
nuovo ordine
modifica consegna/ritiro
NON tocca il carrello finché non premi Conferma
 */
class OrdineFormController extends ChangeNotifier {
  CustomerModel? cliente;

  OrdineTipo tipo = OrdineTipo.consegna;
  DateTime data = DateTime.now();
  String? telefono;
  String? indirizzo;
  String? note;
  final List<OrdineItem> items = [];

  void reset() {
    CustomerModel? cliente;
    tipo = OrdineTipo.consegna;
    data = DateTime.now();
    telefono = null;
    indirizzo = null;
    note = null;
    items.clear();
    notifyListeners();
  }

/*   Ordine buildOrdine() {
    return Ordine(
      nomeCliente: ,
      id: DateTime.now().millisecondsSinceEpoch,
      cliente: cliente!,
      tipo: tipo,
      stato: OrdineStato.nuovo,
      data: data,
      articles: List.from(items),
      telefono: telefono,
      indirizzo: indirizzo,
      note: note,
      paid: 0
    );
  } */

}
