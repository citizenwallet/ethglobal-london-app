import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:scanner/state/products/logic.dart';
import 'package:scanner/state/products/state.dart';
import 'package:scanner/utils/currency.dart';
import 'package:scanner/utils/formatters.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  late ProductsLogic _logic;

  final FocusNode _amountFocusNode = FocusNode();
  final AmountFormatter _amountFormatter = AmountFormatter();

  @override
  void initState() {
    super.initState();

    _logic = ProductsLogic(context);
  }

  void handleAddProduct() {
    _logic.addProduct();

    FocusManager.instance.primaryFocus?.unfocus();
  }

  void handleStartScan() {
    GoRouter.of(context).push('/scan');
  }

  @override
  Widget build(BuildContext context) {
    final nameController = context.read<ProductsState>().nameController;
    final priceController = context.read<ProductsState>().priceController;

    final products = context.watch<ProductsState>().products;

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'Create Product',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                    ),
                    maxLines: 1,
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) => _amountFocusNode.requestFocus(),
                  ),
                  TextField(
                    controller: priceController,
                    decoration: const InputDecoration(
                      labelText: 'Price',
                      prefix: Text('USDC '),
                    ),
                    maxLines: 1,
                    maxLength: 25,
                    autocorrect: false,
                    enableSuggestions: false,
                    focusNode: _amountFocusNode,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: false,
                    ),
                    textInputAction: TextInputAction.done,
                    inputFormatters: [_amountFormatter],
                  ),
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

                              return ListTile(
                                leading: Image.asset(product.image),
                                title: Text(product.name),
                                subtitle: Text(formatCurrency(
                                    double.tryParse(product.price) ?? 0.0,
                                    'USDC')),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () =>
                                      _logic.removeProduct(product.id),
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
        floatingActionButton: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton(
              heroTag: 'add',
              onPressed: handleAddProduct,
              tooltip: 'Add Product',
              child: const Icon(Icons.add),
            ),
            const SizedBox(width: 20),
            FloatingActionButton.extended(
              onPressed: handleStartScan,
              tooltip: 'Start Scanning',
              label: const Text('Start Scanning'),
              icon: const Icon(
                Icons.nfc,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
