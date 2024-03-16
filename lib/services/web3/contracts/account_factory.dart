import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

class AccountFactoryContract {
  final int chainId;
  final Web3Client client;
  final String addr;
  late DeployedContract rcontract;

  AccountFactoryContract(this.chainId, this.client, this.addr);

  Future<void> init() async {
    final rawJson = jsonDecode(
        await rootBundle.loadString('assets/contracts/AccountFactory.json'));

    final cabi =
        ContractAbi.fromJson(jsonEncode(rawJson['abi']), 'AccountFactory');

    rcontract = DeployedContract(cabi, EthereumAddress.fromHex(addr));
  }

  Future<EthereumAddress> getAddress(String owner) async {
    final function = rcontract.function('getAddress');

    final result = await client.call(
      contract: rcontract,
      function: function,
      params: [EthereumAddress.fromHex(owner), BigInt.from(0)],
    );

    return result[0] as EthereumAddress;
  }

  Future<Uint8List> createAccountInitCode(String owner, BigInt amount) async {
    final function = rcontract.function('createAccount');

    final callData =
        function.encodeCall([EthereumAddress.fromHex(owner), BigInt.from(0)]);

    return hexToBytes('$addr${bytesToHex(callData)}');
  }
}
