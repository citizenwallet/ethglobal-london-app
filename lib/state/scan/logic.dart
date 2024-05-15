import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:scanner/services/nfc/service.dart';
import 'package:scanner/services/web3/service.dart';
import 'package:scanner/services/web3/transfer_data.dart';
import 'package:scanner/services/web3/utils.dart';
import 'package:scanner/state/scan/state.dart';
import 'package:scanner/utils/currency.dart';
import 'package:scanner/utils/qr.dart';

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
        dotenv.get(
            kDebugMode ? 'GNOSIS_MAINNET_RPC_URL' : 'GNOSIS_MAINNET_RPC_URL'),
        dotenv.get(kDebugMode ? 'BUNDLER_TESTNET_RPC_URL' : 'BUNDLER_RPC_URL'),
        dotenv.get(kDebugMode ? 'INDEXER_TESTNET_RPC_URL' : 'INDEXER_RPC_URL'),
        dotenv.get(
            kDebugMode ? 'PAYMASTER_TESTNET_RPC_URL' : 'PAYMASTER_RPC_URL'),
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

      _state.setVendorAddress(_web3.account.hexEip55);

      _state.scannerReady();
      return;
    } catch (_) {}

    _state.scannerNotReady();
  }

  void copyVendorAddress() {
    try {
      final vendorAddress = _web3.account.hexEip55;

      Clipboard.setData(ClipboardData(text: vendorAddress));
    } catch (_) {}
  }

  Future<String?> purchase(String name, String amount) async {
    try {
      print('purchasing...');
      _state.startPurchasing(name, amount);

      final serialNumber = await _nfc.readSerialNumber(
        message: 'Scan to purchase $name for EURb $amount',
        successMessage: 'Purchased $name for EURb $amount',
      );

      final cardHash = await _web3.getCardHash(serialNumber);

      final address = await _web3.getCardAddress(cardHash);

      final balance = await _web3.getBalance(address.hexEip55);
      if (balance == BigInt.zero) {
        throw Exception('Insufficient balance');
      }

      final bigAmount = toUnit(amount);
      if (bigAmount > balance) {
        final currentBalance = fromUnit(balance, decimals: 6);
        throw Exception('Cost: $amount, Balance: $currentBalance');
      }

      final withdrawCallData = _web3.withdrawCallData(
        cardHash,
        toUnit(amount),
      );

      final (_, userop) = await _web3.prepareUserop(
          [_web3.cardManagerAddress.hexEip55], [withdrawCallData]);

      final data = TransferData(
        'Purchased $name - $amount',
      );

      final txHash = await _web3.submitUserop(userop, data: data);
      if (txHash == null) {
        throw Exception('failed to withdraw');
      }

      // await _web3.waitForTxSuccess(txHash);

      _state.stopPurchasing();
      return null;
    } catch (e, s) {
      print(e);
      print(s);
      if (e is Exception) {
        _state.stopPurchasing();
        return e.toString();
      }
    }

    _state.stopPurchasing();

    return 'Failed to purchase';
  }

  Future<bool> withdraw(String value) async {
    try {
      final (address, _) = parseQRCode(value);
      if (address == '') {
        throw Exception('invalid address');
      }

      final balance = await _web3.getBalance(_web3.account.hexEip55);
      if (balance == BigInt.zero) {
        throw Exception('no balance');
      }

      final calldata = _web3.erc20TransferCallData(address, balance);

      final (_, userop) =
          await _web3.prepareUserop([_web3.tokenAddress.hexEip55], [calldata]);

      final data = TransferData(
        'Withdraw balance',
      );

      final txHash = await _web3.submitUserop(userop, data: data);
      if (txHash == null) {
        throw Exception('failed to withdraw');
      }

      // await _web3.waitForTxSuccess(txHash);

      return true;
    } catch (_) {}

    return false;
  }

  Future<String?> read({String? message, String? successMessage}) async {
    try {
      _state.setNfcAddressRequest();

      final serialNumber = await _nfc.readSerialNumber(
        message: message,
        successMessage: successMessage,
      );

      final cardHash = await _web3.getCardHash(serialNumber);

      final address = await _web3.getCardAddress(cardHash);

      final balance = await _web3.getBalance(address.hexEip55);

      _state.setNfcAddressSuccess(address.hexEip55);
      _state.setAddressBalance(balance.toString());

      return address.hexEip55;
    } catch (_) {
      _state.setNfcAddressError();
      _state.setAddressBalance(null);
    }

    return null;
  }

  Future<Timer?> listenBalance(String address) async {
    try {
      final balance = await _web3.getBalance(address);

      final formattedBalance = formatCurrency(
        double.tryParse(fromDoubleUnit(balance.toString())) ?? 0.0,
        'EURb',
      );

      _state.setAddressBalance(formattedBalance);

      // every second check the balance
      return Timer.periodic(const Duration(seconds: 1), (_) async {
        final balance = await _web3.getBalance(address);

        final formattedBalance = formatCurrency(
          double.tryParse(fromDoubleUnit(balance.toString())) ?? 0.0,
          'EURb',
        );

        _state.setAddressBalance(formattedBalance);
      });
    } catch (_) {}

    return null;
  }
}
