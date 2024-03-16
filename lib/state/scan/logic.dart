import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:scanner/services/nfc/service.dart';
import 'package:scanner/services/web3/service.dart';
import 'package:scanner/state/scan/state.dart';
import 'package:web3dart/crypto.dart';

class ScanLogic {
  final ScanState _state;
  final NFCService _nfc = NFCService();

  late Web3Service _web3;

  ScanLogic(BuildContext context) : _state = context.read<ScanState>();

  Future<void> init() async {
    try {
      _state.loadScanner();

      _web3 = Web3Service();

      await _web3.init(
        dotenv
            .get(kDebugMode ? 'BASE_TESTNET_RPC_URL' : 'BASE_MAINNET_RPC_URL'),
        dotenv.get(
          kDebugMode
              ? 'CARD_MANAGER_TESTNET_CONTRACT_ADDR'
              : 'CARD_MANAGER_CONTRACT_ADDR',
        ),
      );

      _state.scannerReady();
      return;
    } catch (_) {}

    _state.scannerNotReady();
  }

  void start() async {
    try {
      _state.startScanning();

      final serialNumber = await _nfc.readSerialNumber();

      print('serial number: $serialNumber');

      final cardHash = await _web3.getCardHash(serialNumber);

      print('card hash: ${bytesToHex(cardHash, include0x: true)}');

      final address = await _web3.getCardAddress(cardHash);

      print('card address: ${address.hexEip55}');
      return;
    } catch (e, s) {
      print(e);
      print(s);
    }

    _state.stopScanning();
  }

  void stop() async {
    try {
      await _nfc.stop();

      _state.stopScanning();
    } catch (_) {}
  }
}
