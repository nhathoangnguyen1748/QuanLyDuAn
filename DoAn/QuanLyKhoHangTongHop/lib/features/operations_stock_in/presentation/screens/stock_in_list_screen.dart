import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartstock_admin/core/constants/app_colors.dart';
import 'package:smartstock_admin/core/providers/warehouse_providers.dart';
import 'package:smartstock_admin/core/utils/currency_formatter.dart';
import 'package:smartstock_admin/core/utils/date_formatter.dart';
import 'create_stock_in_screen.dart';
import 'stock_in_detail_screen.dart';

class StockInListScreen extends ConsumerWidget {
  const StockInListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(stockInListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nhập Kho (Stock In)', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: orders.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.move_to_inbox, size: 64, color: Colors.grey),
                  const SizedBox(height: 8),
                  const Text('Chưa có phiếu nhập kho nào', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CreateStockInScreen()),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Tạo Phiếu Nhập Đầu Tiên'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => StockInDetailScreen(order: order)),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                order.orderNumber,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
                              ),
                              Text(
                                DateFormatter.formatDateTime(order.createdAt),
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.business, size: 16, color: AppColors.textSecondaryLight),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  order.supplierName,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${order.items.length} mặt hàng (${CurrencyFormatter.formatNumber(order.totalQuantity)} đơn vị)',
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                              ),
                              Text(
                                CurrencyFormatter.formatVND(order.totalValue),
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateStockInScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Nhập Hàng Mới'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }
}
