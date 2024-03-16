import 'dart:async';

import 'package:nfc_manager/nfc_manager.dart';

class NFCService {
  Future<String> readSerialNumber() async {
    // Check availability
    bool isAvailable = await NfcManager.instance.isAvailable();

    if (!isAvailable) {
      throw Exception('NFC is not available');
    }

    final completer = Completer<String>();

    NfcManager.instance.startSession(
      alertMessage: 'Scan your bracelet',
      onDiscovered: (NfcTag tag) async {
        final List<int> identifier = tag.data['mifare']['identifier'];

        String uid = identifier
            .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
            .join();
        print(uid);

        if (completer.isCompleted) return;
        completer.complete(uid);

        await NfcManager.instance.stopSession(alertMessage: 'Thank you!');
      },
      onError: (error) async {
        if (completer.isCompleted) return;
        completer.completeError(error); // Complete the Future with the error
      },
    );

    return completer.future;
  }

  Future<void> stop() async {
    await NfcManager.instance.stopSession();
  }
}
