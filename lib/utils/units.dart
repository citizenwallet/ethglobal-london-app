/// toUnit takes a user readable amount and converts it to a BigInt
BigInt toUnit(String amount, {int decimals = 6}) {
  final exponent = decimals;
  return BigInt.from((double.tryParse(amount) ?? 0) *
      BigInt.from(10).pow(exponent < 0 ? 0 : exponent).toDouble());
}

/// fromUnit takes a BigInt and converts it into a user readable amount
String fromUnit(BigInt amount, {int decimals = 6}) {
  final pow = decimals;
  return BigInt.from(amount / BigInt.from(10).pow(pow < 0 ? 0 : pow))
      .toString();
}
