import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../data/models/company/company_model.dart';
import '../data/models/sales/sales_order_detail_model.dart';
import 'pdf_fonts.dart';

class InvoicePdf {
  static Future<Uint8List> buildSaleInvoice({
    required SalesOrderDetailModel detail,
    CompanyModel? company,
    String currencySymbol = 'Tk ',
  }) async {
    final doc = pw.Document();

    final regularFont = await PdfFonts.regular;
    final boldFont = await PdfFonts.bold;
    final bengaliRegular = await PdfFonts.bengaliRegular;
    final bengaliBold = await PdfFonts.bengaliBold;

    final invoice = detail.order.invoiceNumber.isNotEmpty
        ? detail.order.invoiceNumber
        : detail.order.id ?? '';

    final date = detail.order.saleDate;
    final dateText =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    // Shop name / company name (might contain Bengali)
    final shopTitle = company?.shopName.isNotEmpty == true
        ? company!.shopName
        : company?.name.isNotEmpty == true
            ? company!.name
            : 'Invoice';

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    shopTitle,
                    style: pw.TextStyle(
                      font: fontFor(shopTitle, boldFont, bengaliBold),
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text('Invoice: $invoice',
                      style: pw.TextStyle(
                        font: fontFor('Invoice: $invoice',
                            regularFont, bengaliRegular),
                      )),
                  pw.Text('Date: $dateText',
                      style: pw.TextStyle(
                        font: fontFor(
                            'Date: $dateText', regularFont, bengaliRegular),
                      )),
                ],
              ),
            ),
            pw.SizedBox(height: 12),
            _buildInvoiceTable(regularFont, boldFont, bengaliRegular, detail.items),
            pw.SizedBox(height: 16),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'Subtotal: $currencySymbol${detail.order.subtotal.toStringAsFixed(2)}',
                    style: pw.TextStyle(font: regularFont),
                  ),
                  pw.Text(
                    'Tax: $currencySymbol${detail.order.taxAmount.toStringAsFixed(2)}',
                    style: pw.TextStyle(font: regularFont),
                  ),
                  pw.Text(
                    'Discount: $currencySymbol${detail.order.discountAmount.toStringAsFixed(2)}',
                    style: pw.TextStyle(font: regularFont),
                  ),
                  pw.Text(
                    'Shipping: $currencySymbol${detail.order.shippingCharge.toStringAsFixed(2)}',
                    style: pw.TextStyle(font: regularFont),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    'Total: $currencySymbol${detail.order.totalAmount.toStringAsFixed(2)}',
                    style: pw.TextStyle(
                      font: boldFont,
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );

    return doc.save();
  }

  /// Builds the invoice items table with Bengali-aware font selection.
  static pw.Widget _buildInvoiceTable(
    pw.Font regularFont,
    pw.Font boldFont,
    pw.Font bengaliRegular,
    List<SalesOrderItemDetailModel> items,
  ) {
    // Check if any item name contains Bengali text
    final hasBengali = items.any((item) {
      final name = (item.productName?.isNotEmpty == true)
          ? item.productName!
          : (item.productSku?.isNotEmpty == true)
              ? item.productSku!
              : item.productId;
      return containsBengali(name);
    });

    final cellFont = hasBengali ? bengaliRegular : regularFont;

    return pw.Table.fromTextArray(
      headers: const ['Item', 'Qty', 'Unit', 'Total'],
      data: [
        for (final item in items)
          [
            (item.productName?.isNotEmpty == true)
                ? item.productName!
                : (item.productSku?.isNotEmpty == true)
                    ? item.productSku!
                    : item.productId,
            item.quantity.toString(),
            item.unitPrice.toStringAsFixed(2),
            (item.quantity * item.unitPrice).toStringAsFixed(2),
          ]
      ],
      headerStyle: pw.TextStyle(
        font: boldFont,
        fontWeight: pw.FontWeight.bold,
      ),
      cellAlignment: pw.Alignment.centerLeft,
      cellStyle: pw.TextStyle(font: cellFont),
      cellAlignments: {
        1: pw.Alignment.centerRight,
        2: pw.Alignment.centerRight,
        3: pw.Alignment.centerRight,
      },
      columnWidths: {
        0: const pw.FlexColumnWidth(4),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FlexColumnWidth(2),
      },
    );
  }
}
