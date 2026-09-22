import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/stock_in_order.dart';
import '../models/stock_out_order.dart';
import '../models/cycle_count_session.dart';
import '../models/product_sku.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';

class PdfReportService {
  /// In hoặc Xem trước Phiếu Nhập Kho
  static Future<void> printStockInOrder(StockInOrder order) async {
    final pdf = pw.Document();

    final font = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'SMARTSTOCK LOGISTICS',
                        style: pw.TextStyle(font: fontBold, fontSize: 18, color: PdfColors.blue800),
                      ),
                      pw.Text(
                        'Tổng Kho Thông Minh Miền Nam',
                        style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey700),
                      ),
                      pw.Text(
                        'Hotline: 1900 6868 - smartstock.vn',
                        style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'PHIẾU NHẬP KHO',
                        style: pw.TextStyle(font: fontBold, fontSize: 16, color: PdfColors.blue900),
                      ),
                      pw.Text(
                        'Mã số: ${order.orderNumber}',
                        style: pw.TextStyle(font: fontBold, fontSize: 12),
                      ),
                      pw.Text(
                        'Ngày lập: ${DateFormatter.formatDateTime(order.createdAt)}',
                        style: pw.TextStyle(font: font, fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Divider(color: PdfColors.grey400),
              pw.SizedBox(height: 8),

              // Thông tin nhà cung cấp
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Nhà cung cấp: ${order.supplierName}', style: pw.TextStyle(font: fontBold, fontSize: 11)),
                  pw.Text('Người lập: ${order.createdBy}', style: pw.TextStyle(font: font, fontSize: 10)),
                ],
              ),
              if (order.supplierPhone != null) ...[
                pw.SizedBox(height: 4),
                pw.Text('Điện thoại NCC: ${order.supplierPhone}', style: pw.TextStyle(font: font, fontSize: 10)),
              ],
              if (order.notes != null && order.notes!.isNotEmpty) ...[
                pw.SizedBox(height: 4),
                pw.Text('Ghi chú: ${order.notes}', style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey800)),
              ],
              pw.SizedBox(height: 16),

              // Bảng danh sách hàng nhập
              pw.TableHelper.fromTextArray(
                context: context,
                border: pw.TableBorder.all(color: PdfColors.grey300),
                headerStyle: pw.TextStyle(font: fontBold, fontSize: 9, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.blue700),
                cellStyle: pw.TextStyle(font: font, fontSize: 8),
                headers: ['STT', 'Mã SKU', 'Tên Hàng Hóa', 'Vị Trí Kệ', 'SL', 'Đơn Giá Nhập', 'Giá Vốn MAC', 'Thành Tiền'],
                data: List.generate(order.items.length, (index) {
                  final item = order.items[index];
                  return [
                    '${index + 1}',
                    item.skuCode,
                    item.skuName,
                    item.locationTag,
                    CurrencyFormatter.formatNumber(item.quantity),
                    CurrencyFormatter.formatVND(item.unitPrice),
                    CurrencyFormatter.formatVND(item.macAfter),
                    CurrencyFormatter.formatVND(item.totalAmount),
                  ];
                }),
              ),
              pw.SizedBox(height: 12),

              // Tổng cộng
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Tổng số lượng: ${CurrencyFormatter.formatNumber(order.totalQuantity)}', style: pw.TextStyle(font: fontBold, fontSize: 10)),
                      pw.SizedBox(height: 4),
                      pw.Text('TỔNG GIÁ TRỊ NHẬP: ${CurrencyFormatter.formatVND(order.totalValue)}', style: pw.TextStyle(font: fontBold, fontSize: 12, color: PdfColors.blue900)),
                    ],
                  ),
                ],
              ),
              pw.Spacer(),

              // Chữ ký xác nhận
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  pw.Column(
                    children: [
                      pw.Text('Người Giao Hàng', style: pw.TextStyle(font: fontBold, fontSize: 10)),
                      pw.Text('(Ký, họ tên)', style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey600)),
                      pw.SizedBox(height: 45),
                      pw.Text('................................', style: pw.TextStyle(font: font, fontSize: 10)),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Text('Thủ Kho Nhận Hàng', style: pw.TextStyle(font: fontBold, fontSize: 10)),
                      pw.Text('(Ký, họ tên)', style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey600)),
                      pw.SizedBox(height: 45),
                      pw.Text(order.createdBy, style: pw.TextStyle(font: fontBold, fontSize: 10)),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Text('Kế Toán Kho', style: pw.TextStyle(font: fontBold, fontSize: 10)),
                      pw.Text('(Ký, họ tên)', style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey600)),
                      pw.SizedBox(height: 45),
                      pw.Text('................................', style: pw.TextStyle(font: font, fontSize: 10)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: '${order.orderNumber}.pdf',
    );
  }

  /// In hoặc Xem trước Phiếu Xuất Kho / Điều chuyển
  static Future<void> printStockOutOrder(StockOutOrder order) async {
    final pdf = pw.Document();

    final font = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('SMARTSTOCK LOGISTICS', style: pw.TextStyle(font: fontBold, fontSize: 18, color: PdfColors.blue800)),
                      pw.Text('Tổng Kho Thông Minh Miền Nam', style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey700)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('PHIẾU XUẤT KHO', style: pw.TextStyle(font: fontBold, fontSize: 16, color: PdfColors.blue900)),
                      pw.Text('Loại: ${order.type.label}', style: pw.TextStyle(font: fontBold, fontSize: 11, color: PdfColors.teal700)),
                      pw.Text('Mã số: ${order.orderNumber}', style: pw.TextStyle(font: fontBold, fontSize: 12)),
                      pw.Text('Ngày: ${DateFormatter.formatDateTime(order.createdAt)}', style: pw.TextStyle(font: font, fontSize: 10)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Divider(color: PdfColors.grey400),
              pw.SizedBox(height: 8),

              pw.Text('Đơn vị / Người nhận: ${order.receiverName}', style: pw.TextStyle(font: fontBold, fontSize: 11)),
              if (order.destinationBranch != null) ...[
                pw.SizedBox(height: 4),
                pw.Text('Địa chỉ chi nhánh nhận: ${order.destinationBranch}', style: pw.TextStyle(font: font, fontSize: 10)),
              ],
              if (order.notes != null && order.notes!.isNotEmpty) ...[
                pw.SizedBox(height: 4),
                pw.Text('Ghi chú xuất kho: ${order.notes}', style: pw.TextStyle(font: font, fontSize: 10)),
              ],
              pw.SizedBox(height: 16),

              pw.TableHelper.fromTextArray(
                context: context,
                border: pw.TableBorder.all(color: PdfColors.grey300),
                headerStyle: pw.TextStyle(font: fontBold, fontSize: 9, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.blue700),
                cellStyle: pw.TextStyle(font: font, fontSize: 8),
                headers: ['STT', 'Mã SKU', 'Tên Mặt Hàng', 'Số Lượng', 'Đơn Giá Xuất', 'Thành Tiền'],
                data: List.generate(order.items.length, (index) {
                  final item = order.items[index];
                  return [
                    '${index + 1}',
                    item.skuCode,
                    item.skuName,
                    CurrencyFormatter.formatNumber(item.quantity),
                    CurrencyFormatter.formatVND(item.unitPrice),
                    CurrencyFormatter.formatVND(item.totalRevenue),
                  ];
                }),
              ),
              pw.SizedBox(height: 12),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Tổng số lượng xuất: ${CurrencyFormatter.formatNumber(order.totalQuantity)}', style: pw.TextStyle(font: fontBold, fontSize: 10)),
                      pw.SizedBox(height: 4),
                      pw.Text('TỔNG GIÁ TRỊ XUẤT: ${CurrencyFormatter.formatVND(order.totalRevenue)}', style: pw.TextStyle(font: fontBold, fontSize: 12, color: PdfColors.blue900)),
                    ],
                  ),
                ],
              ),
              pw.Spacer(),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  pw.Column(
                    children: [
                      pw.Text('Người Nhận Hàng', style: pw.TextStyle(font: fontBold, fontSize: 10)),
                      pw.Text('(Ký, họ tên)', style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey600)),
                      pw.SizedBox(height: 45),
                      pw.Text('................................', style: pw.TextStyle(font: font, fontSize: 10)),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Text('Thủ Kho Xuất', style: pw.TextStyle(font: fontBold, fontSize: 10)),
                      pw.Text('(Ký, họ tên)', style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey600)),
                      pw.SizedBox(height: 45),
                      pw.Text(order.createdBy, style: pw.TextStyle(font: fontBold, fontSize: 10)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: '${order.orderNumber}.pdf',
    );
  }

  /// In Biên bản Kiểm Kê & Đối Soát Chênh Lệch Kho
  static Future<void> printCycleCountReport(CycleCountSession session) async {
    final pdf = pw.Document();

    final font = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('SMARTSTOCK LOGISTICS', style: pw.TextStyle(font: fontBold, fontSize: 18, color: PdfColors.blue800)),
                      pw.Text('BIÊN BẢN ĐỐI SOÁT & ĐIỀU CHỈNH KIỂM KÊ', style: pw.TextStyle(font: fontBold, fontSize: 13, color: PdfColors.red800)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Mã đợt: ${session.sessionCode}', style: pw.TextStyle(font: fontBold, fontSize: 12)),
                      pw.Text('Trạng thái: ${session.status.label}', style: pw.TextStyle(font: font, fontSize: 10)),
                      pw.Text('Ngày: ${DateFormatter.formatDate(session.createdAt)}', style: pw.TextStyle(font: font, fontSize: 10)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 12),
              pw.Divider(color: PdfColors.grey400),
              pw.SizedBox(height: 8),

              pw.Text('Phạm vi kiểm kê: ${session.scope}', style: pw.TextStyle(font: fontBold, fontSize: 11)),
              pw.Text('Cán bộ kiểm đếm: ${session.auditorName}', style: pw.TextStyle(font: font, fontSize: 10)),
              pw.SizedBox(height: 12),

              pw.TableHelper.fromTextArray(
                context: context,
                border: pw.TableBorder.all(color: PdfColors.grey300),
                headerStyle: pw.TextStyle(font: fontBold, fontSize: 8, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
                cellStyle: pw.TextStyle(font: font, fontSize: 8),
                headers: ['Mã SKU', 'Tên Hàng Hóa', 'Kệ', 'Sổ Sách', 'Thực Tế', 'Lệch (SL)', 'Lệch (%)', 'Lệch Giá Trị (VND)'],
                data: List.generate(session.items.length, (index) {
                  final item = session.items[index];
                  final sign = item.varianceQty > 0 ? '+' : '';
                  return [
                    item.skuCode,
                    item.skuName,
                    item.locationTag,
                    '${item.bookStock}',
                    item.isAudited ? '${item.physicalCount}' : 'Chưa kiểm',
                    item.isAudited ? '$sign${item.varianceQty}' : '-',
                    item.isAudited ? '${item.variancePercent.toStringAsFixed(1)}%' : '-',
                    item.isAudited ? CurrencyFormatter.formatVND(item.varianceValue) : '-',
                  ];
                }),
              ),
              pw.SizedBox(height: 12),

              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: const pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    pw.Text('Số SKU lệch: ${session.discrepancyItemsCount} SKU', style: pw.TextStyle(font: fontBold, fontSize: 9)),
                    pw.Text('Thừa: +${session.totalSurplusQty} | Thiếu: -${session.totalDeficitQty}', style: pw.TextStyle(font: fontBold, fontSize: 9)),
                    pw.Text('Tổng chênh lệch giá trị: ${CurrencyFormatter.formatVND(session.totalVarianceValue)}', style: pw.TextStyle(font: fontBold, fontSize: 10, color: session.totalVarianceValue >= 0 ? PdfColors.green800 : PdfColors.red800)),
                  ],
                ),
              ),
              pw.Spacer(),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  pw.Column(
                    children: [
                      pw.Text('Người Kiểm Đếm', style: pw.TextStyle(font: fontBold, fontSize: 10)),
                      pw.SizedBox(height: 45),
                      pw.Text(session.auditorName, style: pw.TextStyle(font: fontBold, fontSize: 10)),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Text('Quản Trị Viên Duyệt Kho', style: pw.TextStyle(font: fontBold, fontSize: 10)),
                      pw.SizedBox(height: 45),
                      pw.Text('................................', style: pw.TextStyle(font: font, fontSize: 10)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: '${session.sessionCode}.pdf',
    );
  }

  /// In Nhãn Barcode Dán Kệ / Hàng Hóa (Khổ nhiệt tiêu chuẩn 80mm x 50mm)
  static Future<void> printBarcodeLabel(ProductSKU product) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();

    pdf.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(80 * PdfPageFormat.mm, 50 * PdfPageFormat.mm),
        margin: const pw.EdgeInsets.all(8),
        build: (context) {
          return pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text('SMARTSTOCK INVENTORY', style: pw.TextStyle(font: fontBold, fontSize: 8, color: PdfColors.grey700)),
              pw.SizedBox(height: 2),
              pw.Text(
                product.name,
                maxLines: 1,
                overflow: pw.TextOverflow.clip,
                style: pw.TextStyle(font: fontBold, fontSize: 9),
              ),
              pw.SizedBox(height: 4),
              pw.BarcodeWidget(
                barcode: pw.Barcode.code128(),
                data: product.barcode,
                width: 180,
                height: 45,
                drawText: true,
                textStyle: pw.TextStyle(font: font, fontSize: 8),
              ),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('SKU: ${product.skuCode}', style: pw.TextStyle(font: fontBold, fontSize: 8)),
                  pw.Text('KỆ: ${product.locationTag}', style: pw.TextStyle(font: fontBold, fontSize: 8, color: PdfColors.blue800)),
                  pw.Text(CurrencyFormatter.formatVND(product.sellingPrice), style: pw.TextStyle(font: fontBold, fontSize: 8)),
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Label_${product.skuCode}.pdf',
    );
  }
}
