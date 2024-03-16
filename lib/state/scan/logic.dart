import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:scanner/services/nfc/service.dart';
import 'package:scanner/services/web3/service.dart';
import 'package:scanner/services/web3/transfer_data.dart';
import 'package:scanner/services/web3/utils.dart';
import 'package:scanner/state/scan/state.dart';
import 'package:scanner/utils/delay.dart';
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
            kDebugMode ? 'BUNDLER_TESTNET_RPC_URL' : 'BUNDLER_MAINNET_RPC_URL'),
        dotenv.get(
            kDebugMode ? 'INDEXER_TESTNET_RPC_URL' : 'INDEXER_MAINNET_RPC_URL'),
        dotenv.get(kDebugMode
            ? 'PAYMASTER_TESTNET_RPC_URL'
            : 'PAYMASTER_MAINNET_RPC_URL'),
        dotenv.get(kDebugMode
            ? 'PAYMASTER_TESTNET_CONTRACT_ADDR'
            : 'PAYMASTER_CONTRACT_ADDR'),
        dotenv.get(
          kDebugMode
              ? 'CARD_MANAGER_TESTNET_CONTRACT_ADDR'
              : 'CARD_MANAGER_CONTRACT_ADDR',
        ),
        dotenv.get(kDebugMode
            ? 'ACCOUNT_FACTORY_TESTNET_CONTRACT_ADDR'
            : 'ACCOUNT_FACTORY_CONTRACT_ADDR'),
        dotenv.get(
          kDebugMode
              ? 'ENTRYPOINT_TESTNET_CONTRACT_ADDR'
              : 'ENTRYPOINT_CONTRACT_ADDR',
        ),
        dotenv.get(kDebugMode ? 'TOKEN_TESTNET_ADDR' : 'TOKEN_ADDR'),
      );

      _state.scannerReady();
      return;
    } catch (_) {}

    _state.scannerNotReady();
  }

  void purchase(String name, String amount) async {
    try {
      _state.startPurchasing();

      final serialNumber = await _nfc.readSerialNumber(name: name);

      final cardHash = await _web3.getCardHash(serialNumber);

      final withdrawCallData = _web3.withdrawCallData(
        cardHash,
        toUnit(amount),
      );

      final (_, userop) = await _web3.prepareUserop(
          [_web3.cardManagerAddress.hexEip55], [withdrawCallData]);

      final data = TransferData(
        'Purchased $name',
      );

      final success = await _web3.submitUserop(userop, data: data);
      if (!success) {
        throw Exception('failed to withdraw');
      }

      _state.stopPurchasing();
      return;
    } catch (_) {}

    _state.stopPurchasing();
  }
}
