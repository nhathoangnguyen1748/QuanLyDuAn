import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartstock_admin/core/constants/app_colors.dart';
import 'package:smartstock_admin/core/providers/warehouse_providers.dart';
import 'package:smartstock_admin/core/services/excel_export_service.dart';
import 'package:smartstock_admin/core/services/pdf_report_service.dart';

class ReportsExportScreen extends ConsumerWidget {
  const ReportsExportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productListProvider);
    final stockInOrders = ref.watch(stockInListProvider);
    final stockOutOrders = ref.watch(stockOutListProvider);
    final cycleCounts = ref.watch(cycleCountListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Báo Cáo & In Ấn', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Banner intro
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryLight],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.print, color: Colors.white, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'Trung Tâm Xuất Báo Cáo & In Ấn',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                SizedBox(height: 6),
                Text(
                  'Hỗ trợ xuất file Excel (.xlsx), biên bản PDF và in trực tiếp qua máy in nhiệt Bluetooth / mạng LAN nội bộ.',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Report 1: Báo cáo tồn kho Excel
          _buildReportCard(
            title: 'Báo Cáo Tồn Kho Toàn Diện (Excel)',
            subtitle: 'Xuất danh sách tất cả ${products.length} SKU, định mức an toàn, vị trí kệ, giá vốn MAC và tổng giá trị tồn kho.',
            icon: Icons.table_chart,
            iconColor: Colors.green,
            buttonText: 'Xuất File Excel (.xlsx)',
            onAction: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đang trích xuất dữ liệu tồn kho sang Excel...')),
              );
              await ExcelExportService.exportInventory(products);
            },
          ),
          const SizedBox(height: 12),

          // Report 2: Báo cáo kiểm kê đối soát
          _buildReportCard(
            title: 'Biên Bản Đối Soát Kiểm Kê & Hao Hụt (PDF & Excel)',
            subtitle: cycleCounts.isNotEmpty
                ? 'Đợt gần nhất: ${cycleCounts.first.sessionCode} (${cycleCounts.first.discrepancyItemsCount} SKU lệch tồn)'
                : 'Chưa có đợt kiểm kê nào',
            icon: Icons.fact_check,
            iconColor: Colors.blue,
            buttonText: 'In Biên Bản PDF',
            onAction: cycleCounts.isEmpty
                ? null
                : () async {
                    await PdfReportService.printCycleCountReport(cycleCounts.first);
                  },
            secondaryButtonText: 'Xuất Excel',
            onSecondaryAction: cycleCounts.isEmpty
                ? null
                : () async {
                    await ExcelExportService.exportCycleCount(cycleCounts.first);
                  },
          ),
          const SizedBox(height: 12),

          // Report 3: In tem nhãn Barcode dán kệ
          _buildReportCard(
            title: 'In Tem Mã Vạch Dán Kệ & Sản Phẩm (Thermal Sticker)',
            subtitle: 'Tạo file PDF chuẩn tem nhiệt 80mm x 50mm chứa Barcode Code 128, mã SKU, vị trí kệ và giá bán.',
            icon: Icons.qr_code,
            iconColor: Colors.amber.shade800,
            buttonText: 'Chọn SKU In Tem',
            onAction: () {
              _showPrintLabelPicker(context, products);
            },
          ),
          const SizedBox(height: 12),

          // Report 4: Lịch sử nhập xuất
          _buildReportCard(
            title: 'Sổ Nhật Ký Nhập - Xuất - Chuyển Kho',
            subtitle: 'Tổng hợp ${stockInOrders.length} phiếu nhập kho và ${stockOutOrders.length} phiếu xuất kho/điều chuyển.',
            icon: Icons.receipt_long,
            iconColor: Colors.purple,
            buttonText: stockInOrders.isNotEmpty ? 'In Phiếu Nhập Gần Nhất' : 'Chưa có phiếu',
            onAction: stockInOrders.isEmpty
                ? null
                : () async {
                    await PdfReportService.printStockInOrder(stockInOrders.first);
                  },
            secondaryButtonText: stockOutOrders.isNotEmpty ? 'In Phiếu Xuất Gần Nhất' : null,
            onSecondaryAction: stockOutOrders.isEmpty
                ? null
                : () async {
                    await PdfReportService.printStockOutOrder(stockOutOrders.first);
                  },
          ),
        ],
      ),
    );
  }

  void _showPrintLabelPicker(BuildContext context, List products) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(ctx).size.height * 0.7,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Chọn mặt hàng để in tem nhãn', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: products.length,
                  itemBuilder: (context, i) {
                    final p = products[i];
                    return ListTile(
                      title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      subtitle: Text('${p.skuCode} • Barcode: ${p.barcode} • Kệ: ${p.locationTag}'),
                      trailing: const Icon(Icons.print, color: AppColors.primary),
                      onTap: () async {
                        Navigator.pop(ctx);
                        await PdfReportService.printBarcodeLabel(p);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReportCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required String buttonText,
    required VoidCallback? onAction,
    String? secondaryButtonText,
    VoidCallback? onSecondaryAction,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (secondaryButtonText != null && onSecondaryAction != null) ...[
                  OutlinedButton(
                    onPressed: onSecondaryAction,
                    child: Text(secondaryButtonText),
                  ),
                  const SizedBox(width: 8),
                ],
                ElevatedButton(
                  onPressed: onAction,
                  child: Text(buttonText),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
