import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/medical_record_model.dart';

class PdfExportUtil {
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
  static Future<pw.Document> generateMedicalRecordPdf(
    MedicalRecord record,
    String patientName,
    String patientNumber,
  ) async {
    final pdf = pw.Document();
    final theme = await _getTheme();
    final logo = await _getLogo();

    pdf.addPage(
      pw.MultiPage(
        pageTheme: _buildPageTheme(theme),
        header: (context) => _buildHeader(context, logo),
        footer: _buildFooter,
        build:
            (context) => [
              _buildPatientInfo(record, patientName, patientNumber),
              pw.SizedBox(height: 20),
              _buildMedicalRecordDetails(record),
              pw.SizedBox(height: 20),
              _buildSection(
                'الوصفة الطبية',
                record.prescription ?? 'لا توجد وصفة طبية',
              ),
              if (record.notes != null && record.notes!.isNotEmpty)
                _buildSection('ملاحظات إضافية', record.notes!),
            ],
      ),
    );
    return pdf;
  }

  static Future<pw.ImageProvider?> _getLogo() async {
    try {
      final logoData = await rootBundle.load('assets/images/logo.png');
      return pw.MemoryImage(logoData.buffer.asUint8List());
    } catch (e) {
      debugPrint('Logo not found, skipping: $e');
      return null;
    }
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
  static pw.Widget _buildHeader(pw.Context context, pw.ImageProvider? logo) {
    return pw.Column(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'تقرير طبي',
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                    color: _primaryColor,
                  ),
                ),
              ],
            ),
            if (logo != null)
              pw.SizedBox(height: 50, width: 50, child: pw.Image(logo)),
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
                'تم الإنشاء في: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
                style: const pw.TextStyle(fontSize: 9, color: _secondaryColor),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- CONTENT WIDGETS ---
  static pw.Widget _buildPatientInfo(
    MedicalRecord record,
    String patientName,
    String patientNumber,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('معلومات المريض'),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: _borderColor, width: _borderWidth),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          ),
          child: pw.Table(
            columnWidths: {
              0: const pw.FlexColumnWidth(1),
              1: const pw.FlexColumnWidth(2),
            },
            children: [
              _buildTableRow('اسم المريض:', patientName),
              _buildTableRow('رقم المريض:', patientNumber ?? 'غير محدد'),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildMedicalRecordDetails(MedicalRecord record) {
    String formattedDate;
    try {
      formattedDate = DateFormat(
        'yyyy-MM-dd',
      ).format(DateTime.parse(record.date));
    } catch (e) {
      formattedDate = record.date; // Fallback to original string
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('تفاصيل التقرير الطبي'),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: _borderColor, width: _borderWidth),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          ),
          child: pw.Table(
            columnWidths: {
              0: const pw.FlexColumnWidth(1),
              1: const pw.FlexColumnWidth(2),
            },
            children: [
              _buildTableRow('تاريخ التقرير:', formattedDate),
              _buildTableRow('اسم الطبيب:', record.doctorName ?? 'غير محدد'),
              _buildTableRow('التشخيص:', record.diagnosis, isLast: true),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildSection(String title, String content) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(title),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: _borderColor, width: _borderWidth),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          ),
          child: pw.Text(content, textAlign: pw.TextAlign.right),
        ),
        pw.SizedBox(height: 20),
      ],
    );
  }

  // --- HELPER WIDGETS ---
  static pw.TableRow _buildTableRow(
    String label,
    String value, {
    bool isLast = false,
  }) {
    return pw.TableRow(
      decoration: pw.BoxDecoration(
        border:
            isLast
                ? null
                : pw.Border(
                  bottom: pw.BorderSide(color: _borderColor, width: 0.5),
                ),
      ),
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          child: pw.Text(value),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          child: pw.Text(
            label,
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: _primaryColor,
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildSectionTitle(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
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

  /// Print the medical record
  static Future<void> printMedicalRecord(
    MedicalRecord record,
    String patientName,
    String patientNumber,
  ) async {
    try {
      final pdf = await generateMedicalRecordPdf(
        record,
        patientName,
        patientNumber,
      );
      await Printing.layoutPdf(onLayout: (format) => pdf.save());
    } catch (e) {
      debugPrint('Error printing medical record: $e');
      // Consider showing a user-facing error message via the calling context.
    }
  }

  /// Share the medical record as a PDF file
  static Future<void> shareMedicalRecord(
    MedicalRecord record,
    String patientName,
    String patientNumber,
  ) async {
    try {
      final pdf = await generateMedicalRecordPdf(
        record,
        patientName,
        patientNumber,
      );
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/medical_record_${record.id}.pdf');
      await file.writeAsBytes(await pdf.save());

      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'التقرير الطبي للمريض: $patientName');
    } catch (e) {
      debugPrint('Error sharing medical record: $e');
      // Consider showing a user-facing error message via the calling context.
    }
  }
}
