
import 'package:flutter/foundation.dart';
import 'package:printing/printing.dart';

class PdfExportService {
  PdfExportService._();

  static Future<void> present({
    required String filename,
    required Future<Uint8List> Function() build,
  }) async {
    final bytes = await build();
    if (kIsWeb) {
      await Printing.layoutPdf(onLayout: (_) async => bytes);
      return;
    }

    await Printing.sharePdf(bytes: bytes, filename: filename);
  }
}
