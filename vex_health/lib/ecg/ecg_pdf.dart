// VEX Health — دروستکردن و ناردنی PDF ی ڕاپۆرتی ECG
//
// وێنەی PNG ی کاغەزی ڕاپۆرت (لە RepaintBoundary) دەخرێتە ناو PDF ی A4 و لە ڕێگەی شیتی سیستەمەوە دەنێردرێت
// (Save to Files / WhatsApp / Telegram / Mail ...).
import 'dart:typed_data';
import 'dart:ui' show Rect;

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

/// [aspect] = پانی / بەرزیی وێنەکە
Future<void> shareEcgPdf(Uint8List png, double aspect, String fileName, Rect origin) async {
  final doc = pw.Document(title: 'VEX Health ECG Report', author: 'VEX Health');
  final img = pw.MemoryImage(png);
  const margin = 24.0;
  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(margin),
      build: (ctx) => pw.Align(
        alignment: pw.Alignment.topCenter,
        child: pw.Image(img, fit: pw.BoxFit.fitWidth),
      ),
    ),
  );
  final bytes = await doc.save();
  await Share.shareXFiles(
    [XFile.fromData(bytes, mimeType: 'application/pdf', name: fileName)],
    fileNameOverrides: [fileName],
    subject: 'VEX Health ECG',
    sharePositionOrigin: origin,
  );
}
