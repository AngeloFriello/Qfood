class VatRateModel {
  final int id;
  final String title;
  final String? value;
  final String? nature;
  final int? departmentNumber;
  final int? trashed;
  final int? enabled;
  final String? lastSync;

  VatRateModel({
    required this.id,
    required this.title,
    this.value,
    this.nature,
    this.departmentNumber,
    this.trashed,
    this.enabled,
    this.lastSync,
  });

  Map<String, Object?> toMap() {
    return <String, Object?>{
      "id" : id,
      "title" : title,
      "value" : value,
      "departmentNumber" : departmentNumber,
      "nature" : nature,
      "trashed" : trashed,
      "enabled" : enabled,
      "lastSync" : lastSync
    };
  }

  factory VatRateModel.fromJson(Map<String, Object?> json) {
    return VatRateModel(
      id: json['id'] as int,
      title: json['title'] as String,
      value: json['value'] as String?,
      nature: json['nature'] as String?,
      departmentNumber: json['departmentNumber'] as int?,
      trashed: json['trashed'] as int?,
      enabled: json['enabled'] as int?,
      lastSync: json['lastSync'] as String?,
    );
  }
}
