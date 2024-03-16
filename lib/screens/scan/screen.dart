import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:scanner/state/products/state.dart';
import 'package:scanner/state/scan/logic.dart';
import 'package:scanner/state/scan/state.dart';
import 'package:scanner/utils/currency.dart';
import 'package:scanner/utils/strings.dart';

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

  void handlePurchase(Product product) {
    _logic.purchase(product.name, product.price);
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

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<ScanState>().loading;
    final ready = context.watch<ScanState>().ready;

    final purchasing = context.watch<ScanState>().purchasing;

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
                  label: Text(formatLongText(vendorAddress)))
              : null,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                if (loading || purchasing) const CircularProgressIndicator(),
                if (ready && products.isEmpty)
                  const Expanded(
                    child: Center(
                      child: Text('No products configured'),
                    ),
                  ),
                if (ready && products.isNotEmpty)
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
                                          'USDC')),
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
      ),
    );
  }
}
