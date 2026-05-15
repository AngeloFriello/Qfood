
class OrdineItem {
  final int idArticolo;
  final String nome;
  final int quantita;
  final double prezzoUnitario;
  final double iva;

  OrdineItem({
    required this.idArticolo,
    required this.nome,
    required this.quantita,
    required this.prezzoUnitario,
    required this.iva,
  });


  factory OrdineItem.fromJson(Map<String, dynamic> json) => OrdineItem(
    idArticolo: json['idArticolo'],
    nome: json['nome'],
    quantita: json['quantita'],
    prezzoUnitario: (json['prezzoUnitario'] as num).toDouble(),
    iva: (json['iva'] as num).toDouble(),
  );

  Map<String, dynamic> toJson() => {
    'idArticolo': idArticolo,
    'nome': nome,
    'quantita': quantita,
    'prezzoUnitario': prezzoUnitario,
    'iva': iva,
  };


  ///  MAPPER DAL CARRELLO
 /*  factory OrdineItem.fromCarrello(ProdottoCarrello p) {
    return OrdineItem(
      idArticolo: p.idArticle,
      nome: p.nome,
      quantita: p.quantita,
      prezzoUnitario: p.prezzo,
      iva: p.vatValue,
    );
  } */

  double get totale => prezzoUnitario * quantita;
}
