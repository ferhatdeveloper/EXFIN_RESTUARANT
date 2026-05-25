import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ReceiptPrintService {
  static Future<void> printReceipt({
    required String receiptNo,
    required String cashier,
    required String tableNo,
    required List<Map<String, dynamic>> items,
    required double subtotal,
    required double discount,
    required double total,
    required double paid,
    String firmName = 'DESTERHAN RESTUARANT',
  }) async {
    final pdf = pw.Document();

    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat(80 * PdfPageFormat.mm, double.infinity, marginAll: 4 * PdfPageFormat.mm),
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(firmName, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            pw.Text('Profesyonel ERP Çözümleri', style: const pw.TextStyle(fontSize: 8)),
            pw.SizedBox(height: 8),
            pw.Divider(thickness: 0.5),
            pw.SizedBox(height: 4),
            _pdfRow('FİŞ NO:', receiptNo),
            _pdfRow('TARİH:', DateTime.now().toString().substring(0, 19)),
            _pdfRow('KASİYER:', cashier),
            _pdfRow('MASA:', tableNo),
            pw.SizedBox(height: 6),
            pw.Divider(thickness: 0.5),
            pw.Row(children: [
              pw.Expanded(flex: 4, child: pw.Text('Ürün', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
              pw.Expanded(flex: 1, child: pw.Text('Ad', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center)),
              pw.Expanded(flex: 2, child: pw.Text('Tutar', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right)),
            ]),
            pw.Divider(thickness: 0.3),
            ...items.map((item) {
              final qty = item['qty'] ?? item['quantity'] ?? 1;
              final price = _toDouble(item['total']);
              return pw.Column(children: [
                pw.Row(children: [
                  pw.Expanded(flex: 4, child: pw.Text(item['name']?.toString() ?? '-', style: const pw.TextStyle(fontSize: 8))),
                  pw.Expanded(flex: 1, child: pw.Text('$qty', style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.center)),
                  pw.Expanded(flex: 2, child: pw.Text('${price.toStringAsFixed(0)} IQD', style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.right)),
                ]),
                pw.SizedBox(height: 2),
              ]);
            }),
            pw.Divider(thickness: 0.5),
            pw.SizedBox(height: 4),
            _pdfRow('ARA TOPLAM:', '${subtotal.toStringAsFixed(0)} IQD'),
            if (discount > 0) _pdfRow('İNDİRİM:', '-${discount.toStringAsFixed(0)} IQD'),
            _pdfRow('TOPLAM:', '${total.toStringAsFixed(0)} IQD', bold: true),
            pw.SizedBox(height: 4),
            _pdfRow('ÖDENEN:', '${paid.toStringAsFixed(0)} IQD'),
            pw.SizedBox(height: 10),
            pw.BarcodeWidget(data: receiptNo, barcode: pw.Barcode.code128(), width: 120, height: 30),
            pw.SizedBox(height: 6),
            pw.Text('Teşekkür ederiz!', style: const pw.TextStyle(fontSize: 9)),
          ],
        );
      },
    ));

    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }

  static pw.Widget _pdfRow(String label, String value, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 8, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
          pw.Text(value, style: pw.TextStyle(fontSize: 8, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        ],
      ),
    );
  }

  static double _toDouble(dynamic val) {
    if (val == null) return 0;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0;
  }
}
