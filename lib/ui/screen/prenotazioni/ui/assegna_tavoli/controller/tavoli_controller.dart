import 'package:flutter/foundation.dart';
import '../api/tavoli_api_service.dart';
import '../model/tavolo.dart';

class TavoliController extends ChangeNotifier {
  final TavoliApiService _api;

  TavoliController(String istanza)
      : _api = TavoliApiService('https://$istanza-api.qfood.it');

  List<Tavolo> _tavoli = [];
  List<Tavolo> get tavoli => _tavoli;

  bool loading = false;

  Future<void> load() async {
    loading = true;
    notifyListeners();

    _tavoli = await _api.loadTavoli();

    loading = false;
    notifyListeners();
  }
}
