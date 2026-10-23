import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartstock_admin/core/constants/app_colors.dart';
import 'package:smartstock_admin/core/models/product_sku.dart';
import 'package:smartstock_admin/core/providers/warehouse_providers.dart';
import 'package:smartstock_admin/core/utils/currency_formatter.dart';
import 'package:smartstock_admin/core/utils/date_formatter.dart';
import 'package:smartstock_admin/features/operations_stock_in/presentation/screens/create_stock_in_screen.dart';
import 'product_detail_screen.dart';

class SafetyStockAlertsScreen extends ConsumerStatefulWidget {
  final int initialTab;

  const SafetyStockAlertsScreen({super.key, this.initialTab = 0});

  @override
  ConsumerState<SafetyStockAlertsScreen> createState() => _SafetyStockAlertsScreenState();
}

class _SafetyStockAlertsScreenState extends ConsumerState<SafetyStockAlertsScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

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

    final lowStockItems = products.where((p) => p.isLowStock).toList();
    final deadStockItems = products.where((p) => p.isDeadStock).toList();
    final expiryItems = products.where((p) => p.isExpiringSoon || p.isExpired).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trung Tâm Cảnh Báo Kho', style: TextStyle(fontWeight: FontWeight.bold)),
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
              text: 'Hạn Dùng (${expiryItems.length})',
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
          _buildExpiryTab(expiryItems),
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

  Widget _buildExpiryTab(List<ProductSKU> items) {
    if (items.isEmpty) {
      return const Center(child: Text('Không có hàng hết hạn hoặc cận date'));
    }

    return ListView.builder(
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
                Text(
                  isExpired
                      ? 'Biện pháp: Cách ly hàng hóa ngay lập tức để lập biên bản hủy hoặc hoàn trả.'
                      : 'Biện pháp: Áp dụng nguyên tắc FEFO (First Expired First Out) - Ưu tiên xuất kho lô này trước.',
                  style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: isExpired ? AppColors.danger : AppColors.warning),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
