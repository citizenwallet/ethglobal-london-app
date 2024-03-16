import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

class CardManagerContract {
  final int chainId;
  final Web3Client client;
  final String addr;
  late DeployedContract rcontract;

  CardManagerContract(this.chainId, this.client, this.addr);

  Future<void> init() async {
    final rawJson = jsonDecode(await rootBundle.loadString(
        'artifacts/contracts/cards/CardManager.sol/CardManager.json'));

    final cabi =
        ContractAbi.fromJson(jsonEncode(rawJson['abi']), 'CardManager');

    rcontract = DeployedContract(cabi, EthereumAddress.fromHex(addr));
  }

  Future<Uint8List> getCardHash(String serial) async {
    BigInt bigIntSerial = BigInt.parse(serial, radix: 16);

    final function = rcontract.function('getCardHash');

    final result = await client.call(
      contract: rcontract,
      function: function,
      params: [bigIntSerial],
    );

    return result[0];
  }

  Future<EthereumAddress> getCardAddress(Uint8List hash) async {
    final function = rcontract.function('getCardAddress');

    final result = await client.call(
      contract: rcontract,
      function: function,
      params: [hash],
    );

    return result[0] as EthereumAddress;
  }

  Future<Uint8List> createAccountInitCode(Uint8List hash) async {
    final function = rcontract.function('createCard');

    final callData = function.encodeCall([hash]);

    return hexToBytes('$addr${bytesToHex(callData)}');
  }

  Uint8List createAccountCallData(Uint8List hash) {
    final function = rcontract.function('createCard');

    final callData = function.encodeCall([hash]);

    return callData;
  }

  Uint8List withdrawCallData(
      Uint8List hash, String token, String to, BigInt amount) {
    final function = rcontract.function('withdraw');

    return function.encodeCall([
      hash,
      EthereumAddress.fromHex(token),
      EthereumAddress.fromHex(to),
      amount
    ]);
  }
}
