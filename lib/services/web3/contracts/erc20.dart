import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:web3dart/web3dart.dart';

class ERC20Contract {
  final int chainId;
  final Web3Client client;
  final String addr;
  late DeployedContract rcontract;

  ERC20Contract(this.chainId, this.client, this.addr);

  Future<void> init() async {
    final rawJson = jsonDecode(await rootBundle.loadString(
        'artifacts/@openzeppelin/contracts/token/ERC20/IERC20.sol/IERC20.json'));

    final cabi = ContractAbi.fromJson(jsonEncode(rawJson['abi']), 'IERC20');

    rcontract = DeployedContract(cabi, EthereumAddress.fromHex(addr));
  }

  Future<BigInt> getBalance(String addr) async {
    final function = rcontract.function('balanceOf');

    final result = await client.call(
      contract: rcontract,
      function: function,
      params: [EthereumAddress.fromHex(addr)],
    );

    return result[0] as BigInt;
  }

  Uint8List transferCallData(String to, BigInt amount) {
    final function = rcontract.function('transfer');

    return function.encodeCall([EthereumAddress.fromHex(to), amount]);
  }
}
