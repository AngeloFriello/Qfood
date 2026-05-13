import 'package:flutter/material.dart';

class ProductSearchController extends ChangeNotifier {
  String _query                      = '';
  String get query                   => _query;
  TextEditingController crtBarSearch = TextEditingController();

  void setQuery(String value) {
    final v = value.trim().toLowerCase();
    if (_query == v) return;
    _query = v;
    notifyListeners();
  }

  void clear() {
    _query = '';
    crtBarSearch.clear();
    notifyListeners();
  }

  bool match(String text) {
    if (_query.isEmpty) return true;
    return text.toLowerCase().contains(_query);
  }
}


