import 'package:flutter/material.dart';

class ControllerNotFiscalInPrinting extends ChangeNotifier {
  bool inPrinting = false;
  bool get inPrintig_ => inPrinting;

  void setInPrinting(bool inPrint){
    inPrinting = inPrint;
    notifyListeners();
  }
}