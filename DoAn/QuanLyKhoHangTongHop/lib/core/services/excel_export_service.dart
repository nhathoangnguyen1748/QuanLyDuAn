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
      TextCellValue('Tồn Hiện Tại'),
      TextCellValue('Tồn An Toàn Min'),
      TextCellValue('Tồn Tối Đa Max'),
      TextCellValue('Giá Vốn MAC (VND)'),
      TextCellValue('Giá Bán (VND)'),
      TextCellValue('Tổng Giá Trị Tồn (VND)'),
      TextCellValue('Hạn Sử Dụng'),
    ]);

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

  /// Xuất Báo Cáo Cảnh Báo Tồn Kho, Dead Stock & Hạn Dùng FEFO ra Excel (.xlsx)
  static Future<void> exportAlertsReport({
    required List<ProductSKU> lowStockProducts,
    required List<ProductSKU> deadStockProducts,
    required List<ProductSKU> expiringProducts,
  }) async {
    final excel = Excel.createExcel();

    // Sheet 1: Thiếu tồn kho an toàn
    final sheetLow = excel[excel.getDefaultSheet() ?? 'Sheet1'];
    excel.rename(sheetLow.sheetName, 'ThieuTonAnToan');
    sheetLow.appendRow([
      TextCellValue('STT'),
      TextCellValue('Mã SKU'),
      TextCellValue('Tên Hàng Hóa'),
      TextCellValue('Vị Trí Kệ'),
      TextCellValue('Đơn Vị'),
      TextCellValue('Tồn Hiện Tại'),
      TextCellValue('Định Mức Min'),
      TextCellValue('Số Lượng Thiếu Hụt'),
      TextCellValue('Giá Vốn MAC (VND)'),
      TextCellValue('Giá Trị Cần Bổ Sung (VND)'),
    ]);
    for (int i = 0; i < lowStockProducts.length; i++) {
      final p = lowStockProducts[i];
      final deficit = p.minSafetyStock - p.currentStock;
      sheetLow.appendRow([
        IntCellValue(i + 1),
        TextCellValue(p.skuCode),
        TextCellValue(p.name),
        TextCellValue(p.locationTag),
        TextCellValue(p.unit),
        IntCellValue(p.currentStock),
        IntCellValue(p.minSafetyStock),
        IntCellValue(deficit > 0 ? deficit : 0),
        DoubleCellValue(p.costPrice),
        DoubleCellValue(deficit > 0 ? deficit * p.costPrice : 0.0),
      ]);
    }

    // Sheet 2: Hàng chậm luân chuyển (Dead Stock)
    final sheetDead = excel['DeadStock'];
    sheetDead.appendRow([
      TextCellValue('STT'),
      TextCellValue('Mã SKU'),
      TextCellValue('Tên Hàng Hóa'),
      TextCellValue('Vị Trí Kệ'),
      TextCellValue('Số Lượng Tồn'),
      TextCellValue('Số Ngày Chưa Xuất'),
      TextCellValue('Giá Vốn MAC (VND)'),
      TextCellValue('Tổng Vốn Ứ Đọng (VND)'),
      TextCellValue('Khuyến Nghị Xử Lý'),
    ]);
    for (int i = 0; i < deadStockProducts.length; i++) {
      final p = deadStockProducts[i];
      sheetDead.appendRow([
        IntCellValue(i + 1),
        TextCellValue(p.skuCode),
        TextCellValue(p.name),
        TextCellValue(p.locationTag),
        IntCellValue(p.currentStock),
        IntCellValue(p.daysSinceLastMovement),
        DoubleCellValue(p.costPrice),
        DoubleCellValue(p.totalInventoryValue),
        TextCellValue('Giảm giá xả hàng hoặc chuyển chi nhánh có nhu cầu cao hơn'),
      ]);
    }

    // Sheet 3: Quản lý Hạn Dùng FEFO
    final sheetExpiry = excel['HanDungFEFO'];
    sheetExpiry.appendRow([
      TextCellValue('STT'),
      TextCellValue('Mã SKU'),
      TextCellValue('Tên Hàng Hóa'),
      TextCellValue('Vị Trí Kệ'),
      TextCellValue('Số Lượng Tồn'),
      TextCellValue('Hạn Sử Dụng'),
      TextCellValue('Số Ngày Còn Lại'),
      TextCellValue('Tình Trạng'),
      TextCellValue('Biện Pháp Ưu Tiên FEFO'),
    ]);
    for (int i = 0; i < expiringProducts.length; i++) {
      final p = expiringProducts[i];
      final isExp = p.isExpired;
      final days = DateFormatter.daysUntilExpiry(p.expiryDate);
      sheetExpiry.appendRow([
        IntCellValue(i + 1),
        TextCellValue(p.skuCode),
        TextCellValue(p.name),
        TextCellValue(p.locationTag),
        IntCellValue(p.currentStock),
        TextCellValue(DateFormatter.formatDate(p.expiryDate)),
        IntCellValue(days),
        TextCellValue(isExp ? 'ĐÃ QUÁ HẠN' : 'CẬN DATE ($days ngày)'),
        TextCellValue(isExp ? 'Cách ly ngay lập tức để lập biên bản hủy' : 'Áp dụng nguyên tắc FEFO: Xuất kho lô này trước'),
      ]);
    }

    final fileBytes = excel.save();
    if (fileBytes != null) {
      await Printing.sharePdf(
        bytes: Uint8List.fromList(fileBytes),
        filename: 'BaoCao_CanhBaoKho_FEFO_${DateTime.now().millisecondsSinceEpoch}.xlsx',
      );
    }
  }
}
