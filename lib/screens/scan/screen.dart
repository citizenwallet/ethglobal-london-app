import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:scanner/services/web3/utils.dart';
import 'package:scanner/state/products/state.dart';
import 'package:scanner/state/scan/logic.dart';
import 'package:scanner/state/scan/state.dart';
import 'package:scanner/utils/currency.dart';
import 'package:scanner/utils/strings.dart';
import 'package:scanner/widget/qr/qr.dart';

enum MenuOption { withdraw }

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  late ScanLogic _logic;

  bool _copied = false;

  @override
  void initState() {
    super.initState();

    _logic = ScanLogic(context);

    // wait for first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _logic.init();
    });
  }

  void handleBack() {
    GoRouter.of(context).pop();
  }

  void handlePurchase(Product product) async {
    final errorMessage = await _logic.purchase(product.name, product.price);
    if (!mounted) {
      return;
    }

    if (errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Purchased ${product.name} for ${product.price} EURb'),
      ),
    );
  }

  void handleCopy() {
    if (_copied) {
      return;
    }

    _logic.copyVendorAddress();

    setState(() {
      _copied = true;
    });

    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _copied = false;
      });
    });
  }

  void handleWithdraw(BuildContext context) async {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    TextEditingController codeController = TextEditingController();

    final codeValue = await showModalBottomSheet<String>(
      context: context,
      builder: (modalContext) => Container(
        height: height * 0.75,
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          children: [
            TextField(
              controller: codeController,
              decoration: const InputDecoration(
                labelText: 'Code',
              ),
              maxLines: 1,
              maxLength: 6,
              autocorrect: false,
              enableSuggestions: false,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: false,
                signed: false,
              ),
              textInputAction: TextInputAction.done,
            ),
            OutlinedButton.icon(
              onPressed: () {
                modalContext.pop(codeController.text);
              },
              icon: const Icon(Icons.qr_code),
              label: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );

    if (codeValue == null ||
        codeValue.isEmpty ||
        codeValue.length != 6 ||
        codeValue != '123987') {
      return;
    }

    final qrValue = await showModalBottomSheet<String>(
      context: context,
      builder: (modalContext) => SizedBox(
        height: height / 2,
        width: width,
        child: MobileScanner(
          // fit: BoxFit.contain,
          controller: MobileScannerController(
            detectionSpeed: DetectionSpeed.normal,
            facing: CameraFacing.back,
            torchEnabled: false,
            formats: <BarcodeFormat>[BarcodeFormat.qrCode],
          ),
          onDetect: (capture) {
            final List<Barcode> barcodes = capture.barcodes;
            for (final barcode in barcodes) {
              debugPrint('Barcode found! ${barcode.rawValue}');
              modalContext.pop(barcode.rawValue);
              break;
            }
          },
        ),
      ),
    );

    if (qrValue == null) {
      return;
    }

    final success = await _logic.withdraw(qrValue);
    if (!mounted) {
      return;
    }
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to withdraw'),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Withdrawing funds...'),
      ),
    );
  }

  void handleMenuItemPress(BuildContext context, MenuOption item) {
    switch (item) {
      case MenuOption.withdraw:
        handleWithdraw(context);
        break;
    }
  }

  void handleTopUp() async {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    final address = await _logic.read(
      message: 'Scan to display top up link',
      successMessage: 'Card scanned',
    );
    if (address == null) {
      return;
    }

    final balanceTimer = await _logic.listenBalance(address);

    if (!mounted) {
      balanceTimer?.cancel();
      return;
    }

    await showModalBottomSheet<String>(
      context: context,
      builder: (modalContext) {
        final balance = modalContext.watch<ScanState>().nfcBalance;

        return Container(
          height: height * 0.75,
          width: width,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Scan to top up your wallet',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              QR(
                data:
                    'https://topup.citizenspring.earth/usdc.base?account=$address&redirectUrl=https://nfcwallet.xyz',
                size: width - 80,
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 60,
                child: Text(
                  'Balance: $balance',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    balanceTimer?.cancel();
  }

  void handleReadNFC() async {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    final address = await _logic.read(
      message: 'Scan to display balance',
      successMessage: 'Card scanned',
    );
    if (address == null) {
      return;
    }

    final balanceTimer = await _logic.listenBalance(address);

    if (!mounted) {
      balanceTimer?.cancel();
      return;
    }

    await showModalBottomSheet<String>(
      context: context,
      builder: (modalContext) {
        final balance = modalContext.watch<ScanState>().nfcBalance;

        return Container(
          height: height * 0.75,
          width: width,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Your card',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              QR(data: address, size: width - 80),
              const SizedBox(height: 16),
              Text(
                'Balance: $balance',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.normal,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Address: ${formatLongText(address)}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
        );
      },
    );

    balanceTimer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<ScanState>().loading;
    final ready = context.watch<ScanState>().ready;

    final purchasing = context.watch<ScanState>().purchasing;

    final purchaseName = context.watch<ScanState>().purchaseName;
    final purchaseAmount = context.watch<ScanState>().purchaseAmount;

    final vendorAddress = context.watch<ScanState>().vendorAddress;

    final products = context.watch<ProductsState>().products;

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: handleBack,
          ),
          title: vendorAddress != null
              ? OutlinedButton.icon(
                  onPressed: handleCopy,
                  icon: _copied
                      ? const Icon(Icons.check)
                      : const Icon(Icons.copy),
                  label: Text(
                    formatLongText(vendorAddress),
                  ),
                )
              : null,
          actions: [
            PopupMenuButton<MenuOption>(
              onSelected: (MenuOption item) {
                handleMenuItemPress(context, item);
              },
              itemBuilder: (BuildContext context) =>
                  <PopupMenuEntry<MenuOption>>[
                const PopupMenuItem<MenuOption>(
                  value: MenuOption.withdraw,
                  child: Text('Withdraw'),
                ),
              ],
            ),
          ],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                if (loading)
                  const Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text(
                            'Loading...',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (purchasing)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          const Text(
                            'Purchasing...',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '$purchaseName for $purchaseAmount EURb',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (ready && products.isEmpty && !purchasing)
                  const Expanded(
                    child: Center(
                      child: Text('No products configured'),
                    ),
                  ),
                if (ready && products.isNotEmpty && !purchasing)
                  Expanded(
                    child: CustomScrollView(
                      slivers: [
                        const SliverToBoxAdapter(
                          child: Text(
                            'Products',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ),
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            childCount: products.length,
                            (context, index) {
                              final product = products[index];

                              return Card(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ListTile(
                                      leading: Image.asset(product.image),
                                      title: Text(product.name),
                                      subtitle: Text(formatCurrency(
                                          double.tryParse(product.price) ?? 0.0,
                                          'EURb')),
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: <Widget>[
                                        const SizedBox(width: 8),
                                        TextButton(
                                          child: Text(purchasing ? '' : 'BUY'),
                                          onPressed: () {
                                            if (!purchasing) {
                                              handlePurchase(product);
                                            }
                                          },
                                        ),
                                        const SizedBox(width: 8),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        )
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        floatingActionButton: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Opacity(
              opacity: !purchasing ? 1 : 0.5,
              child: FloatingActionButton.extended(
                heroTag: 'topup',
                onPressed: !purchasing ? handleTopUp : null,
                tooltip: 'Top up',
                label: const Text('Top up'),
                icon: const Icon(
                  Icons.add,
                ),
              ),
            ),
            const SizedBox(width: 20),
            Opacity(
              opacity: !purchasing ? 1 : 0.5,
              child: FloatingActionButton.extended(
                heroTag: 'readnfc',
                onPressed: !purchasing ? handleReadNFC : null,
                tooltip: 'Read my card',
                label: const Text('Read my card'),
                icon: const Icon(
                  Icons.nfc,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
