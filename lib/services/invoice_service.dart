import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/order_model.dart';

class InvoiceService {
  static Future<void> generateInvoice({
    required OrderModel order,
    required List<dynamic> items,
    required String companyName,
    required String companyAddress,
  }) async {
    final pdf = pw.Document();

    // تحميل الخط العربي
    final arabicFont = await _loadArabicFont();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        textDirection: pw.TextDirection.rtl,
        build: (pw.Context context) {
          return [
            _buildHeaderWithOrderInfo(companyName, companyAddress, order, arabicFont),
            pw.SizedBox(height: 8),
            _buildItemsTableWithHelper(items, arabicFont),
            pw.SizedBox(height: 8),
            _buildTotalSection(order, arabicFont),
            pw.SizedBox(height: 8),
            _buildFooter(arabicFont),
          ];
        },
      ),
    );

    // طباعة أو حفظ الفاتورة
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'فاتورة_طلب_${order.id.substring(0, 8)}.pdf',
    );
  }

  static Future<pw.Font> _loadArabicFont() async {
    final fontData = await rootBundle.load('assets/IBMPlexSansArabic-Medium.ttf');
    return pw.Font.ttf(fontData);
  }

  static pw.Widget _buildHeaderWithOrderInfo(
    String companyName,
    String companyAddress,
    OrderModel order,
    pw.Font arabicFont,
  ) {
    return pw.Column(
      children: [
        // معلومات الشركة في المنتصف
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(
              companyName,
              style: pw.TextStyle(
                font: arabicFont,
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey800,
              ),
              textDirection: pw.TextDirection.rtl,
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              companyAddress,
              style: pw.TextStyle(
                font: arabicFont,
                fontSize: 12,
                color: PdfColors.grey700,
              ),
              textDirection: pw.TextDirection.rtl,
            ),
          ],
        ),
        
        pw.SizedBox(height: 12),
        
        // مستطيل رمادي فاتح للمعلومات
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius: pw.BorderRadius.circular(6),
            border: pw.Border.all(color: PdfColors.grey300),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              // الجانب الأيمن - الاسم والتاريخ
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'الاسم: ${order.customerName}',
                    style: pw.TextStyle(
                      font: arabicFont,
                      fontSize: 10,
                      color: PdfColors.grey800,
                    ),
                    textDirection: pw.TextDirection.rtl,
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'التاريخ: ${_formatDate(order.createdAt)}',
                    style: pw.TextStyle(
                      font: arabicFont,
                      fontSize: 10,
                      color: PdfColors.grey800,
                    ),
                    textDirection: pw.TextDirection.rtl,
                  ),
                ],
              ),
              
              // الجانب الأيسر - الهاتف ورقم الفاتورة
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'رقم الهاتف: ${order.customerPhone}',
                    style: pw.TextStyle(
                      font: arabicFont,
                      fontSize: 10,
                      color: PdfColors.grey800,
                    ),
                    textDirection: pw.TextDirection.rtl,
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'رقم الفاتورة: ${order.id.substring(0, 8)}',
                    style: pw.TextStyle(
                      font: arabicFont,
                      fontSize: 10,
                      color: PdfColors.grey800,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }


  static pw.Widget _buildItemsTableWithHelper(List<dynamic> items, pw.Font arabicFont) {
    return pw.TableHelper.fromTextArray(
      context: null,
      cellAlignment: pw.Alignment.center,
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
      cellHeight: 20,
      cellAlignments: {
        0: pw.Alignment.center,
        1: pw.Alignment.center,
        2: pw.Alignment.center,
        3: pw.Alignment.center,
        4: pw.Alignment.center,
      },
      cellStyle: pw.TextStyle(
        font: arabicFont,
        fontSize: 7,
        color: PdfColors.grey700,
      ),
      headerStyle: pw.TextStyle(
        font: arabicFont,
        fontSize: 8,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.grey800,
      ),
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.3),
      columnWidths: {
        0: const pw.FlexColumnWidth(1.8),   // المجموع - يأخذ الباقي
        1: const pw.FlexColumnWidth(0.6), // السعر
        2: const pw.FlexColumnWidth(0.6), // الكمية
        3: const pw.FlexColumnWidth(0.6), // النوع
        4: const pw.FlexColumnWidth(0.6), // اسم المنتج
      },
      data: [
        // Header
        ['المجموع', 'السعر', 'الكمية', 'النوع', 'اسم المنتج'],
        // Items
        ...items.map((itemData) {
          final item = itemData as OrderItemModel;
          return [
            '${item.subtotal.toStringAsFixed(0)} د.ع',
            '${item.productPrice.toStringAsFixed(0)} د.ع',
            item.quantity.toString(),
            item.isCarton ? 'كارتون' : 'قطعة',
            item.productName,
          ];
        }).toList(),
      ],
    );
  }



  static pw.Widget _buildTotalSection(OrderModel order, pw.Font arabicFont) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'المجموع الإجمالي',
            style: pw.TextStyle(
              font: arabicFont,
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800,
            ),
            textDirection: pw.TextDirection.rtl,
          ),
          pw.Text(
            '${order.totalAmount.toStringAsFixed(0)} دينار عراقي',
            style: pw.TextStyle(
              font: arabicFont,
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800,
            ),
            textDirection: pw.TextDirection.rtl,
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(pw.Font arabicFont) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(6),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            'شكراً لاختياركم لمسة',
            style: pw.TextStyle(
              font: arabicFont,
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800,
            ),
            textDirection: pw.TextDirection.rtl,
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            'نتمنى لكم تجربة تسوق ممتعة',
            style: pw.TextStyle(
              font: arabicFont,
              fontSize: 7,
              color: PdfColors.grey600,
            ),
            textDirection: pw.TextDirection.rtl,
          ),
          pw.SizedBox(height: 4),
          pw.Container(
            width: double.infinity,
            height: 0.5,
            color: PdfColors.grey300,
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            'تم إنشاء هذه الفاتورة تلقائياً - ${_formatDate(DateTime.now())}',
            style: pw.TextStyle(
              font: arabicFont,
              fontSize: 6,
              color: PdfColors.grey500,
            ),
            textDirection: pw.TextDirection.rtl,
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }


}
