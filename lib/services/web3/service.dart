import 'dart:math';
import 'dart:typed_data';

import 'package:http/http.dart';
import 'package:scanner/services/api/api.dart';
import 'package:scanner/services/preferences/service.dart';
import 'package:scanner/services/web3/contracts/account.dart';
import 'package:scanner/services/web3/contracts/account_factory.dart';
import 'package:scanner/services/web3/contracts/card_manager.dart';
import 'package:scanner/services/web3/contracts/entrypoint.dart';
import 'package:scanner/services/web3/contracts/erc20.dart';
import 'package:scanner/services/web3/gas.dart';
import 'package:scanner/services/web3/json_rpc.dart';
import 'package:scanner/services/web3/paymaster_data.dart';
import 'package:scanner/services/web3/transfer_data.dart';
import 'package:scanner/services/web3/userop.dart';
import 'package:scanner/utils/delay.dart';
import 'package:web3dart/crypto.dart';

import 'package:web3dart/web3dart.dart';

class Web3Service {
  static final Web3Service _instance = Web3Service._internal();

  factory Web3Service() {
    return _instance;
  }

  Web3Service._internal() {
    _client = Client();
  }

  final PreferencesService _prefs = PreferencesService();

  BigInt? _chainId;

  late Client _client;
  late String _url;
  late Web3Client _ethClient;

  late APIService _rpc;
  late APIService _indexer;
  late APIService _bundlerRPC;
  late APIService _paymasterRPC;

  late EthereumAddress _account;
  // BigInt _nonce = BigInt.zero;
  late EthPrivateKey _credentials;

  late ERC20Contract _contractToken;
  late CardManagerContract _cardManager;
  late AccountFactoryContract _accountFactory;
  late TokenEntryPointContract _entryPoint;
  late AccountContract _contractAccount;

  late EIP1559GasPriceEstimator _gasPriceEstimator;

  Future<void> init(
    String rpcUrl,
    String bundlerUrl,
    String indexerUrl,
    String paymasterUrl,
    String paymasterAddress,
    String cardManagerAddress,
    String accountFactoryAddress,
    String entryPointAddress,
    String tokenAddress,
  ) async {
    _url = rpcUrl;
    _ethClient = Web3Client(_url, _client);

    _rpc = APIService(baseURL: rpcUrl);
    _indexer = APIService(baseURL: indexerUrl);
    _bundlerRPC = APIService(baseURL: '$bundlerUrl/$paymasterAddress');
    _paymasterRPC = APIService(baseURL: '$paymasterUrl/$paymasterAddress');

    _gasPriceEstimator = EIP1559GasPriceEstimator(
      _rpc,
      _ethClient,
    );

    _chainId = await _ethClient.getChainId();

    if (_chainId == null) {
      throw Exception('Could not get chain id');
    }

    final key = _prefs.key;
    if (key == null) {
      final credentials = EthPrivateKey.createRandom(Random.secure());

      await _prefs.setKey(bytesToHex(credentials.privateKey));

      _credentials = credentials;
    } else {
      _credentials = EthPrivateKey.fromHex(key);
    }

    _contractToken = ERC20Contract(
      _chainId!.toInt(),
      _ethClient,
      tokenAddress,
    );

    await _contractToken.init();

    _cardManager = CardManagerContract(
      _chainId!.toInt(),
      _ethClient,
      cardManagerAddress,
    );

    await _cardManager.init();

    _accountFactory = AccountFactoryContract(
      _chainId!.toInt(),
      _ethClient,
      accountFactoryAddress,
    );

    await _accountFactory.init();

    _account = await _accountFactory.getAddress(_credentials.address.hexEip55);

    _entryPoint = TokenEntryPointContract(
      _chainId!.toInt(),
      _ethClient,
      entryPointAddress,
    );

    await _entryPoint.init();

    // _nonce = await _entryPoint.getNonce(_account.hexEip55);

    _contractAccount = AccountContract(
      _chainId!.toInt(),
      _ethClient,
      _account.hexEip55,
    );

    await _contractAccount.init();
  }

  Future<Uint8List> getCardHash(String serial) async {
    return _cardManager.getCardHash(serial);
  }

  Future<EthereumAddress> getCardAddress(Uint8List hash) async {
    return _cardManager.getCardAddress(hash);
  }

  EthereumAddress get account => _account;
  EthereumAddress get tokenAddress => _contractToken.rcontract.address;
  EthereumAddress get entrypointAddress => _entryPoint.rcontract.address;
  EthereumAddress get cardManagerAddress => _cardManager.rcontract.address;

  Future<BigInt> getNonce(String addr) async {
    return _entryPoint.getNonce(addr);
  }

  /// check if an account exists
  Future<bool> accountExists(
    String account,
  ) async {
    try {
      final url = '/accounts/$account/exists';

      await _indexer.get(
        url: url,
        headers: {
          'Authorization': 'Bearer x',
        },
      );

      return true;
    } catch (_) {}

    return false;
  }

  Future<BigInt> getBalance(String addr) async {
    return _contractToken.getBalance(addr);
  }

  /// construct withdraw call data
  Uint8List erc20TransferCallData(
    String to,
    BigInt amount,
  ) {
    return _contractToken.transferCallData(
      to,
      amount,
    );
  }

  /// construct withdraw call data
  Uint8List withdrawCallData(
    Uint8List hash,
    BigInt amount,
  ) {
    return _cardManager.withdrawCallData(
      hash,
      _contractToken.addr,
      _account.hexEip55,
      amount,
    );
  }

  /// construct withdraw call data
  Uint8List createCardCallData(
    Uint8List cardHash,
  ) {
    return _cardManager.createAccountCallData(cardHash);
  }

  /// makes a jsonrpc request from this wallet
  Future<SUJSONRPCResponse> _requestPaymaster(
    SUJSONRPCRequest body, {
    bool legacy = false,
  }) async {
    final rawResponse = await _paymasterRPC.post(
      body: body,
    );

    final response = SUJSONRPCResponse.fromJson(rawResponse);

    if (response.error != null) {
      throw Exception(response.error!.message);
    }

    return response;
  }

  /// return paymaster data for constructing a user op
  Future<(PaymasterData?, Exception?)> _getPaymasterData(
    UserOp userop,
    String eaddr,
    String ptype, {
    bool legacy = false,
  }) async {
    final body = SUJSONRPCRequest(
      method: 'pm_sponsorUserOperation',
      params: [
        userop.toJson(),
        eaddr,
        {'type': ptype},
      ],
    );

    try {
      final response = await _requestPaymaster(body, legacy: legacy);

      return (PaymasterData.fromJson(response.result), null);
    } catch (exception, s) {
      final strerr = exception.toString();

      if (strerr.contains(gasFeeErrorMessage)) {
        return (null, NetworkCongestedException());
      }

      if (strerr.contains(invalidBalanceErrorMessage)) {
        return (null, NetworkInvalidBalanceException());
      }
    }

    return (null, NetworkUnknownException());
  }

  /// return paymaster data for constructing a user op
  Future<(List<PaymasterData>, Exception?)> _getPaymasterOOData(
    UserOp userop,
    String eaddr,
    String ptype, {
    bool legacy = false,
    int count = 1,
  }) async {
    final body = SUJSONRPCRequest(
      method: 'pm_ooSponsorUserOperation',
      params: [
        userop.toJson(),
        eaddr,
        {'type': ptype},
        count,
      ],
    );

    try {
      final response = await _requestPaymaster(body, legacy: legacy);

      final List<dynamic> data = response.result;
      if (data.isEmpty) {
        throw Exception('empty paymaster data');
      }

      if (data.length != count) {
        throw Exception('invalid paymaster data');
      }

      return (data.map((item) => PaymasterData.fromJson(item)).toList(), null);
    } catch (exception) {
      final strerr = exception.toString();

      if (strerr.contains(gasFeeErrorMessage)) {
        return (<PaymasterData>[], NetworkCongestedException());
      }

      if (strerr.contains(invalidBalanceErrorMessage)) {
        return (<PaymasterData>[], NetworkInvalidBalanceException());
      }
    }

    return (<PaymasterData>[], NetworkUnknownException());
  }

  /// prepare a userop for with calldata
  Future<(String, UserOp)> prepareUserop(
      List<String> dest, List<Uint8List> calldata) async {
    try {
      EthereumAddress acc =
          await _accountFactory.getAddress(_credentials.address.hexEip55);

      // instantiate user op with default values
      final userop = UserOp.defaultUserOp();

      // use the account hex as the sender
      userop.sender = acc.hexEip55;

      // determine the appropriate nonce
      userop.nonce = await _entryPoint.getNonce(acc.hexEip55);
      // userop.nonce = _nonce;

      // if it's the first user op from this account, we need to deploy the account contract
      if (userop.nonce == BigInt.zero) {
        // construct the init code to deploy the account
        userop.initCode = await _accountFactory.createAccountInitCode(
          _credentials.address.hexEip55,
          BigInt.zero,
        );
      }

      // set the appropriate call data for the transfer
      // we need to call account.execute which will call token.transfer
      userop.callData = dest.length > 1 && calldata.length > 1
          ? _contractAccount.executeBatchCallData(
              dest,
              calldata,
            )
          : _contractAccount.executeCallData(
              dest[0],
              BigInt.zero,
              calldata[0],
            );

      // set the appropriate gas fees based on network
      final fees = await _gasPriceEstimator.estimate;
      if (fees == null) {
        throw Exception('unable to estimate fees');
      }

      userop.maxPriorityFeePerGas =
          fees.maxPriorityFeePerGas * BigInt.from(calldata.length);
      userop.maxFeePerGas = fees.maxFeePerGas * BigInt.from(calldata.length);

      // submit the user op to the paymaster in order to receive information to complete the user op
      List<PaymasterData> paymasterOOData = [];
      Exception? paymasterErr;
      final useAccountNonce = userop.nonce == BigInt.zero;
      if (useAccountNonce) {
        // if it's the first user op, we should use a normal paymaster signature
        PaymasterData? paymasterData;
        (paymasterData, paymasterErr) = await _getPaymasterData(
          userop,
          _entryPoint.addr,
          'cw',
        );

        if (paymasterData != null) {
          paymasterOOData.add(paymasterData);
        }
      } else {
        // if it's not the first user op, we should use an out of order paymaster signature
        (paymasterOOData, paymasterErr) = await _getPaymasterOOData(
          userop,
          _entryPoint.addr,
          'cw',
        );
      }

      if (paymasterErr != null) {
        throw paymasterErr;
      }

      if (paymasterOOData.isEmpty) {
        throw Exception('unable to get paymaster data');
      }

      final paymasterData = paymasterOOData.first;
      if (!useAccountNonce) {
        // use the nonce received from the paymaster
        userop.nonce = paymasterData.nonce;
      }

      // add the received data to the user op
      userop.paymasterAndData = paymasterData.paymasterAndData;
      userop.preVerificationGas = paymasterData.preVerificationGas;
      userop.verificationGasLimit = paymasterData.verificationGasLimit;
      userop.callGasLimit = paymasterData.callGasLimit;

      // get the hash of the user op
      final hash = await _entryPoint.getUserOpHash(userop);

      // now we can sign the user op
      userop.generateSignature(_credentials, hash);

      return (bytesToHex(hash, include0x: true), userop);
    } catch (_) {
      rethrow;
    }
  }

  /// makes a jsonrpc request from this wallet
  Future<SUJSONRPCResponse> _requestBundler(
    SUJSONRPCRequest body, {
    bool legacy = false,
  }) async {
    final rawResponse = await _bundlerRPC.post(
      body: body,
    );

    final response = SUJSONRPCResponse.fromJson(rawResponse);

    if (response.error != null) {
      throw Exception(response.error!.message);
    }

    return response;
  }

  /// Submits a user operation to the Ethereum network.
  ///
  /// This function sends a JSON-RPC request to the ERC4337 bundler. The entrypoint is specified by the
  /// [eaddr] parameter, with the [eth_sendUserOperation] method and the given
  /// [userop] parameter. If the request is successful, the function returns a
  /// tuple containing the transaction hash as a string and `null`. If the request
  /// fails, the function returns a tuple containing `null` and an exception
  /// object representing the type of error that occurred.
  ///
  /// If the request fails due to a network congestion error, the function returns
  /// a [NetworkCongestedException] object. If the request fails due to an invalid
  /// balance error, the function returns a [NetworkInvalidBalanceException]
  /// object. If the request fails for any other reason, the function returns a
  /// [NetworkUnknownException] object.
  ///
  /// [userop] The user operation to submit to the Ethereum network.
  /// [eaddr] The Ethereum address of the node to send the request to.
  /// A tuple containing the transaction hash as a string and [null] if
  ///         the request was successful, or [null] and an exception object if the
  ///         request failed.
  Future<(String?, Exception?)> _submitUserOp(
    UserOp userop,
    String eaddr, {
    bool legacy = false,
    TransferData? data,
  }) async {
    final params = [userop.toJson(), eaddr];
    if (!legacy && data != null) {
      params.add(data.toJson());
    }

    final body = SUJSONRPCRequest(
      method: 'eth_sendUserOperation',
      params: params,
    );

    try {
      final response = await _requestBundler(body, legacy: legacy);

      print('response.result: ${response.result}');

      return (response.result as String, null);
    } catch (exception, s) {
      print(exception);
      print(s);
      final strerr = exception.toString();

      if (strerr.contains(gasFeeErrorMessage)) {
        return (null, NetworkCongestedException());
      }

      if (strerr.contains(invalidBalanceErrorMessage)) {
        return (null, NetworkInvalidBalanceException());
      }
    }

    return (null, NetworkUnknownException());
  }

  /// submit a user op
  Future<String?> submitUserop(
    UserOp userop, {
    EthPrivateKey? customCredentials,
    bool legacy = false,
    TransferData? data,
  }) async {
    try {
      bool isLegacy = legacy;

      // send the user op
      final (result, useropErr) = await _submitUserOp(
        userop,
        _entryPoint.addr,
        legacy: isLegacy,
        data: data,
      );
      if (useropErr != null) {
        throw useropErr;
      }

      return result;
    } catch (_) {
      rethrow;
    }
  }

  /// given a tx hash, waits for the tx to be mined
  Future<bool> waitForTxSuccess(
    String txHash, {
    int retryCount = 0,
    int maxRetries = 20,
  }) async {
    print('waiting... $txHash $retryCount $maxRetries');
    if (retryCount >= maxRetries) {
      print('exceeded retries... $txHash $retryCount $maxRetries');
      return false;
    }

    final receipt = await _ethClient.getTransactionReceipt(txHash);
    if (receipt?.status != true) {
      print('receipt false... $txHash $retryCount $maxRetries');
      // there is either no receipt or the tx is still not confirmed

      // increment the retry count
      final nextRetryCount = retryCount + 1;

      // wait for a bit before retrying
      await delay(Duration(milliseconds: 250 * (nextRetryCount)));

      // retry
      return waitForTxSuccess(
        txHash,
        retryCount: nextRetryCount,
        maxRetries: maxRetries,
      );
    }

    print('receipt true... $txHash $retryCount $maxRetries');

    return true;
  }
}
