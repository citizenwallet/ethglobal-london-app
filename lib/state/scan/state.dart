import 'package:flutter/material.dart';

class ScanState with ChangeNotifier {
  bool loading = true;
  bool ready = false;
  bool purchasing = false;

  void loadScanner() {
    loading = true;
    ready = false;
    notifyListeners();
  }

  void scannerReady() {
    loading = false;
    ready = true;
    notifyListeners();
  }

  void scannerNotReady() {
    loading = false;
    ready = false;
    notifyListeners();
  }

  void startPurchasing() {
    purchasing = true;
    notifyListeners();
  }

  void stopPurchasing() {
    purchasing = false;
    notifyListeners();
  }
}
