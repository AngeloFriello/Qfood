import 'package:flutter/foundation.dart';

class ControllerLookPosInPrinder extends ChangeNotifier {
  bool _inPrint = false;
  bool get  inPrint => _inPrint;

  void setInPrint( bool print ){
    _inPrint = print;
    notifyListeners();
  }
}