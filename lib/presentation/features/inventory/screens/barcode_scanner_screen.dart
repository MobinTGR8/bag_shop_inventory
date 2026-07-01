import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/widgets/app_body.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../data/models/product/product_model.dart';
import '../../../../data/repositories/product_repository.dart';

class BarcodeScannerScreen extends ConsumerStatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  ConsumerState<BarcodeScannerScreen> createState() =>
      _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends ConsumerState<BarcodeScannerScreen> {
  final TextEditingController _barcodeController = TextEditingController();

  ProductModel? _matchedProduct;
  String? _lastScannedBarcode;
  String? _lookupError;
  bool _isLookingUp = false;

  @override
  void dispose() {
    _barcodeController.dispose();
    super.dispose();
  }

  Future<void> _lookupBarcode(String barcode) async {
    final code = barcode.trim();
    if (code.isEmpty || _isLookingUp) return;

    setState(() {
      _isLookingUp = true;
      _lookupError = null;
    });

    try {
      final product =
          await ref.read(productRepositoryProvider).getProductByBarcode(code);

      if (!mounted) return;
      setState(() {
        _matchedProduct = product;
        _lookupError =
            product == null ? 'No product matches this barcode.' : null;
        _lastScannedBarcode = code;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _matchedProduct = null;
        _lookupError = e.toString();
        _lastScannedBarcode = code;
      });
    } finally {
      if (mounted) {
        setState(() => _isLookingUp = false);
      }
    }
  }

  void _handleDetect(BarcodeCapture capture) {
    if (_isLookingUp) return;
    if (capture.barcodes.isEmpty) return;

    final raw = capture.barcodes.first.rawValue?.trim();
    if (raw == null || raw.isEmpty) return;
    if (raw == _lastScannedBarcode) return;

    _barcodeController.text = raw;
    _lookupBarcode(raw);
  }

  void _clearResult() {
    setState(() {
      _matchedProduct = null;
      _lookupError = null;
      _lastScannedBarcode = null;
      _barcodeController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Barcode Scanner'),
        actions: [
          IconButton(
            tooltip: 'Clear',
            onPressed: _clearResult,
            icon: const Icon(Icons.clear_all_outlined),
          ),
        ],
      ),
      body: AppBody(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const Card(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'Scan a product barcode or type one manually to find the matching item quickly.',
                ),
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 16 / 12,
                child: MobileScanner(
                  onDetect: _handleDetect,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _barcodeController,
              decoration: InputDecoration(
                labelText: 'Manual barcode lookup',
                prefixIcon: const Icon(Icons.qr_code_2_outlined),
                suffixIcon: IconButton(
                  tooltip: 'Search',
                  onPressed: _isLookingUp
                      ? null
                      : () => _lookupBarcode(_barcodeController.text),
                  icon: _isLookingUp
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.search),
                ),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: _lookupBarcode,
            ),
            const SizedBox(height: 12),
            if (_lookupError != null)
              Card(
                color: Theme.of(context)
                    .colorScheme
                    .errorContainer
                    .withValues(alpha: 0.35),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: ErrorState(
                    title: 'Lookup failed',
                    message: _lookupError!,
                    onRetry: _barcodeController.text.trim().isEmpty
                        ? null
                        : () => _lookupBarcode(_barcodeController.text),
                  ),
                ),
              )
            else if (_matchedProduct == null)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: EmptyState(
                    title: 'No product loaded yet',
                    message:
                        'Scan a barcode or enter one above to view the product record.',
                    icon: Icons.inventory_2_outlined,
                  ),
                ),
              )
            else
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _matchedProduct!.name,
                        style: tt.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      Text('SKU: ${_matchedProduct!.sku}'),
                      Text('Barcode: ${_matchedProduct!.barcode ?? '-'}'),
                      const SizedBox(height: 8),
                      Text(
                        'Price: Tk ${_matchedProduct!.sellingPrice.toStringAsFixed(2)}',
                        style: tt.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Text(
                          'Status: ${_matchedProduct!.isActive ? 'Active' : 'Inactive'}'),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          FilledButton.icon(
                            onPressed: _matchedProduct!.id == null
                                ? null
                                : () => context
                                    .go('/products/${_matchedProduct!.id}'),
                            icon: const Icon(Icons.open_in_new_outlined),
                            label: const Text('Open product'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () =>
                                _lookupBarcode(_barcodeController.text),
                            icon: const Icon(Icons.refresh_outlined),
                            label: const Text('Refresh lookup'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
