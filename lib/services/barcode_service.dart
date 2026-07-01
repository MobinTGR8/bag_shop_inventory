import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeService {
  static Future<String?> scanBarcode(BuildContext context) async {
    return Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const _BarcodeScanScreen()),
    );
  }
}

class _BarcodeScanScreen extends StatefulWidget {
  const _BarcodeScanScreen();

  @override
  State<_BarcodeScanScreen> createState() => _BarcodeScanScreenState();
}

class _BarcodeScanScreenState extends State<_BarcodeScanScreen> {
  bool _didReturn = false;

  void _return(String value) {
    if (_didReturn) return;
    _didReturn = true;
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan barcode'),
      ),
      body: MobileScanner(
        onDetect: (capture) {
          final barcodes = capture.barcodes;
          if (barcodes.isEmpty) return;
          final raw = barcodes.first.rawValue;
          if (raw == null || raw.isEmpty) return;
          _return(raw);
        },
      ),
    );
  }
}
