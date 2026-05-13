import 'package:flutter/foundation.dart';

class ControllerListProductsTable extends ChangeNotifier {
  bool   _preferred = false;
  String _textSerch = '';
  String get textSearch => _textSerch;
  int   _categorySelected = 0;
  bool  get preferred => _preferred;
  int   get categorySelected => _categorySelected;

  void setCategorySelected( int idCat ){
    _categorySelected = idCat;
    notifyListeners();
  }

  void setPreferred( bool p ){
    _preferred = p;
    notifyListeners();
  }

  void setSearch( String t ){
    _textSerch = t;
    notifyListeners();
  }
}