import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../data/models/sales/sales_order_model.dart';
import '../data/repositories/reports_repository.dart';
import '../presentation/features/dashboard/providers/dashboard_stats_provider.dart';
import 'pdf_fonts.dart';

/// Holds loaded fonts so each build method can pass them to helpers.
/// Provides smart Bengali-aware font selection.
class _LoadedFonts {
  final pw.Font interRegular;
  final pw.Font interBold;
  final pw.Font bengaliRegular;
  final pw.Font bengaliBold;

  _LoadedFonts({
    required this.interRegular,
    required this.interBold,
    required this.bengaliRegular,
    required this.bengaliBold,
  });

  static Future<_LoadedFonts> load() async {
    return _LoadedFonts(
      interRegular: await PdfFonts.regular,
      interBold: await PdfFonts.bold,
      bengaliRegular: await PdfFonts.bengaliRegular,
      bengaliBold: await PdfFonts.bengaliBold,
    );
  }

  /// Returns the appropriate regular font for [text].
  pw.Font regular(String text) =>
      fontFor(text, interRegular, bengaliRegular);

  /// Returns the appropriate bold font for [text].
  pw.Font bold(String text) => fontFor(text, interBold, bengaliBold);

  pw.TextStyle textStyle(String text, {double? fontSize}) =>
      pw.TextStyle(font: regular(text), fontSize: fontSize);

  pw.TextStyle boldStyle(String text, {double? fontSize}) =>
      pw.TextStyle(font: bold(text), fontSize: fontSize, fontWeight: pw.FontWeight.bold);
}

class ReportPdf {
  ReportPdf._();

  static Future<Uint8List> buildDashboardSummary({
    required DashboardStats stats,
    required List<SalesOrderModel> recentSales,
    required List<StockReportLine> lowStock,
  }) async {
    final doc = _document('Dashboard Summary');
    final f = await _LoadedFonts.load();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (_) => [
          _header(f, 'Dashboard Summary', 'Live operational snapshot'),
          _summaryRow(f, [
            ('Total products', stats.totalProducts.toString()),
            ('Low stock', stats.lowStockCount.toString()),
            ('Today sales', _money(stats.todaySales)),
            ('Monthly revenue', _money(stats.monthRevenue)),
          ]),
          _sectionTitle(f, 'Weekly sales trend'),
          _simpleTable(
            f,
            headers: const ['Date', 'Sales'],
            rows: [
              for (final day in stats.weeklySales)
                [_date(day.date), _money(day.total)],
            ],
          ),
          _sectionTitle(f, 'Recent sales'),
          _simpleTable(
            f,
            headers: const ['Invoice', 'Customer', 'Amount', 'Status'],
            rows: [
              for (final sale in recentSales.take(8))
                [
                  sale.invoiceNumber.isEmpty
                      ? (sale.id ?? 'Sale')
                      : sale.invoiceNumber,
                  sale.customerName?.trim().isNotEmpty == true
                      ? sale.customerName!
                      : 'Walk-in',
                  _money(sale.totalAmount),
                  sale.paymentStatus,
                ],
            ],
          ),
          _sectionTitle(f, 'Low stock items'),
          _simpleTable(
            f,
            headers: const ['SKU', 'Name', 'Current', 'Minimum'],
            rows: [
              for (final item in lowStock.take(10))
                [
                  item.sku,
                  item.name,
                  item.currentStock.toString(),
                  item.minStock.toString(),
                ],
            ],
          ),
        ],
      ),
    );
    return doc.save();
  }

  static Future<Uint8List> buildSalesReport({
    required SalesReportData report,
  }) async {
    final doc = _document('Sales Report');
    final f = await _LoadedFonts.load();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (_) => [
          _header(f, 'Sales Report', '${_date(report.from)} → ${_date(report.to)}'),
          _summaryRow(f, [
            ('Orders', report.ordersCount.toString()),
            ('Revenue', _money(report.revenue)),
          ]),
          _sectionTitle(f, 'Daily totals'),
          _simpleTable(
            f,
            headers: const ['Date', 'Total'],
            rows: [
              for (final day in report.dailyTotals)
                [_date(day.date), _money(day.total)],
            ],
          ),
          _sectionTitle(f, 'Top products'),
          _simpleTable(
            f,
            headers: const ['Product', 'SKU', 'Qty', 'Revenue'],
            rows: [
              for (final product in report.topProducts)
                [
                  product.name,
                  product.sku ?? '-',
                  product.quantity.toString(),
                  _money(product.revenue),
                ],
            ],
          ),
        ],
      ),
    );
    return doc.save();
  }

  static Future<Uint8List> buildProfitReport({
    required ProfitReportData report,
  }) async {
    final doc = _document('Profit Report');
    final f = await _LoadedFonts.load();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (_) => [
          _header(f, 'Profit Report', '${_date(report.from)} → ${_date(report.to)}'),
          _summaryRow(f, [
            ('Revenue', _money(report.revenue)),
            ('COGS', _money(report.cogs)),
            ('Gross profit', _money(report.grossProfit)),
            ('Margin', '${report.marginPercent.toStringAsFixed(1)}%'),
          ]),
        ],
      ),
    );
    return doc.save();
  }

  static Future<Uint8List> buildStockReport({
    required List<StockReportLine> lines,
  }) async {
    final doc = _document('Stock Report');
    final f = await _LoadedFonts.load();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (_) => [
          _header(f, 'Stock Report', 'Current stock versus minimum stock'),
          _simpleTable(
            f,
            headers: const ['SKU', 'Name', 'Current', 'Minimum', 'Status'],
            rows: [
              for (final line in lines)
                [
                  line.sku,
                  line.name,
                  line.currentStock.toString(),
                  line.minStock.toString(),
                  line.isLowStock ? 'LOW' : 'OK',
                ],
            ],
          ),
        ],
      ),
    );
    return doc.save();
  }

  static Future<Uint8List> buildInventoryValuation({
    required InventoryValuationReportData report,
  }) async {
    final doc = _document('Inventory Valuation');
    final f = await _LoadedFonts.load();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (_) => [
          _header(f, 'Inventory Valuation', _date(report.generatedAt)),
          _summaryRow(f, [
            ('Total stock value', _money(report.totalValue)),
            ('Items', report.lines.length.toString()),
          ]),
          _simpleTable(
            f,
            headers: const ['SKU', 'Name', 'Qty', 'Unit cost', 'Value'],
            rows: [
              for (final line in report.lines.take(30))
                [
                  line.sku,
                  line.name,
                  line.quantity.toString(),
                  _money(line.unitCost),
                  _money(line.value),
                ],
            ],
          ),
        ],
      ),
    );
    return doc.save();
  }

  static Future<Uint8List> buildSupplierPerformance({
    required SupplierPerformanceReportData report,
  }) async {
    final doc = _document('Supplier Performance');
    final f = await _LoadedFonts.load();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (_) => [
          _header(f, 'Supplier Performance',
              '${_date(report.from)} → ${_date(report.to)}'),
          _simpleTable(
            f,
            headers: const [
              'Supplier',
              'Orders',
              'Received',
              'Ordered',
              'Received amt'
            ],
            rows: [
              for (final line in report.lines)
                [
                  line.name,
                  line.purchaseCount.toString(),
                  line.receivedCount.toString(),
                  _money(line.totalOrdered),
                  _money(line.receivedAmount),
                ],
            ],
          ),
        ],
      ),
    );
    return doc.save();
  }

  static pw.Document _document(String title) {
    return pw.Document(
      author: 'Bag Shop Inventory',
      title: title,
      creator: 'Bag Shop Inventory',
    );
  }

  static pw.Widget _header(_LoadedFonts f, String title, String subtitle) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title, style: f.boldStyle(title, fontSize: 20)),
        pw.SizedBox(height: 4),
        pw.Text(subtitle, style: f.textStyle(subtitle, fontSize: 11)),
        pw.SizedBox(height: 14),
      ],
    );
  }

  static pw.Widget _sectionTitle(_LoadedFonts f, String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 8, bottom: 8),
      child: pw.Text(text, style: f.boldStyle(text, fontSize: 14)),
    );
  }

  static pw.Widget _summaryRow(
      _LoadedFonts f, List<(String label, String value)> values) {
    return pw.Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final item in values)
          pw.Container(
            width: 170,
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(item.$1, style: f.textStyle(item.$1, fontSize: 9)),
                pw.SizedBox(height: 4),
                pw.Text(item.$2, style: f.boldStyle(item.$2, fontSize: 13)),
              ],
            ),
          ),
      ],
    );
  }

  static pw.Widget _simpleTable(
    _LoadedFonts f, {
    required List<String> headers,
    required List<List<String>> rows,
  }) {
    // Determine if any data cell contains Bengali text
    final hasBengali = rows.any((row) => row.any(containsBengali));

    final baseRegular = hasBengali ? f.bengaliRegular : f.interRegular;
    final baseBold = hasBengali ? f.bengaliBold : f.interBold;

    return pw.Table.fromTextArray(
      headers: headers,
      data: rows,
      headerStyle: pw.TextStyle(
        font: baseBold,
        fontWeight: pw.FontWeight.bold,
      ),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
      cellAlignment: pw.Alignment.centerLeft,
      cellStyle: pw.TextStyle(font: baseRegular, fontSize: 9),
      columnWidths: {
        for (var i = 0; i < headers.length; i++)
          i: const pw.FlexColumnWidth(),
      },
    );
  }

  static String _money(double value) => 'Tk ${value.toStringAsFixed(2)}';

  static String _date(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
