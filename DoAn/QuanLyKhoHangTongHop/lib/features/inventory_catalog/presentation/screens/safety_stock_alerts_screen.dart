import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartstock_admin/core/constants/app_colors.dart';
import 'package:smartstock_admin/core/models/product_sku.dart';
import 'package:smartstock_admin/core/providers/warehouse_providers.dart';
import 'package:smartstock_admin/core/utils/currency_formatter.dart';
import 'package:smartstock_admin/core/utils/date_formatter.dart';
import 'package:smartstock_admin/features/operations_stock_in/presentation/screens/create_stock_in_screen.dart';
import 'package:smartstock_admin/core/services/pdf_report_service.dart';
import 'package:smartstock_admin/core/services/excel_export_service.dart';
import 'product_detail_screen.dart';

class SafetyStockAlertsScreen extends ConsumerStatefulWidget {
  final int initialTab;

  const SafetyStockAlertsScreen({super.key, this.initialTab = 0});

  @override
  ConsumerState<SafetyStockAlertsScreen> createState() => _SafetyStockAlertsScreenState();
}

class _SafetyStockAlertsScreenState extends ConsumerState<SafetyStockAlertsScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _fefoFilterIndex = 0; // 0: Tất cả, 1: Đã quá hạn, 2: Cận date <= 30 ngày

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: widget.initialTab);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productListProvider);

    // 1. Sắp xếp thiếu an toàn: thiếu nhiều nhất lên đầu
    final lowStockItems = products.where((p) => p.isLowStock).toList()
      ..sort((a, b) => (b.minSafetyStock - b.currentStock).compareTo(a.minSafetyStock - a.currentStock));

    // 2. Sắp xếp Dead Stock: tồn đọng nhiều ngày nhất lên đầu
    final deadStockItems = products.where((p) => p.isDeadStock).toList()
      ..sort((a, b) => b.daysSinceLastMovement.compareTo(a.daysSinceLastMovement));

    // 3. Sắp xếp Hạn Dùng theo FEFO (First Expired First Out): hạn sử dụng gần nhất lên đầu
    final allExpiryItems = products.where((p) => p.isExpiringSoon || p.isExpired).toList()
      ..sort((a, b) => (a.expiryDate ?? DateTime.now()).compareTo(b.expiryDate ?? DateTime.now()));

    final filteredExpiryItems = allExpiryItems.where((p) {
      if (_fefoFilterIndex == 1) return p.isExpired;
      if (_fefoFilterIndex == 2) return p.isExpiringSoon && !p.isExpired;
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trung Tâm Cảnh Báo Kho', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            tooltip: 'In Báo Cáo Cảnh Báo PDF',
            icon: const Icon(Icons.print_outlined, color: AppColors.primary),
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đang tạo file PDF Báo cáo Cảnh báo & FEFO...')),
              );
              await PdfReportService.printAlertsReport(
                lowStock: lowStockItems,
                deadStock: deadStockItems,
                expiring: allExpiryItems,
              );
            },
          ),
          IconButton(
            tooltip: 'Xuất Báo Cáo Cảnh Báo Excel',
            icon: const Icon(Icons.file_download_outlined, color: AppColors.primary),
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đang xuất Báo cáo Cảnh báo ra Excel...')),
              );
              await ExcelExportService.exportAlertsReport(
                lowStockProducts: lowStockItems,
                deadStockProducts: deadStockItems,
                expiringProducts: allExpiryItems,
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondaryLight,
          tabs: [
            Tab(
              text: 'Thiếu Tồn (${lowStockItems.length})',
              icon: const Icon(Icons.warning_amber_rounded, size: 18),
            ),
            Tab(
              text: 'Dead Stock (${deadStockItems.length})',
              icon: const Icon(Icons.hourglass_bottom_rounded, size: 18),
            ),
            Tab(
              text: 'Hạn Dùng (${allExpiryItems.length})',
              icon: const Icon(Icons.event_busy, size: 18),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLowStockTab(lowStockItems),
          _buildDeadStockTab(deadStockItems),
          _buildExpiryTab(filteredExpiryItems, allExpiryItems),
        ],
      ),
    );
  }

  Widget _buildLowStockTab(List<ProductSKU> items) {
    if (items.isEmpty) {
      return const Center(
        child: Text('Tất cả mặt hàng đều đạt ngưỡng tồn kho an toàn!'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final p = items[index];
        final deficit = p.minSafetyStock - p.currentStock;
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(p.skuCode, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Thiếu $deficit ${p.unit}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.danger),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text('Kệ: ${p.locationTag} • Ngành: ${p.categoryName}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text('Tồn hiện tại: ', style: const TextStyle(fontSize: 12)),
                    Text('${p.currentStock}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.danger)),
                    Text(' / Định mức Min: ${p.minSafetyStock} ${p.unit}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                  ],
                ),
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: p.id)),
                        );
                      },
                      child: const Text('Xem chi tiết'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => CreateStockInScreen(preselectedSku: p)),
                        );
                      },
                      icon: const Icon(Icons.add_shopping_cart, size: 16),
                      label: const Text('Tạo Phiếu Nhập Hàng'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDeadStockTab(List<ProductSKU> items) {
    if (items.isEmpty) {
      return const Center(child: Text('Không có mặt hàng tồn kho chậm luân chuyển'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final p = items[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(p.skuCode, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.accentAmber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Đọng ${p.daysSinceLastMovement} ngày',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.accentAmber),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text('Vị trí: ${p.locationTag} • Số lượng tồn: ${p.currentStock} ${p.unit}', style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 4),
                Text('Giá trị vốn đang ứ đọng: ${CurrencyFormatter.formatVND(p.totalInventoryValue)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary)),
                const SizedBox(height: 8),
                Text(
                  'Khuyến nghị: Cần tạo chương trình khuyến mãi xả kho hoặc điều chuyển sang chi nhánh có sức mua cao hơn.',
                  style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildExpiryTab(List<ProductSKU> items, List<ProductSKU> allItems) {
    final expiredCount = allItems.where((p) => p.isExpired).length;
    final soonCount = allItems.where((p) => p.isExpiringSoon && !p.isExpired).length;

    return Column(
      children: [
        // FEFO Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              ChoiceChip(
                label: Text('Tất cả (${allItems.length})'),
                selected: _fefoFilterIndex == 0,
                onSelected: (val) {
                  if (val) setState(() => _fefoFilterIndex = 0);
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: Text('Đã Quá Hạn ($expiredCount)'),
                selected: _fefoFilterIndex == 1,
                selectedColor: AppColors.danger.withValues(alpha: 0.2),
                labelStyle: TextStyle(
                  color: _fefoFilterIndex == 1 ? AppColors.danger : null,
                  fontWeight: _fefoFilterIndex == 1 ? FontWeight.bold : null,
                ),
                onSelected: (val) {
                  if (val) setState(() => _fefoFilterIndex = 1);
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: Text('Cận Date <= 30 ngày ($soonCount)'),
                selected: _fefoFilterIndex == 2,
                selectedColor: AppColors.warning.withValues(alpha: 0.2),
                labelStyle: TextStyle(
                  color: _fefoFilterIndex == 2 ? AppColors.warning : null,
                  fontWeight: _fefoFilterIndex == 2 ? FontWeight.bold : null,
                ),
                onSelected: (val) {
                  if (val) setState(() => _fefoFilterIndex = 2);
                },
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // List
        Expanded(
          child: items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_outline, size: 48, color: AppColors.success),
                      const SizedBox(height: 8),
                      Text(
                        _fefoFilterIndex == 1
                            ? 'Không có mặt hàng nào quá hạn sử dụng!'
                            : (_fefoFilterIndex == 2 ? 'Không có mặt hàng nào cận date <= 30 ngày!' : 'Không có hàng hết hạn hoặc cận date'),
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final p = items[index];
                    final isExpired = p.isExpired;
                    final days = DateFormatter.daysUntilExpiry(p.expiryDate);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(p.skuCode, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: (isExpired ? AppColors.danger : AppColors.warning).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    isExpired ? 'ĐÃ QUÁ HẠN' : 'CẬN DATE ($days ngày)',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: isExpired ? AppColors.danger : AppColors.warning),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 4),
                            Text('Hạn sử dụng: ${DateFormatter.formatDate(p.expiryDate)} • Tồn: ${p.currentStock} ${p.unit}', style: const TextStyle(fontSize: 12)),
                            const SizedBox(height: 4),
                            Text('Kệ lưu trữ: ${p.locationTag}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: (isExpired ? AppColors.danger : AppColors.warning).withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isExpired ? Icons.cancel_outlined : Icons.priority_high,
                                    size: 16,
                                    color: isExpired ? AppColors.danger : AppColors.warning,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      isExpired
                                          ? 'Biện pháp: Cách ly ngay để lập biên bản tiêu hủy hoặc trả nhà cung cấp.'
                                          : 'Biện pháp FEFO: Ưu tiên xuất kho lô hàng này trước để tránh quá hạn.',
                                      style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: isExpired ? AppColors.danger : AppColors.warning),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
