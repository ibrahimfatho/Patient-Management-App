import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

class ReportPdfExportUtil {
  // --- THEME AND STYLING ---
  static const PdfColor _primaryColor = PdfColor.fromInt(
    0xFF003366,
  ); // A deep blue
  static const PdfColor _secondaryColor = PdfColor.fromInt(0xFF667C99);
  static const PdfColor _borderColor = PdfColor.fromInt(0xFFCCCCCC);
  static const double _borderWidth = 1.5;

  static Future<pw.ThemeData> _getTheme() async {
    final fontData = await rootBundle.load(
      'assets/fonts/NotoSansArabic-Regular.ttf',
    );
    final ttf = pw.Font.ttf(fontData.buffer.asByteData());
    return pw.ThemeData.withFont(base: ttf, bold: ttf);
  }

  // --- PDF GENERATION ---
  static Future<pw.Document> generateReportPdf({
    required int totalPatients,
    required int totalAppointments,
    required int scheduledAppointments,
    required int completedAppointments,
    required int cancelledAppointments,
    required int malePatients,
    required int femalePatients,
    required int childrenPatients,
    required int teenPatients,
    required int adultPatients,
    required int seniorPatients,
  }) async {
    final pdf = pw.Document();
    final theme = await _getTheme();

    pdf.addPage(
      pw.MultiPage(
        pageTheme: _buildPageTheme(theme),
        header: (context) => _buildHeader(context),
        footer: _buildFooter,
        build:
            (context) => [
              _buildSectionTitle('ملخص عام'),
              pw.SizedBox(height: 10),
              _buildInfoRow('إجمالي المرضى:', totalPatients.toString()),
              _buildInfoRow('إجمالي المواعيد:', totalAppointments.toString()),
              pw.SizedBox(height: 20),
              _buildSectionTitle('حالة المواعيد'),
              pw.SizedBox(height: 10),
              _buildInfoRow('قيد الانتظار:', scheduledAppointments.toString()),
              _buildInfoRow('مكتملة:', completedAppointments.toString()),
              _buildInfoRow('ملغاة:', cancelledAppointments.toString()),
              pw.SizedBox(height: 20),
              _buildSectionTitle('توزيع الجنس'),
              pw.SizedBox(height: 10),
              _buildInfoRow('ذكور:', malePatients.toString()),
              _buildInfoRow('إناث:', femalePatients.toString()),
              pw.SizedBox(height: 20),
              _buildSectionTitle('الفئات العمرية'),
              pw.SizedBox(height: 10),
              _buildInfoRow('أطفال (0-12):', childrenPatients.toString()),
              _buildInfoRow('مراهقون (13-19):', teenPatients.toString()),
              _buildInfoRow('بالغون (20-59):', adultPatients.toString()),
              _buildInfoRow('كبار السن (60+):', seniorPatients.toString()),
            ],
      ),
    );
    return pdf;
  }

  static pw.PageTheme _buildPageTheme(pw.ThemeData theme) {
    return pw.PageTheme(
      pageFormat: PdfPageFormat.a4,
      theme: theme,
      textDirection: pw.TextDirection.rtl,
      margin: const pw.EdgeInsets.all(30),
    );
  }

  // --- HEADER & FOOTER WIDGETS ---
  static pw.Widget _buildHeader(pw.Context context) {
    return pw.Column(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  'تقرير الأداء العام',
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                    color: _primaryColor,
                  ),
                ),
                pw.Text(
                  'تاريخ التقرير: ${DateFormat('yyyy-MM-dd').format(DateTime.now())}',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: _secondaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Divider(color: _borderColor, thickness: _borderWidth),
        pw.SizedBox(height: 10),
      ],
    );
  }

  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.center,
      margin: const pw.EdgeInsets.only(top: 10),
      child: pw.Column(
        children: [
          pw.Divider(color: _borderColor),
          pw.SizedBox(height: 5),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'صفحة ${context.pageNumber} من ${context.pagesCount}',
                style: const pw.TextStyle(fontSize: 9, color: _secondaryColor),
              ),
              pw.Text(
                'نظام إدارة المرضى',
                style: const pw.TextStyle(fontSize: 9, color: _secondaryColor),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        children: [
          pw.Expanded(
            flex: 3,
            child: pw.Text(
              label,
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: _primaryColor,
              ),
            ),
          ),
          pw.SizedBox(width: 20),
          pw.Expanded(
            flex: 2,
            child: pw.Text(
              value,
              textAlign: pw.TextAlign.right,
              style: const pw.TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSectionTitle(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 16,
          fontWeight: pw.FontWeight.bold,
          color: _primaryColor,
        ),
      ),
    );
  }

  // --- PUBLIC API ---
  static Future<void> printReport({
    required Map<String, int> reportData,
  }) async {
    try {
      final pdf = await _generatePdfFromMap(reportData);
      await Printing.layoutPdf(onLayout: (format) => pdf.save());
    } catch (e) {
      debugPrint('Error printing report: $e');
    }
  }

  static Future<void> shareReport({
    required Map<String, int> reportData,
  }) async {
    try {
      final pdf = await _generatePdfFromMap(reportData);
      final output = await getTemporaryDirectory();
      final file = File(
        '${output.path}/admin_report_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
      );
      await file.writeAsBytes(await pdf.save());

      await Share.shareXFiles([XFile(file.path)], text: 'تقرير الأداء العام');
    } catch (e) {
      debugPrint('Error sharing report: $e');
    }
  }

  static Future<pw.Document> _generatePdfFromMap(Map<String, int> reportData) {
    return generateReportPdf(
      totalPatients: reportData['totalPatients'] ?? 0,
      totalAppointments: reportData['totalAppointments'] ?? 0,
      scheduledAppointments: reportData['scheduledAppointments'] ?? 0,
      completedAppointments: reportData['completedAppointments'] ?? 0,
      cancelledAppointments: reportData['cancelledAppointments'] ?? 0,
      malePatients: reportData['malePatients'] ?? 0,
      femalePatients: reportData['femalePatients'] ?? 0,
      childrenPatients: reportData['childrenPatients'] ?? 0,
      teenPatients: reportData['teenPatients'] ?? 0,
      adultPatients: reportData['adultPatients'] ?? 0,
      seniorPatients: reportData['seniorPatients'] ?? 0,
    );
  }
}
