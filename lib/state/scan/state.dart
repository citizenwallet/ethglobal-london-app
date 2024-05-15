import 'package:flutter/material.dart';

class ScanState with ChangeNotifier {
  String? vendorAddress;

  bool loading = true;
  bool ready = false;
  bool purchasing = false;

  String purchaseName = '';
  String purchaseAmount = '';

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

  void startPurchasing(String name, String amount) {
    purchasing = true;
    purchaseName = name;
    purchaseAmount = amount;
    notifyListeners();
  }

  void stopPurchasing() {
    purchasing = false;
    purchaseName = '';
    purchaseAmount = '';
    notifyListeners();
  }

  void setVendorAddress(String? address) {
    vendorAddress = address;
    notifyListeners();
  }

  String? nfcAddress;
  String? nfcBalance;

  bool nfcAddressLoading = false;
  bool nfcAddressError = false;

  void setNfcAddressRequest() {
    nfcAddressLoading = true;
    nfcAddressError = false;
    notifyListeners();
  }

  void setNfcAddressSuccess(String? address) {
    nfcAddress = address;
    nfcAddressLoading = false;
    nfcAddressError = false;
    notifyListeners();
  }

  void setAddressBalance(String? balance) {
    nfcBalance = balance;
    notifyListeners();
  }

  void setNfcAddressError() {
    nfcAddressError = true;
    nfcAddressLoading = false;
    notifyListeners();
  }
}
