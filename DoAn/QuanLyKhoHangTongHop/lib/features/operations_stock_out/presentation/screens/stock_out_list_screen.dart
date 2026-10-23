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
  final TextEditingController _searchController = TextEditingController();
  String _sortBy = 'NEWEST'; // NEWEST, OLDEST, HIGHEST_VALUE

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(stockOutListProvider);
    final query = _searchController.text.trim().toLowerCase();

    final filtered = orders.where((o) {
      if (_selectedTypeFilter != null && o.type != _selectedTypeFilter) {
        return false;
      }
      if (query.isNotEmpty) {
        final matchNumber = o.orderNumber.toLowerCase().contains(query);
        final matchReceiver = o.receiverName.toLowerCase().contains(query);
        final matchBranch = o.destinationBranch?.toLowerCase().contains(query) ?? false;
        final matchItem = o.items.any((item) =>
            item.skuName.toLowerCase().contains(query) ||
            item.skuCode.toLowerCase().contains(query));
        return matchNumber || matchReceiver || matchBranch || matchItem;
      }
      return true;
    }).toList();

    // Sắp xếp
    if (_sortBy == 'NEWEST') {
      filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else if (_sortBy == 'OLDEST') {
      filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    } else if (_sortBy == 'HIGHEST_VALUE') {
      filtered.sort((a, b) => b.totalRevenue.compareTo(a.totalRevenue));
    }

    // Tính toán số liệu tổng hợp
    final int totalVouchers = orders.length;
    final double totalRevenue = orders.fold(0.0, (sum, o) => sum + o.totalRevenue);
    final double totalCogs = orders.fold(0.0, (sum, o) => sum + o.totalCogs);
    final double totalProfit = totalRevenue - totalCogs;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Xuất Kho & Điều Chuyển', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            tooltip: 'Sắp xếp danh sách',
            onSelected: (val) => setState(() => _sortBy = val),
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'NEWEST', child: Text('Mới nhất trước')),
              const PopupMenuItem(value: 'OLDEST', child: Text('Cũ nhất trước')),
              const PopupMenuItem(value: 'HIGHEST_VALUE', child: Text('Giá trị xuất cao nhất')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary Metrics Banner
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF0F766E), AppColors.accent], // Teal gradient
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                _buildStatItem('Tổng phiếu', '$totalVouchers', Icons.receipt_long),
                Container(width: 1, height: 36, color: Colors.white24),
                _buildStatItem('Doanh thu xuất', CurrencyFormatter.formatVND(totalRevenue), Icons.payments_outlined),
                Container(width: 1, height: 36, color: Colors.white24),
                _buildStatItem('Lãi gộp ước tính', CurrencyFormatter.formatVND(totalProfit), Icons.trending_up),
              ],
            ),
          ),

          // Search Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm theo mã phiếu, bên nhận, chi nhánh, SKU...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                _buildFilterChip('Tất cả (${orders.length})', null),
                _buildFilterChip(
                  'Bán lẻ (${orders.where((o) => o.type == StockOutType.retail).length})',
                  StockOutType.retail,
                ),
                _buildFilterChip(
                  'Bán sỉ (${orders.where((o) => o.type == StockOutType.wholesale).length})',
                  StockOutType.wholesale,
                ),
                _buildFilterChip(
                  'Điều chuyển (${orders.where((o) => o.type == StockOutType.transfer).length})',
                  StockOutType.transfer,
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Order list
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.outbox, size: 64, color: Colors.grey),
                        const SizedBox(height: 8),
                        Text(
                          query.isNotEmpty
                              ? 'Không tìm thấy phiếu xuất nào phù hợp'
                              : 'Không có phiếu xuất nào trong danh mục này',
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const CreateStockOutScreen()),
                            );
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Tạo Phiếu Xuất Mới'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final order = filtered[index];
                      Color typeColor;
                      IconData typeIcon;
                      if (order.type == StockOutType.transfer) {
                        typeColor = AppColors.purple;
                        typeIcon = Icons.swap_horiz;
                      } else if (order.type == StockOutType.wholesale) {
                        typeColor = AppColors.accent;
                        typeIcon = Icons.store;
                      } else {
                        typeColor = AppColors.primary;
                        typeIcon = Icons.person;
                      }

                      return Card(
                        elevation: 1,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            order.orderNumber,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: typeColor.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(typeIcon, size: 12, color: typeColor),
                                              const SizedBox(width: 4),
                                              Text(
                                                order.type.label,
                                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: typeColor),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      DateFormatter.formatDateTime(order.createdAt),
                                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Icon(
                                      order.type == StockOutType.transfer
                                          ? Icons.location_on_outlined
                                          : Icons.person_outline,
                                      size: 16,
                                      color: AppColors.textSecondaryLight,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        order.type == StockOutType.transfer && order.destinationBranch != null
                                            ? '${order.receiverName} ➔ ${order.destinationBranch}'
                                            : order.receiverName,
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                // Preview danh sách mặt hàng
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: [
                                      ...order.items.take(3).map(
                                            (item) => Container(
                                              margin: const EdgeInsets.only(right: 6),
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade100,
                                                borderRadius: BorderRadius.circular(4),
                                                border: Border.all(color: Colors.grey.shade300),
                                              ),
                                              child: Text(
                                                '${item.skuName} (${item.quantity})',
                                                style: const TextStyle(fontSize: 10, color: Colors.black87),
                                              ),
                                            ),
                                          ),
                                      if (order.items.length > 3)
                                        Text(
                                          '+${order.items.length - 3} món khác',
                                          style: const TextStyle(fontSize: 10, color: AppColors.textSecondaryLight),
                                        ),
                                    ],
                                  ),
                                ),
                                const Divider(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${order.items.length} mặt hàng (${CurrencyFormatter.formatNumber(order.totalQuantity)} đơn vị)',
                                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                                    ),
                                    Text(
                                      CurrencyFormatter.formatVND(order.totalRevenue),
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primary),
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
      padding: const EdgeInsets.only(right: 6.0),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? AppColors.primary : Colors.black87,
          ),
        ),
        selected: isSelected,
        selectedColor: AppColors.primary.withValues(alpha: 0.15),
        checkmarkColor: AppColors.primary,
        onSelected: (_) => setState(() => _selectedTypeFilter = type),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.white70, size: 16),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
