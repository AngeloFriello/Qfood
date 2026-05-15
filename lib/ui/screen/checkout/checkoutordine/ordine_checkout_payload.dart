class OrdineCheckoutPayload {
  final String? clienteNome;
  final String? telefono;
  final String? indirizzo;
  final String? note;
  final String tipoOrdine; // 'Ritiro' | 'Consegna'
  final DateTime data;
  final List<OrdineCheckoutItem> items;

  OrdineCheckoutPayload({
    required this.clienteNome,
    required this.telefono,
    required this.indirizzo,
    required this.note,
    required this.tipoOrdine,
    required this.data,
    required this.items,
  });
}

class OrdineCheckoutItem {
  final String nome;
  final int quantita;
  final double prezzo;

  OrdineCheckoutItem({
    required this.nome,
    required this.quantita,
    required this.prezzo,
  });
}
