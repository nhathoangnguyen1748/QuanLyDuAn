import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartstock_admin/core/constants/app_colors.dart';
import 'package:smartstock_admin/core/providers/warehouse_providers.dart';
import 'package:smartstock_admin/core/services/excel_export_service.dart';
import 'package:smartstock_admin/features/dashboard_analytics/presentation/widgets/kpi_summary_grid.dart';
import 'package:smartstock_admin/features/dashboard_analytics/presentation/widgets/abc_pareto_chart.dart';
import 'package:smartstock_admin/features/dashboard_analytics/presentation/widgets/itr_trend_chart.dart';
import 'package:smartstock_admin/features/dashboard_analytics/presentation/widgets/holding_cost_chart.dart';
import 'package:smartstock_admin/features/dashboard_analytics/presentation/widgets/category_donut_chart.dart';
import 'package:smartstock_admin/features/inventory_catalog/presentation/screens/safety_stock_alerts_screen.dart';
import 'package:smartstock_admin/features/scanner/presentation/barcode_scanner_sheet.dart';
import 'package:smartstock_admin/features/inventory_catalog/presentation/screens/product_detail_screen.dart';

class AnalyticsDashboardScreen extends ConsumerWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kpi = ref.watch(executiveKPIProvider);
    final pareto = ref.watch(paretoABCProvider);
    final itr = ref.watch(itrTrendProvider);
    final holdingCost = ref.watch(holdingCostProvider);
    final categoryDist = ref.watch(categoryDistributionProvider);
    final settings = ref.watch(warehouseSettingsProvider);
    final products = ref.watch(productListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'SmartStock Admin',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'ONLINE',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.success),
                  ),
                ),
              ],
            ),
            Text(
              settings.name,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
            ),
          ],
        ),
        actions: [
          // Quick Barcode Scan Lookup button
          IconButton(
            tooltip: 'Quét Barcode tra cứu nhanh',
            icon: const Icon(Icons.qr_code_scanner, color: AppColors.primary),
            onPressed: () async {
              final barcode = await BarcodeScannerSheet.scan(context);
              if (barcode != null && barcode.isNotEmpty && context.mounted) {
                final product = ref.read(productListProvider.notifier).findByBarcode(barcode);
                if (product != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: product.id)),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Không tìm thấy mặt hàng có mã: $barcode'),
                      backgroundColor: AppColors.danger,
                    ),
                  );
                }
              }
            },
          ),
          // Export Excel Report button
          IconButton(
            tooltip: 'Xuất Báo Cáo Excel (.xlsx)',
            icon: const Icon(Icons.file_download_outlined, color: AppColors.primary),
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đang xuất báo cáo tồn kho Excel...')),
              );
              await ExcelExportService.exportInventory(products);
            },
          ),
          // Reset demo data menu
          PopupMenuButton<String>(
            onSelected: (val) async {
              if (val == 'reset') {
                await ref.read(storageServiceProvider).resetToSeedData();
                ref.read(productListProvider.notifier).refresh();
                ref.read(stockInListProvider.notifier).refresh();
                ref.read(stockOutListProvider.notifier).refresh();
                ref.read(cycleCountListProvider.notifier).refresh();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã khôi phục dữ liệu mẫu thành công!')),
                  );
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'reset',
                child: Row(
                  children: [
                    Icon(Icons.restore, size: 18, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('Khôi phục Seed Data'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.read(productListProvider.notifier).refresh();
          ref.read(stockInListProvider.notifier).refresh();
          ref.read(stockOutListProvider.notifier).refresh();
          ref.read(cycleCountListProvider.notifier).refresh();
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // 1. Executive KPI Cards
            KPISummaryGrid(
              kpi: kpi,
              onLowStockTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SafetyStockAlertsScreen()),
                );
              },
              onDeadStockTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SafetyStockAlertsScreen(initialTab: 1),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // 2. Phân Tích ABC Pareto (80/20)
            ABCParetoChart(paretoResult: pareto),
            const SizedBox(height: 16),

            // 3. Vòng Quay Hàng Tồn Kho (ITR)
            ITRTrendChart(trendData: itr),
            const SizedBox(height: 16),

            // 4. Chi Phí Lưu Kho & Dòng Tiền (Holding Cost)
            HoldingCostChart(dataPoints: holdingCost),
            const SizedBox(height: 16),

            // 5. Cơ Cấu Danh Mục Hàng Hóa (Donut Chart)
            CategoryDonutChart(categories: categoryDist),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
