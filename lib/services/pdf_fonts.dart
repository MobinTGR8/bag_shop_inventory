import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;

/// Bengali Unicode range constants.
const _bengaliStart = 0x0980;
const _bengaliEnd = 0x09FF;

/// Returns true if [text] contains any Bengali/Bangla character.
bool containsBengali(String text) {
  for (final code in text.runes) {
    if (code >= _bengaliStart && code <= _bengaliEnd) return true;
  }
  return false;
}

/// Selects the best font for a piece of text:
/// - Bengali font (Noto Sans Bengali) if the text contains Bengali chars
/// - Inter font otherwise (covers Latin, symbols, arrows, etc.)
pw.Font fontFor(String text, pw.Font interFont, pw.Font bengaliFont) {
  return containsBengali(text) ? bengaliFont : interFont;
}

/// Loads a font from [ttfPath], falling back to [otfPath] if the TTF
/// file hasn't been downloaded yet (backward-compatible transition).
Future<pw.Font> _loadFont({
  required String ttfPath,
  required String otfPath,
}) async {
  // Try TTF first (Google Fonts - proper Unicode cmap for Bengali/symbols)
  try {
    final data = await rootBundle.load(ttfPath);
    final font = pw.Font.ttf(data);
    return font;
  } catch (_) {
    // Fallback to OTF for backward-compatibility
    final data = await rootBundle.load(otfPath);
    return pw.Font.ttf(data);
  }
}

/// Loads and caches fonts for PDF generation.
///
/// Uses TrueType (TTF) fonts from Google Fonts for proper Unicode/Bengali support:
/// - Inter (Latin, symbols, arrows, numbers)
/// - Noto Sans Bengali (Bengali/Bangla script)
///
/// Falls back to the bundled OTF files if TTF fonts haven't been downloaded yet.
class PdfFonts {
  PdfFonts._();

  static pw.Font? _regular;
  static pw.Font? _bold;
  static pw.Font? _semiBold;
  static pw.Font? _medium;

  static pw.Font? _bengaliRegular;
  static pw.Font? _bengaliBold;

  /// The regular-weight Inter font (Latin/symbols).
  static Future<pw.Font> get regular async {
    if (_regular != null) return _regular!;
    return _regular = await _loadFont(
      ttfPath: 'assets/fonts/Inter-Regular.ttf',
      otfPath: 'assets/fonts/Inter-Regular.otf',
    );
  }

  /// The bold-weight Inter font (Latin/symbols).
  static Future<pw.Font> get bold async {
    if (_bold != null) return _bold!;
    return _bold = await _loadFont(
      ttfPath: 'assets/fonts/Inter-Bold.ttf',
      otfPath: 'assets/fonts/Inter-Bold.otf',
    );
  }

  /// The semi-bold Inter font (Latin/symbols).
  static Future<pw.Font> get semiBold async {
    if (_semiBold != null) return _semiBold!;
    return _semiBold = await _loadFont(
      ttfPath: 'assets/fonts/Inter-SemiBold.ttf',
      otfPath: 'assets/fonts/Inter-SemiBold.otf',
    );
  }

  /// The medium Inter font (Latin/symbols).
  static Future<pw.Font> get medium async {
    if (_medium != null) return _medium!;
    return _medium = await _loadFont(
      ttfPath: 'assets/fonts/Inter-Medium.ttf',
      otfPath: 'assets/fonts/Inter-Medium.otf',
    );
  }

  /// The Noto Sans Bengali regular font.
  /// Falls back to Inter regular if Bengali font not yet downloaded.
  static Future<pw.Font> get bengaliRegular async {
    if (_bengaliRegular != null) return _bengaliRegular!;
    try {
      final data =
          await rootBundle.load('assets/fonts/NotoSansBengali-Regular.ttf');
      return _bengaliRegular = pw.Font.ttf(data);
    } catch (_) {
      // Fallback: use Inter regular (Latin only) if Bengali TTF not available
      return regular;
    }
  }

  /// The Noto Sans Bengali bold font.
  /// Falls back to Inter bold if Bengali font not yet downloaded.
  static Future<pw.Font> get bengaliBold async {
    if (_bengaliBold != null) return _bengaliBold!;
    try {
      final data =
          await rootBundle.load('assets/fonts/NotoSansBengali-Bold.ttf');
      return _bengaliBold = pw.Font.ttf(data);
    } catch (_) {
      // Fallback: use Inter bold (Latin only) if Bengali TTF not available
      return bold;
    }
  }

  /// Pre-loads all cached fonts (call once at app startup for best latency).
  static Future<void> preload() async {
    await Future.wait([
      regular,
      bold,
      semiBold,
      medium,
      bengaliRegular,
      bengaliBold,
    ]);
  }
}
