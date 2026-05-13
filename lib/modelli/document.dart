import 'dart:convert';

import 'package:dashboard/modelli/articleInCart.dart';

class Documento {
  final int? id;
  int? idReal;
  int? assignedDocumentNumber;
  final String title;
  final String realDate;
  final String jobDate;
  String? documentRtNumber;
  String? documentRtCloseNumber;
  final double amount;
  final double amountTaxable;
  final double amountTax;
  final double amountRt;
  final double receiptRounding;
  double? tips;
  final double remainder;
  final String platform;
  final int printed;
  String? printedAt;
  final int idDevice;
  final int idOperator;
  int? idCustomer;
  final List<Line> lines;
  final List<Payment> payments;
  final double? footDiscount;
  final int? idRateFootDiscount;
  final String? overrideMovementType;
  int? idDocumentReference;
  List<ProdottoCarrello> copyCart;
  int? idTable;
  String? deletedBy; 
  String? deleteNumber;
  String? discountReason;
  String? deliveryService; //glovo, alfonsino, justEat, deliveroo, takeAway
  String? uuid_riga_turno;
  int invoice_paid;
  int credit_note_exclude_total_report;

  Documento({
    required this.title,
    this.id,
    this.idReal,
    required this.realDate,
    required this.jobDate,
    this.documentRtNumber,
    this.documentRtCloseNumber,
    required this.amount,
    required this.amountTaxable,
    required this.amountTax,
    required this.amountRt,
    required this.receiptRounding,
    this.tips,
    required this.remainder,
    required this.platform,
    required this.printed,
    this.printedAt,
    required this.idDevice,
    required this.idOperator,
    this.idCustomer,
    required this.lines,
    required this.payments,
    this.footDiscount,
    this.idRateFootDiscount,
    this.overrideMovementType,
    this.idDocumentReference,
    required this.copyCart,
    this.idTable,
    this.deletedBy,
    this.deleteNumber,
    this.assignedDocumentNumber,
    this.discountReason,
    this.deliveryService,
    required this.uuid_riga_turno,
    required this.invoice_paid,
    required this.credit_note_exclude_total_report
  });

  factory Documento.fromJson(Map<String, dynamic> json) {
    return Documento(
      id:     (json['id'] ?? null) as int?,
      idReal: (json['idReal'] ?? null) as int?,
      title: (json['title'] ?? '') as String,
      realDate: (json['realDate'] ?? '') as String,
      jobDate: (json['jobDate'] ?? '') as String,
      documentRtNumber: json['documentRtNumber'] as String?,
      documentRtCloseNumber: json['documentRtCloseNumber'] as String?,
      amount: (json['amount'] as num).toDouble(),
      amountTaxable: (json['amountTaxable'] as num).toDouble(),
      amountTax: (json['amountTax'] as num).toDouble(),
      amountRt: (json['amountRt'] as num).toDouble(),
      receiptRounding: (json['receiptRounding'] as num).toDouble(),
      tips: json['tips'] == null ? null : (json['tips'] as num).toDouble(),
      remainder: (json['remainder'] as num).toDouble(),
      platform: (json['platform'] ?? '') as String,
      printed: (json['printed'] as num).toInt(),
      printedAt: json['printedAt'] as String?,
      idDevice: (json['idDevice'] as num).toInt(),
      idOperator: (json['idOperator'] as num).toInt(),
      idCustomer: json['idCustomer'] == null ? null : (json['idCustomer'] as num).toInt(),
      lines: ((json['lines'] as List<dynamic>?) ?? const [])
          .map((e) => Line.fromJson(e as Map<String, dynamic>))
          .toList(),
      payments: ((json['payments'] as List<dynamic>?) ?? const [])
          .map((e) => Payment.fromJson(e as Map<String, dynamic>))
          .toList(),
      footDiscount: json['footDiscount'] == null ? null : (json['footDiscount'] as num).toDouble(),
      idRateFootDiscount: json['idRateFootDiscount'] == null ? null : (json['idRateFootDiscount'] as num).toInt(),
      overrideMovementType: json['overrideMovementType'] as String?,
      idDocumentReference: json['idDocumentReference'] == null ? null : (json['idDocumentReference'] as num).toInt(),
      copyCart: json['copyCart'] as List<ProdottoCarrello>,
      idTable: json['idTable'] as int?,
      deletedBy: json['deletedBy'] as String?,
      deleteNumber: json['deleteNumber'] as String?,
      discountReason: json['discountReason'] as String?,
      deliveryService: json['deliveryService'] as String?,
      uuid_riga_turno:json['uuid_riga_turno'] as String?,
      invoice_paid: json['invoice_paid']  ?? 0,
      credit_note_exclude_total_report:  json['credit_note_exclude_total_report'] ?? 0
    );
  }


  factory Documento.fromJsonLocaDB(Map<String, dynamic> json) {
    return Documento(
      id:     (json['id'] ?? null) as int?,
      idReal: (json['idReal'] ?? null) as int?,
      title: (json['title'] ?? '') as String,
      realDate: (json['realDate'] ?? '') as String,
      jobDate: (json['jobDate'] ?? '') as String,
      documentRtNumber: json['documentRtNumber'] as String?,
      documentRtCloseNumber: json['documentRtCloseNumber'] as String?,
      amount: (json['amount'] as num).toDouble(),
      amountTaxable: (json['amountTaxable'] as num).toDouble(),
      amountTax: (json['amountTax'] as num).toDouble(),
      amountRt: (json['amountRt'] as num).toDouble(),
      receiptRounding: (json['receiptRounding'] as num).toDouble(),
      tips: json['tips'] == null ? null : (json['tips'] as num).toDouble(),
      remainder: (json['remainder'] as num).toDouble(),
      platform: (json['platform'] ?? '') as String,
      printed: (json['printed'] as num).toInt(),
      printedAt: json['printedAt'] as String?,
      idDevice: (json['idDevice'] as num).toInt(),
      idOperator: (json['idOperator'] as num).toInt(),
      idCustomer: json['idCustomer'] == null ? null : (json['idCustomer'] as num).toInt(),
      lines: (( jsonDecode(json['lines'])  as List<dynamic>?) ?? const [])
          .map((e) => Line.fromJson(e as Map<String, dynamic>)).toList(),
      payments: ( (jsonDecode(json['payments'])  as List<dynamic>?) ?? const [])
          .map((e) => Payment.fromJson(e as Map<String, dynamic>)).toList(),
      footDiscount: json['footDiscount'] == null ? null : (json['footDiscount'] as num).toDouble(),
      idRateFootDiscount: json['idRateFootDiscount'] == null ? null : (json['idRateFootDiscount'] as num).toInt(),
      overrideMovementType: json['overrideMovementType'] as String?,
      idDocumentReference: json['idDocumentReference'] == null ? null : (json['idDocumentReference'] as num).toInt(),
      copyCart: (( jsonDecode(json['copyCart']) as List<dynamic>) ?? const [])
          .map((e) => ProdottoCarrello.fromJson(e as Map<String, dynamic>)).toList(),
      idTable: json['idTable'] as int?,
      deleteNumber:    json['deleteNumber'] as String?,
      deletedBy:       json['deletedBy'] as String?,
      discountReason:  json['discountReason'] as String?,
      deliveryService: json['deliveryService'] as String?,
      uuid_riga_turno: json['uuid_riga_turno'] as String?,
      invoice_paid:    json['invoice_paid']  ?? 0,
      credit_note_exclude_total_report:  json['credit_note_exclude_total_report']  ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id' : id,
      'idReal': idReal,
      'title': title,
      'realDate': realDate,
      'jobDate': jobDate,
      'documentRtNumber': documentRtNumber,
      'documentRtCloseNumber': documentRtCloseNumber,
      'amount': amount,
      'amountTaxable': amountTaxable,
      'amountTax': amountTax,
      'amountRt': amountRt,
      'receiptRounding': receiptRounding,
      'tips': tips,
      'remainder': remainder,
      'platform': platform,
      'printed': printed,
      'printedAt': printedAt,
      'idDevice': idDevice,
      'idOperator': idOperator,
      'idCustomer': idCustomer,
      'lines': jsonEncode(lines.map((e) => e.toJson()).toList()),
      'payments': jsonEncode(payments.map((e) => e.toJson()).toList()),
      'footDiscount': footDiscount,
      'idRateFootDiscount': idRateFootDiscount,
      'overrideMovementType': overrideMovementType,
      'idDocumentReference': idDocumentReference,
      'copyCart' : jsonEncode(copyCart.map((e) => e.toJson()).toList()),
      'idTable'  : idTable,
      'deleteNumber' : deleteNumber,
      'deletedBy'    : deletedBy,
      'discountReason' : discountReason,
      'deliveryService' : deliveryService,
      'uuid_riga_turno' : uuid_riga_turno,
      'invoice_paid'    :  invoice_paid  ?? 0,
      'credit_note_exclude_total_report' :credit_note_exclude_total_report ?? 0 
    };
  }

    Map<String, dynamic> toJsonForSendBackoffice() {
    return {
      //'id' : id,
      'idReal': idReal,
      'title': title,
      'realDate': realDate,
      'jobDate': jobDate,
      'documentRtNumber': documentRtNumber,
      'documentRtCloseNumber': documentRtCloseNumber,
      'amount': amount,
      'amountTaxable': amountTaxable,
      'amountTax': amountTax,
      'amountRt': amountRt,
      'receiptRounding': receiptRounding,
      'tips': tips,
      'remainder': remainder,
      'platform': platform,
      'printed': printed,
      'printedAt': printedAt,
      'idDevice': idDevice,
      'idOperator': idOperator,
      'idCustomer': idCustomer,
      'lines': lines.map((l) => l.toJson()).toList(),
      'payments': payments.map((p) => { "idPayment":p.idPayment, "amount":20.0, }).toList(),
      'footDiscount': footDiscount,
      'idRateFootDiscount': idRateFootDiscount,
      'overrideMovementType': overrideMovementType,
      'idDocumentReference': idDocumentReference,
      'idTable' : idTable,
      'discountReason': discountReason,
      'deliveryService': deliveryService,
      'invoice_paid' : invoice_paid  ?? 0,
      'credit_note_exclude_total_report' : credit_note_exclude_total_report ?? 0
    };
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id' : id,
      'idReal': idReal,
      'title': title,
      'realDate': realDate,
      'jobDate': jobDate,
      'documentRtNumber': documentRtNumber,
      'documentRtCloseNumber': documentRtCloseNumber,
      'amount': amount,
      'amountTaxable': amountTaxable,
      'amountTax': amountTax,
      'amountRt': amountRt,
      'receiptRounding': receiptRounding,
      'tips': tips,
      'remainder': remainder,
      'platform': platform,
      'printed': printed,
      'printedAt': printedAt,
      'idDevice': idDevice,
      'idOperator': idOperator,
      'idCustomer': idCustomer,
      'lines': jsonEncode(lines.map((e) => e.toJson()).toList()),
      'payments': jsonEncode(payments.map((e) => e.toJson()).toList()),
      'footDiscount': footDiscount,
      'idRateFootDiscount': idRateFootDiscount,
      'overrideMovementType': overrideMovementType,
      'idDocumentReference': idDocumentReference,
      'idTable' : idTable,
      'deleteNumber' : deleteNumber,
      'deletedBy'    : deletedBy,
      'discountReason' : discountReason,
      'deliveryService': deliveryService,
      'uuid_riga_turno': uuid_riga_turno,
      'invoice_paid' : invoice_paid  ?? 0,
      'credit_note_exclude_total_report' : credit_note_exclude_total_report ?? 0
    };
  }

  factory Documento.fromMap(Map<String, dynamic> map) {
    final linesRaw    = map['lines'] as String?;
    final paymentsRaw = map['payments'] as String?;
    final copyCart    = map['copyCart'] as String?;

    return Documento(
      id : map["id"],
      assignedDocumentNumber: map['assignedDocumentNumber'],
      idReal: map["idReal"],
      title: map['title'] as String,
      realDate: map['realDate'] as String,
      jobDate: map['jobDate'] as String,
      documentRtNumber: map['documentRtNumber'] as String?,
      documentRtCloseNumber: map['documentRtCloseNumber'] as String?,
      amount: (map['amount'] as num).toDouble(),
      amountTaxable: (map['amountTaxable'] as num).toDouble(),
      amountTax: (map['amountTax'] as num).toDouble(),
      amountRt: (map['amountRt'] as num).toDouble(),
      receiptRounding: (map['receiptRounding'] as num).toDouble(),
      tips: map['tips'] == null ? null : (map['tips'] as num).toDouble(),
      remainder: (map['remainder'] as num).toDouble(),
      platform: map['platform'] as String,
      printed: (map['printed'] as num).toInt(),
      printedAt: map['printedAt'] as String?,
      idDevice: (map['idDevice'] as num).toInt(),
      idOperator: (map['idOperator'] as num).toInt(),
      idCustomer: map['idCustomer'] == null ? null : (map['idCustomer'] as num).toInt(),
      lines: linesRaw == null
          ? <Line>[]
          : (jsonDecode(linesRaw) as List<dynamic>).map((e) => Line.fromJson(e as Map<String, dynamic>)).toList(),
      payments: paymentsRaw == null
          ? <Payment>[]
          : (jsonDecode(paymentsRaw) as List<dynamic>).map((e) => Payment.fromJson(e as Map<String, dynamic>)).toList(),
      footDiscount: map['footDiscount'] == null ? null : (map['footDiscount'] as num).toDouble(),
      idRateFootDiscount: map['idRateFootDiscount'] == null ? null : (map['idRateFootDiscount'] as num).toInt(),
      overrideMovementType: map['overrideMovementType'] as String?,
      idDocumentReference: map['idDocumentReference'] == null ? null : (map['idDocumentReference'] as num).toInt(),
      copyCart: copyCart == null
          ? <ProdottoCarrello>[]
          : (jsonDecode(copyCart) as List<dynamic>).map((e) => ProdottoCarrello.fromJson(e as Map<String, dynamic>)).toList(),
      idTable: map['idTable'] as int?,
      deleteNumber :  map['deleteNumber'] as String?,
      deletedBy    :  map['deletedBy'] as String?,
      discountReason : map['discountReason'] as String?,
      deliveryService: map['deliveryService'] as String?,
      uuid_riga_turno: map['uuid_riga_turno'] as String?,
      invoice_paid :  map["invoice_paid"]  ?? 0 ,
      credit_note_exclude_total_report : map["credit_note_exclude_total_report"]  ?? 0
    );
  }
}



class Line {
  final int idArticle;
  final String title;
  final double price;
  final double quantity;
  final int idVatRate;
  final String rowGuid;
  final String? rowGuidReference;

  Line({
    required this.rowGuid,
    this.rowGuidReference,
    required this.idArticle,
    required this.title,
    required this.price,
    required this.quantity,
    required this.idVatRate,
  });

  factory Line.fromJson(Map<String, dynamic> json) {
    return Line(
      rowGuid : json['rowGuid'] as String,
      rowGuidReference: json['rowGuidReference']  as String?,
      idArticle: (json['idArticle'] as num).toInt(),
      title: (json['title'] ?? '') as String,
      price: (json['price'] as num).toDouble(),
      quantity: (json['quantity'] as num).toDouble(),
      idVatRate: (json['idVatRate'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
        'rowGuid'  : rowGuid,
        'rowGuidReference': rowGuidReference,
        'idArticle': idArticle,
        'title': title,
        'price': price,
        'quantity': quantity,
        'idVatRate': idVatRate,
      };

  Map<String, Object?> toMap() => {
        'rowGuid'  : rowGuid,
        'rowGuidReference': rowGuidReference,
        'idArticle': idArticle,
        'title': title,
        'price': price,
        'quantity': quantity,
        'idVatRate': idVatRate,
      };

  factory Line.fromMap(Map<String, dynamic> map) => Line(
        rowGuid : map['rowGuid'] as String,
        rowGuidReference: map['rowGuidReference']  as String?,
        idArticle: (map['idArticle'] as num).toInt(),
        title: map['title'] as String,
        price: (map['price'] as num).toDouble(),
        quantity: (map['quantity'] as num).toDouble(),
        idVatRate: (map['idVatRate'] as num).toInt(),
      );
}

class Payment {
  final String title;
  final int idPayment;
  final double amount;
  final int tend;
  final int? subTend;

  Payment({
    required this.title,
    required this.idPayment,
    required this.amount,
    required this.tend,
    this.subTend
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      title: json['title'],
      idPayment: (json['idPayment'] as num).toInt(),
      amount: (json['amount'] as num).toDouble(),
      tend: json['tend'] as int,
      subTend: 1
    );
  }

  Map<String, dynamic> toJson() => {
        'idPayment': idPayment,
        'amount': amount,
        "tend": tend,
        "subTend": subTend,
        "title": title
      };

  Map<String, Object?> toMap() => {
        'idPayment': idPayment,
        'amount': amount,
        "tend": tend,
        "subTend": subTend,
        "title"  : title
      };

  factory Payment.fromMap(Map<String, dynamic> map) => Payment(
        idPayment: (map['idPayment'] as num).toInt(),
        amount: (map['amount'] as num).toDouble(),
        tend: map['tend'] ?? 1,
        subTend: map['subTend'] ?? 1,
        title: map['title']
      );
}
