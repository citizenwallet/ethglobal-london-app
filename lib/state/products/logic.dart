import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scanner/state/products/state.dart';

class ProductsLogic {
  final ProductsState _state;

  ProductsLogic(BuildContext context) : _state = context.read<ProductsState>();

  void addProduct() {
    _state.addProduct();
  }

  void removeProduct(String id) {
    _state.removeProduct(id);
  }

  void updateProduct(Product product) {
    _state.updateProduct(product);
  }

  void clearProducts() {
    _state.clearProducts();
  }

  void clearForm() {
    _state.clearForm();
  }
}
