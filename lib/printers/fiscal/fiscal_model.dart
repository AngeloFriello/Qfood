class FiscalReceiptLine {

  // Campi obbligatori
  late int      departmentNumber;
  late String   title;
  late int      quantity;
  late double   price;

  // Campi opzionali linea  
  String? note;

}

class FiscalPayment {

  // Campi obbligatori
  late double amount;
  late String title;
  late int tend;
  
  // Campi opzionali
  int? subTend;

}

class FiscalReceipt {

  // Campi obbligatori
  late List<FiscalReceiptLine>  lines;
  late List<FiscalPayment>      payments;

  // Campi opzionali
  double? discount;
  String? barcode;

}

class FiscalReceiptResponse {

  bool    success = false;
  String? fiscalClosure;
  String? fiscalNumber;

}