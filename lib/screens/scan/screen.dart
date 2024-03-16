import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:scanner/state/scan/logic.dart';
import 'package:scanner/state/scan/state.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  late ScanLogic _logic;

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

  void handleScan() {
    _logic.start();
    print('scanning');
  }

  void handleStopScan() {
    _logic.stop();
    print('stopping');
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<ScanState>().loading;
    final ready = context.watch<ScanState>().ready;

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: handleBack,
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Hello',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                if (loading) const CircularProgressIndicator(),
                if (ready)
                  FilledButton(
                    onPressed: handleScan,
                    child: const Text('Scan'),
                  ),
                if (ready)
                  FilledButton(
                    onPressed: handleStopScan,
                    child: const Text('Stop'),
                  )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
