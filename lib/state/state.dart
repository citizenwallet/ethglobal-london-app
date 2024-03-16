import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scanner/state/products/state.dart';

Widget provideAppState(Widget child) => MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ProductsState(),
        ),
      ],
      child: child,
    );
