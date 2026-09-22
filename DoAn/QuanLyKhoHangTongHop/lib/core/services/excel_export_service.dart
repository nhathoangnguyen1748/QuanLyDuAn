import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:printing/printing.dart';
import '../models/product_sku.dart';
import '../models/cycle_count_session.dart';
import '../utils/date_formatter.dart';

class ExcelExportService {
  /// Xuất toàn bộ danh mục hàng tồn kho ra file Excel (.xlsx)
  static Future<void> exportInventory(List<ProductSKU> products) async {
    final excel = Excel.createExcel();
    final Sheet sheet = excel[excel.getDefaultSheet() ?? 'Sheet1'];
    excel.rename(sheet.sheetName, 'TonKho');

    // Header
    sheet.appendRow([
      TextCellValue('STT'),
      TextCellValue('Mã SKU'),
      TextCellValue('Mã Vạch Barcode'),
      TextCellValue('Tên Hàng Hóa'),
      TextCellValue('Ngành Hàng'),
      TextCellValue('Đơn Vị'),
      TextCellValue('Vị Trí Kệ'),
      IntCellValue(0), // Tồn Hiện Tại header placeholder -> will be text
      IntCellValue(0), // Tồn An Toàn
      IntCellValue(0), // Tồn Tối Đa
      DoubleCellValue(0.0), // Giá Nhập
      DoubleCellValue(0.0), // Giá Bán
      DoubleCellValue(0.0), // Tổng Giá Trị
      TextCellValue('Hạn Sử Dụng'),
    ]);

    // Replace header cells with actual header texts
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: 0)).value = TextCellValue('Tồn Hiện Tại');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: 0)).value = TextCellValue('Tồn An Toàn Min');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: 0)).value = TextCellValue('Tồn Tối Đa Max');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: 0)).value = TextCellValue('Giá Vốn MAC (VND)');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 11, rowIndex: 0)).value = TextCellValue('Giá Bán (VND)');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 12, rowIndex: 0)).value = TextCellValue('Tổng Giá Trị Tồn (VND)');

    for (int i = 0; i < products.length; i++) {
      final p = products[i];
      sheet.appendRow([
        IntCellValue(i + 1),
        TextCellValue(p.skuCode),
        TextCellValue(p.barcode),
        TextCellValue(p.name),
        TextCellValue(p.categoryName),
        TextCellValue(p.unit),
        TextCellValue(p.locationTag),
        IntCellValue(p.currentStock),
        IntCellValue(p.minSafetyStock),
        IntCellValue(p.maxStock),
        DoubleCellValue(p.costPrice),
        DoubleCellValue(p.sellingPrice),
        DoubleCellValue(p.totalInventoryValue),
        TextCellValue(DateFormatter.formatDate(p.expiryDate)),
      ]);
    }

    final fileBytes = excel.save();
    if (fileBytes != null) {
      await Printing.sharePdf(
        bytes: Uint8List.fromList(fileBytes),
        filename: 'BaoCao_TonKho_${DateTime.now().millisecondsSinceEpoch}.xlsx',
      );
    }
  }

  /// Xuất Báo Cáo Đối Soát Kiểm Kê ra Excel (.xlsx)
  static Future<void> exportCycleCount(CycleCountSession session) async {
    final excel = Excel.createExcel();
    final Sheet sheet = excel[excel.getDefaultSheet() ?? 'Sheet1'];
    excel.rename(sheet.sheetName, 'KiemKe');

    sheet.appendRow([
      TextCellValue('STT'),
      TextCellValue('Mã SKU'),
      TextCellValue('Mã Barcode'),
      TextCellValue('Tên Sản Phẩm'),
      TextCellValue('Vị Trí Kệ'),
      TextCellValue('Tồn Sổ Sách'),
      TextCellValue('Kiểm Thực Tế'),
      TextCellValue('Chênh Lệch (SL)'),
      TextCellValue('Chênh Lệch (%)'),
      TextCellValue('Chênh Lệch Giá Trị (VND)'),
      TextCellValue('Trạng Thái'),
    ]);

    for (int i = 0; i < session.items.length; i++) {
      final item = session.items[i];
      sheet.appendRow([
        IntCellValue(i + 1),
        TextCellValue(item.skuCode),
        TextCellValue(item.barcode),
        TextCellValue(item.skuName),
        TextCellValue(item.locationTag),
        IntCellValue(item.bookStock),
        IntCellValue(item.isAudited ? item.physicalCount : 0),
        IntCellValue(item.isAudited ? item.varianceQty : 0),
        DoubleCellValue(item.isAudited ? item.variancePercent : 0.0),
        DoubleCellValue(item.isAudited ? item.varianceValue : 0.0),
        TextCellValue(item.discrepancyStatus),
      ]);
    }

    final fileBytes = excel.save();
    if (fileBytes != null) {
      await Printing.sharePdf(
        bytes: Uint8List.fromList(fileBytes),
        filename: 'BienBan_KiemKe_${session.sessionCode}.xlsx',
      );
    }
  }
}
