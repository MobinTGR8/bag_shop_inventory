// Run with: dart run scripts/download_pdf_fonts.dart
// This script downloads Inter TTF fonts and Noto Sans Bengali TTF fonts
// from Google Fonts for proper Unicode/Bengali PDF export support.

// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

final _fonts = <_FontSpec>[
  const _FontSpec(
    name: 'Inter-Regular.ttf',
    url:
        'https://fonts.gstatic.com/s/inter/v20/UcCO3FwrK3iLTeHuS_nVMrMxCp50SjIw2boKoduKmMEVuLyfMZg.ttf',
    weight: 400,
  ),
  const _FontSpec(
    name: 'Inter-Medium.ttf',
    url:
        'https://fonts.gstatic.com/s/inter/v20/UcCO3FwrK3iLTeHuS_nVMrMxCp50SjIw2boKoduKmMEVuI6fMZg.ttf',
    weight: 500,
  ),
  const _FontSpec(
    name: 'Inter-SemiBold.ttf',
    url:
        'https://fonts.gstatic.com/s/inter/v20/UcCO3FwrK3iLTeHuS_nVMrMxCp50SjIw2boKoduKmMEVuGKYMZg.ttf',
    weight: 600,
  ),
  const _FontSpec(
    name: 'Inter-Bold.ttf',
    url:
        'https://fonts.gstatic.com/s/inter/v20/UcCO3FwrK3iLTeHuS_nVMrMxCp50SjIw2boKoduKmMEVuFuYMZg.ttf',
    weight: 700,
  ),
  const _FontSpec(
    name: 'NotoSansBengali-Regular.ttf',
    url:
        'https://fonts.gstatic.com/s/notosansbengali/v33/Cn-SJsCGWQxOjaGwMQ6fIiMywrNJIky6nvd8BjzVMvJx2mcSPVFpVEqE-6KmsolLudA.ttf',
    weight: 400,
  ),
  const _FontSpec(
    name: 'NotoSansBengali-Bold.ttf',
    url:
        'https://fonts.gstatic.com/s/notosansbengali/v33/Cn-SJsCGWQxOjaGwMQ6fIiMywrNJIky6nvd8BjzVMvJx2mcSPVFpVEqE-6Kmsm5MudA.ttf',
    weight: 700,
  ),
];

class _FontSpec {
  final String name;
  final String url;
  final int weight;
  const _FontSpec({
    required this.name,
    required this.url,
    required this.weight,
  });
}

Future<void> main() async {
  final fontDir = Directory('assets/fonts');
  if (!fontDir.existsSync()) {
    fontDir.createSync(recursive: true);
  }

  print('Downloading PDF fonts from Google Fonts...\n');

  for (final font in _fonts) {
    final path = '${fontDir.path}/${font.name}';
    if (File(path).existsSync()) {
      print('  ✓ ${font.name} already exists, skipping');
      continue;
    }

    print('  Downloading ${font.name}...');
    try {
      final client = HttpClient();
      client.autoUncompress = true;
      final request = await client.getUrl(Uri.parse(font.url));
      final response = await request.close();

      if (response.statusCode != 200) {
        print('  ✗ Failed: HTTP ${response.statusCode}');
        client.close();
        continue;
      }

      final bytes = await consolidateHttpClientResponseBytes(response);
      await File(path).writeAsBytes(bytes);
      client.close();
      print('  ✓ ${font.name} downloaded (${bytes.length ~/ 1024} KB)');
    } catch (e) {
      print('  ✗ Error downloading ${font.name}: $e');
    }
  }

  // Remove old OTF files
  const oldFiles = [
    'Inter-Regular.otf',
    'Inter-Medium.otf',
    'Inter-SemiBold.otf',
    'Inter-Bold.otf',
  ];

  print('\nCleaning up old OTF files...');
  for (final oldFile in oldFiles) {
    final path = '${fontDir.path}/$oldFile';
    if (File(path).existsSync()) {
      File(path).deleteSync();
      print('  Removed $oldFile');
    }
  }

  print('\n✓ All PDF font files are ready!');
  print('Run "flutter clean && flutter pub get" to apply the changes.');
}

/// Reads all bytes from an HttpClientResponse (dart:io built-in).
Future<Uint8List> consolidateHttpClientResponseBytes(
    HttpClientResponse response) async {
  final completer = Completer<Uint8List>();
  final bytes = <int>[];
  response.listen(
    (data) {
      bytes.addAll(data);
    },
    onDone: () {
      completer.complete(Uint8List.fromList(bytes));
    },
    onError: (error) {
      completer.completeError(error);
    },
  );
  return completer.future;
}
