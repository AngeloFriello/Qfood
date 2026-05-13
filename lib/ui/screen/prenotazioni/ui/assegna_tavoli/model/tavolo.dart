class Tavolo {
  final int id;        // ID backend (482, 483…)
  final String nome;   // "Tavolo 1"
  final int capienza;

  Tavolo({
    required this.id,
    required this.nome,
    required this.capienza,
  });

  factory Tavolo.fromJson(Map<String, dynamic> json) {
    return Tavolo(
      id: json['id'],
      nome: json['nome'],
      capienza: json['capienza'],
    );
  }
}
