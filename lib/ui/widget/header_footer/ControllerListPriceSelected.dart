
import 'package:dashboard/modelli/listPrice.dart';
import 'package:flutter/cupertino.dart';

class ControllerListPriceSelected extends ChangeNotifier {
    ListPriceModel? _listPriceSelected;
  
    ListPriceModel? get listPriceSelected => _listPriceSelected;
    
    set listPriceSelected(ListPriceModel? value) {
      _listPriceSelected = value;
      notifyListeners();
    }
}