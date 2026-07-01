import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/widgets/app_body.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../services/bulk_data_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../customers/providers/customer_provider.dart';
import '../../products/providers/product_provider.dart';
import '../../purchases/providers/supplier_admin_provider.dart';
import '../../purchases/providers/suppliers_provider.dart';

class BulkDataScreen extends ConsumerStatefulWidget {
  const BulkDataScreen({super.key});

  @override
  ConsumerState<BulkDataScreen> createState() => _BulkDataScreenState();
}

class _BulkDataScreenState extends ConsumerState<BulkDataScreen> {
  final _productCsvCtrl = TextEditingController();
  final _supplierCsvCtrl = TextEditingController();
  final _customerCsvCtrl = TextEditingController();
  String _status = '';
  bool _busy = false;

  @override
  void dispose() {
    _productCsvCtrl.dispose();
    _supplierCsvCtrl.dispose();
    _customerCsvCtrl.dispose();
    super.dispose();
  }

  Future<void> _setExportText(
      TextEditingController controller, String csv, String label) async {
    controller.text = csv;
    await Clipboard.setData(ClipboardData(text: csv));
    await Share.share(csv, subject: '$label CSV export');
    if (!mounted) return;
    setState(() => _status = '$label exported and copied to clipboard.');
  }

  Future<void> _importProducts(String companyId) async {
    setState(() => _busy = true);
    try {
      final result = await ref.read(bulkDataServiceProvider).importProductsCsv(
            companyId: companyId,
            csvText: _productCsvCtrl.text,
          );
      ref.invalidate(productsProvider);
      ref.invalidate(productsStreamProvider);
      ref.invalidate(categoriesProvider);
      ref.invalidate(brandsProvider);
      if (!mounted) return;
      setState(() => _status =
          'Products import: ${result.created} created, ${result.updated} updated, ${result.skipped} skipped.');
      for (final warning in result.warnings) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(warning)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _importSuppliers(String companyId) async {
    setState(() => _busy = true);
    try {
      final result = await ref.read(bulkDataServiceProvider).importSuppliersCsv(
            companyId: companyId,
            csvText: _supplierCsvCtrl.text,
          );
      ref.invalidate(suppliersAdminProvider);
      ref.invalidate(suppliersProvider);
      if (!mounted) return;
      setState(() => _status =
          'Suppliers import: ${result.created} created, ${result.updated} updated, ${result.skipped} skipped.');
      for (final warning in result.warnings) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(warning)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _importCustomers(String companyId) async {
    setState(() => _busy = true);
    try {
      final result = await ref.read(bulkDataServiceProvider).importCustomersCsv(
            companyId: companyId,
            csvText: _customerCsvCtrl.text,
          );
      ref.invalidate(customersProvider);
      if (!mounted) return;
      setState(() => _status =
          'Customers import: ${result.created} created, ${result.updated} updated, ${result.skipped} skipped.');
      for (final warning in result.warnings) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(warning)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final companyId = ref.watch(authProvider).companyId;

    if (companyId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Data Tools')),
        body: const AppBody(
          child: EmptyState(
            title: 'No company linked',
            message:
                'Sign in with an admin or staff account that has a company.',
            icon: Icons.lock_outline,
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Data Tools'),
          actions: [
            IconButton(
              tooltip: 'Copy status',
              onPressed: _status.isEmpty
                  ? null
                  : () async {
                      await Clipboard.setData(ClipboardData(text: _status));
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Status copied.')),
                      );
                    },
              icon: const Icon(Icons.copy_outlined),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Products'),
              Tab(text: 'Suppliers'),
              Tab(text: 'Customers'),
            ],
          ),
        ),
        body: Column(
          children: [
            if (_status.isNotEmpty)
              Container(
                width: double.infinity,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                padding: const EdgeInsets.all(12),
                child: Text(_status),
              ),
            Expanded(
              child: TabBarView(
                children: [
                  _BulkPanel(
                    title: 'Products CSV',
                    description:
                        'Export the current catalog or paste CSV to create/update products.',
                    controller: _productCsvCtrl,
                    busy: _busy,
                    onExport: () async {
                      final csv = await ref
                          .read(bulkDataServiceProvider)
                          .exportProductsCsv(companyId: companyId);
                      await _setExportText(_productCsvCtrl, csv, 'Products');
                    },
                    onImport: () => _importProducts(companyId),
                    sampleCsv:
                        'sku,name,description,category,brand,bag_type,material,color,size,dimensions,weight_grams,barcode,unit_cost,selling_price,wholesale_price,min_stock,max_stock,reorder_point,is_active,has_warranty,warranty_months\nBAG-CSV-001,Example Backpack,Example import row,Backpacks,Urban Nomad,Backpack,Polyester,Black,Medium,18 x 12 x 7 in,900,BAR-BAG-CSV-001,20,45,35,5,25,5,true,false,0',
                    shareTitle: 'Products CSV export',
                  ),
                  _BulkPanel(
                    title: 'Suppliers CSV',
                    description:
                        'Export suppliers or paste a single-column CSV with name rows.',
                    controller: _supplierCsvCtrl,
                    busy: _busy,
                    onExport: () async {
                      final csv = await ref
                          .read(bulkDataServiceProvider)
                          .exportSuppliersCsv(companyId: companyId);
                      await _setExportText(_supplierCsvCtrl, csv, 'Suppliers');
                    },
                    onImport: () => _importSuppliers(companyId),
                    sampleCsv: 'name\nABC Bags Wholesale\nMetro Supply House',
                    shareTitle: 'Suppliers CSV export',
                  ),
                  _BulkPanel(
                    title: 'Customers CSV',
                    description:
                        'Export customers or paste a name/phone CSV to add buyers quickly.',
                    controller: _customerCsvCtrl,
                    busy: _busy,
                    onExport: () async {
                      final csv = await ref
                          .read(bulkDataServiceProvider)
                          .exportCustomersCsv(companyId: companyId);
                      await _setExportText(_customerCsvCtrl, csv, 'Customers');
                    },
                    onImport: () => _importCustomers(companyId),
                    sampleCsv:
                        'name,phone\nJohn Doe,+8801711111111\nJane Smith,+8801722222222',
                    shareTitle: 'Customers CSV export',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BulkPanel extends StatelessWidget {
  final String title;
  final String description;
  final TextEditingController controller;
  final bool busy;
  final VoidCallback onImport;
  final VoidCallback onExport;
  final String sampleCsv;
  final String shareTitle;

  const _BulkPanel({
    required this.title,
    required this.description,
    required this.controller,
    required this.busy,
    required this.onImport,
    required this.onExport,
    required this.sampleCsv,
    required this.shareTitle,
  });

  @override
  Widget build(BuildContext context) {
    return AppBody(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(description),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      FilledButton.icon(
                        onPressed: busy ? null : onExport,
                        icon: const Icon(Icons.file_download_outlined),
                        label: const Text('Export to clipboard'),
                      ),
                      OutlinedButton.icon(
                        onPressed: busy
                            ? null
                            : () {
                                controller.text = sampleCsv;
                              },
                        icon: const Icon(Icons.auto_fix_high_outlined),
                        label: const Text('Load example CSV'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            enabled: !busy,
            minLines: 12,
            maxLines: 20,
            decoration: const InputDecoration(
              labelText: 'CSV text',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: busy ? null : onImport,
                  icon: busy
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.upload_outlined),
                  label: const Text('Import CSV'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('How export works'),
              subtitle: Text(
                'The export is copied to your clipboard and shared with the system share sheet using "$shareTitle".',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
