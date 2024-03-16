import 'dart:typed_data';

import 'package:http/http.dart';
import 'package:scanner/services/web3/contracts/card_manager.dart';

import 'package:web3dart/web3dart.dart';

class Web3Service {
  static final Web3Service _instance = Web3Service._internal();

  factory Web3Service() {
    return _instance;
  }

  Web3Service._internal() {
    _client = Client();
  }

  BigInt? _chainId;

  late Client _client;
  late String _url;
  late Web3Client _ethClient;

  late CardManagerContract _cardManager;

  Future<void> init(String rpcUrl, String cardManagerAddress) async {
    _url = rpcUrl;
    _ethClient = Web3Client(_url, _client);

    _chainId = await _ethClient.getChainId();

    if (_chainId == null) {
      throw Exception('Could not get chain id');
    }

    _cardManager = CardManagerContract(
      _chainId!.toInt(),
      _ethClient,
      cardManagerAddress,
    );

    await _cardManager.init();
  }

  Future<Uint8List> getCardHash(String serial) async {
    return _cardManager.getCardHash(serial);
  }

  Future<EthereumAddress> getCardAddress(Uint8List hash) async {
    return _cardManager.getCardAddress(hash);
  }
}
