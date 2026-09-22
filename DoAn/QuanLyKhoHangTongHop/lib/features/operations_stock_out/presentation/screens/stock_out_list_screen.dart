import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartstock_admin/core/constants/app_colors.dart';
import 'package:smartstock_admin/core/models/stock_out_order.dart';
import 'package:smartstock_admin/core/providers/warehouse_providers.dart';
import 'package:smartstock_admin/core/utils/currency_formatter.dart';
import 'package:smartstock_admin/core/utils/date_formatter.dart';
import 'create_stock_out_screen.dart';
import 'stock_out_detail_screen.dart';

class StockOutListScreen extends ConsumerStatefulWidget {
  const StockOutListScreen({super.key});

  @override
  ConsumerState<StockOutListScreen> createState() => _StockOutListScreenState();
}

class _StockOutListScreenState extends ConsumerState<StockOutListScreen> {
  StockOutType? _selectedTypeFilter;

  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(stockOutListProvider);

    final filtered = orders.where((o) {
      if (_selectedTypeFilter != null && o.type != _selectedTypeFilter) {
        return false;
      }
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Xuất Kho & Điều Chuyển', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip('Tất cả', null),
                _buildFilterChip('Bán lẻ', StockOutType.retail),
                _buildFilterChip('Bán sỉ', StockOutType.wholesale),
                _buildFilterChip('Điều chuyển nội bộ', StockOutType.transfer),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.outbox, size: 64, color: Colors.grey),
                        const SizedBox(height: 8),
                        const Text('Không có phiếu xuất nào', style: TextStyle(color: Colors.grey)),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const CreateStockOutScreen()),
                            );
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Tạo Phiếu Xuất Đầu Tiên'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final order = filtered[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => StockOutDetailScreen(order: order)),
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
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryLight.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        order.type.label,
                                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primaryLight),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      order.type == StockOutType.transfer ? Icons.swap_horiz : Icons.person_outline,
                                      size: 16,
                                      color: AppColors.textSecondaryLight,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        order.receiverName,
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      DateFormatter.formatShortDate(order.createdAt),
                                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
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
                                      CurrencyFormatter.formatVND(order.totalRevenue),
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
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateStockOutScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Xuất Hàng Mới'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildFilterChip(String label, StockOutType? type) {
    final isSelected = _selectedTypeFilter == type;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(label, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
        selected: isSelected,
        onSelected: (_) {
          setState(() => _selectedTypeFilter = type);
        },
      ),
    );
  }
}
