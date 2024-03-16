import 'package:flutter/material.dart';
import 'package:scanner/utils/currency.dart';

class Product {
  final String id;
  final String name;
  final String price;
  final String image;

  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.image,
  });
}

class ProductsState with ChangeNotifier {
  TextEditingController nameController = TextEditingController();
  TextEditingController priceController = TextEditingController();

  List<Product> products = [];

  void addProduct() {
    final product = Product(
      id: DateTime.now().toString(),
      name: nameController.text,
      price:
          formatCurrency(double.tryParse(priceController.text) ?? 0.0, 'USDC'),
      image: 'assets/product.png',
    );

    products.add(product);

    nameController.clear();
    priceController.clear();
    notifyListeners();
  }

  void removeProduct(String id) {
    products.removeWhere((element) => element.id == id);
    notifyListeners();
  }

  void updateProduct(Product product) {
    final index = products.indexWhere((element) => element.id == product.id);
    products[index] = product;
    notifyListeners();
  }

  void clearProducts() {
    products.clear();
    notifyListeners();
  }

  void clearForm() {
    nameController.clear();
    priceController.clear();
  }
}
