import 'package:flutter/material.dart';

class AppSessionController extends ChangeNotifier {
  int?    storeId;
  String? storeName;

  int? deviceId;
  String? deviceName;

  bool get isReady => storeId != null && deviceId != null;

  void setStore({
    required int id,
    required String name,
  }) {
    storeId = id;
    storeName = name;
    notifyListeners();
  }

  void setDevice({
    required int id,
    required String name,
  }) {
    deviceId = id;
    deviceName = name;
    notifyListeners();
  }

  void clear() {
    storeId = null;
    storeName = null;
    deviceId = null;
    deviceName = null;
    notifyListeners();
  }
}
