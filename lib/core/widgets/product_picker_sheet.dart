import 'package:flutter/material.dart';

import '../../data/models/product/product_model.dart';

/// Reusable bottom sheet that lets the user search and pick a product.
///
/// Used in StockTakeScreen, TransferStockScreen, AdjustStockScreen, and POS.
Future<ProductModel?> showProductPickerSheet({
  required BuildContext context,
  required List<ProductModel> products,
  String title = 'Search products',
}) {
  return showModalBottomSheet<ProductModel>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) {
      final searchCtrl = TextEditingController();
      return StatefulBuilder(
        builder: (context, setState) {
          final q = searchCtrl.text.trim().toLowerCase();
          final filtered = q.isEmpty
              ? products
              : products.where((p) {
                  final hay =
                      '${p.name} ${p.sku} ${p.barcode ?? ''} ${p.bagType ?? ''} ${p.material ?? ''}'
                          .toLowerCase();
                  return hay.contains(q);
                }).toList();

          return SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: searchCtrl,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: title,
                      hintText: 'Type name, SKU, or barcode…',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                searchCtrl.clear();
                                setState(() {});
                              },
                            )
                          : null,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: filtered.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 32),
                            child: Text('No matching products found'),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            itemCount: filtered.length.clamp(0, 40),
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final p = filtered[index];
                              return ListTile(
                                leading: CircleAvatar(
                                  radius: 18,
                                  backgroundColor:
                                      Theme.of(context).colorScheme.primaryContainer,
                                  child: Text(
                                    p.name.isNotEmpty
                                        ? p.name[0].toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimaryContainer,
                                    ),
                                  ),
                                ),
                                title: Text(p.name),
                                subtitle: Text(
                                  [
                                    p.sku,
                                    if (p.bagType != null && p.bagType!.isNotEmpty)
                                      p.bagType,
                                    if (p.barcode != null && p.barcode!.isNotEmpty)
                                      'Barcode: ${p.barcode}',
                                  ].join(' • '),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: Text(
                                  'Tk ${p.sellingPrice.toStringAsFixed(0)}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                onTap: () => Navigator.of(context).pop(p),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
