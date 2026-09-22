import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:excel/excel.dart' as xls;
import 'package:file_saver/file_saver.dart';

import '../models/contributor.dart';

/// Same two export formats the original "Records" screen offered.
class ExportService {
  ExportService._();
  static final ExportService instance = ExportService._();

  static const _headers = [
    'ID',
    'Full Name',
    'Card Type',
    'Amount (TZS)',
    'Date',
    'Phone',
    'Checked In',
    'Checked In Time',
  ];

  List<List<dynamic>> _rows(List<Contributor> list) => [
        _headers,
        ...list.map((r) => [
              r.id,
              r.fullName,
              r.cardType,
              r.amount,
              r.date,
              r.phone,
              r.checkedIn ? 'Yes' : 'No',
              r.checkedInTime ?? '',
            ]),
      ];

  Future<void> exportCsv(List<Contributor> list) async {
    final csv = const ListToCsvConverter().convert(_rows(list));
    final bytes = Uint8List.fromList(utf8.encode(csv));
    await FileSaver.instance.saveFile(
      name: 'wedding_contributors',
      bytes: bytes,
      fileExtension: 'csv',
      mimeType: MimeType.csv,
    );
  }

  Future<void> exportXlsx(List<Contributor> list) async {
    final book = xls.Excel.createExcel();
    final sheetName = 'Contributors';
    final sheet = book[sheetName];
    // createExcel() ships with a default 'Sheet1' - drop it once ours exists.
    if (book.sheets.containsKey('Sheet1') && sheetName != 'Sheet1') {
      book.delete('Sheet1');
    }
    for (final row in _rows(list)) {
      sheet.appendRow(row.map((v) => xls.TextCellValue(v.toString())).toList());
    }
    final bytes = book.encode();
    if (bytes == null) return;
    await FileSaver.instance.saveFile(
      name: 'wedding_contributors',
      bytes: Uint8List.fromList(bytes),
      fileExtension: 'xlsx',
      mimeType: MimeType.microsoftExcel,
    );
  }
}
