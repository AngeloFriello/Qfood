class SuspendedCheckout {
  final String id;
  final DateTime createdAt;
  final String? note;
  final Map<String, dynamic> payload;
  final bool isActive;

  SuspendedCheckout({
    required this.id,
    required this.createdAt,
    this.note,
    required this.payload,
    this.isActive = false,
  });

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "createdAt": createdAt.toIso8601String(),
      "note": note,
      "payload": payload,
    };
  }

  factory SuspendedCheckout.fromMap(Map<String, dynamic> map) {
    return SuspendedCheckout(
      id: map["id"],
      createdAt: DateTime.parse(map["createdAt"]),
      note: map["note"],
      payload: Map<String, dynamic>.from(map["payload"]),
    );
  }
}
