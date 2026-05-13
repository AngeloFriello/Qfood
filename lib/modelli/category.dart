class CategoryModel {
  final int id;
  final String title;
  final String? description;
  final String? color;
  final int? position;
  final String? productionValue;
  final int? idProductionCenter;
  final int? availableInPos;
  final int? endMeal;
  final int? alwaysFirstCourse;
  final int? promotional;
  final String? promotionalDiscount;
  final String? printGroup;
  final String? fiscalGroup;
  final String? tipology;
  final int? idManagementUnit;
  final int? idParentCategory;
  final int? enabled;
  final int? trashed;
  final String? lastSync;

  CategoryModel({
    required this.id,
    required this.title,
    this.description,
    this.color,
    this.position,
    this.productionValue,
    this.idProductionCenter,
    this.availableInPos,
    this.endMeal,
    this.alwaysFirstCourse,
    this.promotional,
    this.promotionalDiscount,
    this.printGroup,
    this.fiscalGroup,
    this.tipology,
    this.idManagementUnit,
    this.idParentCategory,
    this.enabled,
    this.trashed,
    this.lastSync,
  });

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'title': title,
      'description': description,
      'color': color ?? '',
      'position': position,
      'productionValue': productionValue ?? '',
      'idProductionCenter': idProductionCenter,
      'availableInPos': availableInPos ?? 0,
      'endMeal': endMeal ?? 0,
      'alwaysFirstCourse': alwaysFirstCourse ?? 0,
      'promotional': promotional ?? 0,
      'promotionalDiscount': promotionalDiscount ?? '',
      'printGroup': printGroup ?? '',
      'fiscalGroup': fiscalGroup ?? '',
      'tipology': tipology ?? '',
      'idManagementUnit': idManagementUnit,
      'idParentCategory': idParentCategory,
      'enabled': enabled ?? 1,
      'trashed': trashed ?? 0,
      'lastSync': lastSync ?? '',
    };
  }

  factory CategoryModel.fromJson(Map<String, Object?> json) {
    return CategoryModel(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      color: json['color'] as String? ?? '',
      position: json['position'] as int?,
      productionValue: json['productionValue'] as String?,
      idProductionCenter: json['idProductionCenter'] as int?,
      availableInPos: json['availableInPos'] as int?,
      endMeal: json['endMeal'] as int?,
      alwaysFirstCourse: json['alwaysFirstCourse'] as int?,
      promotional: json['promotional'] as int?,
      promotionalDiscount: json['promotionalDiscount'] as String?,
      printGroup: json['printGroup'] as String?,
      fiscalGroup: json['fiscalGroup'] as String?,
      tipology: json['tipology'] as String?,
      idManagementUnit: json['idManagementUnit'] as int?,
      idParentCategory: json['idParentCategory'] as int?,
      enabled: json['enabled'] as int?,
      trashed: json['trashed'] as int?,
      lastSync: json['lastSync'] as String?,
    );
  }
}
