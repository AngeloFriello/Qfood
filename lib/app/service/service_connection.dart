import 'package:flutter/foundation.dart';

class ConnectionController extends ChangeNotifier {
  bool _connected        = true;
  bool get connected => _connected;

  void setRete (bool active){
    _connected = active;
    notifyListeners();
  }
  
}